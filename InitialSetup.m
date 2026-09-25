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
ConventionNotation = {EL-> e, CW->Cos[Subscript[\[Theta], W]], SW->Sin[Subscript[\[Theta], W]], MW-> Subscript[m, W] ,
CAB-> Cos[\[Alpha] + \[Beta]], CBA-> Cos[\[Beta]-\[Alpha]], SAB-> Sin[\[Alpha] + \[Beta]], 
SBA-> Sin[\[Beta]-\[Alpha]], S2B-> Sin[2 \[Beta]], 
C2B->Cos[2 \[Beta]], S2A-> Sin[2 \[Alpha]], 
C2A->Cos[2 \[Alpha]], Mh0-> Subscript[m, h], 
MHH->Subscript[m, H], MHp->Subscript[m, Hp], 
Lambda5 -> Subscript[\[Lambda], 5]};


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
Pair[Momentum[k1,D], Momentum[k1, D]] -> Subscript[m, h0], Pair[Momentum[k3, D], Momentum[k3, D]] -> 0, 
Pair[Momentum[k2, D], Momentum[k2, D]]-> Subscript[m, Z],
Pair[Momentum[k1, D], Momentum[k2, D]]-> (Subscript[q, 12] - Subscript[m, h0]^2 - Subscript[m, Z]^2)/2,
Pair[Momentum[k1, D], Momentum[k3, D]]-> (Subscript[q, 13] -  Subscript[m, h0]^2)/2,
Pair[Momentum[k2, D], Momentum[k3, D]]-> (Subscript[q, 23] - Subscript[m, Z]^2)/2
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



(* Non-orthogonal Projections *)
P1[\[Mu]_,\[Nu]_] = -Pair[Momentum[k3, D], Momentum[k1, D]] MTD[\[Mu],\[Nu]] + Pair[Momentum[k1, D], LorentzIndex[\[Mu], D]] Pair[ Momentum[k3, D], LorentzIndex[\[Nu], D]];
P2[\[Mu]_,\[Nu]_] = - MTD[\[Mu],\[Nu]] Pair[Momentum[k3, D], Momentum[k2, D]] +Pair[Momentum[k3, D], LorentzIndex[\[Mu], D]] Pair[Momentum[k2,D], LorentzIndex[\[Nu], D]];
P3[\[Mu]_,\[Nu]_] = (Pair[Momentum[k3, D], Momentum[k1, D]]/Pair[Momentum[k3, D], Momentum[k2, D]]) Pair[Momentum[k1,  D], LorentzIndex[\[Mu], D]] Pair[Momentum[k2,D], LorentzIndex[\[Nu], D]]  +  Pair[Momentum[k1,  D], LorentzIndex[\[Mu], D]] Pair[Momentum[k1,D], LorentzIndex[\[Nu], D]] ;



TriangleList = Range[80];
BoxesList = Range[81, 256];
TwoPoints = Range[257, 266];


(* Create diagrams *)
model = "THDM2";
tt = CreateTopologies[1, 1->3,  ExcludeTopologies->{ Tadpoles, Internal}];
diagrams = InsertFields[tt, {S[2]}-> {{S[1]}, {V[2]}, {V[1]}}, InsertionLevel-> {Particles}, Model->model, Restrictions->{NoGeneration1, NoGeneration2, NoElectronHCoupling, NoLightFHCoupling}, ExcludeParticles->{V[5], F[1], F[2], -F[1], -F[2]}];


(* Fixing UTF-8 Broken Font in Model file*)
plainGreekRules={(*Lowercase Greek*)\[CapitalIHat]\.b2->\[Beta],\[CapitalIHat]\.b3->\[Gamma],\[CapitalIHat]\.b3->\[Gamma],\[CapitalIHat]\.b4->\[Delta],\[CapitalIHat]\[Micro]->\[Epsilon],\[CapitalIHat]\[Paragraph]->\[Zeta],\[CapitalIHat]\.b9->\[Iota],\[CapitalIHat]\.ba->\[Kappa],\[CapitalIHat]\[RightGuillemet]->\[Lambda],\[CapitalIHat]\.bc->\[Mu],\[CapitalIHat]\.bd->\[Nu],\[CapitalIHat]\.be->\[Xi],\[CapitalIHat]\[DownQuestion]->\[Omicron](*Safeguard for\[PlusMinus]/operator variants*)};
If[model=="THDM",
M$CouplingMatrices = M$CouplingMatrices/.plainGreekRules
];


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
ListCouplings = {44, 53, 57, 45, 178, 67, 68, 107}
Subscript[g, hhH0]
Subscript[g, hHH]
Subscript[g, H0HH]
Subscript[g, hH0H0]
Subscript[g, HoldForm[HHZ\[Gamma] ]]
Subscript[g, HoldForm[H H \[Gamma]]]
Subscript[g, HoldForm[H H Z]]
Subscript[g, HoldForm[H H H0 h0]]











(* Reducible diagrams *)
tt2 = CreateTopologies[1, 1->3,  ExcludeTopologies->{SelfEnergies , Tadpoles, Irreducible}];
tt3 =TopologyList[tt2[[1]], tt2[[2]], tt2[[4]], tt2[[7]], tt2[[8]],tt2[[9]], tt2[[10]], tt2[[12]], tt2[[14]], tt2[[16]], tt2[[18]]];
tt4 = CreateVFTopologies[1, 1->3, ExcludeTopologies->{SelfEnergies, Tadpoles}];
genericTopologies = TopologyList[tt4[[1;;4]]];

diags = InsertFields[tt4, {S[2]}-> {{S[1]}, {V[2]}, {V[1]}}, InsertionLevel-> {Particles}, Model->model, Restrictions->{NoGeneration1, NoGeneration2, NoElectronHCoupling, NoLightFHCoupling}, ExcludeParticles->{V[5], F[1], F[2], -F[1], -F[2]}];


(* contributed topologies *)
Paint[DiagramExtract[diags, {1,2,3,4,5,6,7,8,9}], Numbering->Simple, SheetHeader->None]



TriangleReduced = Range[1,100];
SelfReduced = Range[101, 123];
WFDiagrams =InsertFields[tt3, {S[2]}-> {{S[1]}, {V[2]}, {V[1]}}, InsertionLevel-> {Particles}, Model->model, Restrictions->{NoGeneration1, NoGeneration2, NoElectronHCoupling, NoLightFHCoupling}, ExcludeParticles->{V[5], F[1], F[2], -F[1], -F[2]}];


(* Reducible self *)
WFSelfHDiagrams = DiagramExtract[WFDiagrams, SelfReduced];

WFSelfWithH = DiagramSelect[WFSelfHDiagrams, !FreeQ[LoopFields[##], S[5]]&];
(* charged Higgs *)
WFSelfH = DiagramExtract[WFSelfWithH, {1,2,5}];
(* Mixed Higgs/W *)
WFSelfHWu = DiagramComplement[WFSelfWithH, WFSelfH];
(*  Vector boson/Goldstone/u *)
WFSelfGWu = DiagramComplement[WFSelfHDiagrams, WFSelfWithH];


(* Reducible triangles *)
WFTriangleDiagrams = DiagramExtract[WFDiagrams, TriangleReduced];
(* Reducible fermion *)
WFTriangleWithFermion = DiagramSelect[WFTriangleDiagrams, !FreeQ[LoopFields[##], F[3, {3, _}]]&];
WFTriangleWithH = DiagramSelect[WFTriangleDiagrams, !FreeQ[LoopFields[##], S[5]]&];
(*Charged Higgs *)
WFTriangleH = DiagramExtract[WFTriangleWithH, {1,2,3,4,17,18}];
(* Mixed Higgs/W/G*)
WFTriangleHGWu = DiagramComplement[WFTriangleWithH, WFTriangleH];
(* Vector boson/G/u *)
WFTriangleGWu = DiagramComplement[WFTriangleDiagrams, WFTriangleWithH, WFTriangleWithFermion];


RollbackCouplings = \!\(TraditionalForm\`{\*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "\[Gamma]"}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(FCGV \(("\<EL\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(FCGV \(("\<EL\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", "\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "\[Gamma]", " ", "W"}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", "Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\), \(FCGV \(("\<CW\>")\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "Z", " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\), \(FCGV \(("\<CW\>")\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}], " ", "W"}],
HoldForm]] -> \(-I\)\ \(FCGV("\<EL\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}], " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<EL\>")\)\)\), \(FCGV \(("\<SW\>")\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(\(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["u", "\"\<+\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(\(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
SubscriptBox["u", "\[Gamma]"], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], ")"}]}],
HoldForm]] -> \(-I\)\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", 
SubscriptBox["u", "\[Gamma]"], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], ")"}]}],
HoldForm]] -> \(-I\)\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
SubscriptBox["u", "Z"], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\ \((
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)])\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", 
SubscriptBox["u", "Z"], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\ \((
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)])\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
SubscriptBox["u", "\"\<+\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "Z"]}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(Z\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "Z"]}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(Z\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", "\[Gamma]"}],
HoldForm]] -> \(-I\)\ \(FCGV("\<EL\>")\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], " ", 
SubscriptBox["u", "\"\<+\>\""], " ", "\[Gamma]"}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", "Z"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<EL\>")\)\)\), \(FCGV \(("\<SW\>")\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], " ", 
SubscriptBox["u", "\"\<+\>\""], " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<EL\>")\)\)\), \(FCGV \(("\<SW\>")\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], " ", 
SubscriptBox["u", "\[Gamma]"], " ", "W"}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], " ", 
SubscriptBox["u", "\[Gamma]"], " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-I\)\ \(FCGV("\<EL\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\[Gamma]"]}], " ", 
SubscriptBox["u", "\"\<+\>\""], " ", "W"}],
HoldForm]] -> \(-I\)\ \(FCGV("\<EL\>")\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\[Gamma]"]}], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], " ", 
SubscriptBox["u", "Z"], " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<EL\>")\)\)\), \(FCGV \(("\<SW\>")\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], " ", 
SubscriptBox["u", "Z"], " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<EL\>")\)\)\), \(FCGV \(("\<SW\>")\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "Z"]}], " ", 
SubscriptBox["u", "\"\<+\>\""], " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<EL\>")\)\)\), \(FCGV \(("\<SW\>")\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
SubscriptBox["u", "Z"]}], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<EL\>")\)\)\), \(FCGV \(("\<SW\>")\)\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "\[Gamma]", " ", "\[Gamma]"}],
HoldForm]] -> 2\ I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "\[Gamma]", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\)\), \(\(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ 
\*SuperscriptBox[\((
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"\[Gamma]", " ", "\[Gamma]", " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{"\[Gamma]", " ", "Z", " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \(FCGV \(("\<CW\>")\)\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(FCGV \(("\<SW\>")\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"Z", " ", "Z", " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]], \*
SubscriptBox["g", 
TagBox[
RowBox[{"W", " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(3\ I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*SuperscriptBox[\(Mh0\), \(2\)]\ \((2\ CAB + S2A\ SBA)\) - 
\*FractionBox[\(4\ CAB\ 
\*SuperscriptBox[\(CBA\), \(2\)]\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(2\ S2B\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \(FCGV \(("\<EL\>")\)\)\ \((\((2\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A - 
\*FractionBox[\(2\ Lambda5\ \((3\ S2A - S2B)\)\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(2\ S2B\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ \(FCGV \(("\<EL\>")\)\)\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] + 2\ 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A - 
\*FractionBox[\(2\ Lambda5\ \((3\ S2A + S2B)\)\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(2\ S2B\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(3\ I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2A)\) - 
\*FractionBox[\(4\ Lambda5\ SAB\ 
\*SuperscriptBox[\(SBA\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(2\ S2B\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*FractionBox[\(CAB\ \((2\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(S2B\)] - \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 2\ 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ SBA)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*SuperscriptBox[\(Mh0\), \(2\)])\)\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ 
\*SuperscriptBox[\(Mh0\), \(2\)]\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*FractionBox[\(SAB\ \((2\ 
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(S2B\)] - CBA\ \((
\*SuperscriptBox[\(MHH\), \(2\)] - 2\ 
\*SuperscriptBox[\(MA0\), \(2\)])\))\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \((
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(MHH\), \(2\)]\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*FractionBox[\(CAB\ \((2\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(S2B\)] - \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 2\ 
\*SuperscriptBox[\(MHp\), \(2\)])\)\ SBA)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHp\), \(2\)])\)\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHp\), \(2\)])\)\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ 
\*SuperscriptBox[\(Mh0\), \(2\)]\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*FractionBox[\(SAB\ \((2\ 
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(S2B\)] - CBA\ \((
\*SuperscriptBox[\(MHH\), \(2\)] - 2\ 
\*SuperscriptBox[\(MHp\), \(2\)])\))\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \((
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*SuperscriptBox[\(MHp\), \(2\)])\)\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ \((
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*SuperscriptBox[\(MHp\), \(2\)])\)\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(MHH\), \(2\)]\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(\((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(\((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"], " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(CBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["G", "0"], " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["A", "0"], " ", "Z"}],
HoldForm]] -> \(-
\*FractionBox[\(SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["G", "0"], " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(CBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "\[Gamma]"}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \((
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ \(FCGV \(("\<EL\>")\)\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(FCGV \(("\<EL\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(FCGV \(("\<EL\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<MW\>")\)\)\), \(
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<MW\>")\)\)\), \(
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<MW\>")\)\)\), \(FCGV \(("\<SW\>")\)\)], \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<MW\>")\)\)\), \(FCGV \(("\<SW\>")\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["u", "Z"], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "Z"]}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(Z\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["u", "Z"], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "Z"]}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(Z\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["u", "\"\<-\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<-\>\""]}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["u", "\"\<+\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["u", "\"\<+\>\""], " ", 
RowBox[{"(", 
RowBox[{"-", 
SubscriptBox["u", "\"\<+\>\""]}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \(TraditionalForm\`
\*SubscriptBox[\("\<xi\>"\), \(W\)]\)\ \(FCGV("\<EL\>")\)\ \(FCGV("\<MW\>")\)\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(3\ I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(S2A\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\((2\ CAB + S2A\ SBA)\), \(2\)] - 
\*FractionBox[\(2\ 
\*SuperscriptBox[\((C2A + C2B)\), \(2\)]\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(3\ I\ CBA\ S2A\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A\ SBA + CAB\ \((2\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\)\), \(4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((3\ 
\*SuperscriptBox[\(S2A\), \(2\)]\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)] - 
\*FractionBox[\(2\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\) - S2B\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A - 
\*FractionBox[\(2\ Lambda5\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> 
\*FractionBox[\(3\ I\ S2A\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A + SAB\ \((2\ 
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\)\), \(4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(3\ I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\((2\ SAB - CBA\ S2A)\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\(S2A\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)] - 
\*FractionBox[\(2\ 
\*SuperscriptBox[\((C2A - C2B)\), \(2\)]\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\), \(4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((2\ CAB + S2A\ SBA)\)\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 2\ 
\*SuperscriptBox[\(MA0\), \(2\)]\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)] - 
\*FractionBox[\(4\ \((
\*SuperscriptBox[\(CAB\), \(2\)] + 
\*SuperscriptBox[\(C2B\), \(2\)]\ 
\*SuperscriptBox[\(CBA\), \(2\)])\)\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + CBA\ 
\*SuperscriptBox[\(MHH\), \(2\)]\ S2A\ \((2\ SAB - CBA\ S2B)\))\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A\ SBA - S2B\ \((2\ 
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\ SBA + CAB\ \((2\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*SuperscriptBox[\(Mh0\), \(2\)])\)\ S2A\ 
\*SuperscriptBox[\(CBA\), \(2\)] + S2B\ \((2\ 
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\ 
\*SuperscriptBox[\(CBA\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ S2B)\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ S2A\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ S2A\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ S2A\ \((2\ SAB - CBA\ S2B)\)\ SBA + CBA\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ SBA\ \((2\ 
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \n\*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\(-S2B\)\ \((
\*SuperscriptBox[\(CBA\), \(2\)] - 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(MA0\), \(2\)] + 
\*FractionBox[\(4\ C2B\ CBA\ Lambda5\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + S2A\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A - S2B\ \((2\ 
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\)\), \(4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\(-S2A\)\ SBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 2\ 
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(MA0\), \(2\)]\ 
\*SuperscriptBox[\(S2B\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ \((
\*SuperscriptBox[\(SAB\), \(2\)] + 
\*SuperscriptBox[\(C2B\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2A)\)\ \((2\ SAB - CBA\ S2B)\))\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \((I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A - CBA\ S2B\ \((2\ 
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\) + SAB\ \((2\ 
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((S2B\ 
\*SuperscriptBox[\(MHH\), \(2\)] + \((
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*SuperscriptBox[\(Mh0\), \(2\)])\)\ S2A\ 
\*SuperscriptBox[\(SBA\), \(2\)] + S2B\ 
\*SuperscriptBox[\(SBA\), \(2\)]\ \((2\ 
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "H", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((2\ CAB + S2A\ SBA)\)\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 2\ 
\*SuperscriptBox[\(MHp\), \(2\)]\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)] - 
\*FractionBox[\(4\ \((
\*SuperscriptBox[\(CAB\), \(2\)] + 
\*SuperscriptBox[\(C2B\), \(2\)]\ 
\*SuperscriptBox[\(CBA\), \(2\)])\)\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + CBA\ 
\*SuperscriptBox[\(MHH\), \(2\)]\ S2A\ \((2\ SAB - CBA\ S2B)\))\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "H", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A\ SBA - S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\ SBA + CAB\ \((2\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A\ SBA - S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\ SBA + CAB\ \((2\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "G", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*SuperscriptBox[\(Mh0\), \(2\)])\)\ S2A\ 
\*SuperscriptBox[\(CBA\), \(2\)] + S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\)\ 
\*SuperscriptBox[\(CBA\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ S2B)\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "H", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ S2A\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ S2A\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ S2A\ \((2\ SAB - CBA\ S2B)\)\ SBA + CBA\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ SBA\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\(-S2B\)\ \((
\*SuperscriptBox[\(CBA\), \(2\)] - 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(MHp\), \(2\)] + 
\*FractionBox[\(4\ C2B\ CBA\ Lambda5\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + S2A\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\(-S2B\)\ \((
\*SuperscriptBox[\(CBA\), \(2\)] - 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(MHp\), \(2\)] + 
\*FractionBox[\(4\ C2B\ CBA\ Lambda5\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + S2A\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "G", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A - S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\)\), \(4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "H", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\(-S2A\)\ SBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 2\ 
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(MHp\), \(2\)]\ 
\*SuperscriptBox[\(S2B\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ \((
\*SuperscriptBox[\(SAB\), \(2\)] + 
\*SuperscriptBox[\(C2B\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2A)\)\ \((2\ SAB - CBA\ S2B)\))\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \((I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A + SAB\ \((2\ 
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\) - CBA\ S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \((I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ S2A + SAB\ \((2\ 
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\) - CBA\ S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "G", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((S2B\ 
\*SuperscriptBox[\(MHH\), \(2\)] + \((
\*SuperscriptBox[\(MHH\), \(2\)] - 
\*SuperscriptBox[\(Mh0\), \(2\)])\)\ S2A\ 
\*SuperscriptBox[\(SBA\), \(2\)] + S2B\ 
\*SuperscriptBox[\(SBA\), \(2\)]\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "H", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(\((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> 
\*FractionBox[\(\((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "H", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> 
\*FractionBox[\(CBA\ \((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["h", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(CBA\ \((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "H", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(CBA\ \((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> 
\*FractionBox[\(CBA\ \((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(\((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["H", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> 
\*FractionBox[\(\((
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*SuperscriptBox[\(MA0\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((3\ I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\((2\ SAB - CBA\ S2B)\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\((2\ CAB - S2B\ SBA)\), \(2\)] - 
\*FractionBox[\(8\ 
\*SuperscriptBox[\(C2B\), \(2\)]\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-\((\((3\ I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\)\ SBA)\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((3\ 
\*SuperscriptBox[\(CBA\), \(2\)]\ S2B - S2A)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((3\ S2B\ 
\*SuperscriptBox[\(SBA\), \(2\)] + S2A)\))\)\), \(4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(3\ I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(3\ I\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(MHH\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "H", " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\((2\ SAB - CBA\ S2B)\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\((2\ CAB - S2B\ SBA)\), \(2\)] - 
\*FractionBox[\(8\ 
\*SuperscriptBox[\(C2B\), \(2\)]\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\)/\((4\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "H", " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\)\ SBA)\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\)\ SBA)\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "G", " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((SBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + CBA\ 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\) + S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "H", " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\)\ SBA)\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHp\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHp\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
SubscriptBox["A", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "H", " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((SBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + CBA\ 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\) + S2B\ \((2\ 
\*SuperscriptBox[\(MHp\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "H", " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "G", " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "G", " ", 
SubscriptBox["G", "0"], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(MHH\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(4\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "H"}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\((2\ SAB - CBA\ S2B)\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\((2\ CAB - S2B\ SBA)\), \(2\)] - 
\*FractionBox[\(8\ 
\*SuperscriptBox[\(C2B\), \(2\)]\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\)/\((2\ 
\*SuperscriptBox[\(S2B\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\)\ SBA)\))\)/\((2\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", "H", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \((\(-
\*SuperscriptBox[\(MA0\), \(2\)]\) + 
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((CBA\ \((2\ CAB - S2B\ SBA)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*FractionBox[\(4\ C2B\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]] - 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ SAB - CBA\ S2B)\)\ SBA)\))\)/\((2\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "G", " ", "H"}],
HoldForm]] -> \(-\((\((I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((\((2\ 
\*SuperscriptBox[\(CBA\), \(2\)]\ S2B - S2A)\)\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ \((2\ S2B\ 
\*SuperscriptBox[\(SBA\), \(2\)] + S2A)\) + S2B\ \((
\*SuperscriptBox[\(MA0\), \(2\)] - 
\*FractionBox[\(4\ Lambda5\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\), 
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]])\))\))\)/\((4\ S2B\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\))\)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "G", " ", "H"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "H"}], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "G", " ", "G"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \((\(-
\*SuperscriptBox[\(MA0\), \(2\)]\) + 
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(Mh0\), \(2\)] + 
\*SuperscriptBox[\(MHH\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"G", " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ \((
\*SuperscriptBox[\(Mh0\), \(2\)] - 
\*SuperscriptBox[\(MHH\), \(2\)])\)\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", "G"}], " ", "G", " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "G"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \((
\*SuperscriptBox[\(CBA\), \(2\)]\ 
\*SuperscriptBox[\(MHH\), \(2\)] + 
\*SuperscriptBox[\(Mh0\), \(2\)]\ 
\*SuperscriptBox[\(SBA\), \(2\)])\)\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<MW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "H", " ", "\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "H", " ", "Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "G", " ", "\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", "G", " ", "Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "\[Gamma]", " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "Z", " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "\[Gamma]", " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["h", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "Z", " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
SubscriptBox["H", "0"], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "H", " ", "\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "H", " ", "Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "G", " ", "\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", "G", " ", "Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "\[Gamma]", " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "Z", " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ SBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "\[Gamma]", " ", "W"}],
HoldForm]] -> 
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["H", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "Z", " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ CBA\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
SubscriptBox["A", "0"], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", "H", " ", "\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", "H", " ", "Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<CW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "\[Gamma]", " ", "W"}],
HoldForm]] -> 
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["A", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "Z", " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", "G", " ", "\[Gamma]", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", "G", " ", "Z", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<CW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "\[Gamma]", " ", "W"}],
HoldForm]] -> 
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
SubscriptBox["G", "0"], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}], " ", "Z", " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[
SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \(2\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "\[Gamma]", " ", "\[Gamma]"}],
HoldForm]] -> 2\ I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "\[Gamma]", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ \((
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\)\), \(\(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "Z", " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\ 
\*SuperscriptBox[\((
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)] - 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)])\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<CW\>")\)\), \(2\)]\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{"H", " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}], " ", "W", " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ 
\*SuperscriptBox[\(FCGV \(("\<EL\>")\)\), \(2\)]\), \(2\ 
\*SuperscriptBox[\(FCGV \(("\<SW\>")\)\), \(2\)]\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ Yuk1\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ 
\*SubscriptBox[\(C\), \(A\)]\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((3, {j1, o1})\))\)\)\), \(2\ SB\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["h", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ Yuk1\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((4, {j1, o1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> 
\*FractionBox[\(\(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(\(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((3, {j1, o1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["G", "0"]}],
HoldForm]] -> 
\*FractionBox[\(\(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((4, {j1, o1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", "\[Gamma]"}],
HoldForm]] -> I\ \(FCGV("\<EL\>")\)\ \(IndexDelta(j1, j2)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o1"}], "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o2"}], "}"}]}], ")"}], " ", "\[Gamma]"}],
HoldForm]] -> \(-
\*FractionBox[\(2\), \(3\)]\)\ I\ \(FCGV("\<EL\>")\)\ \(IndexDelta(j1, j2)\)\ \(IndexDelta(o1, o2)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o1"}], "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o2"}], "}"}]}], ")"}], " ", "\[Gamma]"}],
HoldForm]] -> 
\*FractionBox[\(1\), \(3\)]\ I\ \(FCGV("\<EL\>")\)\ \(IndexDelta(j1, j2)\)\ \(IndexDelta(o1, o2)\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", "Z"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\), \(2\ \(FCGV \(("\<CW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", "Z"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\), \(FCGV \(("\<CW\>")\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o1"}], "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o2"}], "}"}]}], ")"}], " ", "Z"}],
HoldForm]] -> 
\*FractionBox[\(2\ I\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\), \(3\ \(FCGV \(("\<CW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o1"}], "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o2"}], "}"}]}], ")"}], " ", "Z"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\), \(3\ \(FCGV \(("\<CW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ Yuk2\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ SA\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((3, {j1, o1})\))\)\)\), \(2\ SB\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["H", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ Yuk2\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((4, {j1, o1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(Yuk3\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(\(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((3, {j1, o1})\))\)\)\), \(2\ TB\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
SubscriptBox["A", "0"]}],
HoldForm]] -> \(-
\*FractionBox[\(Yuk3\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((4, {j1, o1})\))\)\)\), \(2\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", "G"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j2})\))\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j1})\))\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", "W"}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", "H"}],
HoldForm]] -> 
\*FractionBox[\(I\ Yuk3\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j2})\))\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"2", ",", 
RowBox[{"{", "j1", "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"1", ",", 
RowBox[{"{", "j2", "}"}]}], ")"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ Yuk3\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((j1, j2)\)\)\ \(Mass \((F \((2, {j1})\))\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", "G"}],
HoldForm]] -> \*
FractionBox[
RowBox[{"I", " ", 
TemplateBox[{RowBox[{"CKM", "(", RowBox[{"j1", ",", "j2"}], ")"}]},
"Conjugate"], " ", 
RowBox[{"FCGV", "(", "\"\<EL\>\"", ")"}], " ", 
RowBox[{"IndexDelta", "(", 
RowBox[{"o1", ",", "o2"}], ")"}], " ", 
RowBox[{"Mass", "(", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], ")"}]}], 
RowBox[{
SqrtBox["2"], " ", 
RowBox[{"FCGV", "(", "\"\<MW\>\"", ")"}], " ", 
RowBox[{"FCGV", "(", "\"\<SW\>\"", ")"}]}]], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "G"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(CKM \((j2, j1)\)\)\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((4, {j1, o1})\))\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o1"}], "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o2"}], "}"}]}], ")"}], " ", "W"}],
HoldForm]] -> \(-\*
FractionBox[
RowBox[{"I", " ", 
TemplateBox[{RowBox[{"CKM", "(", RowBox[{"j1", ",", "j2"}], ")"}]},
"Conjugate"], " ", 
RowBox[{"FCGV", "(", "\"\<EL\>\"", ")"}], " ", 
RowBox[{"IndexDelta", "(", 
RowBox[{"o1", ",", "o2"}], ")"}]}], 
RowBox[{
SqrtBox["2"], " ", 
RowBox[{"FCGV", "(", "\"\<SW\>\"", ")"}]}]]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o1"}], "}"}]}], ")"}]}], " ", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o2"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "W"}], ")"}]}],
HoldForm]] -> \(-
\*FractionBox[\(I\ \(CKM \((j2, j1)\)\)\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((o1, o2)\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<SW\>")\)\)\)]\), \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", "H"}],
HoldForm]] -> \*
FractionBox[
RowBox[{"I", " ", 
TemplateBox[{RowBox[{"CKM", "(", RowBox[{"j1", ",", "j2"}], ")"}]},
"Conjugate"], " ", 
RowBox[{"FCGV", "(", "\"\<EL\>\"", ")"}], " ", 
RowBox[{"IndexDelta", "(", 
RowBox[{"o1", ",", "o2"}], ")"}], " ", 
RowBox[{"Mass", "(", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], ")"}]}], 
RowBox[{
SqrtBox["2"], " ", "TB", " ", 
RowBox[{"FCGV", "(", "\"\<MW\>\"", ")"}], " ", 
RowBox[{"FCGV", "(", "\"\<SW\>\"", ")"}]}]], \*
SubscriptBox["g", 
TagBox[
RowBox[{
RowBox[{"F", "(", 
RowBox[{"4", ",", 
RowBox[{"{", 
RowBox[{"j1", ",", "o1"}], "}"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", 
RowBox[{"F", "(", 
RowBox[{"3", ",", 
RowBox[{"{", 
RowBox[{"j2", ",", "o2"}], "}"}]}], ")"}]}], ")"}], " ", 
RowBox[{"(", 
RowBox[{"-", "H"}], ")"}]}],
HoldForm]] -> 
\*FractionBox[\(I\ Yuk3\ \(CKM \((j2, j1)\)\)\ \(FCGV \(("\<EL\>")\)\)\ \(IndexDelta \((o1, o2)\)\)\ \(Mass \((F \((4, {j1, o1})\))\)\)\), \(
\*SqrtBox[\(2\)]\ \(FCGV \(("\<MW\>")\)\)\ \(FCGV \(("\<SW\>")\)\)\)]}\);
rollbackCouplings = RollbackCouplings//FCGVToSymbol;


M$CouplingMatrices[[80]]
