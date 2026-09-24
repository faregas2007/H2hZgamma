(* ::Package:: *)

Clear[P1, P2, P3, variables, variables2, PG, PZ]


variables = {
Pair[Momentum[k3, D], Momentum[k1, D]]-> a,
Pair[Momentum[k3, D], Momentum[k2, D]]-> b,
Pair[Momentum[k1, D], Momentum[k2, D]]-> c,
Pair[Momentum[k1, D], Momentum[k1, D]]-> x,
Pair[Momentum[k2, D], Momentum[k2, D]]-> y,
Pair[Momentum[k3, D], Momentum[k3, D]]-> 0
};

variables2 = {
Subscript[m, h]-> Sqrt[x],
Subscript[m, Z]-> Sqrt[y],
a^2 y - 2 a b c + b^2 x -> \[CapitalDelta],
a^2(-y) + 2 a b c - b^2 x -> - \[CapitalDelta],
a^2 (D-2)y - 2 a b c (D-2) + b^2 (D-2)x-> (D-2)\[CapitalDelta],
-a^2 (D-2)y + 2 a b c (D-2) - b^2 (D-2)x-> -(D-2)\[CapitalDelta]
};


P2[\[Mu]_,\[Nu]_]:= - a MTD[\[Mu],\[Nu]] + Pair[Momentum[k3, D], LorentzIndex[\[Mu],D]]Pair[Momentum[k1, D], LorentzIndex[\[Nu],D]];
P1[\[Mu]_,\[Nu]_]:= - b MTD[\[Mu],\[Nu]] + Pair[Momentum[k3, D], LorentzIndex[\[Mu],D]]Pair[Momentum[k2, D], LorentzIndex[\[Nu],D]];
P3[\[Mu]_,\[Nu]_]:= - a Pair[Momentum[k1, D], LorentzIndex[\[Mu],D]]Pair[Momentum[k2, D], LorentzIndex[\[Nu],D]]  + b  Pair[Momentum[k1, D], LorentzIndex[\[Mu],D]]Pair[Momentum[k1, D], LorentzIndex[\[Nu],D]];

PList[\[Mu]_,\[Nu]_] := {P1[\[Mu],\[Nu]], P2[\[Mu],\[Nu]], P3[\[Mu],\[Nu]]};

PG[\[Mu]_,\[Nu]_]:= -MTD[\[Mu],\[Nu]];
PZ[\[Mu]_,\[Nu]_] := -MTD[\[Mu],\[Nu]] + Pair[Momentum[k2, D], LorentzIndex[\[Mu],D]]Pair[Momentum[k2, D], LorentzIndex[\[Nu],D]]/y;


Gij[i_, j_] := PList[\[Rho],\[Sigma]][[i]] PZ[\[Mu],\[Rho]]PG[\[Nu],\[Sigma]]PList[\[Mu],\[Nu]][[j]]//Contract;
Gphys = ((Table[Gij[i,j], {i,3}, {j,3}]/.variables//FullSimplify)/.variables2/.{a^2(D-3) y + 2 a b c - b^2 x-> a^2 (D-2) y - \[CapitalDelta]}//Simplify)/.{-a^2 (D-2) y + 2 a b c (D-2) - b^2 (D-2) x -> -(D-2)\[CapitalDelta]}//Simplify


inverseG =(Inverse[GphysD/.variables2/.{a^2 (D-3)y -> -a^2 y + a^2(D-2)y}/.variables2]//Simplify)/.{a^2 (D-2)y - 2 a b c (D-2) + b^2 (D-2)x-> (D-2)\[CapitalDelta]}//FullSimplify


(* Checking inverseG.G = I *)
(Gphys . inverseG//Simplify)/.{-a^2 (D-2) y + 2 a b c (D-2) - b^2 (D-2) x -> -(D-2)\[CapitalDelta], a^2 (D-2) y - 2 a b c (D-2) + b^2 (D-2) x -> (D-2)\[CapitalDelta]}//Simplify


pvec[\[Mu]_,\[Nu]_, m_] := (PList[\[Rho], \[Sigma]][[m]] PZ[\[Mu],\[Rho]] PG[\[Nu], \[Sigma]]//Contract)/.variables//Simplify
\[CapitalPi]vec[\[Mu]_,\[Nu]_]:= Table[Bvec[\[Mu],\[Nu], i], {i,3}]


(* Dual projector *)
Proj[\[Mu]_,\[Nu]_] := inverseG . bvec[\[Mu],\[Nu]]


(* Sanity check if Proj amp_i = F_i *)
amp[\[Mu]_,\[Nu]_] := P1[\[Mu],\[Nu]] F1 + P2[\[Mu],\[Nu]]F2 + P3[\[Mu],\[Nu]]F3
(((Proj[\[Mu],\[Nu]]amp[\[Mu],\[Nu]]//Contract)/.variables/.variables2//FullSimplify)/.variables2//FullSimplify)/.variables2


(* Checking CP-odd and CP-even othorgonal to each other *)
Podd[\[Mu],\[Nu]]:= LeviCivita[\[Mu],\[Nu],\[Rho],\[Sigma]] Pair[Momentum[k1, D], LorentzIndex[\[Rho], D]] Pair[Momentum[k2, D], LorentzIndex[\[Sigma], D]]
ChangeDimension[Podd[\[Mu],\[Nu]], D] Proj[\[Mu],\[Nu]]//Contract
