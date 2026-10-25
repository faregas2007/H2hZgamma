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
