import Mathlib
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
  have hl : ∀ n, 𝓕.lam 0 n ≤ 2 * vonMangoldt n := fun n =>
    le_trans (Finset.single_le_sum (f := fun g => 𝓕.lam g n) (fun g _ => 𝓕.lam_nonneg g n)
      (Finset.mem_univ _)) (𝓕.lam_le n)
  rw [← Finset.sum_filter_add_sum_filter_not _ (fun n : ℕ => n.Prime)]
  apply add_le_add
  · have h1 : ∑ n ∈ (Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊).filter (fun n : ℕ => n.Prime), 𝓕.lam 0 n =
        ∑ n ∈ GlobalTheory.Mem.An.normPrimes d M X Y, 𝓕.lam 0 n := by
      symm
      apply Finset.sum_subset
      · intro p hp
        simp only [GlobalTheory.Mem.An.normPrimes, Finset.mem_filter] at hp ⊢
        exact ⟨hp.1, hp.2.1⟩
      · intro p hp hq
        simp only [GlobalTheory.Mem.An.normPrimes, Finset.mem_filter] at hp hq
        by_contra h
        exact hq ⟨hp.1, hp.2, hN p hp.2 h⟩
    rw [h1, mul_comm, ← nsmul_eq_mul]
    apply Finset.sum_le_card_nsmul
    intro p hp
    simp only [GlobalTheory.Mem.An.normPrimes, Finset.mem_filter, Finset.mem_Ioc] at hp
    have h2 : (p : ℝ) ≤ Y := (Nat.le_floor_iff (by linarith)).1 hp.1.2
    have h4 := hl p
    rw [vonMangoldt_apply_prime hp.2.1] at h4
    linarith [Real.log_le_log (by exact_mod_cast hp.2.1.pos) h2]
  · rw [Chebyshev.psi_sub_theta_eq_sum_not_prime, Finset.mul_sum]
    refine le_trans (Finset.sum_le_sum fun n _ => hl n) ?_
    apply Finset.sum_le_sum_of_subset_of_nonneg
    · exact Finset.filter_subset_filter _ (Finset.Ioc_subset_Ioc_left (Nat.zero_le _))
    · intro n _ _
      exact mul_nonneg (by norm_num) (@vonMangoldt_nonneg n)

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
  -- Insert a proof here.

end GlobalTheory.Hk
