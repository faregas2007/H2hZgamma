# fc2lt: FeynCalc → C++

```bash
fc2lt [--registry] [--model FILE]... [-f NAME] [-o OUT] [INPUT]
fc2lt --tokens INPUT           # debug: how the lexer splits the input
```
`--registry` emits `ampgen::NAME::eval(const ampflow::Args&)` plus a descriptor listing the inputs and SLHA entries the amplitude needs (what the runner uses).
Without it, a plain `std::complex<double> NAME(double x, double y, ...)`. Supported functions: `A0 B0 C0 D0` (arguments pass through to LoopTools unchanged),
`Sqrt Log Exp Sin Cos Tan Abs Csc Sec Cot ArcTan ArcSin ArcCos`, `+ − * / ^`, implicit multiplication, `I Pi E`. Anything else (`Pair`, `DiracTrace`, `PaVe`, ...) stops with a
message pointing at the exact spot.

## FeynCalc compatibility (no conversion before export)

* **SMP / FCGV atoms:** `SMP["m_t"]`, `FCGV["MT"]`, `Subscript[m, t]` are each ONE symbol, key = the canonical text. Arguments may be any expression
  (`Subscript[g, HoldForm[Subscript[h, 0] Subscript[H, 0] Subscript[H, 0]]]`); `HoldForm[x]` is `x`. Other heads stay errors.
* **Unicode and named characters** are normalised **in the lexer**: Greek letters (`α`, `\[Alpha]` → `alpha`), `π`/`\[Pi]` → `Pi`, the imaginary unit (`ⅈ`, `\[ImaginaryI]` → `I`), `ⅇ`,
  U+2212 minus, fullwidth punctuation, odd spaces, a BOM. Only ASCII reaches the generated code, the CSVs and file names. Plots convert names back (`mu` → μ).
  Any other non-ASCII character is an error naming the code point (`U+0449`). The lexer's tables are data (`tables.h`).
* **D → 4:** an amplitude that still carries the dimension `D` (e.g. `((D−4)A0 − 2m²B0)/(D−3)`) is taken to 4 dimensions by `fc2lt`, **keeping the rational terms**:
  `c(D) F → c(4) F − 2 c′(4) r_F` for `F = A0, B0` (UV-pole residues `m` and `1`); `C0`, `D0` only get D → 4. `D` may appear only rationally (not in function
  arguments or exponents). Example: `((D−4)A0[m] − 2 m B0[0,m,m])/(D−3)  →  −2m (B0 + 3)`.
* **Complex SMP entries** (`SMP["V_ud", I]`) are accepted as atoms; define them in a model as an expression.
* Leave `1/Eps` out of the export (use `FCHideEpsilon`): the pole is `Δ`, handled by the backend.
* Argument order: FeynCalc's documented `PaVe` order for four-point functions is `{r10², r12², r23², r30², r20², r13²}` with masses `m0..m3`, which is LoopTools'
  `D0(p1s, p2s, p3s, p4s, p1p2s, p2p3s, m1s..m4s)` element for element.

## Errors

```
fc2lt: error: argument 2 of B0 must be real, but this expression is complex
  at examples/sm/amplitudes/x.m line 1, column 13:
    2 x + B0[s, Sqrt[x], m]
                ^
```
