# 短区间范数素数定理：逐轮精简计划

## 目标与范围

目标文件：`src/Development/AbelianVarietyTheory/Proofs/GlobalInterpolation/NormPrimesImagQuadShortIntervalLowerBound.lean`。

固定主定理 `GlobalTheory.Hk.normPrimes_short_interval_lower` 的名称、所在命名空间和完整陈述，只精简证明实现。保持现有数学结论和上游调用方可用。允许整理本文件内的辅助引理，但不能通过新增 `axiom`、`sorry`、`admit`、削弱假设或更换成未经证明的结论来缩短代码。

主定理原始声明（截至计划创建时，原文件第 98 行）：

```lean
theorem normPrimes_short_interval_lower : ∃ A c c' : ℝ, 0 < A ∧ 0 < c ∧ 0 < c' ∧ ∀ (d M : ℕ) (X h : ℝ), d.Prime → d % 4 = 3 → 100 ≤ d → 3 ≤ M → 1 ≤ X → Real.log (4 * (d : ℝ) * (M : ℝ) ^ 2) ≤ c * Real.sqrt (Real.log X) → Real.exp (-c * Real.sqrt (Real.log X)) ≤ h → h ≤ 1 → c' * h * X / ((4 * (d : ℝ) * (M : ℝ) ^ 2) ^ A * Real.log X) ≤ ((GlobalTheory.Mem.An.normPrimes d M X (X * (1 + h))).card : ℝ) := by
```

这行声明连同末尾换行的 SHA-256 为 `bdf5805bb40e62695526f71dff76365928bb39b227c7965a1dd03954868277c2`。每轮从当前文件提取以 `theorem normPrimes_short_interval_lower :` 开头的行并核对该哈希；如必须调整格式，先单独确认陈述在 Lean 中定义等价，不能把格式变化混在证明精简中。

## 基线

| 指标 | 当前值 |
| --- | ---: |
| 文件总行数 | 149 |
| 主定理证明体 | 49 行（原文件第 99–147 行） |
| 本文件辅助引理 | 2 个：`sum_lam_zero_le_card_normPrimes`、`sqrt_le_short_main` |
| 项目内传递依赖 | 约 60,668 行；按导入闭包去重，Mathlib 不计入 |

本计划创建时**不运行编译**。正式改动前，先记录一次 `lake build Development.AbelianVarietyTheory.Proofs.GlobalInterpolation.NormPrimesImagQuadShortIntervalLowerBound` 的基线结果、耗时和资源占用。若基线失败，先定位原始失败，避免把它归因于重构。

## 逐轮自动重构

每轮只处理一个小的证明片段：改动、核对固定声明、构建目标模块、记录行数和结果，再进入下一轮。已有构建产物用于增量构建，不运行整个库的 `lake build`。

1. **清理主证明中的中间步骤。** 从明显的候选项开始，例如 `hY2`、`H5`；先确认后续 tactic 没有隐式使用，再删除。合并只为一次调用服务的等式或不等式，保持证明结构可读。
2. **精简主证明的估计链。** 检查 `H1` 至 `H7`、`hlog`、`hsq` 的局部推导；优先用已有引理直接组合，减少重复的 `set`、`rw` 和算术收尾。每次替换后单独构建，避免一次性改变多个 tactic 的上下文。
3. **精简 `sqrt_le_short_main`。** 检查对数、指数和平方根转换中能否复用已得到的事实；保留正性条件和分母非零的显式依据，不用更脆弱的自动化掩盖关键论证。
4. **精简 `sum_lam_zero_le_card_normPrimes`。** 检查素数与非素数两部分求和的重复展开和中间等式；保持该引理陈述不变，除非确认它只在本文件使用且改动能明显缩短总证明。
5. **收尾。** 删除重构后确实无用的本地辅助步骤，整理名称和缩进；复查所有调用方所需的导出定理名称与陈述，并再次构建目标模块。

## 每轮验收与记录

- 固定主定理声明的哈希保持一致；`git diff` 中没有陈述、假设或新增公理的变化。
- 目标模块的 `lake build` 成功，且不出现新增的 `sorry`、`admit` 或编译警告。
- 记录文件总行数、主证明体行数、改动内容、构建耗时和构建结果。仅在证明更短且可读性不下降时保留该轮改动；否则回退该轮局部改动。
- 最后检查 `git diff --check` 和工作区状态。若资源不足导致构建未完成，记录为“未验证”，不标记为成功。

| 轮次 | 改动 | 文件行数 | 主证明体行数 | 构建结果 | 备注 |
| --- | --- | ---: | ---: | --- | --- |
| 基线 | 原始文件 | 149 | 49 | 待执行 | 仅完成静态分析 |
