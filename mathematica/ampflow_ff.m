(* ::Package:: *)

(* ampflow_ff.m -- helpers shared by the FeynArts + FeynCalc form-factor scripts of ampflow.

   Load AFTER FeynCalc:
       $LoadAddOns = {"FeynArts"};  << FeynCalc`
       Get[FileNameJoin[{<this folder>, "ampflow_ff.m"}]];

   Everything here is plain FeynCalc / Mathematica. All names start with AF (functions) or af (internal symbols). *)

(* Verbosity: environment variable VERBOSE (or $AFVerbose = n before the run).
     1  (default)  one line per diagram, per cell, per stage; failures
     2             also one line per STEP inside every diagram (amplitude conversion, trace, contraction, ApartFF, TID, kinematics,
                   names) with seconds and the size (LeafCount) of what the step returned.
   AFLog prints at level 1, AFLogV at level 2; AFStep[name, body] times one step at level 2 and is just `body` at level 1. *)
$AFVerbose = With[{v = Environment["VERBOSE"]},
  If[StringQ[v] && StringMatchQ[v, DigitCharacter ..], ToExpression[v], 1]];

AFLog[args__] := Print["[ampflow ", DateString[{"Hour24", ":", "Minute", ":", "Second"}], "] ", args];
AFLogV[args__] := If[$AFVerbose >= 2, Print["[ampflow ", DateString[{"Hour24", ":", "Minute", ":", "Second"}], "]     ", args]];

SetAttributes[AFStep, HoldRest];
AFStep[name_String, body_] := If[$AFVerbose < 2, body,
  Module[{t, r}, {t, r} = AbsoluteTiming[body];
    AFLogV[StringPadRight[name, 16], Round[t, 0.01], " s   leaves: ", LeafCount[r]]; r]];

(* What may still stand in a finished coefficient. Anything else (DiracTrace, Pair, Momentum, FeynAmpDenominator, GaugeXi, SUN...,
   Eps, D) means a step was skipped or did not act: the diagram FAILS here, with the list, instead of a wrong file being saved. *)
$AFBadHeads = {DiracTrace, DiracGamma, TR, Pair, Momentum, LorentzIndex, FeynAmpDenominator, PropagatorDenominator,
  StandardPropagatorDenominator, GaugeXi, Eps, SUNF, SUND, SUNDelta, SUNFDelta, SUNIndex, SUNFIndex, PaVe, ScalarProduct};
AFLeftovers[expr_] := Intersection[$AFBadHeads, DeleteDuplicates[Cases[expr, f_Symbol[___] :> f, {0, Infinity}]]];

(* AFFail stops the script (Quit) or the notebook evaluation (Abort). Inside AFGuarded it only throws, so that a long run can
   skip the failing item, remember why, and go on. *)
$AFCatching = False;
AFFail[args__] := Module[{msg = StringJoin[ToString /@ {args}]},
  Print["[ampflow] FAILED: ", msg];
  If[$AFCatching, Throw[msg, "AFFail"], If[$FrontEnd === Null, Quit[1], Abort[]]]
];

(* AFGuarded[body, seconds]: {"ok", value} or {"fail", message}; AFFail and the time limit end up as "fail". *)
SetAttributes[AFGuarded, HoldFirst];
(* A FeynCalc "fatal problem ... must abort the computation" is an Abort[]: it is caught here too, so that only THIS item is lost
   (the message FeynCalc printed stays on the screen) and the run goes on with the next one. *)
AFGuarded[body_, limit_ : Infinity] := Block[{$AFCatching = True},
  Catch[
    CheckAbort[
      TimeConstrained[{"ok", body}, limit, {"fail", "time limit of " <> ToString[limit] <> " s exceeded"}],
      {"fail", "FeynCalc aborted (fatal error; its message is printed above)"}],
    "AFFail", {"fail", #1} &]];

(* Option handling without OptionValue plumbing: defaults of `head` overridden by the rules given, as an Association.
   An option name that the head does not have is an error (a typo must not pass silently). *)
AFOptions[head_, given_List] := Module[{rules = Flatten[given], unknown},
  unknown = Complement[First /@ rules, First /@ Options[head]];
  If[unknown =!= {}, AFFail[ToString[head], ": unknown option(s) ", unknown, "; known: ", First /@ Options[head]]];
  Association[Join[Options[head], rules]]
];

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
   Linear forms over the scalar integrals.

   An expression  c0 + c1 I1 + c2 I2 + ...  (I_i = A0, B0, C0, D0 objects, the c_i free of them) is kept as the Association
       <|I1 -> c1, I2 -> c2, ..., 1 -> c0|>
   The coefficients may be vectors (a list {F1, F2, F3}); everything below works for both. Adding diagrams is then adding
   coefficients, and every later step (G^-1, D -> 4, couplings back, simplification) works on one small coefficient at a time
   instead of on one huge sum.                                                                                       *)

AFLinearForm[exprs_List] := Module[{lins = AFLinearForm /@ exprs, keys},
  keys = Union[Join @@ (Keys /@ lins)];
  Association[Table[key -> Table[Lookup[lin, key, 0], {lin, lins}], {key, keys}]]
];

AFLinearForm[expr_] := Module[{ints, ph, arrays},
  ints = DeleteDuplicates[Cases[expr, _A0 | _B0 | _C0 | _D0, {0, Infinity}]];
  If[ints === {}, Return[<|1 -> expr|>]];
  ph = Table[Unique["afI"], Length[ints]];
  arrays = CoefficientArrays[expr /. Thread[ints -> ph], ph];
  If[Length[arrays] > 2, AFFail["AFLinearForm: the expression is not linear in A0 B0 C0 D0"]];
  Select[Association[Append[Thread[ints -> Normal[arrays[[2]]]], 1 -> arrays[[1]]]], # =!= 0 &]
];

AFLinearSum[lins_List] := Merge[lins, Total];
AFFromLinear[lin_Association] := Total[KeyValueMap[#1 #2 &, lin]];
AFFromLinear[lin_Association, n_Integer] := Total[KeyValueMap[#1 #2[[n]] &, lin]];     (* component n of vector coefficients *)

(* coefficient of the UV pole Delta of a scalar integral: A0[m] = m Delta + ..., B0 = Delta + ..., C0, D0 finite *)
AFUVPole[A0[m_]] := m;
AFUVPole[_B0] := 1;
AFUVPole[_] := 0;

(* ---------------------------------------------------------------------------------------------------------------
   D -> 4 with the rational terms.

   The PaVe functions carry a UV pole (Delta = 1/eps - gamma_E + ln 4pi, the Delta of LoopTools), and a coefficient that depends
   on D = 4 - 2 eps multiplies it: c(eps) = c0 + eps c1 + ...  ==>  c (P/eps + I_fin) = c0 P/eps + c0 I_fin + c1 P, so the
   finite "rational term" c1 P must not be lost ((D - 4) B0 = -2 + ...). In terms of the usual A0, B0 (Delta inside) the result
   is   sum_i c_i(4) I_i + (rational terms),   with  c1 = dc/d eps at 0  and  P = AFUVPole[I]. Delta cancels identically.
   Per coefficient this is one substitution and one derivative; no series of a long sum is needed.
   Returns <|"Lin" -> linear form at D = 4, "Pole" -> coefficient of Delta (list or scalar, as the coefficients)|>.  *)

afAtZero[e_] := Module[{v = e /. afEps -> 0},
  If[FreeQ[v, Indeterminate | ComplexInfinity | DirectedInfinity], Return[v]];
  v = Together[e] /. afEps -> 0;                                  (* removable 0/0: cancel first *)
  If[!FreeQ[v, Indeterminate | ComplexInfinity | DirectedInfinity],
    AFFail["AFLinearTo4: a coefficient is singular at D = 4, it multiplies an integral with a pole of its own"]];
  v
];

AFLinearTo4[lin_Association] := Module[{out = <||>, pole = 0, shift = 0, ce, c0, p},
  Do[
    ce = FCReplaceD[lin[key], D -> 4 - 2 afEps];
    c0 = afAtZero[ce];
    out[key] = c0;
    p = AFUVPole[key];
    If[p =!= 0, pole += p c0; shift += p afAtZero[D[ce, afEps]]],
    {key, Keys[lin]}];
  out[1] = Lookup[out, 1, 0] + shift;
  <|"Lin" -> out, "Pole" -> pole|>
];

(* the same for one expression *)
AFLimitTo4[expr_] := AFFromLinear[AFLinearTo4[AFLinearForm[expr]]["Lin"]];

(* Checks of the linear form and of D -> 4 against results known by hand: (D-4) B0 -> -2, (D-4) A0[m] -> -2 m,
   (D-2)/(D-3) B0 -> 2 B0 + 2, C0 coefficients just at D = 4, the sum of two linear forms, the vector form. *)
AFLinearSelfTest[] := Module[{res = {}, check, lin},
  check[name_String, ok_] := (AppendTo[res, TrueQ[ok]]; Print["[ampflow] linear-form check ", If[TrueQ[ok], "OK      ", "FAILED  "], name]);
  check["(D-4) B0 -> -2", PossibleZeroQ[AFLimitTo4[(D - 4) B0[s, m1, m2]] + 2]];
  check["(D-4) A0[m] -> -2 m", PossibleZeroQ[AFLimitTo4[(D - 4) A0[m]] + 2 m]];
  check["(D-2)/(D-3) B0 -> 2 B0 + 2", PossibleZeroQ[AFLimitTo4[(D - 2)/(D - 3) B0[s, m1, m2]] - 2 B0[s, m1, m2] - 2]];
  check["C0 and rational terms at D = 4", PossibleZeroQ[AFLimitTo4[(D - 1) C0[s1, s2, s3, m1, m2, m3] + (D - 3) t] - 3 C0[s1, s2, s3, m1, m2, m3] - t]];
  lin = AFLinearSum[{AFLinearForm[{p1 A0[m] + q1, 0, B0[s, m, m]}], AFLinearForm[{p2 A0[m], r2 C0[s, s, s, m, m, m], 1}]}];
  check["vector linear form and sum", PossibleZeroQ[AFFromLinear[lin, 1] - (p1 + p2) A0[m] - q1] &&
    PossibleZeroQ[AFFromLinear[lin, 2] - r2 C0[s, s, s, m, m, m]] && PossibleZeroQ[AFFromLinear[lin, 3] - B0[s, m, m] - 1]];
  And @@ res
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
AFAllowedHeads = {Plus, Times, Power, Rational, Complex, List, Row, A0, B0, C0, D0, SMP, FCGV, Subscript,
  Sin, Cos, Tan, Sec, Csc, Cot, HoldForm};     (* trigonometric functions of the mixing angles; HoldForm only labels coupling names, fc2lt ignores it *)

AFExportAmplitude[file_String, expr_, header_String] := Module[{heads, bad, text},
  heads = DeleteDuplicates[Cases[expr, f_Symbol[___] :> f, {0, Infinity}]];
  bad = Complement[heads, AFAllowedHeads];
  If[bad =!= {}, AFFail["export refused: the expression still contains ", bad, "  (only A0 B0 C0 D0, SMP, FCGV are allowed)"]];
  If[!FreeQ[expr, D | Epsilon | afEps | EulerGamma],
    AFFail["export refused: the expression still contains D, Epsilon or Delta symbols"]];
  text = "(* " <> header <> " *)\n" <> ToString[expr, InputForm, PageWidth -> Infinity] <> "\n";
  Quiet[CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  Export[file, text, "Text"];
  AFLog["wrote ", file];
  file
];
