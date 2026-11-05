# mathematica/ — from Feynman diagrams to an amplitude fc2lt can read

Two FeynArts + FeynCalc scripts that take a process from the diagrams to **one form factor**, check it, and export
it as a plain `A0/B0/C0` expression for `fc2lt` (→ C++ → scan → CSV → plots).

| Script | Process | Loop functions | Form factor |
|---|---|---|---|
| `01_photon_selfenergy.m` | γ\*(k) → γ\*(k), top-quark loop | `A0 B0` | `Π(s)`, `Σ_T(s) = −sΠ` |
| `02_higgs_diphoton.m` | H → γγ, top-quark triangle | `C0 B0 A0` | `A(s)`, `F(s) = 2A/s` |

`ampflow_ff.m` holds the helpers both use. Run (Mathematica + FeynArts + FeynCalc installed):

```bash
wolframscript -file 01_photon_selfenergy.m
wolframscript -file 02_higgs_diphoton.m          # writes export/*.m  (or to $AFExportDir, see below)
```

## What each script does

| # | Step | Tool | Guard |
|---|---|---|---|
| 1 | `CreateTopologies`, `InsertFields` (top loop only) | FeynArts | |
| 2 | `CreateFeynAmp` → `FCFAConvert` (D dimensions, `Truncated`: open indices μ ν) | FeynArts → FeynCalc | |
| 3 | colour factor `Nc` restored, kinematics set (`ScalarProduct`) | FeynCalc | |
| 4 | `DiracSimplify` (loop trace), `TID[..., ToPaVe -> True]` | FeynCalc | |
| 5 | Lorentz decomposition `AFLorentzCoefficients`: contract with every structure, solve the Gram system, D kept symbolic | helper | singular Gram matrix → error |
| 6 | **Ward identity** `k_μ Π^{μν} = 0` (and `k1_μ M^{μν} = k2_ν M^{μν} = 0`) in D dimensions | helper | residual ≠ 0 → stop. For H→γγ both assignments of μ to a photon are tried; a missing diagram fails both |
| 7 | **Transversality**: transverse polarisations keep `g^{μν}` and `k2^μ k1^ν`; the Ward identity merges them into one form factor | physics | |
| 8 | `AFLimitTo4`: D → 4 **keeping the rational terms** (`(D−4)×pole`); Δ cancels, which is verified | helper | Δ left over → stop |
| 9 | Shape check against the known function, UV-pole coefficient | helper | s-dependence differs → stop; H→γγ must have no pole |
| 10 | `AFExportAmplitude`: InputForm, ASCII, one line | helper | refuses anything but `A0 B0 C0 D0`, `SMP`, `FCGV`, numbers and symbols |

Every check **stops with a message naming the step**, so a wrong convention cannot be exported silently.

## Conventions (all stated in the scripts)

* The FeynArts amplitude (`PreFactor -> 1`, `Truncated`) is the value of the diagram, `i𝓜^{μν}` (for the self-energy:
  `iΠ^{μν}`).
* The loop measure has an implicit `1/(2π)^D`; `TID` with `ToPaVe` returns `i π² × PaVe` (FeynCalc documentation), so the
  amplitude in LoopTools normalisation is `TID result /(2π)^4 = i/(16π²) × PaVe`. The `(2π)^{D−4}` and `μ^{4−D}` factors cancel.
* `DropSumOver` removes the colour sum over the quark; the scripts multiply by `Nc`.
* `Σ_T = −sΠ` is Denner's convention (`vacpol_fermion.m` in `amplitudes/`).
* Δ = 1/ε − γ_E + ln 4π, as in LoopTools. The exported A0/B0 contain it; the divergent column of ampflow is its coefficient.

## What comes out, and how it joins the pipeline

Set `$AFExportDir` to a workspace's `amplitudes/` folder before running the scripts (default: `./export`) and the next build of that workspace picks the exports up. The exported expressions use FeynCalc's
`SMP["e"]`, `SMP["m_t"]`, `SMP["Q_u"]`, ... (defined in `models/feyncalc_smp.model`), `Nc` (`models/custom.model`) and the input `s`. If a
name is not defined, the build stops with the file, line and a "did you mean". Scan it with a `scans/*.scan` that lists the amplitude. `fc2lt` also takes a leftover dimension `D` to 4 (`src/fc2lt/include/fc2lt/dimension.h`).

`examples/sm/amplitudes/fa_vacpol_sigmaT.m` is a **hand-written stand-in** (clearly marked) in the exact format script 01 writes. The
repo's tests require it to equal `vacpol_fermion` numerically: the downstream path is tested, and it is what the script's real output must match.

## What was verified without Mathematica — and what was not

Checked during development (the check tools are not part of this tree):

* **Syntax:** all three files parse as Wolfram Language (Mathics3 parser).
* **API:** every FeynCalc function the scripts use exists in the FeynCalc source tree, and every option given to `FCFAConvert` and `TID` is declared there. The call patterns follow
  FeynCalc's own examples (`Examples/QED/OneLoop/Mathematica/`, `Examples/QCD/OneLoop/Mathematica/H-GlGl.m`).
* **Physics:** the closed forms the shape checks use were compared numerically with independent formulas (Denner's `Σ_T` equals −s times the
  Peskin–Schroeder Feynman-parameter vacuum polarisation to 1e-12; `m²(2+(4m²−s)C0) = m² τ A_{1/2}(τ)`).
* **Algorithm:** `AFLimitTo4`'s method, run symbolically (sympy) on the hand-derived D-dimensional `Π(D)`, gives Denner's formula exactly
  including the rational term `s/3`, with the pole `e²NcQ²s/(12π²)`. The Ward-identity relation `B0(0,m,m) = (D−2)/(2m) A0` was checked the same way.

**Not verified: the scripts have never been executed.** Mathematica, FeynArts and FeynCalc were not available.

* The FeynArts calls (`CreateTopologies`, `InsertFields`, `ExcludeParticles` patterns, ...) follow FeynCalc's examples but are not auditable here.
* Assumptions to check on the first run: that `DiracSimplify` evaluates the closed-loop trace (as the shipped examples assume); the order of
  `LorentzIndexNames` (H→γγ tries both); how FeynArts' SM model writes the quark charge (`SMP["Q_u"]` assumed); the `I π²` normalisation.
* `fc2lt` has the same D → 4 method in C++ (`src/fc2lt/include/fc2lt/dimension.h`), so an amplitude exported with `D` still in it is handled downstream too.
* The helper `AFLimitTo4` is Wolfram code that was parsed, not run (the Mathics3 session would not start here); the *method* is what was tested.
* If something is off, the scripts stop at the failing check with its name instead of exporting.

## H0 → h0 Z γ in the 2HDM (dual projector)

| File | Role |
|---|---|
| `00_dual_projector_check.m` | FeynCalc only, seconds. Gram matrix vs report eq. 25, `det G`, `G·G⁻¹`, projector round trip in D dimensions, CP-odd orthogonality, photon Ward identity, and the coupling conversion on a made-up model section. Run it first. |
| `ampflow_dual.m` | The dual projector: `AFDualProject[tensor, mu, nu] → {F1,F2,F3}`, `AFDualProjectOdd` (F4), `AFDualSumSquared`, `AFPutDelta`. Process independent. |
| `ampflow_ff.m` | Shared helpers: logging, `AFFail` / `AFGuarded` (skip instead of stop), `AFOptions`, linear forms over A0..D0 and D → 4 (`AFLinearForm`, `AFLinearTo4`), the export guard. |
| `ampflow_couplings.m` | The whole coupling section of a FeynArts model as symbols `g_{fields}` and back (see below). Process independent. |
| `ampflow_fermion.m` | Closed fermion loops with γ5 and Levi-Civita in D dimensions (from `fermion_reduced.m`): colour, traces in NDR or Larin, projection before TID, `AFDropLoopEps`. Used by the "Fermion" group. |
| `ampflow_h0hzg.m` | The process: all diagrams (`AFH0hZgDiagrams`), cells by loop group and size (`AFH0hZgCells`), topology class of a diagram (`AFH0hZgTopologyClass`), ONE diagram → linear form (`AFH0hZgDiagramLinear`), a sum of diagrams → form factors (`AFH0hZgFinish`), model-coupling check (`AFH0hZgCheckModelCouplings`). |
| `ampflow_h0hzg_run.m` | The long run as saved, logged, restartable steps (`AFH0hZgRun`); see "Running". |
| `03_h0_hzgamma.m` | Driver (options from environment variables). Writes `h0hzg_<class>_<group>_<size>_F<i>.m`, the class sums `h0hzg_<class>_F<i>.m` and the total `h0hzg_F<i>.m` to `$AFExportDir`. |

Conventions: `k1 = h0 (x = m_h²)`, `k2 = Z (y = m_Z²)`, `k3 = γ`; `a = k3·k1`, `b = k3·k2`, `c = k1·k2`, `Δ = a²y − 2abc + b²x`, as in `thdm.model`.
`P1 = −b g + k3^μ k2^ν`, `P2 = −a g + k3^μ k1^ν`, `P3 = −a k1^μ k2^ν + b k1^μ k1^ν`.

**Differences from report.pdf** (found by checking the algebra numerically in 5–7 dimensions):
* The report's `P1, P2` are this code's `P2, P1`: its F1, F2 are our F2, F1. F3 agrees.
* Eq. (24) (`a = k3·k2, b = k3·k1`) contradicts eq. (26): `Δ` is the Gram determinant only for `a = k3·k1`. Eq. (25) and `det G = −(D−3)Δ³/y` hold with the definitions above. Eq. (4) uses `b` for both `k3·k1` and `k3·k2`.
* Eq. (30): the CP-odd weight is `2(c² − xy)`, not `c²` (the Gram element of `ε^{μν k1 k2}`). The other terms of (30) agree with `FᵀGF` at D = 4.

**Fixed relative to the old `DualProjector.m` / `InitialSetup.m`:** a missing comma in `variables2` (the last rule was multiplied into the previous one, and was wrong anyway); `Gphys` depended on pattern rules matching `FullSimplify` output; `Kinematics` had two rules for `k1²` (the first, `m_Z²`, won) and `k2² → m_Z` (not squared); `P1..P3` differed between the two files; the Windows `SetDirectory`, diagram selection by position (`Range[80]`, ...), coupling positions `{44, 53, ...}` and the Greek-letter repair rules (replaced by `$CharacterEncoding = "UTF-8"`).

**Order of work in all groups:** contract each diagram with the three CP-even vectors Πₘ first, then `TID` the resulting scalar functions to PaVe (`AFDualProjectLoopRaw`), and write the result as a *linear form* over A0, B0, C0, D0 (below). Summing, G⁻¹, D → 4 and the vertices come afterwards, on the coefficients. The bosonic groups use the same order (no traces, no γ5, hence no ε and no CP-odd part there); `AFDualProject` (reduce first, project after) remains for tensors that are already loop-free.

## Topologies and their classes (arXiv:1408.2534, appendix C.4)

`AFH0hZgDiagrams` generates **all** one-loop topologies of 1 → 3 (one `CreateTopologies[1, 1 -> 3]`, no `ExcludeTopologies`); FeynArts itself drops what the model does not allow at the field insertion. Nothing is thrown away and no diagram can be counted twice. Each diagram is classified from its amplitude (`AFH0hZgTopologyClass`) by its *tree propagators*, those without the loop momentum. Two big groups, as in the earlier repo:

| Class | Rule |
|---|---|
| `Irreducible` | no tree propagator |
| `Reducible:photon` / `Z` / `h0` | the tree propagator carries `k3` / `k2` / `k1` (`Reducible:photon` holds the Z–γ mixing, fig. 12 diagram 3) |
| `Reducible:none` | tree propagators, none on an external leg (tadpoles, internal self-energies, ...) |
| `Reducible:multiple` | tree propagators on more than one external leg |
| `OnShell:photon` / `Z` / `h0` | like `Reducible:<leg>`, but the propagator has the leg's own mass: `1/(k² − m²)` is singular at the physical point |

The `OnShell` diagrams are **flagged as a group of their own and computed like all others**: with `x`, `y` independent of the masses the symbolic work does not notice the singularity, and handling it is the job of the amplitude writer on the C++ side. They are not in the default total (`"TotalClasses" -> Automatic` = every class but `OnShell:*`; pass a list to change that), and they have their own files.

* **Counterterms are not added.** C.4 shows that the on-shell Z–γ mixing counterterm cancels the reducible diagram with an on-shell photon, and that the vertex counterterm equals the sum of the reducible diagrams (eq. C.13).
* The run logs the diagrams per class and the tree propagators; the on-shell test compares the propagator mass with `m_h`, `m_Z`, `0` after `AFH0hZgNames`, so a mass FeynCalc writes with a name that `AFH0hZgConvention` does not know would hide an on-shell diagram in a `Reducible:` class — read the log of the first trial for that.
* Groups are `Fermion` (any closed fermion loop), `H`, `HGWu`, `GWu` and `Other` (everything else; the groups partition all diagrams). Sizes are `Single` (1 loop propagator), `Self` (2), `Triangle` (3), `Box` (4).
* Not checked here: eq. (C.13) itself; it would be a good first test of `Reducible:photon`.

## Linear forms: how the sums are done

An expression `c0 + c1·I1 + c2·I2 + ...` (`Ik` = A0, B0, C0, D0 objects) is kept as the Association `<|I1 -> c1, I2 -> c2, ..., 1 -> c0|>` (`AFLinearForm`), with vector coefficients `{c_F1, c_F2, c_F3}`. Why:

* the sum over diagrams is adding coefficients, not expanding one huge expression;
* **G⁻¹** is a 3×3 matrix times each coefficient vector, not a product with a long sum;
* **D → 4** (`AFLinearTo4`) is, per coefficient `c(D)`, one substitution and one derivative: `c(4−2ε) = c0 + ε c1`, so `c·B0 → c0 B0 + c1`, `c·A0[m] → c0 A0 + c1 m` (the rational terms), `Δ` cancels identically. This replaces the series of the whole sum (checked against the series method symbolically; `AFLinearSelfTest` checks the standard cases);
* `AFPutDelta`, the vertices back and the names are applied per coefficient, which is small, and can be inspected and retried one by one.

## Running (`ampflow_h0hzg_run.m`)

Two stages that talk through files in `<export>/work`:

1. **Diagrams** — one file per diagram, `work/diagrams/<group>_<size>_<nnnn>.m` (FeynArts amplitude → projection → TID → linear form; the expensive part). A diagram whose file exists for the same FeynArts amplitude and options is skipped. A diagram that fails (`AFFail`, time limit) is logged with the reason, leaves `<file>.failed`, and is skipped (`AF_ONERROR=Stop` stops instead). The next run redoes only the failed or missing diagrams.
2. **Combine** — per cell and class, `work/cells/<class>_<group>_<size>.m` (sum, G⁻¹, D → 4, vertices back), then the exported `h0hzg_*` files. A cell with a missing diagram is not combined; class sums and the total are written only when everything selected is complete. A failing class is logged and skipped, the other classes go on.

Every step is printed with a time stamp (`[ampflow 14:03:22] H/Triangle 12/37 done Reducible:photon 3.2 s`).

**Trial first.** `03_h0_hzgamma.m` runs a trial by default: the first `AF_TRIAL` (default 2) diagrams of every cell, into `export/trial/` (own work directory), with the same export guard as the real run (unknown symbols and heads show up here). `AF_GROUPS=H AF_SIZES=Triangle` restricts it to one cell. `AF_MODE=full` starts the real run. What a trial can tell you: the model-coupling check, the diagram census, the topology classes and the tree-propagator line, that rollback and names leave no foreign symbols, how long a box takes, and whether the loop-momentum assertion after TID holds. What it cannot: UV finiteness (needs all diagrams).

**Several processes.** `AF_SHARD=i/n AF_STAGE=Diagrams` in n processes on the same export directory (each does every n-th diagram), then one `AF_STAGE=Combine`. `AF_RECOMPUTE=1` ignores the files; `AF_TIMELIMIT=seconds` limits one diagram.

## Fermion loops (`ampflow_fermion.m`)

`fermion_reduced.m` as a module: `AFTraceEvaluate` (traces, scheme `"NDR"` or `"Larin"` via `AFGammaScheme`), `AFDropLoopEps`, `AFFermionProjectRaw` (one diagram: colour → trace → contraction with the three CP-even vectors → drop loop-ε → TID). `AFH0hZgDiagramLinear` uses it for the Fermion group.

Kept from the script: the idea that Levi-Civita scalars with the loop momentum vanish after projecting onto CP-even structures (`eps1..eps4 → 0`). That is correct: after the projection only eps(k1,k2,k3,l)-type scalars remain, and reduction turns l into the external momenta.

**Loop-momentum rules.** `looplineardependences` / `squareloopterms` (`l·kᵢ → 0`, `(l·kᵢ)(l·kⱼ) → l² kᵢ·kⱼ/D`) are not used by the module, and I would keep them out of the fermion group, for this reason. After the projection the numerators are scalars, yes, but they still contain `l·kᵢ`, and the denominators are `(l+kᵢ)² − m²`. A shift of the loop momentum moves the `kᵢ` into the numerator, it does not remove it. Minimal example (equal masses, `D₁ = l² − m²`, `D₂ = (l+p)² − m²`):
`l·p = ½(D₂ − D₁ − p²)`  ⇒  `∫ l·p/(D₁D₂) = ½(A₀ − A₀ − p² B₀) = −(p²/2) B₀(p²,m,m) ≠ 0`,
while the rule gives 0. `TID` does exactly this reduction (scalar products of `l` with the external momenta are rewritten with the denominators), which is why it must see them; `AFFermionSelfTest` checks that `TID` of `(l·q)/(D₁D₂)` is not zero. Note also the order in the uploaded script: `/.looplineardependences/.squareloopterms` applies the linear rule first, which already sets every `l·kᵢ` inside `(l·kᵢ)(l·kⱼ)` to 0 before the square rule can act (the other order is what you describe). With `TID` first the rules would act on nothing (no loop momentum is left after it), so `AFDualProjectLoopRaw` instead checks that none is left and stops otherwise. If you have a diagram where the rules and `TID` agree, that is a tadpole-type term (`A₀`); I would be glad to see a case where they differ and the rules are right.

**γ5 schemes.** The module supports `"NDR"`, `"Larin"` and `"BMHV"` (`AFGammaScheme`), and `AFH0hZgFermionSchemeCheck[diags, {"NDR","Larin","BMHV"}]` runs the same diagrams through each and returns the differences. Larin and BMHV are D-dimensional and keep trace cyclicity; they do not preserve the chiral Ward identities, so a rational difference between schemes in the sum is a statement about finite counterterms to be understood, not by itself an error in one of them. For the CP-even form factors here only even numbers of γ5 contribute (odd ones give ε-scalars that vanish after projection), which is where the schemes should agree up to such terms.

**The 4-dimensional pre-simplification** (`ChangeDimension[amp, 4]` before `DiracSimplify`) is a separate matter from Larin's scheme: it replaces `γ^α … γ_α = D·…`-type D-dimensional identities and the loop momentum's dimension by 4-dimensional ones. I left it off by default (`"PreSimplify4" -> True` restores it); the scheme comparison above is the test of whether it matters.

Also changed: colour is done by `SUNSimplify` (the colour indices get `SUNFIndexNames`, as in your script), so the fermion group no longer multiplies by `Nc` by hand; CP-odd `F4` is not computed for the fermion group (it must cancel between the two loop orientations; the CP-odd projector can be added when you want that check).

## Coupling conversion (`ampflow_couplings.m`)

Every vertex of the model becomes a symbol `g_{fields}` while the diagrams are worked on, and the original expressions are put back once, on the finished coefficients:

```mathematica
AFCouplingsInit[]          (* after the model is loaded: symbols and rollback rules for EVERY vertex *)
AFCouplingsVerify[]        (* (symbolic /. rollback) == original, vertex by vertex *)
AFCouplingsApply[]         (* M$CouplingMatrices = symbolic        (AFCouplingsRestore[] = original again) *)
... CreateFeynAmp, TID, projection ...
AFCouplingsRollback[expr]  (* the original vertices back; options "Keep", "Map" *)
AFCouplingsSave[file]      (* the rollback rules in one ASCII file;  AFCouplingsLoad[file] reads them *)
AFCouplingsInstallModel[]  (* THDM2.mod -> THDM2sym.mod: the original file, then the symbolic section: Model -> "THDM2sym" *)
```

The file is organised in six short sections (names, one entry, init/apply/verify, rollback, files, self test). Rules that matter:
* **Names from a table keyed by field** (`AFCouplingFieldNames`); fields with no name are reported and get a generic one. An antiparticle is `-name`.
* **One symbol per non-numeric matrix entry**, `g_{fields}` or `g_{fields, row col}`; numbers stay numbers.
* **Flavour and colour stay in FeynCalc's hands:** `IndexDelta` and `CKM` stay outside the symbol; the symbol takes the free indices of what is left as arguments and its rollback is a pattern rule.
* **`Mass[F[n,{j,…}]]`** in rolled-back vertices is resolved from the class descriptions. **`Keep` / `Map`:** leave chosen symbols alone, or replace them (e.g. `g_hhH0 → −I g_hhH0(model)`) first.
* **ASCII files with `\[Name]` escapes:** no encoding problem can break the Greek letters; model files are read as UTF-8 (`AFH0hZgUseUTF8[]`).
* The model-file route (`AFCouplingsInstallModel`, "Couplings" -> "ModelFile") does not depend on *when* FeynArts reads `M$CouplingMatrices`; the in-memory route does. It relies on a model file being plain Wolfram code that can `Get` the original; unverified.
* Removed as unused: `AFCouplingsInventory`, the three-file writer (now `AFCouplingsSave`).

**A convention to settle before trusting any number.** In the vertices of your own `InitialSetup.m` dump, FeynArts' `g_hhH0` contains `Λ5` and no `m_A`, e.g. `−i·CBA·EL((2Mh0²+MHH²)S2A − 2Λ5(3S2A−S2B)MW²SW²/EL²)/(2 S2B MW SW)`. Comparing with `thdm.model` (`M² = m_A² + λ5 v²`) the two agree only if FeynArts' `Lambda5 = 2M²/v²`, not the standard `λ5` the card holds. `AFH0hZgConvention` used to map `Lambda5 → λ5` unchanged. `AFH0hZgCheckModelCouplings[]` compares both vertices numerically and **stops the run** on a mismatch; set `"Lambda5" -> "TwoM2OverV2"` if that is the cause. (Derived from the formulas, not from FeynArts' documentation.)

**Open points:** with all vertices rolled back from FeynArts, the scan needs only the model-file symbols that remain (`Nc`, the top-Yukawa and `tan β` symbols `Yuk1..3`, `TB` of the fermion group, `Δ`); `fc2lt` stops with the name if one is missing. Gauge-independence is not tested; the run uses Feynman gauge (`GaugeXi[_] -> 1`).
Status: parsed only; none of it has been run (see below and `docs/status.md`). `00_dual_projector_check.m` is the first thing to run.
