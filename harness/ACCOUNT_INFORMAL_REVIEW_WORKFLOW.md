# 使用 Codex 账号复核 informal 草稿

这是按 [`PROOF_IDEA_DISTILLATION_PLAN.md`](../PROOF_IDEA_DISTILLATION_PLAN.md)
进行的一次账号试跑。使用已登录 ChatGPT 账号的 Codex，不需要 Python 或 API key。
复核 AI 只接收下方可复制的消息；不要提供原 Lean 证明或本文的操作说明。

## 脚本运行

在仓库根目录运行 `bash harness/run_account_informal_review.sh`，默认选择
`review_status` 为 `draft_not_reviewed` 的下一份草图。也可传入具体草图路径，
如 `bash harness/run_account_informal_review.sh harness/FiniteIndexSemisimpleSketch.tex`。
脚本核对冻结的 TeX 哈希和 gap 数量，自动生成输入，创建 `/tmp` 空工作目录，
通过 `codex exec` 新开账号复核线程，并把输入、原始回答、JSONL 事件和检查摘要
保存到 `harness/reviews/<草图名>_<UTC时间>/`。脚本不使用 API key。

检查 `summary.txt` 和 `events.jsonl`：只有完整运行、没有工具事件时，才能记录
“本轮未观察到文件读取”。这仍不是严格的文件系统隔离；`read-only` 不阻止读取。
若有工具事件或运行失败，先检查日志，不能把结果判为独立复核通过。

## 操作步骤

1. 新建一个**不含仓库文件的空目录**作为复核工作目录。在 Codex 中从该目录新建
   **新线程**；不要使用 Resume、Fork、子代理，或本仓库的工作树。
2. 只复制 `REVIEW MESSAGE START` 与 `REVIEW MESSAGE END` 之间的文字作为首条消息。
   不附源码、不贴仓库链接、不带入本次对话历史。要求本轮不调用工具，并记下模型。
3. 先保存首轮完整回答，再决定是否追问。把原始回答复制到结果文件。
4. 按文末模板记录结论。如果缺口或连接失败，先修订并冻结草稿，再用**另一个**
   新 Codex 线程复核。

如果使用本机 Codex CLI，可在终端中运行 `mkdir -p /tmp/ray-form-review`，然后运行
`codex --cd /tmp/ray-form-review --sandbox read-only` 并粘贴上述消息。当前本机
`codex login status` 显示通过 ChatGPT 登录。`read-only` 限制写入，但**不保证禁止读取**
其他目录；仅凭新线程和空目录不能严格证明复核者没有访问仓库。若日志显示读取了
原仓库，或无法核查实际可读范围，请将结果标为“回顾性阅读”。

## 首题的历史复核输入

REVIEW MESSAGE START

You are independently checking whether an informal proof sketch can be
reconstructed. Use only the statement, sketch, and allowed facts below. Do not
call tools, search for the original theorem, or use external files. Do not
assume the target theorem, an equivalent injectivity result, or linear
independence of a and b.

First, give a short, checkable informal proof of Gap 1. Second, do the same for
Gap 2. For each gap, state exactly which assumptions and allowed facts you use;
if it fails, state the missing condition or a possible counterexample. Third,
assuming only gaps you actually proved, reconstruct the full argument to the
target and check every intermediate step, quantifier, and hypothesis. Report
each gap as "proved informally", "conditional or doubtful", or "not proved";
report separately whether the full argument closes. Do not merely assert that
any step is obvious.

Target statement: For all complex numbers a and b such that
Im(conjugate(a) * b) is nonzero, the map F : Z × Z → C defined by
F(m,n) = m*a + n*b is injective. Integer coefficients are embedded in C.

Frozen sketch (LaTeX source; mathematical content is the review input):

```tex
\documentclass[11pt]{article}
\usepackage[T1]{fontenc}
\usepackage{amsmath,amssymb}
\usepackage[margin=1in]{geometry}

\title{Injectivity of the Integer Combination Map}
\author{}
\date{}

\begin{document}
\maketitle

Let $a,b\in\mathbb C$ satisfy
\[
  \Delta=\operatorname{Im}(\overline a b)\ne 0.
\]
We must show that $F:\mathbb Z^2\to\mathbb C$, defined by
$F(m,n)=ma+nb$, is injective. In particular, $a\ne0$, since
$a=0$ would make $\Delta=0$.

\section*{Main line}

Suppose $F(v)=F(w)$. Gap 2 reduces this equality to
$(v_1-w_1)a+(v_2-w_2)b=0$. Multiply by $\overline a$ and take
imaginary parts. Gap 1 gives $(v_2-w_2)\Delta=0$, so $v_2=w_2$.
The remaining equation is $(v_1-w_1)a=0$; because $a\ne0$, also
$v_1=w_1$. Thus $v=w$.

\section*{Gaps to prove independently}

\paragraph{Gap 1.}
For all $a,b\in\mathbb C$ and $m,n\in\mathbb Z$,
\[
  \operatorname{Im}\bigl(\overline a(ma+nb)\bigr)
  =n\operatorname{Im}(\overline a b).
\]
The integer coefficients are viewed as real scalars. This identity
isolates the coefficient of $b$.

\paragraph{Gap 2.}
For all $a,b\in\mathbb C$ and $v,w\in\mathbb Z^2$, if
$v_1a+v_2b=w_1a+w_2b$, then
$(v_1-w_1)a+(v_2-w_2)b=0$.

\section*{Allowed facts}

Use elementary complex arithmetic, that $\overline a a$ is real, and
the zero-product property for real and complex numbers. No result
asserting injectivity or linear independence of $a,b$ may be assumed.

\end{document}
```

REVIEW MESSAGE END

## 记录结果

把原始回答逐字保存在单独文件，并填写以下简要记录：

```text
Review date and time:
Model displayed in ChatGPT:
Sketch SHA-256: 0a042202d371ff57b982f8761e83bb99b76a6e9360847850d757eda320858a61
Gap 1: proved informally / conditional or doubtful / not proved
Gap 2: proved informally / conditional or doubtful / not proved
Full argument closes: yes / no / uncertain
Specific issue, if any:
Elapsed time, if measured:
Token usage: unavailable in account UI (unless displayed)
Reviewer context: new Codex thread in an empty directory; no repository,
                  proof, prior review, or connected tools supplied
```

这套流程控制聊天输入，不能证明绝对没有信息暴露。如果无法核查隔离条件，
按 plan 将本轮标为“回顾性阅读”，不要称为“独立复核”。
