#!/bin/bash
# 论文引用验证包装器
# 用法:
#   bash script/paper/verify_citations.sh <draft.md|draft.tex> [--bib <file.bib>]
#
# 功能:
#   1. 从草稿文件中提取引用 key（LaTeX \cite{} 或 Markdown @key）
#   2. 从 BibTeX 文件解析 title/doi/year/authors
#   3. 调用 paper_search.sh --mode verify 逐条校验
#   4. 生成分类报告到 relate-work/citation_verification_report_<timestamp>.md
#
# 示例:
#   bash script/paper/verify_citations.sh relate-work/draft.tex --bib relate-work/references.bib

set -e

# 初始化（v0.6+：拆分 SKILL_DIR / PROJECT_DIR）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAPER_SKILL_DIR="${PAPER_SKILL_DIR:-${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}}"
PAPER_PROJECT_DIR="${PAPER_PROJECT_DIR:-$PWD}"
PROJECT_ROOT="${PAPER_SKILL_DIR}"  # back-compat alias

source "$SCRIPT_DIR/load_config.sh"

# ---- 参数解析 ----
DRAFT_FILE=""
BIB_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bib)   BIB_FILE="$2"; shift 2 ;;
        --bib=*) BIB_FILE="${1#--bib=}"; shift ;;
        *)
            if [[ -z "$DRAFT_FILE" ]]; then
                DRAFT_FILE="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$DRAFT_FILE" ]]; then
    echo "Usage: $0 <draft.md|draft.tex> [--bib <file.bib>]" >&2
    exit 1
fi

if [[ ! -f "$DRAFT_FILE" ]]; then
    echo "Error: Draft file not found: $DRAFT_FILE" >&2
    exit 1
fi

# 自动查找 BibTeX 文件
if [[ -z "$BIB_FILE" ]]; then
    DRAFT_DIR="$(dirname "$DRAFT_FILE")"
    BIB_FILE=$(find "$DRAFT_DIR" -maxdepth 2 -name "*.bib" -type f 2>/dev/null | head -1)
    if [[ -z "$BIB_FILE" ]]; then
        echo "Error: No .bib file found near draft. Specify with --bib" >&2
        exit 1
    fi
fi

if [[ ! -f "$BIB_FILE" ]]; then
    echo "Error: BibTeX file not found: $BIB_FILE" >&2
    exit 1
fi

# ---- Step 1: 从草稿提取 BibTeX keys ----
# 支持 LaTeX (\cite{key}, \citep{key}, \citet{key}, \parencite{key})
# 和 Markdown (@key 形式，常见于 Pandoc/RMarkdown)
extract_citation_keys() {
    local draft="$1"
    local ext="${draft##*.}"

    if [[ "$ext" == "tex" || "$ext" == "latex" ]]; then
        grep -oP '\\cite[ptea]?\*?\s*\{[^}]+\}' "$draft" 2>/dev/null \
            | grep -oP '\{[^}]+\}' \
            | tr -d '{}' \
            | tr ',' '\n' \
            | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
            | sort -u \
            | grep -v '^$'
    else
        grep -oP '@[a-zA-Z0-9_:-]+' "$draft" 2>/dev/null \
            | sed 's/^@//' \
            | sort -u \
            | grep -v '^$'
    fi
}

echo "Extracting citation keys from $DRAFT_FILE ..." >&2
KEYS=$(extract_citation_keys "$DRAFT_FILE")
if [[ -z "$KEYS" ]]; then
    echo "No citation keys found in $DRAFT_FILE" >&2
    exit 0
fi

TOTAL=$(echo "$KEYS" | wc -l | tr -d ' ')
echo "Found $TOTAL unique citation keys" >&2

# ---- Step 2: 从 BibTeX 解析为 NDJSON (perl, 因 Windows 无 python3) ----
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

KEYS_FOR_PERL=$(echo "$KEYS" | tr '\n' ' ')
perl -e '
use strict;
my ($bibfile, $keystr) = @ARGV;
my %targets = map { $_ => 1 } split /\s+/, $keystr;

open my $fh, "<:encoding(UTF-8)", $bibfile or die "Cannot open $bibfile: $!";
local $/; my $content = <$fh>; close $fh;

for my $entry (split /@[\w]+\s*\{/, $content) {
    next unless $entry =~ /^([\w:.@\/-]+)\s*,/m;
    my $key = $1;
    next unless $targets{$key};

    my %fields;
    while ($entry =~ /(\w+)\s*=\s*(?:\{([^}]*)\}|"([^"]*)"|(\d+))/g) {
        my $name = lc($1);
        my $val = defined($2) ? $2 : (defined($3) ? $3 : $4);
        $val =~ s/^\s+|\s+$//g;
        $fields{$name} = $val;
    }

    # JSON encode (simple: escape backslash, quote, newline)
    my %out;
    $out{key} = $key;
    $out{title} = $fields{title} // $key;
    $out{doi} = $fields{doi} // "";
    $out{year} = $fields{year} // "";
    $out{authors} = $fields{author} // "";

    for my $v (values %out) {
        $v =~ s/\\/\\\\/g;
        $v =~ s/"/\\"/g;
        $v =~ s/\n/\\n/g;
    }

    printf "{\"key\":\"%s\",\"title\":\"%s\",\"doi\":\"%s\",\"year\":\"%s\",\"authors\":\"%s\"}\n",
        $out{key}, $out{title}, $out{doi}, $out{year}, $out{authors};
}
' "$BIB_FILE" "$KEYS_FOR_PERL" > "$TMPDIR/input.ndjson"

RESOLVED=$(wc -l < "$TMPDIR/input.ndjson" | tr -d ' ')
UNRESOLVED=$((TOTAL - RESOLVED))
echo "Resolved $RESOLVED / $TOTAL keys from BibTeX" >&2

# ---- Step 3: 运行 paper_search.sh --mode verify ----
echo "Running S2 Tier 0 verification ..." >&2

bash "$SCRIPT_DIR/paper_search.sh" --mode verify --input "$TMPDIR/input.ndjson" > "$TMPDIR/verdicts.ndjson" 2>/dev/null || true

VERIFIED=$(grep -c '"VERIFIED"' "$TMPDIR/verdicts.ndjson" 2>/dev/null || echo "0")
FAILED=$((RESOLVED - VERIFIED))

# ---- Step 4: 生成报告 (perl) ----
# 报告写入论文项目目录（PROJECT_DIR），不是 skill 目录
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_PATH="$PAPER_PROJECT_DIR/relate-work/citation_verification_report_${TIMESTAMP}.md"

mkdir -p "$PAPER_PROJECT_DIR/relate-work"

NOW=$(date -Iseconds 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")

perl -e '
use strict;
my ($verdicts_file, $draft, $bib, $now) = @ARGV;

my @verdicts;
open my $vf, "<", $verdicts_file or die "Cannot open $verdicts_file: $!";
while (my $line = <$vf>) {
    chomp $line;
    next unless $line =~ /\S/;
    # Simple JSON parse (handles our known format)
    my %v;
    for my $k (qw/input_title verdict s2_id match_score hallucination_class notes key/) {
        if ($line =~ /"$k"\s*:\s*"([^"]*)"/) {
            $v{$k} = $1;
        } elsif ($line =~ /"$k"\s*:\s*(null|true|false)/) {
            $v{$k} = $1;
        }
    }
    if ($line =~ /"match_score"\s*:\s*([\d.]+)/) {
        $v{match_score} = $1;
    }
    push @verdicts, \%v;
}
close $vf;

my $total = scalar @verdicts;
my $verified = grep { $_->{verdict} eq "VERIFIED" } @verdicts;
my $failed = $total - $verified;
my $pct = $total > 0 ? sprintf("%.0f", $verified / $total * 100) : 0;

# Group by class
my %classes = (
    TF => [], PAC => [], IH => [], PH => [], SH => [],
    DOI_MISMATCH => [], S2_NOT_FOUND => [], S2_UNAVAILABLE => []
);
for my $v (@verdicts) {
    my $vd = $v->{verdict} // "";
    next if $vd eq "VERIFIED";
    my $hc = $v->{hallucination_class} // "";
    $hc =~ s/^"|"//g;  # strip quotes
    if ($vd eq "DOI_MISMATCH") { push @{$classes{DOI_MISMATCH}}, $v; }
    elsif ($vd eq "S2_NOT_FOUND") { push @{$classes{S2_NOT_FOUND}}, $v; }
    elsif ($vd eq "S2_UNAVAILABLE") { push @{$classes{S2_UNAVAILABLE}}, $v; }
    if ($hc && exists $classes{$hc}) {
        # avoid duplicate
        my $found = 0;
        for my $e (@{$classes{$hc}}) {
            $found = 1 if $e == $v;
        }
        push @{$classes{$hc}}, $v unless $found;
    }
}

my $R = "";
$R .= "# Citation Verification Report\n\n";
$R .= "**Date**: $now\n";
$R .= "**Draft**: $draft\n";
$R .= "**BibTeX**: $bib\n";
$R .= "**Total citations**: $total\n";
$R .= "**Verified**: $verified ($pct%)\n";
$R .= "**Failed**: $failed\n\n";
$R .= "## Failures by class\n\n";

for my $cls (qw/TF PAC IH PH SH DOI_MISMATCH S2_NOT_FOUND S2_UNAVAILABLE/) {
    my $label = $cls;
    $label .= " (may exist outside S2)" if $cls eq "S2_NOT_FOUND";
    $R .= "### $label\n";
    if (@{$classes{$cls}}) {
        for my $v (@{$classes{$cls}}) {
            my $k = $v->{key} // "?";
            my $t = $v->{input_title} // "unknown";
            my $n = $v->{notes} // "";
            my $s = $v->{match_score} // "0";
            if ($n) {
                $R .= "- **$k**: $t \xe2\x80\x94 $n\n";
            } else {
                $R .= "- **$k**: $t (score=$s)\n";
            }
        }
    } else {
        $R .= "- (none)\n";
    }
    $R .= "\n";
}

$R .= "## Audit trail\n\n\`\`\`ndjson\n";
for my $v (@verdicts) {
    my $line = "{";
    my @parts;
    for my $k (qw/input_title verdict s2_id match_score hallucination_class notes/) {
        my $val = $v->{$k} // "null";
        if ($val eq "null" && $k ne "match_score") {
            push @parts, "\"$k\": null";
        } elsif ($k eq "match_score") {
            push @parts, "\"$k\": $val";
        } else {
            push @parts, "\"$k\": \"$val\"";
        }
    }
    $line .= join(", ", @parts) . "}";
    $R .= "$line\n";
}
$R .= "\`\`\`\n";

print $R;
' "$TMPDIR/verdicts.ndjson" "$DRAFT_FILE" "$BIB_FILE" "$NOW" > "$REPORT_PATH"

echo "" >&2
echo "=== Verification Summary ===" >&2
echo "Total: $RESOLVED | Verified: $VERIFIED | Failed: $FAILED" >&2
echo "Report: $REPORT_PATH" >&2
