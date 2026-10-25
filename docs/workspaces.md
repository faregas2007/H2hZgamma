# Workspaces

A workspace is a folder with `amplitudes/`, `models/`, `cards/`, `scans/` and a `CMakeLists.txt` of one or two lines. The repository's
`examples/sm` and `examples/thdm` are workspaces; yours is one more.

## Your own workspace

```
mywork/
├── CMakeLists.txt        ampflow_add_workspace(mywork)
├── amplitudes/my_amp.m   FeynCalc export (see below)
├── models/10-mine.model  kappa = SLHA[MYBLOCK, 1]
├── cards/my.slha
└── scans/s.scan
```
```bash
cmake --preset default -DAMPFLOW_EXTRA_WORKSPACES=/path/to/mywork
cmake --build build/default
cmake --build build/default --target scan_mywork_s        # -> build/default/data/mywork/s/my_amp.csv
```
Adding, removing or editing a file in `amplitudes/`, `models/` or `scans/` is noticed at the next build.

## What `ampflow_add_workspace(<name> [DIR <folder>])` does

1. Collects the models: the library models (`AMPFLOW_LIBRARY_MODELS`: `sm`, `feyncalc_smp`, `feynarts_sm`) followed by the workspace's `models/*.model`
   **in file-name order**; later files override earlier ones (use `10-…`, `20-…` to control the order). A model file hash is recorded in every CSV.
2. Translates each `amplitudes/*.m` with `fc2lt --registry` against those models.
3. Builds the registry and links it with the runner: `<build>/examples/<name>/ampscan`.
4. Creates `scan_<name>_<run>` and `plots_<name>_<run>` for every `scans/*.scan` and hooks them into the global `scan` and `plots`.

Because every workspace has its own registry and models, two workspaces may give the same name different meanings (the 2HDM's `alpha` is the mixing angle;
the Standard Model workspace keeps α_em) without interfering.

## Amplitudes: from Mathematica

```mathematica
Export["amplitudes/my_amp.m", ToString[expr, InputForm], "Text"]
```
The expression must already be reduced to `A0 B0 C0 D0` (no `PaVe`, `Pair`, ...; a leftover dimension `D` is taken to 4 by `fc2lt`). Masses and
invariants are the **squared** quantities, as FeynCalc writes them. `.nb` notebooks are not parsed. The scripts in `mathematica/` do the whole chain
from diagrams to a form factor; set `$AFExportDir = "<workspace>/amplitudes"` before running them and the exports land in the workspace.

## Scans

```
card      ../cards/sm.slha          # paths are relative to the scan file
mudim     29756.25                  # mu^2 for the backend
scan s    linspace 1000 600000 300  # or logspace; one variable
set  t    -50                       # fixed values for other inputs
amplitudes vacpol_fermion           # optional; default: every amplitude of the workspace
```
The `amplitudes` entry has no length limit. Wrap it with a trailing backslash, repeat the line (lists add up, they do not replace each other),
or select from the repository instead of naming everything:
```
amplitudes vacpol_fermion vacpol_smp \     # wrapped line
           bubble_unequal
amplitudes fa_vacpol_sigmaT                # a second line adds to the first
amplitudes vacpol_*                        # wildcard: * any run of characters, ? one character
amplitudes @my_amplitudes.txt              # names from a file (one or more per line, # comments), relative to the scan file
amplitudes all -tadpole_*                  # 'all' = the whole repository; -NAME / -PATTERN leaves entries out
```
Entries are processed left to right; with only exclusions, everything else is kept. `ampscan -a` takes the same entries.
Where an input comes from: the scan variable or a `set` line; everything else an amplitude reads is an SLHA entry, bound in the models.
