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

* **`ampflow_dual.m`, `ampflow_h0hzg.m`, `ampflow_h0hzg_run.m`, `03_h0_hzgamma.m`** (H0 → h0 Zγ) have never been executed. The Gram matrix, its determinant, the dual-projection property and the CP-odd Gram element were checked numerically outside Mathematica; the Wolfram files were only parsed. Unverified: `LoopFields` as a loop-propagator count, the WF topology positions, the `M$CouplingMatrices` layout, `TID`/`PaVe` output forms, and `LCD` contraction in D dimensions.
* **`ampflow_couplings.m`**: the conversion logic, the rollback and `AFCouplingsInstallModel` were only parsed. Unverified: the shape of `M$CouplingMatrices` entries (`C[...] == {{...}}`, scalar right-hand sides), that FeynArts reads the symbolic section in memory (otherwise use the model-file route), `FeynArts`$ModelPath` for locating `THDM2.mod`, and the `Lambda5` relation above (derived from formulas). `AFCouplingsSelfTest` exercises the conversion on a made-up section.
* **`ampflow_fermion.m`** and the "Fermion" branch of `AFH0hZgDiagramLinear`: parsed only. Unverified: `FCSetDiracGammaScheme` / `$Larin` availability in the installed FeynCalc, that FCFAConvert emits `SUNFDelta` for the colour indices when they are named, and `TR` with a single γ5 in D dimensions (the resulting Eps terms are dropped).
* **Topology classes** (`AFH0hZgTopologyClass`, all topologies from one `CreateTopologies[1, 1 -> 3]`): parsed only. Unverified: that the tree propagators of an amplitude appear as `PropagatorDenominator[Momentum[k_i, D], m]` (or `StandardPropagatorDenominator`) after `FCFAConvert`; that a tadpole's zero-momentum line is visible in the amplitude (otherwise it is classified `Irreducible`, size `Single`); that the masses of the external legs are written with names `AFH0hZgConvention` knows (the `OnShell` test); what FeynArts returns for the topologies that used to be excluded (`Tadpoles`, `Internal`, `SelfEnergies`), and that the `Fermion` group (any closed fermion loop) takes the b-quark loops, if there are any, through the trace path.
* **Linear forms and checkpoints** (`AFLinearForm`, `AFLinearTo4`, `ampflow_h0hzg_run.m`): parsed only. The D → 4 formula was checked against the series method in SymPy; `AFLinearSelfTest` repeats the standard cases in FeynCalc. Unverified: `CoefficientArrays` on the projected amplitudes (needs them linear in A0..D0), `Put`-style ASCII round trip of the diagram files (`Export` + `Get`), `Hash` of a FeynArts amplitude as the identity of a diagram, `DiagramExtract[diagrams, {i}]` on one diagram, and `TimeConstrained` around FeynCalc calls.
* **`AFCouplingsInstallModel`** (original model file + symbolic section in a new `.mod`): not run; assumes `M$ModelName` and `M$CouplingMatrices` may be set after `Get` of the original.

## 2026-11-05 changes (stage 1 / projection), not executed

Written without Mathematica available; only bracket balance was checked. First thing to run: `VERBOSE=2 wolframscript -file 03_h0_hzgamma.m` (trial).
* `ampflow_dual.m`: `AFDualProjectLoopRaw` = contract, tree propagators written out + kinematics, ApartFF (+ FCLoopRemoveScaleless when FeynCalc has it), TID, kinematics on the PaVe arguments. `$AFDualApartFF = False` (or `AF_APARTFF=0`) restores TID on the whole expression.
* `ampflow_fermion.m`: `AFEvaluateTraces`: TR, then DiracSimplify[..., DiracTraceEvaluate -> True]; a DiracTrace that survives fails the diagram.
* `ampflow_h0hzg.m`: "Couplings" -> "Symbolic" now installs `<Model>sym.mod` and inserts the diagrams again with it (the in-memory change of M$CouplingMatrices does not reach CreateFeynAmp; "InMemory" keeps the old way). GaugeXi rules applied after FCFAConvert. Guards at the end of `AFH0hZgDiagramLinear` (leftover DiracTrace/Pair/FeynAmpDenominator/GaugeXi/..., missing coupling symbols, all-zero projection logged). Census total check in `AFH0hZgCells`.
* `ampflow_h0hzg_run.m`: "RollBack" -> False by default (symbols g_{...} stay; `h0hzg_couplings.m` and `h0hzg_couplings_rollback.m` are written); ledger (done/failed/missing per cell, per class, duplicate keys); gamma5 scheme comparison in trial runs; code version in the cache key (diagram files of older code are recomputed).
* `ampflow_ff.m`: `VERBOSE` levels (`AFLog` level 1, `AFLogV`/`AFStep` level 2).
