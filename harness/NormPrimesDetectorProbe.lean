import Mathlib
import Development.AbelianVarietyTheory.Definitions.GlobalTwisting.PrimeDetectingWeight
import Development.AbelianVarietyTheory.Definitions.GlobalTwisting.LamIdealOfNotPrimePow
import Development.AbelianVarietyTheory.Proofs.GlobalInterpolation.TrivialClassShortIntervalStatement
import Development.AbelianVarietyTheory.Proofs.GlobalInterpolation.ExistsLFamRayStatement
open Complex ArithmeticFunction MeasureTheory Filter Topology NumberField GlobalTheory.Hk GlobalTheory.Mem
open scoped Classical

namespace GlobalTheory.Hk


theorem sum_lam_zero_le_card_normPrimes (𝓕 : LFam) (d M : ℕ)
    (hN : ∀ p : ℕ, p.Prime → 𝓕.lam 0 p ≠ 0 → GlobalTheory.Mem.An.NormOne d M p) (X Y : ℝ) (hY : 1 ≤ Y) :
    ∑ n ∈ Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊, 𝓕.lam 0 n ≤
      2 * Real.log Y * ((GlobalTheory.Mem.An.normPrimes d M X Y).card : ℝ) +
        2 * (Chebyshev.psi Y - Chebyshev.theta Y) := by
  simpa only [PrimeDetectingWeight.ofLFam_weight, GlobalTheory.Mem.An.normPrimes] using
    (PrimeDetectingWeight.sum_Ioc_le_prime_count
      (PrimeDetectingWeight.ofLFam 𝓕 hN) X Y hY)

theorem sqrt_le_short_main {A K c B X h : ℝ} (hA : 0 < A) (hK : 0 < K) (hc : 0 < c)
    (hcT : c ≤ 1 / (2 * (1 + A) + 2 + K)) (hB : 4 ≤ B) (hX : 1 ≤ X)
    (hBX : Real.log B ≤ c * Real.sqrt (Real.log X))
    (hh : Real.exp (-c * Real.sqrt (Real.log X)) ≤ h) :
    1 ≤ Real.log X ∧ K * Real.sqrt X ≤ h * X / B ^ A := by
  set s := Real.sqrt (Real.log X) with hs
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hss : s * s = Real.log X := Real.mul_self_sqrt (Real.log_nonneg hX)
  have hB0 : 0 < B := by linarith
  have hB1 : 1 ≤ Real.log B :=
    (Real.le_log_iff_exp_le hB0).2 (by linarith [Real.exp_one_lt_d9])
  set T := 2 * (1 + A) + 2 + K with hT
  have hT0 : 0 < T := by positivity
  have hcT' : c * T ≤ 1 := by rwa [le_div_iff₀ hT0] at hcT
  have hsT : T ≤ s := by nlinarith
  have hc1 : c ≤ 1 := by nlinarith
  have hs1 : 1 ≤ s := by linarith
  refine ⟨by nlinarith, ?_⟩
  have hX0 : 0 < X := by linarith
  have hsq : Real.sqrt X = Real.exp (s * s / 2) := by
    rw [hss, Real.sqrt_eq_rpow, Real.rpow_def_of_pos hX0]
    congr 1; ring
  have hXe : X = Real.exp (s * s) := by rw [hss, Real.exp_log hX0]
  have hcs : c * s ≤ s := by nlinarith
  have hBA : B ^ A ≤ Real.exp (A * s) := by
    rw [Real.rpow_def_of_pos hB0]
    exact Real.exp_le_exp.2 (by nlinarith)
  have hh' : Real.exp (-s) ≤ h := le_trans (Real.exp_le_exp.2 (by linarith)) hh
  have hKe : K ≤ Real.exp (s * s / 2 - (1 + A) * s) := by
    nlinarith [Real.add_one_le_exp (s * s / 2 - (1 + A) * s)]
  rw [le_div_iff₀ (Real.rpow_pos_of_pos hB0 A), hsq]
  calc K * Real.exp (s * s / 2) * B ^ A
      ≤ Real.exp (s * s / 2 - (1 + A) * s) * Real.exp (s * s / 2) * Real.exp (A * s) := by
        gcongr
    _ = Real.exp (-s) * Real.exp (s * s) := by
        simp only [← Real.exp_add]; congr 1; ring
    _ ≤ h * X := by
        rw [← hXe]; gcongr

theorem normPrimes_short_interval_lower : ∃ A c c' : ℝ, 0 < A ∧ 0 < c ∧ 0 < c' ∧ ∀ (d M : ℕ) (X h : ℝ), d.Prime → d % 4 = 3 → 100 ≤ d → 3 ≤ M → 1 ≤ X → Real.log (4 * (d : ℝ) * (M : ℝ) ^ 2) ≤ c * Real.sqrt (Real.log X) → Real.exp (-c * Real.sqrt (Real.log X)) ≤ h → h ≤ 1 → c' * h * X / ((4 * (d : ℝ) * (M : ℝ) ^ 2) ^ A * Real.log X) ≤ ((GlobalTheory.Mem.An.normPrimes d M X (X * (1 + h))).card : ℝ) := by
  obtain ⟨A, c₀, c₁, hA, hc₀, hc₁, H⟩ :=
    GlobalTheory.Hk.ShortInt.trivialClass_shortInterval
  obtain ⟨C, hC⟩ := Chebyshev.psi_sub_theta_le_mul_sqrt
  let K : ℝ := (8 * |C| + 1) / c₁
  have hK : 0 < K := div_pos (by positivity) hc₁
  let T : ℝ := 2 * (1 + A) + 2 + K
  have hT : 0 < T := by dsimp [T]; positivity
  let c : ℝ := min c₀ (1 / T)
  have hc : 0 < c := lt_min hc₀ (div_pos (by norm_num) hT)
  have hcT : c ≤ 1 / T := min_le_right _ _
  refine ⟨A, c, c₁ / 8, hA, hc, div_pos hc₁ (by norm_num), ?_⟩
  intro d M X h hd hd4 hd100 hM hX hBX hh hh1
  obtain ⟨𝓕, hFB, hN⟩ := exists_lFam_ray d M hd hd4 hd100 hM
  let B : ℝ := 4 * (d : ℝ) * (M : ℝ) ^ 2
  have hB4 : 4 ≤ B := by
    dsimp [B]
    have hd' : (100 : ℝ) ≤ d := by exact_mod_cast hd100
    have hM' : (3 : ℝ) ≤ M := by exact_mod_cast hM
    nlinarith
  have hmain := sqrt_le_short_main hA hK hc (by simpa [T] using hcT) hB4 hX
    (by simpa [B] using hBX) hh
  obtain ⟨hlogX, hsqrt⟩ := hmain
  have hX0 : 0 < X := by linarith
  have hh0 : 0 < h := lt_of_lt_of_le (Real.exp_pos _) hh
  let Y : ℝ := X * (1 + h)
  have hY1 : 1 ≤ Y := by dsimp [Y]; nlinarith
  have hY2 : Y ≤ 2 * X := by dsimp [Y]; nlinarith
  have hlogY : Real.log Y ≤ 2 * Real.log X := by
    have h := Real.log_le_log (by positivity : 0 < Y) hY2
    rw [Real.log_mul (by norm_num : (2 : ℝ) ≠ 0) (ne_of_gt hX0)] at h
    have h2 : Real.log (2 : ℝ) ≤ Real.log X := by
      have : Real.log (2 : ℝ) ≤ 1 := by
        nlinarith [Real.log_le_sub_one_of_pos (by norm_num : (0 : ℝ) < 2)]
      linarith
    linarith
  have hsqrtY : Real.sqrt Y ≤ 2 * Real.sqrt X := by
    have : Y ≤ 4 * X := by linarith
    calc
      Real.sqrt Y ≤ Real.sqrt (4 * X) := Real.sqrt_le_sqrt this
      _ = 2 * Real.sqrt X := by rw [Real.sqrt_mul (by norm_num : (0 : ℝ) ≤ 4)]; norm_num
  have hB0 : 0 < B := by linarith
  have hBpow : 0 < B ^ A := Real.rpow_pos_of_pos hB0 _
  have hmass : c₁ * h * X / B ^ A ≤
      ∑ n ∈ Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊, 𝓕.lam 0 n := by
    have hlogB : Real.log 𝓕.B ≤ c₀ * Real.sqrt (Real.log X) := by
      rw [hFB]
      exact le_trans hBX (mul_le_mul_of_nonneg_right (min_le_left _ _) (Real.sqrt_nonneg _))
    have hhh : Real.exp (-c₀ * Real.sqrt (Real.log X)) ≤ h := by
      exact le_trans (Real.exp_le_exp.2 (by
        have : c ≤ c₀ := min_le_left _ _
        nlinarith [Real.sqrt_nonneg (Real.log X)])) hh
    simpa only [hFB, Y, B] using H 𝓕 X h hX hlogB hhh hh1
  have hcount := sum_lam_zero_le_card_normPrimes 𝓕 d M hN X Y hY1
  have herror : 2 * (Chebyshev.psi Y - Chebyshev.theta Y) ≤
      4 * |C| * Real.sqrt X := by
    have hψ := hC Y
    have hCabs : C ≤ |C| := le_abs_self C
    have hsqrtY0 : 0 ≤ Real.sqrt Y := Real.sqrt_nonneg _
    have hsqrtX0 : 0 ≤ Real.sqrt X := Real.sqrt_nonneg _
    nlinarith [mul_nonneg (sub_nonneg.mpr hCabs) hsqrtY0,
      mul_nonneg (abs_nonneg C) (sub_nonneg.mpr hsqrtY)]
  have hdominates : 4 * |C| * Real.sqrt X ≤
      (c₁ / 2) * (h * X / B ^ A) := by
    have hcK : 4 * |C| ≤ c₁ / 2 * K := by
      dsimp [K]
      rw [div_eq_mul_inv]
      field_simp
      nlinarith
    calc
      4 * |C| * Real.sqrt X ≤ (c₁ / 2 * K) * Real.sqrt X :=
        mul_le_mul_of_nonneg_right hcK (Real.sqrt_nonneg _)
      _ ≤ (c₁ / 2) * (h * X / B ^ A) := by
        nlinarith [mul_le_mul_of_nonneg_left hsqrt (by linarith : 0 ≤ c₁ / 2)]
  have hlogX0 : 0 < Real.log X := by linarith
  have hcount0 : 0 ≤ ((GlobalTheory.Mem.An.normPrimes d M X Y).card : ℝ) := by positivity
  have hineq : (c₁ / 2) * (h * X / B ^ A) ≤
      4 * Real.log X * ((GlobalTheory.Mem.An.normPrimes d M X Y).card : ℝ) := by
    have := le_trans hmass hcount
    have hmass' : c₁ * (h * X / B ^ A) ≤
        ∑ n ∈ Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊, 𝓕.lam 0 n := by
      convert hmass using 1; ring
    have hlogterm : 2 * Real.log Y * ((GlobalTheory.Mem.An.normPrimes d M X Y).card : ℝ) ≤
        4 * Real.log X * ((GlobalTheory.Mem.An.normPrimes d M X Y).card : ℝ) := by
      nlinarith [mul_nonneg (sub_nonneg.mpr hlogY) hcount0]
    linarith [hmass', hcount, herror, hdominates, hlogterm]
  dsimp [Y] at hineq ⊢
  change c₁ / 8 * h * X / (B ^ A * Real.log X) ≤
    ((GlobalTheory.Mem.An.normPrimes d M X (X * (1 + h))).card : ℝ)
  calc
    c₁ / 8 * h * X / (B ^ A * Real.log X) =
        ((c₁ / 2) * (h * X / B ^ A)) / (4 * Real.log X) := by ring
    _ ≤ ((GlobalTheory.Mem.An.normPrimes d M X (X * (1 + h))).card : ℝ) := by
      apply (div_le_iff₀ (by positivity : 0 < 4 * Real.log X)).2
      nlinarith [hineq]

end GlobalTheory.Hk
