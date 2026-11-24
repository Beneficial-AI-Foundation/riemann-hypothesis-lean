# 单个 Lean 定理的证明思路提炼实验

## 目标

先用已有的子定理 `GlobalTheory.Hk.normPrimes_short_interval_lower` 测试“非形式化证明思路能否指导 AI 重建 Lean 证明”。阅读该定理及必要的前置结果，写一份不超过 500 词的 informal Markdown；让独立的证明 AI 只凭定理陈述、允许的前置结果和这份说明完成 Lean 证明。随后逐版提炼说明，寻找更少的词数或更少的 thinking token，同时保持证明成功。

本轮只研究这个已知定理的回顾性重建。不扩展到 `Main.lean` 的主证明链，也不把结果解释为对黎曼猜想整体证明的审查。

## 当前进度

英文 summarizer 提示词与运行脚本已实现，首版 [`NormPrimesProofIdea.md`](harness/NormPrimesProofIdea.md) 为 227 词，已保存来源哈希。证明 agent 尚未实现，也尚未测试这份说明能否帮助重建证明。

## 固定题目和隔离

目标文件是 `src/Development/AbelianVarietyTheory/Proofs/GlobalInterpolation/NormPrimesImagQuadShortIntervalLowerBound.lean`。已有的 `harness/NormPrimesDetectorProbe.lean` 表明：给定候选定义后，证明 AI 可以在隐藏原证明的题目里重建辅助定理 `sum_lam_zero_le_card_normPrimes` 和主定理。新实验以同一对定理为对象，但不给证明 AI 先前生成的完整证明。

两道定理的原证明都必须从题目输入中移除；导入不能暴露它们或同义成品定理。现有 `harness/NormPrimesTask.lean` 保留了辅助定理原证明，不能直接作为新实验题目。记录固定的源码提交、Lean/Mathlib 版本、题目文本、允许导入和提示格式。`PrimeDetectingWeight` 属于先前定义发现实验，本轮默认不提供；若日后比较定义的作用，须另设单独条件。

## 证明 agent 的实施计划

参考 `/home/zhang-liao/auto_verify_dalek` 的 agent 运行方法，实施顺序如下；本节目前只是设计，不表示代码已经复制或证明实验已经运行。

1. **移植最小运行层。** 核对该项目的 agent 启动、会话隔离、进程组超时、逐轮日志和 Lean 检查代码。只复制当前试验实际需要的部分及许可证，并记录上游文件哈希；针对本仓库单独写入口，不直接搬用其针对 Dalek 的大型 driver、任务说明或验证规则。
2. **准备不可泄题的工作区。** 工作区只包含允许的 Lean 前置模块、两道定理的无证明题目和待测试的 Markdown。隐藏原目标文件、`NormPrimesDetectorProbe.lean`、历史证明日志、同义成品定理和 `.git` 历史；校验导入链与编译产物不能提供目标结论。证明 agent 的工具只访问该工作区。
3. **运行成对试验。** 同一个英文证明任务模板在两种条件下运行：无 Markdown 基线，以及附上某一冻结版本的 Markdown。每次使用独立的新会话和工作区，并固定模型、允许工具、时间与轮数预算。允许 agent 编辑题目中的证明位置和调用 Lean 检查；不向它提供 summarizer 的源码阅读记录或先前完成的证明。
4. **独立验收。** 在 agent 结束后由 harness 对最终 Lean 文件重新编译，检查两道定理的陈述未改、无 `sorry`/`admit`/新增 `axiom`、无额外导入或直接引用目标，并记录实际公理依赖。agent 自报成功或一次局部编译成功均不代替验收。
5. **保留完整证据。** 每次运行保存输入文件与提示词哈希、模型和工具配置、原始事件日志、最终证明、Lean 诊断、耗时和 API 报告的 token 用量。若提供商没有单列 thinking token，则记录“不可得”，不从文本长度推算。

第一个实施里程碑是可审阅的隔离题目与一次不调用模型的预检。通过后才运行无说明与首版说明的证明 agent。

## 单题流程

1. **写说明。** 阅读原证明和必要背景，写不超过 500 词的英文 informal Markdown，按空白分词记录词数。说明数学目标、关键中间命题、转化顺序和容易遗漏的条件；不粘贴 Lean 证明或逐行 tactic 脚本。
2. **建立基线。** 在全新上下文中，只提供隔离题目、原始前置结果、固定工具与预算，不提供说明。记录能否重建两道定理。
3. **测试说明。** 用相同模型、工具、提示格式、依赖和预算，在另一全新上下文中提供该版说明。编译提交的 Lean 证明，拒绝 `sorry`、`admit`、新增 `axiom` 和从导入中直接引用目标。
4. **记录结果。** 每次保存说明版本和词数、输入 token、输出 token、API 实际报告的 thinking token（若可得）、总 token、耗时、两道定理是否分别通过及失败原因。API 未提供 thinking token 时，不用耗时或文本长度代替。
5. **逐版提炼。** 根据失败和成功的记录修改说明。优先删去不影响重建的句子，或加入能减少搜索成本的关键提示。每版都在全新上下文中测试，不把上一版的完成证明交给证明 AI。

## 如何判断改进

- 同一版本重复运行，分别报告通过率和已通过运行的 thinking token 分布；不能凭单次运行认定“同样多”或“更少”。
- 保留两类有价值的版本：词数更少且成功率、thinking token 基本不变；或词数不增加且成功率不降、thinking token 更少。
- 把说明的输入 token 与证明 AI 的 thinking token 分开记录。若说明更短但导致反复失败，不能只看一次成功的 token 数。
- 本题的结果只能说明这道已知题上的效果。是否能迁移到其他定理，留待以后另行测试。

## 近期交付物

1. 隐藏辅助定理和主定理原证明的固定隔离题目及其预检。
2. 按上述计划移植证明 agent，运行无说明基线和现有 227 词说明。
3. 至少一轮有记录的说明修订，比较词数、通过率及可用的 thinking token 数据。

先前的定义发现实验见 [THEOREM_DISCOVERY_HARNESS_PLAN.md](THEOREM_DISCOVERY_HARNESS_PLAN.md)；本轮不以新定义为目标。
