# Models and card templates

A model file uses the **same language as the amplitudes** and is read by the same lexer and parser:

```
Inputs[s, t, u]                        (* symbols the runner supplies per scan point *)
mt     = SLHA[MASS, 6]                 (* a symbol defined by a card entry *)
alphaEM = 1/SLHA[SMINPUTS, 1]          (* ... or by an expression *)
e      = Sqrt[4 Pi alphaEM]            (* derived parameters use other definitions *)
SMP["m_t"] = mt                        (* FeynCalc atoms can be defined directly *)
SMP["Delta_UV"] = Runner[Delta]        (* values the runner provides: Delta or Mu2 *)
```

* One statement per line (it continues while a bracket is open or the line ends in an operator), or `;`-separated.
* **Order and override:** library models first, then the workspace's, each file in order; a later file may redefine a symbol of an earlier one,
  but one file may not define a symbol twice.
* A symbol that is neither defined nor declared in `Inputs[...]` is an error with a position and a "did you mean ...?". An error inside a model file is reported in that file.
* Derived values (`Sqrt`, `Log`, `I`, ...) are complex numbers in the generated code: they can be couplings but cannot be loop-function arguments (caught at translation time).
* `SLHA[BLOCK, i, ...]`: block names are case-insensitive; no index for a single-value block (`SLHA[ALPHA]`).

## Library models (`models/`)

| File | Content |
|---|---|
| `sm.model` | Standard Model symbols from the fixed SLHA blocks (`SMINPUTS` 1–7, 11, 13; `MASS` 24, 25) and derived `e`, `gs`, `mudim` |
| `feyncalc_smp.model` | FeynCalc's `SMP["..."]` parameters (the names of `SMP[]` in the FeynCalc manual) in terms of the above |
| `feynarts_sm.model` | FeynArts' `FCGV["..."]` placeholders (usual SM.mod spelling; unchecked against a real export) |

## Card templates (`templates/`)

| Template | Content | Use |
|---|---|---|
| `sm_standard.slha` | only blocks and indices fixed by the SLHA specification | edit numbers only |
| `custom_block.slha` | a block of your own (`AMPPAR`) | symbols no standard block carries (`Nc`, charges, ...): bind them in your workspace's model |
| `thdm_standard.slha` | SMINPUTS, MASS (24, 25, 35, 36, 37), `MINPAR` 3 (tan β), `ALPHA` | the 2HDM, see [thdm.md](thdm.md) |
| `thdm_custom.slha` | block `THDM` entry 1 = λ₅ | the one 2HDM parameter no standard block has |

A workspace's card is normally a template with the numbers changed, or two templates joined (`examples/sm/cards/sm.slha`).
