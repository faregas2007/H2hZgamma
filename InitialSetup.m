(* ::Package:: *)

SetDirectory["C:\\Users\\fareg\\Downloads\\hzgamma\\HtohZgammadiagram"]
If[$FrontEnd==Null, $FeynCalcStartupMessages=False;
	Print[description];];
If[$Notebooks == False, $FeynCalcStartupMessages = False];
$LoadFeynArts = True;
$LoadAddOns={"FeynHelpers"};
<<FeynCalc`;
$FAVerbose=0;


(* Convention Notations *)
ConventionNotation = {CAB-> Cos[\[Alpha] + \[Beta]], CBA-> Cos[\[Beta]-\[Alpha]], SAB-> Sin[\[Alpha] + \[Beta]], SBA-> Sin[\[Beta]-\[Alpha]], S2B-> Sin[2 \[Beta]], C2B->Cos[2 \[Beta]], S2A-> Sin[2 \[Alpha]], C2A->Cos[2 \[Alpha]], Mh0-> Subscript[m, h], MHH->Subscript[m, H], MHp->Subscript[m, Hp], Lambda5 -> Subscript[\[Lambda], 5]};



(* 
	odd number of loop momenta integral vanishes 
  and (_, l)(_, l) -> l^2 (_, _)/D
*)
external = {Momentum[k1, D], Momentum[k2, D], Momentum[k3, D]};
loop = Momentum[l, D];
squareloopterms = Flatten[Table[Pair[external[[i]],loop] Pair[external[[j]],loop]->Pair[loop,loop] Pair[external[[i]],external[[j]]]/D,{i,1,Length@external}, {j,1, Length@external}]];
looplineardependences1 =Flatten[Table[Pair[external[[i]],loop] Pair[external[[j]],external[[k]]]->0,{i,1,Length@external},{j,1,Length@external},{k,1,Length@external}]] 
looplineardependences2 =Flatten[Table[Pair[external[[i]],loop]->0,{i,1,Length@external}]]
looplineardependences = Join[looplineardependences1, looplineardependences2] ;


(* Kinematics *)
Kinematics = {
Pair[Momentum[k1 + k3, D], Momentum[k1 + k3, D]] -> Subscript[q, 13],Pair[Momentum[k2 + k3, D], Momentum[k2 + k3, D]] -> Subscript[q, 23],Pair[Momentum[k1 + k2, D], Momentum[k1 + k2, D]] -> Subscript[q, 12], Pair[Momentum[k1, D], Momentum[k1, D]] -> Subscript[m, Z]^2,
Pair[Momentum[k2,D], Momentum[k2, D]] -> 0, Pair[Momentum[k3, D], Momentum[k3, D]] -> Subscript[m, h0]^2, 
Pair[Momentum[k1, D], Momentum[k2, D]]-> (Subscript[q, 12] - Subscript[m, Z]^2)/2,
Pair[Momentum[k1, D], Momentum[k3, D]]-> (Subscript[q, 13] -  Subscript[m, h0]^2)/2,
Pair[Momentum[k2, D], Momentum[k3, D]]-> (Subscript[q, 23] - Subscript[m, h0]^2 - Subscript[m, Z]^2)/2
};
InvariantKinematics = { 
Subscript[q, 13]  + Subscript[q, 23] +Subscript[q, 12]-> Subscript[m , h0]^2 + Subscript[m, Z]^2 + Subscript[m, H0]^2
};
Kinematics2 = {
Pair[Momentum[k1, D], Momentum[k1, D]]-> Subscript[m, h0]^2,
Pair[Momentum[k2, D], Momentum[k2, D]]-> Subscript[m, Z]^2,
Pair[Momentum[k3, D], Momentum[k3, D]]-> 0
};
Kinematics3 = {
Pair[Momentum[k1, D], Momentum[k2, D]]-> (q12 - Subscript[m, Z]^2 - Subscript[m, h0]^2)/2,
Pair[Momentum[k1, D], Momentum[k3, D]] -> (q13 - Subscript[m, h0]^2)/2,
Pair[Momentum[k2, D], Momentum[k3, D]]-> (q23 - Subscript[m, Z]^2)/2
};
Kinematics4 = {
q12 + q23 + q13-> Subscript[m, h0]^2 + Subscript[m, Z]^2 + Subscript[m, H0]^2
};



(* Projections *)
P1[\[Mu]_,\[Nu]_] = -Pair[Momentum[k3, D], Momentum[k1, D]] MTD[\[Mu],\[Nu]] + Pair[Momentum[k1, D], LorentzIndex[\[Mu], D]] Pair[ Momentum[k3, D], LorentzIndex[\[Nu], D]];
P2[\[Mu]_,\[Nu]_] = - MTD[\[Mu],\[Nu]] Pair[Momentum[k3, D], Momentum[k2, D]] +Pair[Momentum[k3, D], LorentzIndex[\[Mu], D]] Pair[Momentum[k2,D], LorentzIndex[\[Nu], D]];
P3[\[Mu]_,\[Nu]_] = (Pair[Momentum[k3, D], Momentum[k1, D]]/Pair[Momentum[k3, D], Momentum[k2, D]]) Pair[Momentum[k1,  D], LorentzIndex[\[Mu], D]] Pair[Momentum[k2,D], LorentzIndex[\[Nu], D]]  +  Pair[Momentum[k1,  D], LorentzIndex[\[Mu], D]] Pair[Momentum[k1,D], LorentzIndex[\[Nu], D]] ;



TriangleList = Range[80];
BoxesList = Range[81, 256];
TwoPoints = Range[257, 266];


(* Create diagrams *)
tt = CreateTopologies[1, 1->3,  ExcludeTopologies->{ Tadpoles, Internal}];
diagrams = InsertFields[tt, {S[2]}-> {{S[1]}, {V[2]}, {V[1]}}, InsertionLevel-> {Particles}, Model->"THDM", Restrictions->{NoGeneration1, NoGeneration2, NoElectronHCoupling, NoLightFHCoupling}, ExcludeParticles->{V[5], F[1], F[2], -F[1], -F[2]}];


(* Self/2 points diagrams *)
TwoPointsDiagrams = DiagramExtract[diagrams, TwoPoints];
(* Hp loops *)
SelfH = DiagramExtract[TwoPointsDiagrams, {1}];
(* Mixed W/G/u *)
selfGWu = DiagramExtract[TwoPointsDiagrams, {2,5,6,9,10}];
(* Mixed H/G/W/u *)
selfHGWu = DiagramExtract[TwoPointsDiagrams, {3,4,7,8}];


(* Triangles *)
trianglewithoutW = DiagramSelect[DiagramExtract[diagrams, TriangleList], FreeQ[LoopFields[##],  V[3]]&];
trianglewithH = DiagramSelect[DiagramExtract[diagrams, TriangleList],
!FreeQ[LoopFields[##], S[5]]&];

(* Hp loops *)
triangleH = DiagramSelect[trianglewithoutW, FreeQ[LoopFields[##], S[6]]&];
(* Mixed W/G/u *)
triangleGWu = DiagramSelect[DiagramExtract[diagrams, TriangleList], FreeQ[LoopFields[##],  S[5]]&];
(* Mixed H/G/W/u *)
triangleHGWu = DiagramComplement[trianglewithH, triangleH];


(* Boxes *)
BoxesDiagrams = DiagramExtract[diagrams, BoxesList];
BoxesWithH = DiagramSelect[BoxesDiagrams,
!FreeQ[LoopFields[##], S[5]]&];

(* Fermion Loop *)
BoxesWithFermion =  DiagramSelect[BoxesDiagrams,
!FreeQ[LoopFields[##], F[3, {3, _}]]&];

BoxesWithoutW =  DiagramSelect[BoxesDiagrams,
FreeQ[LoopFields[##], V[3]]&];

BoxesWithoutWG = DiagramSelect[BoxesWithoutW, FreeQ[LoopFields[##],  S[6]]&];
BoxesWithoutWGt = DiagramComplement[BoxesWithoutWG, BoxesWithFermion];
BoxesWithoutWGtu = DiagramSelect[BoxesWithoutWGt, FreeQ[LoopFields[##], U[_]]&];
BoxesWithoutH= DiagramComplement[BoxesDiagrams, BoxesWithH];

(* Hp loop *)
BoxesH = BoxesWithoutWGtu;
(* Mixed W/G/u *)
BoxesGWu = DiagramComplement[BoxesDiagrams,  BoxesWithH, BoxesWithFermion];
(* Mixed H/G/W/u *)
BoxesHGWu = DiagramComplement[BoxesWithH, BoxesH];


(* Position to rollback model file couplings *)
ListCouplings = {53, 57, 45, 178, 67, 68, 107}
Subscript[g, hHH]
Subscript[g, H0HH]
Subscript[g, hH0H0]
Subscript[g, HoldForm[HHZ\[Gamma] ]]
Subscript[g, HoldForm[H H \[Gamma]]]
Subscript[g, HoldForm[H H Z]]
Subscript[g, HoldForm[H H H0 h0]]
