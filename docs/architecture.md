# Architecture

## The pipeline

```
 amplitudes/NAME.m ──┐
                     ├─► fc2lt ─► generated/amp_NAME.h ─┐
 models/*.model ─────┘                                  ├─► registry ─► ampscan ─► data/<ws>/<run>/NAME.csv ─► plots
                                          cards/*.slha ─┤                   ▲
                                          scans/*.scan ─┴───────────────────┘
```

| Stage | Code | Time |
|---|---|---|
| Lex: text → tokens; Unicode and named characters → ASCII | `src/fc2lt/include/fc2lt/lexer.h` | build |
| Parse: tokens → tree. The same parser reads amplitudes and models | `parser.h` | build |
| Resolve: apply the model once (inline definitions, `SLHA[...]` → numbered slots, unknown symbols rejected) | `model.h`, `resolve.h` | build |
| Dimension: D → 4 with the rational terms | `dimension.h` | build |
| Emit: tree → C++ expression; real/complex tracking | `emitter.h` | build |
| Render: a C++ header per amplitude with a descriptor (inputs, SLHA entries) | `render.h` | build |
| Run: check the card, evaluate at Δ = 0, 1, 2 along the scan, write CSV | `src/ampscan/` | run |
| Plot | `python/ampflow/plot.py` | after |

Errors carry a position; `diagnostics.h` shows the line and a caret, in the right file (an error inside a model file points into that file).

## What lives where

* **`src/fc2lt`** — the translator. Header-only core (`include/fc2lt/`), one `main.cpp`. Knows nothing about SLHA cards or scans.
* **`src/ampscan`** — the runner as a *library* (`ampscan_core`) without amplitudes: `slha.h`, `scanfile.h`, `csvout.h`, `runner.{h,cpp}` (evaluate one
  amplitude), `cli.{h,cpp}` (options). It receives the registry as an argument; each workspace compiles the 6-line `main.cpp` with its own registry.
* **`include/ampflow/amplitude.h`** — `Amplitude`, `Args`, `SlhaRef`: the only interface shared by generated code and the runner.
* **LoopTools** — the loop-integral library (`A0`, `B0`, `C0`, `D0`). Generated code includes `"clooptools.h"`; `ampscan` initialises and configures it in `backend.h`.

## CMake

The root `CMakeLists.txt` only wires modules together:

| Module | Defines |
|---|---|
| `cmake/AmpflowOptions.cmake` | the cache variables (`LOOPTOOLS_ROOT`, `AMPFLOW_FETCH_LOOPTOOLS`, `AMPFLOW_LOOPTOOLS_*`, `AMPFLOW_LIBRARY_MODELS`, `AMPFLOW_EXTRA_WORKSPACES`, output folders), warnings |
| `cmake/AmpflowBackend.cmake`, `cmake/AmpflowLoopTools.cmake` | the target `ampflow::backend`: finds LoopTools, or downloads and builds it into `third_party/` |
| `cmake/AmpflowPython.cmake` | whether numpy + matplotlib exist: decides whether the `plots` targets are made |
| `cmake/AmpflowWorkspace.cmake` | `ampflow_add_workspace()`; the global targets `scan` and `plots` |

Each directory has its own small `CMakeLists.txt` (`src/fc2lt`, `src/ampscan`, `examples/<workspace>`).
Targets per workspace `<w>`: `ampscan_<w>` (binary `<build>/examples/<w>/ampscan`), `scan_<w>_<run>`, `plots_<w>_<run>`.
