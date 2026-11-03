(* ::Package:: *)

(* ampflow_ff.m -- helpers shared by the FeynArts + FeynCalc form-factor scripts of ampflow.

   Load AFTER FeynCalc:
       $LoadAddOns = {"FeynArts"};  << FeynCalc`
       Get[FileNameJoin[{<this folder>, "ampflow_ff.m"}]];

   Everything here is plain FeynCalc / Mathematica. All names start with AF (functions) or af (internal symbols). *)

AFLog[args__] := Print["[ampflow] ", args];

AFFail[args__] := (
  Print["[ampflow] FAILED: ", args];
  If[$FrontEnd === Null, Quit[1], Abort[]]
);

AFRequire[] := (
  If[!ValueQ[$FeynCalcVersion],
    AFFail["FeynCalc is not loaded: use  $LoadAddOns = {\"FeynArts\"}; << FeynCalc`"]];
  If[Length[Names["FeynArts`CreateTopologies"]] === 0,
    AFFail["the FeynArts add-on is not loaded: use  $LoadAddOns = {\"FeynArts\"}  before << FeynCalc`"]];
  AFLog["FeynCalc ", $FeynCalcVersion]
);


(* ---------------------------------------------------------------------------------------------------------------
   Lorentz decomposition.

   AFLorentzCoefficients[tensor, structures] writes   tensor = Sum_i c_i structures_i   and returns {c_1, ..., c_n}.

   `structures` are FeynCalc tensors carrying the same free indices as `tensor` (in D dimensions), e.g.
       {MTD[mu, nu], FVD[k, mu] FVD[k, nu]}
   Method: contract the tensor with every structure (a vector T_i), contract the structures with each other (Gram matrix
   G_ij) and solve  G c = T.  D stays symbolic, so this is exact in dimensional regularisation. The scalar products of
   the momenta must be defined before (ScalarProduct[k, k] = s, ...).                                               *)
AFLorentzCoefficients[tensor_, structures_List] := Module[{gram, rhs},
  gram = Table[Contract[structures[[i]] structures[[j]]], {i, Length[structures]}, {j, Length[structures]}];
  rhs  = Table[Contract[structures[[i]] tensor], {i, Length[structures]}];
  If[Det[gram] === 0, AFFail["AFLorentzCoefficients: the structures are linearly dependent (singular Gram matrix)"]];
  Together /@ LinearSolve[gram, rhs]
];


(* ---------------------------------------------------------------------------------------------------------------
   D -> 4 with the rational terms.

   The PaVe functions carry a UV pole: A0[m] = m Delta + ...,  B0[...] = Delta + ...,  Delta = 1/eps - gamma_E + ln 4pi
   (the Delta of LoopTools). Coefficients that depend on D = 4 - 2 eps multiply these poles, so
   (D - 4) B0 = -2 + O(eps) leaves a finite "rational term" that must not be lost.

   Procedure: write A0 -> m/eps + A0fin, B0 -> 1/eps + B0fin, expand in eps (Series), then put A0fin = A0 - m Delta,
   B0fin = B0 - Delta back. What comes out is  Sum_i c_i(D=4) F_i + rational terms  in terms of the ordinary A0, B0 (the
   LoopTools functions, Delta included). Delta cancels identically; that is verified, not assumed.
   C0 and D0 have no UV pole and only get D -> 4.                                                                   *)
AFLimitTo4[expr_] := Module[{e, ser, pole, fin, rest, final},
  e = FCReplaceD[expr, D -> 4 - 2 afEps] /. {
        A0[m_] :> m/afEps + afA0f[m],
        B0[p_, m1_, m2_] :> 1/afEps + afB0f[p, m1, m2]};
  ser  = Collect[Normal[Series[e, {afEps, 0, 0}]], afEps];
  pole = Coefficient[ser, afEps, -1];
  fin  = Coefficient[ser, afEps, 0];
  rest = Simplify[ser - pole/afEps - fin];
  If[rest =!= 0, AFFail["AFLimitTo4: unexpected powers of eps left: ", rest]];
  final = (fin /. {afA0f[m_] :> A0[m] - m afDelta, afB0f[p_, m1_, m2_] :> B0[p, m1, m2] - afDelta}) + pole afDelta;
  If[Simplify[(final /. afDelta -> 1) - (final /. afDelta -> 0)] =!= 0,
    AFFail["AFLimitTo4: Delta does not cancel; the expression is not linear in A0/B0 with D-dependent coefficients"]];
  final /. afDelta -> 0
];

(* Coefficient of the UV pole Delta of an expression made of A0, B0, C0, D0 (what the divergent column of ampflow shows). *)
AFPoleCoefficient[expr_] := Simplify[
  Coefficient[expr /. {A0[m_] :> m afDelta, B0[__] :> afDelta, C0[__] :> 0, D0[__] :> 0}, afDelta, 1]];


(* ---------------------------------------------------------------------------------------------------------------
   Normal form for export and comparison.

   C0 with equal masses is symmetric in its three invariants: put them in sorted order, so  C0[0, s, 0, m, m, m]  and
   C0[0, 0, s, m, m, m]  are the same expression.                                                                   *)
AFCanonicalC0[expr_] := expr /. C0[x_, y_, z_, m_, m_, m_] /; Sort[{x, y, z}] =!= {x, y, z} :>
  C0 @@ Join[Sort[{x, y, z}], {m, m, m}];

(* The ratio result/shape must not depend on the listed variables. Prints the ratio; fails if it does depend. *)
AFShapeCheck[name_String, result_, shape_, vars_List] := Module[{ratio = Simplify[result/shape]},
  If[FreeQ[ratio, Alternatives @@ vars],
    AFLog["shape check OK (", name, "): result/shape = ", ratio]; ratio,
    AFFail["shape check (", name, "): result/shape still depends on ", vars, ":  ", ratio]]
];


(* ---------------------------------------------------------------------------------------------------------------
   Export for fc2lt.

   Writes the expression as Mathematica InputForm text (one line, ASCII) with a comment header. Before writing, the
   expression is checked: it may only contain numbers, symbols, + * ^, the scalar integrals A0 B0 C0 D0 and FeynCalc
   parameter atoms SMP["..."] / FCGV["..."]. Anything else (Pair, Momentum, DiracGamma, PaVe, D, Epsilon, ...) means a
   step was forgotten, and nothing is written.                                                                       *)
AFAllowedHeads = {Plus, Times, Power, Rational, Complex, A0, B0, C0, D0, SMP, FCGV, Subscript,
  Sin, Cos, Tan, Sec, Csc, Cot, HoldForm};     (* trigonometric functions of the mixing angles; HoldForm only labels coupling names, fc2lt ignores it *)

AFExportAmplitude[file_String, expr_, header_String] := Module[{heads, bad, text},
  heads = DeleteDuplicates[Cases[expr, f_Symbol[___] :> f, {0, Infinity}]];
  bad = Complement[heads, AFAllowedHeads];
  If[bad =!= {}, AFFail["export refused: the expression still contains ", bad, "  (only A0 B0 C0 D0, SMP, FCGV are allowed)"]];
  If[!FreeQ[expr, D | Epsilon | afEps | afDelta | EulerGamma],
    AFFail["export refused: the expression still contains D, Epsilon or Delta symbols"]];
  text = "(* " <> header <> " *)\n" <> ToString[expr, InputForm, PageWidth -> Infinity] <> "\n";
  Quiet[CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  Export[file, text, "Text"];
  AFLog["wrote ", file];
  file
];
