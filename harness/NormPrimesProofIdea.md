## Main line

Write \(B=4dM^2\) and \(Y=X(1+h)\). The ray-family existence theorem supplies an \(LFam\) with this \(B\), whose nonzero prime weights \(\mathcal F.\mathrm{lam}\,0\,p\) imply `NormOne d M p`. The short-interval weighted-sum theorem then gives
\[
e\,hX/B^A\le \sum_{X<n\le Y}\mathcal F.\mathrm{lam}\,0\,n.
\]
The helper `sum_lam_zero_le_card_normPrimes` bounds that sum by
\[
2\log Y\cdot N+2(\psi(Y)-\theta(Y)),
\]
where \(N\) counts the desired primes. Since \(h\le1\), \(\log Y\le2\log X\) and \(\sqrt Y\le2\sqrt X\). The Chebyshev estimate therefore yields
\[
e\,hX/B^A\le4\log X\cdot N+4(|C|+1)\sqrt X.
\]
Choose \(K=8(|C|+1)/e\). The helper `sqrt_le_short_main` gives \(K\sqrt X\le hX/B^A\), so the error is at most half the lower bound. Rearranging gives \(N\ge(e/8)hX/(B^A\log X)\).

## Distinctive moves

The weighted sum is split into primes and nonprimes. On primes, the support condition removes every prime outside `normPrimes`, while `LFam.lam_le` bounds each remaining weight by \(2\log Y\). On nonprimes, the same bound by \(2\Lambda(n)\) places their total inside the prime-power error \(\psi(Y)-\theta(Y)\). This changes a weighted lower bound into a count plus a controllable error.

To make that error absorbable, take \(c=\min(c_0,1/[2(1+A)+2+K])\). Put \(s=\sqrt{\log X}\). Because \(B\ge4\), \(\log B\ge1\); the hypothesis \(\log B\le cs\) forces \(s\ge2(1+A)+2+K\). Also \(B^A\le e^{As}\) and \(h\ge e^{-s}\). Using \(X=e^{s^2}\) and \(\sqrt X=e^{s^2/2}\), this large lower bound on \(s\) proves \(K\sqrt X\le hX/B^A\) and ensures \(\log X\ge1\).

## Essential prerequisites

`exists_lam_zero_sum_shortInterval_ge` supplies the weighted lower bound; `exists_lFam_normOne_of_mod_four_eq_three` supplies the family and prime-support implication; `Chebyshev.psi_sub_theta_le_mul_sqrt` bounds the prime-power error.
