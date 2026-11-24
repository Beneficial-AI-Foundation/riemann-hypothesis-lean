import Mathlib
import Development.AbelianVarietyTheory.Definitions.GlobalTwisting.LamIdealOfNotPrimePow

open ArithmeticFunction
open scoped Classical

namespace GlobalTheory.Hk

/-- A nonnegative von Mangoldt bounded weight whose prime support detects `P`.
The weight may also be nonzero at prime powers; that contribution is controlled separately. -/
structure PrimeDetectingWeight (P : ℕ → Prop) where
  weight : ℕ → ℝ
  nonneg : ∀ n, 0 ≤ weight n
  le_vonMangoldt : ∀ n, weight n ≤ 2 * Λ n
  detects : ∀ p, p.Prime → weight p ≠ 0 → P p

namespace PrimeDetectingWeight

variable {P : ℕ → Prop}

/-- Every predicate admits the zero detector. -/
def zero (P : ℕ → Prop) : PrimeDetectingWeight P where
  weight := fun _ ↦ 0
  nonneg := by intro; rfl
  le_vonMangoldt := by intro; positivity
  detects := by intro p hp h; exact False.elim (h rfl)

@[simp] theorem zero_weight (P : ℕ → Prop) (n : ℕ) : (zero P).weight n = 0 := rfl

/-- Von Mangoldt's function is a nonzero detector when every prime is accepted. -/
noncomputable def vonMangoldtWeight : PrimeDetectingWeight (fun _ ↦ True) where
  weight := fun n ↦ Λ n
  nonneg := by intro n; exact vonMangoldt_nonneg
  le_vonMangoldt := by
    intro n
    have h := @vonMangoldt_nonneg n
    linarith
  detects := by intro p hp hn; trivial

theorem vonMangoldtWeight_pos_two : 0 < vonMangoldtWeight.weight 2 := by
  change 0 < Λ 2
  rw [vonMangoldt_apply_prime (by norm_num : Nat.Prime 2)]
  exact Real.log_pos (by norm_num)

/-- A detector cannot assign positive weight to `1`. -/
theorem weight_one_eq_zero (D : PrimeDetectingWeight P) : D.weight 1 = 0 := by
  have h := D.le_vonMangoldt 1
  simp only [vonMangoldt_apply_one, mul_zero] at h
  exact le_antisymm h (D.nonneg 1)

/-- For example, the constant weight `1` is not a detector for any predicate. -/
example (P : ℕ → Prop) : ¬ ∃ D : PrimeDetectingWeight P, D.weight 1 = 1 := by
  rintro ⟨D, h⟩
  rw [D.weight_one_eq_zero] at h
  norm_num at h

/-- The prime support of a detector converts weighted interval mass into a
count, while `ψ - θ` pays for the nonprime prime-power contribution. -/
theorem sum_Ioc_le_prime_count (D : PrimeDetectingWeight P) (X Y : ℝ) (hY : 1 ≤ Y) :
    ∑ n ∈ Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊, D.weight n ≤
      2 * Real.log Y *
        (((Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊).filter (fun p ↦ p.Prime ∧ P p)).card : ℝ) +
        2 * (Chebyshev.psi Y - Chebyshev.theta Y) := by
  rw [← Finset.sum_filter_add_sum_filter_not _ (fun n : ℕ ↦ n.Prime)]
  apply add_le_add
  · have h1 : ∑ n ∈ (Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊).filter (fun n : ℕ ↦ n.Prime),
        D.weight n =
        ∑ n ∈ (Finset.Ioc ⌊X⌋₊ ⌊Y⌋₊).filter (fun n ↦ n.Prime ∧ P n),
          D.weight n := by
      symm
      apply Finset.sum_subset
      · intro p hp
        simp only [Finset.mem_filter] at hp ⊢
        exact ⟨hp.1, hp.2.1⟩
      · intro p hp hq
        simp only [Finset.mem_filter] at hp hq
        by_contra h
        exact hq ⟨hp.1, hp.2, D.detects p hp.2 h⟩
    rw [h1, mul_comm, ← nsmul_eq_mul]
    apply Finset.sum_le_card_nsmul
    intro p hp
    simp only [Finset.mem_filter, Finset.mem_Ioc] at hp
    have hpY : (p : ℝ) ≤ Y := (Nat.le_floor_iff (by linarith)).1 hp.1.2
    have hw := D.le_vonMangoldt p
    rw [vonMangoldt_apply_prime hp.2.1] at hw
    linarith [Real.log_le_log (by exact_mod_cast hp.2.1.pos) hpY]
  · rw [Chebyshev.psi_sub_theta_eq_sum_not_prime, Finset.mul_sum]
    refine le_trans (Finset.sum_le_sum fun n _ ↦ D.le_vonMangoldt n) ?_
    apply Finset.sum_le_sum_of_subset_of_nonneg
    · exact Finset.filter_subset_filter _ (Finset.Ioc_subset_Ioc_left (Nat.zero_le _))
    · intro n _ _
      exact mul_nonneg (by norm_num) (@vonMangoldt_nonneg n)

/-- The zeroth `LFam` coefficient supplies a detector whenever its prime support
lies in `P`. -/
def ofLFam (𝓕 : LFam) (hP : ∀ p, p.Prime → 𝓕.lam 0 p ≠ 0 → P p) :
    PrimeDetectingWeight P where
  weight := 𝓕.lam 0
  nonneg := 𝓕.lam_nonneg 0
  le_vonMangoldt := by
    intro n
    exact le_trans
      (Finset.single_le_sum (f := fun g ↦ 𝓕.lam g n)
        (fun g _ ↦ 𝓕.lam_nonneg g n) (Finset.mem_univ _)) (𝓕.lam_le n)
  detects := hP

@[simp] theorem ofLFam_weight (𝓕 : LFam)
    (hP : ∀ p, p.Prime → 𝓕.lam 0 p ≠ 0 → P p) (n : ℕ) :
    (ofLFam 𝓕 hP).weight n = 𝓕.lam 0 n := rfl

end PrimeDetectingWeight
end GlobalTheory.Hk
