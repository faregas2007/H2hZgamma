(* ::Package:: *)

(* ampflow_dual.m -- dual projector for amplitudes  S(k1) Z(k2) gamma(k3)  (all momenta outgoing).

   Used for  H0 -> h0 Z gamma  in the 2HDM (report.pdf, sections 1-4), but nothing here is specific to the 2HDM: any
   amplitude A^{mu nu} (mu: Z index, nu: photon index) with a scalar k1^2 = x, a massive vector k2^2 = y and a photon
   k3^2 = 0 decomposes into the same structures.

   Load AFTER FeynCalc and ampflow_ff.m:
       $LoadAddOns = {"FeynArts"};  << FeynCalc`
       Get[FileNameJoin[{<this folder>, "ampflow_ff.m"}]];
       Get[FileNameJoin[{<this folder>, "ampflow_dual.m"}]];
   Everything is plain FeynCalc. Names start with AFDual (functions) or afDual (internal).

   ---- Conventions (they are the ones of examples/thdm/models/thdm.model) ---------------------------------------------
     k1 = scalar h0     k1.k1 = x = m_h^2
     k2 = Z             k2.k2 = y = m_Z^2
     k3 = photon        k3.k3 = 0
     a = k3.k1,  b = k3.k2,  c = k1.k2          (with q13 = (k1+k3)^2, q23 = (k2+k3)^2 and the parent mass mH:
                                                 a = (q13 - x)/2,  b = (q23 - y)/2,  c = (mH^2 - q13 - q23)/2,  report eq. 4)
     Delta = a^2 y - 2 a b c + b^2 x            (minus the Gram determinant of k1, k2, k3)

   ---- The decomposition ------------------------------------------------------------------------------------------------
     A^{mu nu} = F1 P1 + F2 P2 + F3 P3 + F4 eps^{mu nu k1 k2}
         P1 = -b g^{mu nu} + k3^mu k2^nu
         P2 = -a g^{mu nu} + k3^mu k1^nu
         P3 = -a k1^mu k2^nu + b k1^mu k1^nu
   They satisfy the photon Ward identity k3_nu P_i^{mu nu} = 0 and are transverse for eps_Z.k2 = 0 and eps_gamma.k3 = 0
   (report eqs. 11-16).

   The P_i are not orthogonal under the polarisation sum, so contracting A with P_i does not give F_i. The dual projector
       Proj_i^{mu nu} = (G^-1)_{im} Pi_m^{mu nu},   Pi_m^{mu nu} = P_m^{rho sigma} PZ^{mu}_rho PG^{nu}_sigma,
       G_ij = P_i^{rho sigma} PZ_{mu rho} PG_{nu sigma} P_j^{mu nu}
   with PZ = -g + k2 k2/y (Z polarisation sum) and PG = -g (photon: the k3 k3 terms drop by the Ward identity), satisfies
   Proj_i . P_j = delta_ij, hence Proj_i . A = F_i, in D dimensions and with no tensor reduction left for later.

   ---- Relation to the report's labels -----------------------------------------------------------------------------------
   The report writes P1 = -(k3.k1) g + k3^mu k1^nu and P2 = -(k3.k2) g + k3^mu k2^nu, i.e. its F1, F2 are THIS file's F2, F1.
   F3 is the same. Its eq. (24) defines a = k3.k2, b = k3.k1, which is inconsistent with its own Delta in eq. (26); with the
   definitions above (a = k3.k1, b = k3.k2, as in thdm.model) the Gram matrix of eq. (25) and det G = -(D-3) Delta^3/y hold
   (AFDualSelfTest checks both).                                                                                            *)


(* ---------------------------------------------------------------------------------------------------------------------
   Kinematics
   --------------------------------------------------------------------------------------------------------------------- *)

AFDualDeltaPoly = a^2 y - 2 a b c + b^2 x;

(* Scalar products of the three external momenta. Applied after ExpandScalarProduct, so (k1+k3)^2 etc. are covered. *)
AFDualKinRules[] := Flatten[Table[{
  Pair[Momentum[k3, dim], Momentum[k1, dim]] -> a,
  Pair[Momentum[k3, dim], Momentum[k2, dim]] -> b,
  Pair[Momentum[k1, dim], Momentum[k2, dim]] -> c,
  Pair[Momentum[k1, dim], Momentum[k1, dim]] -> x,
  Pair[Momentum[k2, dim], Momentum[k2, dim]] -> y,
  Pair[Momentum[k3, dim], Momentum[k3, dim]] -> 0}, {dim, {D, 4}}]];

AFDualKin[expr_] := ExpandScalarProduct[expr] /. AFDualKinRules[];

(* The names the module uses as plain symbols must be free. *)
AFDualCheckSymbols[] := Module[{bad},
  bad = Select[{"a", "b", "c", "x", "y", "k1", "k2", "k3", "\[CapitalDelta]"}, ToExpression[#, InputForm, ValueQ] &];
  If[bad =!= {}, AFFail["AFDual: these symbols have a value and would be replaced silently: ", bad, "  (Clear them first)"]]
];


(* ---------------------------------------------------------------------------------------------------------------------
   Structures, polarisation sums, Gram matrix
   --------------------------------------------------------------------------------------------------------------------- *)

AFDualStructures[mu_, nu_] := {
  -b MTD[mu, nu] + FVD[k3, mu] FVD[k2, nu],
  -a MTD[mu, nu] + FVD[k3, mu] FVD[k1, nu],
  -a FVD[k1, mu] FVD[k2, nu] + b FVD[k1, mu] FVD[k1, nu]};

AFDualPZ[mu_, nu_] := -MTD[mu, nu] + FVD[k2, mu] FVD[k2, nu]/y;
AFDualPG[mu_, nu_] := -MTD[mu, nu];

(* Pi_m^{mu nu} = P_m^{rho sigma} PZ^{mu}_rho PG^{nu}_sigma  (free indices mu, nu) *)
AFDualPiVectors[mu_, nu_] := Module[{rho, sigma, P},
  P = AFDualStructures[rho, sigma];
  Table[AFDualKin[Contract[P[[m]] AFDualPZ[mu, rho] AFDualPG[nu, sigma]]], {m, 3}]
];

afDualBuild[] := Module[{rho, sigma, mu, nu, P, Q, gram, det, inv},
  AFDualCheckSymbols[];
  P = AFDualStructures[rho, sigma];
  Q = AFDualStructures[mu, nu];
  gram = Table[Together[AFDualKin[Contract[P[[i]] AFDualPZ[mu, rho] AFDualPG[nu, sigma] Q[[j]]]]], {i, 3}, {j, 3}];
  det = Factor[Det[gram]];
  If[PossibleZeroQ[det], AFFail["AFDual: the Gram matrix is singular"]];
  inv = Map[Together, Inverse[gram], {2}];
  <|"Gram" -> gram, "Det" -> det, "GramInverse" -> inv|>
];

(* Computed once per session. *)
afDualData = None;
AFDualSetup[] := (If[!AssociationQ[afDualData], afDualData = afDualBuild[]]; afDualData);

AFDualGram[] := AFDualSetup[]["Gram"];
AFDualGramInverse[] := AFDualSetup[]["GramInverse"];


(* ---------------------------------------------------------------------------------------------------------------------
   Projection:  tensor^{mu nu} -> {F1, F2, F3}  (and F4)

   `tensor` has the free indices mu, nu (FeynCalc LorentzIndex[mu, D]), D-dimensional, no loop momentum left (after TID).
   The result is exact in D; send it through AFLimitTo4 (ampflow_ff.m) afterwards.                                        *)

AFDualProject[tensor_, mu_, nu_] := Module[{pis, raw},
  pis = AFDualPiVectors[mu, nu];
  raw = Table[AFDualKin[Contract[tensor pis[[m]]]], {m, 3}];
  AFDualGramInverse[] . raw
];

(* Same, for an amplitude that still contains the loop momentum: contract with the three vectors Pi_m (CP-even, no epsilon in them),
   apply `prep` (e.g. AFDropLoopEps) to each contraction, reduce with TID, express the scalar products of k1..k3. Returns the
   three RAW projections; the caller sums over diagrams first and multiplies with AFDualGramInverse[] once.                *)
(* ---- the steps for ONE contraction  Pi_m . A, in this order (each is timed at VERBOSE=2) --------------------------------------
     1  contract with Pi_m, `prep` (dropping loop epsilons for fermions)
     2  tree propagators (no loop momentum, e.g. the 1/(k2+k3)^2 - m^2 of reducible diagrams) written out as scalar products,
        and the kinematics k1^2 = x, k2^2 = y, k3^2 = 0, k1.k3 = a, ...: the coefficients are rational in a b c x y
     3  ApartFF: scalar products l.k_i in the numerators are written with the loop propagators, linearly dependent denominators
        are partial-fractioned; then the scaleless integrals are dropped.  Afterwards TID has only short pieces and few
        tensor structures left.  ($AFDualApartFF = False: skip, TID on the whole expression as before)
     4  TID to PaVe
     5  kinematics again: it acts on the arguments of the PaVe functions (A0, B0, C0, D0)                                       *)
$AFDualApartFF = True;

afDualSplitFAD[ps_List, loop_] := Module[{tree, lp},
  (* the loop momentum may stand inside a sum, Momentum[l + k2, D], so test for the symbol, not for Momentum[l, ___]:
     the first version turned (l + k2)^2 - m^2 into an explicit denominator and ApartFF and TID then failed on it *)
  tree = Select[ps, FreeQ[#, loop] &];
  lp = Select[ps, !FreeQ[#, loop] &];
  If[tree === {}, FeynAmpDenominator @@ ps,
    FeynAmpDenominatorExplicit[FeynAmpDenominator @@ tree] * If[lp === {}, 1, FeynAmpDenominator @@ lp]]
];
afDualTreeExplicit[e_, loop_] := e /. FeynAmpDenominator[ps__] :> afDualSplitFAD[{ps}, loop];

afDualApart[e_, loop_] := Module[{r},
  If[FreeQ[e, FeynAmpDenominator], Return[e]];
  (* ApartFF can abort the kernel (FeynCalc fatal error) or fail with a message: CheckAbort/Check make that an ordinary fallback to
     TID on the expression as it was; VERBOSE=2 shows FeynCalc's own messages and the input *)
  r = CheckAbort[
    If[$AFVerbose >= 2, Check[ApartFF[e, {loop}], $Failed], Quiet[Check[ApartFF[e, {loop}], $Failed]]], $Failed];
  If[r === $Failed,
    AFLog["  ApartFF failed or aborted; TID on the expression without it. Input was: ",
      StringTake[ToString[e, InputForm], UpTo[500]]];
    Return[e]];
  If[NameQ["FeynCalc`FCLoopRemoveScaleless"],
    r = CheckAbort[FCLoopRemoveScaleless[r, {loop}], AFLog["  FCLoopRemoveScaleless aborted, skipped"]; r]];
  r
];

afDualProjectOne[tensor_, pi_, loop_, prep_] := Module[{e},
  e = AFStep["contract", prep[Contract[tensor pi]]];
  e = AFStep["tree props, kin", AFDualKin[afDualTreeExplicit[e, loop]]];
  If[$AFDualApartFF, e = AFStep["ApartFF", afDualApart[e, loop]]];
  e = AFStep["TID", TID[e, loop, ToPaVe -> True]];
  AFStep["kin (PaVe args)", AFDualKin[e]]
];

AFDualProjectLoopRaw[tensor_, mu_, nu_, loop_, prep_: Identity] := Module[{pis, r},
  pis = AFDualPiVectors[mu, nu];
  r = Table[afDualProjectOne[tensor, pis[[m]], loop, prep], {m, 3}];
  (* TID first; afterwards no loop momentum may be left (so rules such as l.k -> 0, (l.k)(l.k') -> l^2 k.k'/D would act on nothing) *)
  If[!FreeQ[r, Momentum[loop, ___]], AFFail["AFDualProjectLoopRaw: loop momentum ", loop, " is still present after TID (an integral TID could not reduce)"]];
  r
];

(* CP-odd structure eps^{mu nu k1 k2}: its Gram element is eps.eps = 2 (c^2 - x y) (the k2 k2 term of PZ drops out), and
   it is orthogonal to P1..P3 (every contraction has a repeated momentum). Only meaningful in 4 dimensions: the epsilon is the
   4-dimensional LC, not LCD, because FeynCalc contracts two D-dimensional epsilons with an extra factor (D-2)(D-3)/2.     *)
AFDualProjectOdd[tensor_, mu_, nu_] :=
  AFDualKin[Contract[tensor LC[mu, nu][k1, k2]]]/(2 (c^2 - x y));


(* ---------------------------------------------------------------------------------------------------------------------
   Polarisation sum

   Sum_pol |A|^2 = Conjugate[F] . G . F  +  2 (c^2 - x y) |F4|^2          (report eq. 18 and 30)
   dim = 4 for the physical result. a, b, c, x, y, Delta are real.                                                         *)

AFDualSumSquared[F_List, F4_: 0, dim_: 4] := Module[{g, s},
  If[Length[F] =!= 3, AFFail["AFDualSumSquared: expected {F1, F2, F3}"]];
  g = AFDualGram[] /. D -> dim;
  s = Conjugate[F] . g . F + 2 (c^2 - x y) Conjugate[F4] F4;
  s /. Conjugate[r : (a | b | c | x | y | \[CapitalDelta])] :> r
];


(* ---------------------------------------------------------------------------------------------------------------------
   Delta: factor exact powers of the Gram determinant out of numerator and denominator.

   AFPutDelta[coeff] writes  coeff = Delta^n * rest  where Delta = a^2 y - 2 a b c + b^2 x  is divided out only when it divides EXACTLY
   (no remainder), so the result always equals coeff; it is a presentation step (the model file defines Delta). Meant for the
   coefficients of a linear form (no A0..D0 inside); anything that is not a rational function of x, y, a, b, c is returned as it is. *)

afDualPeel[p_] := Module[{red, n = 0, q = p},
  If[p === 0 || p === 1, Return[{0, p}]];
  While[True,
    red = Quiet[Check[PolynomialReduce[q, {AFDualDeltaPoly}, {x, y, c, a, b}], $Failed]];
    If[red === $Failed || red[[2]] =!= 0 || red[[1, 1]] === 0, Break[]];
    q = red[[1, 1]]; n++];
  {n, q}
];

AFPutDelta[coeff_] := Module[{tog = Together[coeff], num, den, nn, qn, nd, qd},
  {num, den} = {Numerator[tog], Denominator[tog]};
  If[!PolynomialQ[num, {x, y, c, a, b}] || !PolynomialQ[den, {x, y, c, a, b}], Return[coeff]];
  {nn, qn} = afDualPeel[Expand[num]];
  {nd, qd} = afDualPeel[Expand[den]];
  \[CapitalDelta]^(nn - nd) qn/qd
];


(* ---------------------------------------------------------------------------------------------------------------------
   Self test: the algebra of the module against closed forms and consistency conditions (no diagrams needed).

   1  Gram matrix equals the closed form of report eq. (25)           (contracted by FeynCalc here, typed in by hand there)
   2  det G = -(D-3) Delta^3 / y                                     (report eq. 26)
   3  G . G^-1 = 1
   4  round trip: Proj_i . (Sum_j f_j P_j) = f_i  for symbolic f_j, in D dimensions
   5  eps^{mu nu k1 k2} . Pi_m = 0                                    (CP-even and CP-odd do not mix)
   6  AFDualProjectOdd recovers f4 from f4 eps^{mu nu k1 k2}          (Gram element 2 (c^2 - x y))
   7  photon Ward identity: k3_nu P_i^{mu nu} = 0
   8  AFPutDelta only rewrites (expression unchanged)
   Returns True when all pass; prints one line per check.                                                                 *)

AFDualSelfTest[] := Module[{res = {}, add, zeroQ, dl, closed, g, det, inv, mu, nu, f, f4, amp, back, eps, odd, ward},
  add[name_String, ok_] := (AppendTo[res, TrueQ[ok]];
    Print["[ampflow] dual projector check ", If[TrueQ[ok], "OK      ", "FAILED  "], name]);
  zeroQ[e_] := PossibleZeroQ[Together[e]];
  dl = AFDualDeltaPoly;
  closed = {{(D - 2) b^2, (D - 2) a b, -dl}, {(D - 2) a b, (D - 2) a^2 - dl/y, -c dl/y}, {-dl, -c dl/y, dl (x - c^2/y)}};
  g = AFDualGram[]; det = AFDualSetup[]["Det"]; inv = AFDualGramInverse[];

  add["Gram matrix = closed form (report eq. 25)", And @@ (zeroQ /@ Flatten[g - closed])];
  add["det G = -(D-3) Delta^3/y (report eq. 26)", zeroQ[det + (D - 3) dl^3/y]];
  add["G . G^-1 = 1", And @@ (zeroQ /@ Flatten[g . inv - IdentityMatrix[3]])];

  f = {afF1, afF2, afF3};
  amp = f . AFDualStructures[mu, nu];
  back = AFDualProject[amp, mu, nu];
  add["Proj_i . (Sum_j F_j P_j) = F_i in D dimensions", And @@ (zeroQ /@ (back - f))];

  eps = LCD[mu, nu][k1, k2];
  odd = Table[Contract[eps AFDualPiVectors[mu, nu][[m]]], {m, 3}];
  add["eps^{mu nu k1 k2} . Pi_m = 0 (CP-even and CP-odd do not mix)", And @@ (zeroQ /@ odd)];

  f4 = afF4;
  add["Proj_odd recovers F4 (Gram element 2 (c^2 - x y))", zeroQ[AFDualProjectOdd[f4 LC[mu, nu][k1, k2], mu, nu] - f4]];

  ward = Table[AFDualKin[Contract[AFDualStructures[mu, nu][[i]] FVD[k3, nu]]], {i, 3}];
  add["photon Ward identity k3_nu P_i^{mu nu} = 0", And @@ (zeroQ /@ ward)];

  (* AFPutDelta returns an expression in the symbol Delta; it equals the input once Delta is replaced by its polynomial *)
  add["AFPutDelta leaves the expression unchanged",
    And @@ Flatten[Table[zeroQ[(AFPutDelta[inv[[i, j]]] /. \[CapitalDelta] -> dl) - inv[[i, j]]], {i, 3}, {j, i, 3}]]];

  And @@ res
];
