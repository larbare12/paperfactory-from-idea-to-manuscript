论文写作规范

一、Overleaf 项目命名规范

Overleaf 网站上的论文项目名统一按照该格式命名：姓名_标题_类型0x_年月

二、内容

1. 数学符号

数学符号在文中第一次出现要给出相应的定义，位置可以是出现之前，

也可以是出现之后不远的地方。

2. 缩写

第一次出现，要给出全称+缩写，之后出现，只用缩写即可

对上一条的补充：摘要中出现的全称+缩写，正文中不能直接用缩写，要重新定义

全称的首字母可以大写也可以不大写，但是在一篇论文中要统一

上一条的补充：以人名命名的术语、专有名词在任何情况下都要大写，

3. 格式

3.1 公式模块

有关代码块或公式块下面针对数学符号的解释不进行缩进，即where前无缩进

3.2 证明模块

如果投稿IEEE Trans的期刊，请不要使用其他自己添加的命令，请用原模板自带证明命令：

\begin{IEEEproof}

...

\end{IEEEproof}

4. 注意事项：

所有的section x里的x都必须要通过\label{yy}, \ref{yy}命令引用具体位置，不可以手打，以养成良好写作习惯。

保证行文简洁清晰、直达要点，避免空话、重复表达。写完关键句后，可将其用翻译软件/AI直译回中文进行核对，确认译文与自己想表达的意思一致。

三、参考文献

1. 代码

2. 效果

3. 规则说明

4.  特殊符号输入技巧

“比如引号、破折号、特殊字符等，请用Latex命令，而不是直接用中文系统里的字符，这样的字符在ASCII码环境下都是乱码。比如

引号应该用 `` <quoted text here> '' 。

在 LaTeX 中打破折号（破折号对应英文的 em-dash），最常用和标准的方法是输入三个连字符 ---，这会生成一个长破折号；表示范围的短横线（en-dash）用 --；而单词内的连字符（hyphen）用单个 -。

特殊字母应该用下面表格：”

四、其他

1. 中-英文表述

引号，破折号，双破折号容易引发在英文环境下的乱码，编译时不要开中文环境

xxx-which xxx-xxx这样的表述很AI，应注意转化为正常

2. 作者

通讯作者应在最后的版本中进行标注，投稿时不必标注

基金内容应在提交终稿前进行确认下

最后个人简介的照片（eps格式）一般来说不应超过2M，个人简介及照片在投稿时不要添加，除非刊物特别要求

论文版本中的左上角版本应该按照不同的类型进行相应的调整

五、最终版本确认与检查

最终版本提交给王老师或者刘老师之前，必须要自查 （以下引用王老师原文）：

1.  如果确定投某个刊物，自己查查投该刊物的要求（篇幅限制、单盲双盲等等），

并请教组里投过该刊物的同学；

在Letpub、小红书、小木虫等媒体做调查；


| 以下蓝字添加部分源自王子栋教授于2025年12月6日-12月19日期间对我们论文的指导与提醒，部分引用王老师的原话。目前已经整合进原有版本，欢迎大家补充完善。
这里重点感谢王老师对我们小组的辛劳与付出！ |


| 姓名 | 英文，姓用全拼，名用首字母 |
标题 | 关键词的首字母缩写 |
类型0x | 后面的0x表示第x版，final后可不加版本。 |
年月 | 2位年份+2位月份 |


| 例：Y.Nie_EM-SDPD_final_2409，或 Z.Wang_DRL-AF_paper02_2407 |


| 例：Define $x \triangleq ...$, ... |


| 例：where $x$ denotes ... |


| 例：particle filter (PF)......PF...... |


| 例：support vector machine (SVM) 或 Support Vector Machine (SVM) |


| 例：Kalman filter (KF)、Internet of Things (IoT) |


|  |


| LaTeX
\begin{thebibliography} {00}  

\bibitem{xxx}
xxx...

\bibitem{chang1984application}
C.~Chang, and J.~Tabaczynski, ``Application of state estimation to target tracking,'' \emph{IEEE Transactions on automatic control}, vol.~29, no.~2, pp. 98--109, 1984.

\bibitem{xxx}
xxx...

\end{thebibliography} |


| 作者 | 名用大写首字母+「.」，姓用全拼
最后一个作者前面的「and」也要加「,」 |
标题 | 句首单词首字母大写，专有名词首字母大写
前后加引号（「``」和「''」）【上述引号可以不用加，2025. 12. 6】，标题末尾的「,」在引号内 |
期刊 | 斜体，用\emph{}、\textit{}或{\it }
每个单词首字母大写，介词、连词等小写 |
卷/期/页/年 | 无 |


| 参考文献请按alphabetical order排序，即按照名字首字母进行排序 |


| 例：{\it (Corresponding author: Qinyuan Liu)}} |


| 例：\markboth{{\it Final version}}、\markboth{{\it Revision}} |

