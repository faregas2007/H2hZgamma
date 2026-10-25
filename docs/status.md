# Status: assumptions and what was not verified

This tree contains no tests. During development it was built with LoopTools 2.16, and the results were compared with independent
references; none of that test code is included here.

## Not verified

* **The Mathematica scripts have never been run** (Mathematica, FeynArts and FeynCalc were not available). Their FeynArts calls follow FeynCalc's own examples but are not auditable here.
  Assumptions to check on the first run: `DiracSimplify` evaluating the closed-loop trace, the order of `LorentzIndexNames`, how FeynArts' SM model writes the quark charge, the `I π²` normalisation.
  See [../mathematica/README.md](../mathematica/README.md).
* **LoopTools** was used only as the Ubuntu 24.04 package `libooptools-dev` (2.16, gfortran 13); other versions and quadruple-precision builds were not tried.
* **Physical region:** boxes and general triangles were compared with references only in the Euclidean region (all invariants ≤ 0); above threshold they rest on LoopTools.
* **Real FeynCalc exports** were not available. The SMP names come from the FeynCalc manual's `SMP[]` list; `SMP["Delta_UV"]` is from FeynCalc's tutorial output (not in that list) and its
  convention must match LoopTools' Δ; the `FCGV` names follow the usual FeynArts SM spelling.
* **2HDM:** the sign and normalisation of `g_hhH0`, `g_h0H0H0` against FeynArts' THDM model; `v = 2 m_W sin θ_W/e`; the identification of the sample's process (H0 → h0 Z γ) and the momentum
  relation `c = (m_H² − x − y)/2 − a − b`. The comparison with the potential validated the model file's algebra, not these conventions.
* The sample amplitudes other than the vacuum polarisation and the H→γγ shape are toys.
