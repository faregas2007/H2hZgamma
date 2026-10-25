# Output

## The CSV repository

`data/<workspace>/<run>/` is self-describing: one CSV per amplitude, `manifest.csv`, and copies of the card (`parameters.slha`) and the scan file (`run.scan`).

```
# amplitude: vacpol_smp       <- '#' lines: backend, scan, mu^2, model files + hashes, fixed inputs, SLHA entries read
s,re_finite,im_finite,re_div,im_div
```
* **finite** = the amplitude at Δ = 0.  **div** = the coefficient of Δ = 1/ε − γ_E + ln 4π, the UV pole: `amplitude = finite + Δ·div`.
* The runner evaluates at Δ = 0, 1, 2: `div = A(1) − A(0)`; `A(2)` checks linearity (a warning appears for Δ² terms). The absolute error of `div` is about 1e-16·|amplitude|.
* IR divergences are not separated.

Read it with `from ampflow import csvio; csvio.read_run("data/sm/demo")` or with pandas (`read_csv(..., comment="#")`).

## Loop-integral library

`A0`, `B0`, `C0`, `D0` all come from LoopTools (the `backend:` line in every CSV says `LoopTools`). CMake uses an installed copy (`-DLOOPTOOLS_ROOT=/path`, needs
`include/clooptools.h` and `libooptools.a`; the Ubuntu/Debian package `libooptools-dev` works with `-DLOOPTOOLS_ROOT=/usr`). If none is found, LoopTools 2.16 is
downloaded from feynarts.de, built and installed into `third_party/looptools/` at configure time (needs gfortran, make, network; or put `LoopTools-2.16.tar.gz` there by hand).
