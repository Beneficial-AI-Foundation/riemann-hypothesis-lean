# 定义发现与证明实验：计划和进度

> 历史实验记录。当前方向是[黎曼猜想证明思路提炼实验](PROOF_IDEA_DISTILLATION_PLAN.md)。

## 目标

让 AI 阅读完整的相关 Lean 证明库，从反复出现的数学结构中提出定义、实例、非实例和可复用引理。再挑选一些已有定理，分析新定义可能如何缩短或简化证明，并让独立的证明 agent 阅读该定义、尝试证明。Lean 检查证明是否正确；数学解释用于评价定义是否有价值。目前没有模型微调，也不以 80/20 划分作为主流程。

首个主题是 `GlobalInterpolation` 的短区间范数素数定理 `GlobalTheory.Hk.normPrimes_short_interval_lower`。研究目标和数学评价原则见 [`proposal.md`](proposal.md)。

## 当前进度（2026-11-24）

| 阶段 | 状态 | 结果 |
| --- | --- | --- |
| 证明库阅读 | 进行中 | 已阅读重点定理、`LFam`、短区间权重下界和范数素数构造；尚未逐一审阅目录内全部模块 |
| 首个候选定义与 Lean 检查 | 已完成 | `PrimeDetectingWeight`、实例、非实例与通用引理已通过编译；移除了与原辅助定理同陈述的特例以免直接暴露答案 |
| 定理选择与节省 token 的预分析 | 已完成首轮 | 分析 agent 只找到重点主定理这一道明显适用的非同义目标；节省 token 仍是预测 |
| 独立证明 agent 尝试 | 已完成首轮 | 在隔离题目中重建辅助定理和主定理；`lake env lean` 通过 |
| token 对照 | 未开始 | 尚无同题、同条件的无定义对照运行 |

## 首个候选：素数探测权重

[`PrimeDetectingWeight.lean`](src/Development/AbelianVarietyTheory/Definitions/GlobalTwisting/PrimeDetectingWeight.lean) 定义了非负且受 `2 * Λ` 控制的权重；权重在素数上的非零支撑落在目标谓词内。它把 `LFam` 的解析权重性质与所计数的素数性质分开。零权重和 von Mangoldt 权重是实例，后者在素数 `2` 处严格为正；在 `1` 处恒为 `1` 的权重是非实例。

通用引理把区间加权和限制在目标素数计数项与 `ψ - θ` 的素数幂误差项之内。原有的范数素数估计可由它导出，但候选库没有存放这个同陈述特例，以免证明 agent 直接引用答案。`lake env lean` 和该模块的 `lake build` 通过；主要引理只依赖 Lean 常用公理 `propext`、`Classical.choice`、`Quot.sound`。这是项目内的新抽象，尚无数学文献意义上的新颖性结论，也尚未显示节省 token。

## 接下来的实验步骤

1. **分析 agent：** 可阅读完整证明库，挑选与候选定义相关的已有定理。逐题记录原证明中的可替换片段、预期调用的新引理、为何可能降低证明成本，以及不适合该定义的例子。此时的“省 token”只是预测。
2. **证明 agent：** 每题使用干净上下文，给定定理陈述、原始依赖和冻结的候选定义/引理，尝试写出证明。为避免直接复述答案，任务文件隐藏该题的原证明和等价成品定理；分析 agent 的具体证明步骤不传给证明 agent。此隔离针对单题证明尝试，不限制前面的定义发现阶段阅读全库。若证明 agent 之前见过原证明，就将结果标为回顾性尝试。
3. **验证与记录：** Lean 编译目标证明，拒绝 `sorry`、`admit` 和新增 `axiom`。记录成功与失败、实际 token（若 API 提供思考 token 则单列）、总 token、耗时和证明长度。
4. **比较：** 若要报告“节省了多少 token”，对同一题再运行一次不提供候选定义的证明 agent，保持模型、工具、原始依赖、提示格式和预算相同，并分别清空上下文。没有此对照，只报告使用定义时的结果，不称为节省。已在定义发现阶段看过证明的题目，可用于回顾性工具比较，但不能声称对未见题目的泛化能力。

## 已有辅助工具

`scripts/split_theorems.py` 和 `theorem-split.json` 是此前实现的 80/20 位置清单；它们不参与上述主流程，也不保证题目独立。`scripts/make_isolated_target.py` 可生成重点定理的无原证明任务和 `harness/NormPrimesTask.check.json`，验证原证明可通过而空证明及直接引用目标被拒绝。单题隔离工具仍可复用，但目前只支持该重点定理。现有 Python 单元测试共 5 项。

## 首轮证明尝试结果

分析 agent 检索后只找到 `normPrimes_short_interval_lower` 这一道明显适用的非同义目标。它指出原候选库含有与辅助定理完全同陈述的特例，原隔离题目也保留辅助定理原证明；两处均已从本轮输入中移除。新的 [`NormPrimesDetectorProbe.lean`](harness/NormPrimesDetectorProbe.lean) 隐藏辅助定理和主定理的原证明，仅导入通用候选库与原始前置结果。

另一个从干净上下文开始的证明 agent 在该文件中完成两个证明。辅助定理调用 `PrimeDetectingWeight.ofLFam` 与 `sum_Ioc_le_prime_count`，主定理再使用辅助定理、原始短区间下界、射线族存在性和 Chebyshev 误差界。`lake env lean harness/NormPrimesDetectorProbe.lean` 通过，无 `sorry`、`admit` 或新增 `axiom`；公理扫描仅列出 `propext`、`Classical.choice`、`Quot.sound`。辅助定理的证明明显缩短，主定理的新证明文本则比原版长。这是已知定理的回顾性重建；尚无无定义对照、API 思考 token 数据或跨题复用，因此不能声称节省 token。

## 限制

- 目前只阅读了一个连贯证明链，候选定义还需检查跨题复用和数学意义。
- 现有隔离题目仍保留目标前的两个辅助定理；每道新题都要检查 imports 和等价包装能否直接暴露答案。
- 单个定理的 token 差异不足以评价定义；证明成功率和多题复用更重要。
