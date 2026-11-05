(* ::Package:: *)

(* ampflow_fermion.m -- closed fermion loops with gamma5 and Levi-Civita tensors, in D dimensions.

   Load after ampflow_dual.m; ampflow_h0hzg.m uses it for the "Fermion" group.

   Order of the work for ONE diagram (AFFermionProjectRaw):
     colour    SUNSimplify on the colour deltas / traces of the quark loop           (Nc comes out as SUNN -> Nc)
     trace     Dirac traces in D dimensions with a chosen gamma5 scheme              (AFTraceEvaluate)
     project   contract with the three vectors Pi_m^{mu nu} of the dual projector     (CP-even: no Levi-Civita in them)
     eps       Levi-Civita scalars containing the loop momentum are dropped           (AFDropLoopEps, justification below)
     reduce    TID to A0 B0 C0 D0                                                     (once per form factor, not per structure)
     combine   G^-1 . (...) gives F1, F2, F3                                          (once, for the sum over diagrams)

   ---- gamma5 and Levi-Civita ----------------------------------------------------------------------------------------
   The CP-even form factors F1..F3 are projections with structures built from g^{mu nu} and the three external momenta only.
   A single gamma5 in a trace produces eps^{...} with four vectors; after the projection every free index is contracted, so
   what is left is an eps SCALAR of four vectors out of {k1, k2, k3, l}. Three independent external momenta and l: the scalar
   always contains l, and after tensor reduction l^alpha -> sum_i c_i k_i^alpha  and  g^{alpha beta} -> contraction with the
   other factors, so eps(k1,k2,k3,k_i) = 0 and it vanishes.
   Traces with an even number of gamma5 contain no eps and are evaluated by anticommuting (NDR) or by the Larin definition.
   Anything that still contains an eps with free indices belongs to the CP-odd structure eps^{mu nu k1 k2}, whose coefficient
   F4 has to cancel in the sum over the two orientations of the loop (Furry / CP); it is computed only on request.

   ---- Choices made here ----------------------------------------------------------------------------------------------
   * No ChangeDimension[amp, 4] before the Dirac algebra (option "PreSimplify4" -> True reproduces it). Doing the algebra with
     4-dimensional contraction identities (gamma^a ... gamma_a = 4 instead of D, l^2 of a 4-dimensional l) drops terms
     proportional to (D - 4) that multiply UV poles of the individual diagrams; they give finite rational terms that the
     sum over diagrams does not necessarily cancel.
   * No loop-momentum rules (looplineardependences / squareloopterms). Replacing (l.k_i) -> 0 and (l.k_i)(l.k_j) -> l^2 k_i.k_j/D is
     the result of integrating a tensor integral with NO external momentum in its denominators (A0 type). With the shifted
     denominators (l + k_i)^2 - m^2 of triangles and boxes it is wrong: e.g. the C1 coefficient is not zero. TID does the
     reduction exactly, so the rules are not needed.
   * Colour by SUNSimplify (the colour indices of the vertices are given SUNFIndex names), not by a hand-inserted Nc.        *)


(* ---------------------------------------------------------------------------------------------------------------------
   gamma5 scheme.  FeynCalc 10: FCSetDiracGammaScheme. FeynCalc 9.x: $BreitMaison / $Larin.
   "NDR"   anticommuting gamma5 (default; cyclicity of the trace is not guaranteed for an odd number of gamma5)
   "Larin" gamma5 = (i/4!) eps_{abcd} gamma^a gamma^b gamma^c gamma^d, eps contracted in D dimensions: D-dimensional, keeps
           trace cyclicity and the trace evaluation, gamma5 does not anticommute (finite renormalisation of axial currents)
   "BMHV"  Breit-Maison / 't Hooft-Veltman: gamma5 anticommutes with the 4-dimensional gammas, commutes with the (D-4)-dimensional
   Run the same diagrams in two or three schemes and compare (AFFermionSchemeCheck).                                          *)

$AFGammaScheme = "NDR";

AFGammaScheme[scheme_String] := (
  Which[
    NameQ["FeynCalc`FCSetDiracGammaScheme"],
      Switch[scheme,
        "NDR", ToExpression["FCSetDiracGammaScheme[\"NDR\"]"],
        "Larin", ToExpression["FCSetDiracGammaScheme[\"Larin\"]"],
        "BMHV", ToExpression["FCSetDiracGammaScheme[\"BMHV\"]"],
        _, AFFail["AFGammaScheme: scheme must be \"NDR\", \"Larin\" or \"BMHV\""]],
    True,
      Switch[scheme,
        "NDR", $Larin = False; $BreitMaison = False,
        "Larin", $Larin = True; $BreitMaison = False,
        "BMHV", $Larin = False; $BreitMaison = True,
        _, AFFail["AFGammaScheme: scheme must be \"NDR\", \"Larin\" or \"BMHV\""]]];
  $AFGammaScheme = scheme);


(* ---------------------------------------------------------------------------------------------------------------------
   Levi-Civita scalars with the loop momentum (no free index left) -> 0.  Valid only after the projection with CP-even
   structures, before or after TID (see above).                                                                            *)

AFDropLoopEps[expr_, loop_: l] :=
  expr /. (e_Eps /; FreeQ[List @@ e, LorentzIndex[__]] && !FreeQ[e, Momentum[loop, ___]]) :> 0;


(* ---------------------------------------------------------------------------------------------------------------------
   Colour: the quark loop. FCFAConvert has to be called with SUNIndexNames / SUNFIndexNames so the colour indices are
   SUNFDelta's; here they are summed. SUNN is FeynCalc's N_c.                                                              *)

(* SUNSimplify aborts the whole kernel when it cannot separate the colour objects from the rest ("Failed to properly isolate the
   color algebraic expressions"). CheckAbort turns that into an ordinary failure of THIS diagram, and the message names what is
   in the way: any function other than the SUN heads that has a colour index among its arguments. *)
AFFermionColour[amp_] := Module[{r, bad},
  r = CheckAbort[AFStep["colour", SUNSimplify[amp, Explicit -> False]], $Failed];
  If[r === $Failed,
    bad = DeleteDuplicates[Cases[amp,
      e : (h_[___]) /; !MemberQ[{SUNFDelta, SUNDelta, SUNF, SUND, SUNT, SUNTF, SUNIndex, SUNFIndex, Plus, Times, Power, List}, h] &&
        !FreeQ[Rest[e], _SUNIndex | _SUNFIndex], {0, Infinity}]];
    AFFail["SUNSimplify aborted: colour isolation failed. Objects with a colour index inside: ",
      StringTake[ToString[Take[bad, UpTo[3]], InputForm], UpTo[600]],
      "   (", Length[bad], " such objects; ", LeafCount[amp], " leaves)"]];
  r /. SUNN -> Nc
];


(* ---------------------------------------------------------------------------------------------------------------------
   Traces
   --------------------------------------------------------------------------------------------------------------------- *)

Options[AFTraceEvaluate] = {"Scheme" -> "NDR", "PreSimplify4" -> False, "DropOddGamma5" -> True};

(* Terms of a trace with an ODD number of gamma5 give Levi-Civita tensors: with the CP-even projection the eps scalar contains the loop
   momentum and vanishes (header of this file); they belong to the CP-odd structure F4. FeynCalc's NDR leaves such a trace
   unevaluated when the gammas are D-dimensional (that was the failure of the first trial run), so they are removed here, term by term,
   independently of the scheme. Terms with an even number are untouched and go to TR. *)
afDropOddGamma5[x_] := Module[{e = Expand[x]},
  If[Head[e] === Plus,
    Total[Select[List @@ e, EvenQ[Count[#, DiracGamma[5], {0, Infinity}]] &]],
    If[EvenQ[Count[e, DiracGamma[5], {0, Infinity}]], e, 0]]];

AFTraceEvaluate[amp_, OptionsPattern[]] := Module[{a = amp},
  AFGammaScheme[OptionValue["Scheme"]];
  a = FCTraceFactor[Contract[a]];
  If[OptionValue["PreSimplify4"],
    a = DiracSimplify[ChangeDimension[a, 4], InsideDiracTrace -> True];
    a = ChangeDimension[a, D]];
  If[OptionValue["DropOddGamma5"], a = a /. DiracTrace[x_, o___] :> DiracTrace[afDropOddGamma5[x], o]];
  a = AFEvaluateTraces[a];
  Contract[a]
];

(* Every DiracTrace must be gone afterwards: TR first, then DiracSimplify with DiracTraceEvaluate -> True. A trace that survives is an
   error (the diagram fails with the first leftover trace in the message), because TID would treat it as an opaque factor and the
   result would be zero or wrong. *)
AFEvaluateTraces[amp_] := Module[{a = amp, left},
  If[FreeQ[a, DiracTrace], Return[a]];
  a = a /. DiracTrace[x_, ___] :> TR[x];
  If[!FreeQ[a, DiracTrace],
    a = DiracSimplify[a, DiracTraceEvaluate -> True]];
  left = Cases[a, _DiracTrace, {0, Infinity}];
  If[left =!= {},
    AFFail["traces not evaluated (", Length[left], " left, gamma5 scheme ", $AFGammaScheme, "), first: ",
      ToString[First[left], InputForm]]];
  a
];


(* ---------------------------------------------------------------------------------------------------------------------
   One diagram to its raw projections (before G^-1).

   amp  one FeynCalc amplitude from FCFAConvert (momenta k1, k2, k3, open indices mu, nu, colour indices named).
   Returns {Pi_1 . A, Pi_2 . A, Pi_3 . A} reduced to PaVe functions. The caller sums over diagrams and multiplies with G^-1
   (AFDualGramInverse[]) once.                                                                                              *)

Options[AFFermionProjectRaw] = {"Scheme" -> "NDR", "PreSimplify4" -> False};

AFFermionProjectRaw[amp_, mu_, nu_, loop_, opts : OptionsPattern[]] :=
  AFDualProjectLoopRaw[AFTraceEvaluate[AFFermionColour[amp], opts], mu, nu, loop, AFDropLoopEps];

(* The same diagrams through different gamma5 schemes. Returns <|"Forms" -> <|scheme -> {F1, F2, F3}|>, "Differences" -> {...}|>
   (each scheme against the first one, simplified). PaVe functions are the common basis, so a vanishing difference is
   an exact statement; a nonzero one should be a rational (PaVe-free) term, which is the scheme dependence to be understood
   (finite counterterms of the scheme) before one of the results is used.                                                    *)
AFFermionSchemeCheck[amps_List, mu_, nu_, loop_, schemes_List : {"NDR", "Larin"}] := Module[{forms},
  forms = Association[Table[s -> AFDualGramInverse[] . Total[AFFermionProjectRaw[#, mu, nu, loop, "Scheme" -> s] & /@ amps], {s, schemes}]];
  AFGammaScheme["NDR"];
  <|"Forms" -> forms, "Differences" -> Table[s -> Simplify[forms[First[schemes]] - forms[s]], {s, Rest[schemes]}]|>
];


(* ---------------------------------------------------------------------------------------------------------------------
   Self test (FeynCalc only).                                                                                              *)

AFFermionSelfTest[] := Module[{res = {}, add, e1, e2, tt},
  add[name_String, ok_] := (AppendTo[res, TrueQ[ok]]; Print["[ampflow] fermion check ", If[TrueQ[ok], "OK      ", "FAILED  "], name]);
  e1 = Eps[Momentum[k1, D], Momentum[k2, D], Momentum[k3, D], Momentum[l, D]];
  e2 = Eps[LorentzIndex[mu, D], LorentzIndex[nu, D], Momentum[k1, D], Momentum[k2, D]];
  add["Eps scalar with the loop momentum is dropped", AFDropLoopEps[afT e1 + afU] === afU];
  add["Eps with free indices is kept (CP-odd structure)", AFDropLoopEps[afT e2 + afU] === afT e2 + afU];
  add["Eps scalar of external momenta only is kept", AFDropLoopEps[afT Eps[Momentum[k1, D], Momentum[k2, D], Momentum[k3, D], Momentum[afP, D]] + afU] =!= afU];
  tt = TID[SPD[l, afQ] FAD[{l, afM}, {l + afQ, afM}], l, ToPaVe -> True];
  add["TID of (l.q)/(D1 D2) is NOT zero (the rule l.q -> 0 would give 0 for a denominator with a shifted momentum)", !PossibleZeroQ[Simplify[tt]]];
  add["AFGammaScheme switches between NDR and Larin",
    (AFGammaScheme["NDR"]; $AFGammaScheme === "NDR") && (AFGammaScheme["Larin"]; $AFGammaScheme === "Larin") && (AFGammaScheme["NDR"]; True)];
  And @@ res
];
