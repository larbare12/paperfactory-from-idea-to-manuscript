# M8 格式检查模块

## 功能
期刊格式、参考文献、最终提交检查

## 输入
- 最终稿件（LaTeX/Word）
- 期刊模板
- 提交要求
- 作者信息

## 输出
- 格式合规检查报告
- 参考文献格式校正
- 图表规范检查
- 提交前最终清单
- 修改建议

## 使用场景
1. 投稿前最终检查
2. 转投不同期刊格式转换
3. 回应格式相关审稿意见
4. 最终版本准备

## 格式检查清单

### 文档结构
- [ ] 是否包含所有必需章节？
- [ ] 章节顺序是否正确？
- [ ] 页码是否连续？
- [ ] 目录是否完整？

### 标题和作者
- [ ] 标题长度是否符合要求？
- [ ] 作者信息是否完整？
- [ ] 单位信息是否正确？
- [ ] 通讯作者是否标注？
- [ ] 邮箱格式是否正确？

### 摘要和关键词
- [ ] 摘要字数是否符合要求？
- [ ] 关键词数量是否符合要求？
- [ ] 是否包含非缩写形式？

### 正文格式
- [ ] 字体、字号是否符合要求？
- [ ] 行距、页边距是否正确？
- [ ] 段落缩进是否统一？
- [ ] 公式编号是否连续？

### 图表
- [ ] 图表编号是否连续？
- [ ] 图表标题是否完整？
- [ ] 图表清晰度是否足够？
- [ ] 图表位置是否正确？
- [ ] 颜色是否适合黑白打印？

### 参考文献
- [ ] 格式是否符合要求（IEEE/ACM/APA）？
- [ ] 是否按字母序/出现顺序排列？
- [ ] 是否包含所有引用？
- [ ] 是否有未引用文献？
- [ ] DOI/URL 是否完整？

### 附录
- [ ] 附录编号是否正确？
- [ ] 补充材料是否完整？
- [ ] 代码/数据链接是否有效？

## 期刊特定要求

### IEEE Transactions
- 双栏格式
- 公式使用 IEEEeqnarray
- 图表放在顶部或底部
- 参考文献按出现顺序编号

### ACM
- 单栏或双栏（视会议）
- 使用 acmart 模板
- CCS 概念和关键词
- 图表使用 figure/table 环境

### NeurIPS/ICML/ICLR
- 单栏，9页限制（含参考文献）
- 第9页只允许参考文献
- 使用 provided style file
- 匿名评审要求

### ACL/EMNLP
- 单栏或双栏
- 使用官方模板
- 匿名评审要求
- 限制页数（通常8页正文+参考文献）

## LaTeX 格式检查

### 编译检查
```bash
# 检查编译错误
pdflatex paper.tex

# 检查引用
bibtex paper
pdflatex paper.tex
pdflatex paper.tex

# 检查警告
# 注意 Overfull/Underfull hbox/vbox
```

### 常见 LaTeX 错误
| 错误 | 修正 |
|-----|------|
| Overfull hbox | 调整公式或换行 |
| 引用未定义 | 多次编译或检查 bib |
| 图片未找到 | 检查路径和文件名 |
| 字体缺失 | 安装相应字体包 |

## 图表规范

### 图片
- 分辨率：≥300 dpi（印刷）
- 格式：矢量图优先（PDF/EPS）
- 字体：≥8 pt
- 颜色：考虑黑白打印可读性

### 表格
- 使用三线表
- 对齐：数字右对齐，文本左对齐
- 单位：明确标注
- 注释：放在表格下方

### 示例
```latex
% 图片
\begin{figure}[t]
\centering
\includegraphics[width=0.8\linewidth]{figure.pdf}
\caption{Caption text.}
\label{fig:example}
\end{figure}

% 表格
\begin{table}[t]
\centering
\caption{Caption text.}
\label{tab:example}
\begin{tabular}{lcc}
\toprule
Method & Accuracy & F1 \\
\midrule
Method A & 85.2 & 0.823 \\
Method B & 87.5 & 0.856 \\
\bottomrule
\end{tabular}
\end{table}
```

## 参考文献格式

### IEEE 格式
```
[1] C. Chang and J. Tabaczynski, ``Application of state 
estimation to target tracking,'' \emph{IEEE Trans. Autom. 
Control}, vol. 29, no. 2, pp. 98--109, 1984.
```

### ACM 格式
```
[1] Chang, C. and Tabaczynski, J. 1984. Application of 
state estimation to target tracking. \emph{IEEE Trans. 
Autom. Control} 29, 2, 98--109.
```

## 提交前最终清单

### 内容检查
- [ ] 标题准确反映内容
- [ ] 摘要独立可读
- [ ] 引言清晰陈述贡献
- [ ] 方法可复现
- [ ] 实验充分
- [ ] 结论明确

### 格式检查
- [ ] 符合期刊模板
- [ ] 页数符合要求
- [ ] 图表清晰
- [ ] 参考文献完整
- [ ] 无编译错误

### 语言检查
- [ ] 拼写检查
- [ ] 语法检查
- [ ] 术语一致
- [ ] 时态正确

### 提交材料
- [ ] 主文档（PDF）
- [ ] 源文件（LaTeX/Word）
- [ ] 补充材料（如有）
- [ ] 作者信息表
- [ ] 版权/利益冲突声明
- [ ] Cover letter（如需要）

## 示例 Prompt

```
请帮我检查以下论文的格式：

论文文件：[上传]
目标期刊：[填入]
提交要求：[粘贴]

请输出：
1. 格式合规检查报告
2. 参考文献格式问题
3. 图表规范问题
4. 修改建议
5. 提交前最终清单
```

## 常见格式问题

| 问题 | 影响 | 修正 |
|-----|------|------|
| 页数超限 | 直接拒稿 | 精简内容 |
| 格式不符 | 印象差 | 使用官方模板 |
| 图表模糊 | 可读性差 | 使用矢量图 |
| 引用格式混乱 | 不专业 | 统一格式 |
| 缺少材料 | 不完整 | 补充齐全 |

## 参考资源
- 参见 refence/ACADEMIC-WRITING-GUIDE.md 第三部分
