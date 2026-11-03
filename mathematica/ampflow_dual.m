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
AFDualProjectLoopRaw[tensor_, mu_, nu_, loop_, prep_: Identity] := Module[{pis, r},
  pis = AFDualPiVectors[mu, nu];
  r = Table[AFDualKin[TID[prep[Contract[tensor pis[[m]]]], loop, ToPaVe -> True]], {m, 3}];
  (* TID first; afterwards no loop momentum may be left (so rules such as l.k -> 0, (l.k)(l.k') -> l^2 k.k'/D would act on nothing) *)
  If[!FreeQ[r, Momentum[loop, ___]], AFFail["AFDualProjectLoopRaw: loop momentum ", loop, " is still present after TID (an integral TID could not reduce)"]];
  r
];

(* CP-odd structure eps^{mu nu k1 k2}: its Gram element is eps.eps = 2 (c^2 - x y) (the k2 k2 term of PZ drops out), and
   it is orthogonal to P1..P3 (every contraction has a repeated momentum). Only meaningful in 4 dimensions.             *)
AFDualProjectOdd[tensor_, mu_, nu_] :=
  AFDualKin[Contract[tensor LCD[mu, nu][k1, k2]]]/(2 (c^2 - x y));


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

   AFPutDelta[expr] writes  expr = Delta^n * rest  where Delta = a^2 y - 2 a b c + b^2 x  is divided out only when it
   divides EXACTLY (no remainder), so the result is always equal to expr; it is a presentation step (the model file
   defines Delta). Functions A0..D0 are treated as constants.                                                             *)

afDualPeel[p_] := Module[{red, n = 0, q = p},
  If[p === 0 || p === 1, Return[{0, p}]];
  While[True,
    red = Quiet[Check[PolynomialReduce[q, {AFDualDeltaPoly}, {x, y, c, a, b}], $Failed]];
    If[red === $Failed || red[[2]] =!= 0 || red[[1, 1]] === 0, Break[]];
    q = red[[1, 1]]; n++;
  ];
  {n, q}
];

AFPutDelta[expr_] := Module[{tog, num, den, fs, ph, rules, back, nn, qn, nd, qd, res},
  tog = Together[expr];
  fs = DeleteDuplicates[Cases[tog, _A0 | _B0 | _C0 | _D0, {0, Infinity}]];
  ph = Table[Unique["afDualPh"], {Length[fs]}];
  rules = Thread[fs -> ph]; back = Thread[ph -> fs];
  {num, den} = {Numerator[tog], Denominator[tog]} /. rules;
  If[!PolynomialQ[num, {x, y, c, a, b}] || !PolynomialQ[den, {x, y, c, a, b}], Return[expr]];
  {nn, qn} = afDualPeel[Expand[num]];
  {nd, qd} = afDualPeel[Expand[den]];
  res = \[CapitalDelta]^(nn - nd) qn/qd;
  res /. back
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
  add["Proj_odd recovers F4 (Gram element 2 (c^2 - x y))", zeroQ[AFDualProjectOdd[f4 eps, mu, nu] - f4]];

  ward = Table[AFDualKin[Contract[AFDualStructures[mu, nu][[i]] FVD[k3, nu]]], {i, 3}];
  add["photon Ward identity k3_nu P_i^{mu nu} = 0", And @@ (zeroQ /@ ward)];

  add["AFPutDelta leaves the expression unchanged", zeroQ[AFPutDelta[inv[[2, 2]]] - inv[[2, 2]]]];

  And @@ res
];
