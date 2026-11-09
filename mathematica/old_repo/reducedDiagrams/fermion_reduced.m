(* ::Package:: *)

(* Divided them into topology group they belong to *)
(* To group: fermion group and non-fermion group *)



(*Fermions*)
topWFDiagrams = DiagramSelect[WFDiagrams, !FreeQ[ LoopFields[##], F[3, _]]&];
Paint[topWFDiagrams, Numbering->Simple, SheetHeader->None]


(*fermion*)
vfTopo1 = Range[1, 4];
vfTopo2 = Range[5, 10];
vfTopo3 = Range[11, 16];
sfTopo4 = Range[17, 22];
sfTopo5 = Range[23, 31];
sfTopo6 = Range[32, 40];




fListTopo = {vfTopo1, vfTopo2, vfTopo3, sfTopo4, sfTopo5, sfTopo6};
couplingreplace = {Subscript[g, HoldForm[Subscript[H, 0] Z Z]]-> I e Subscript[m, W] Cos[\[Beta]-\[Alpha]]/(Sin[Subscript[\[Theta], W]] Cos[Subscript[\[Theta], W]]^2)}


Clear[amprrtop]
amprrtop = CreateFeynAmp[topWFDiagrams, Truncated->True, GaugeRules->{_FAGaugeXi->1}];
amprrtop = FCFAConvert[amprrtop, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},
LoopMomenta-> {l},  ChangeDimension->D, UndoChiralSplittings->True, DropSumOver->True , TransversePolarizationVectors->{k2, k3}, List->True, 
SMP->True, LorentzIndexNames->{\[Mu], \[Nu], \[Rho], \[Sigma], \[Delta], \[Lambda]}, SUNIndexNames->{a,b,c,d,f,e,g,h},SUNFIndexNames-> {w,v,z,x,m,n,q,r}
]/.ConventionNotation//Contract//FCTraceFactor//Simplify; 



amprrtopvTopo1 = amprrtop[[vfTopo1]];
amprrtopvTopo2 = amprrtop[[vfTopo2]];
amprrtopvTopo3 = amprrtop[[vfTopo3]];
amprrtopsTopo4 = amprrtop[[sfTopo4]];
amprrtopsTopo5 = amprrtop[[sfTopo5]];
amprrtopsTopo6 = amprrtop[[sfTopo6]]; 



(* Trace evaluation *)
$Larin = False;
$BreitMaison = False;
ampffvTopo1 = DiracSimplify[ChangeDimension[amprrtopvTopo1,4], InsideDiracTrace->True];
ampffvTopo2 = DiracSimplify[ChangeDimension[amprrtopvTopo2,4], InsideDiracTrace->True];
ampffvTopo3 = DiracSimplify[ChangeDimension[amprrtopvTopo3,4], InsideDiracTrace->True];
ampffsTopo4 = DiracSimplify[ChangeDimension[amprrtopsTopo4,4], InsideDiracTrace->True];
ampffsTopo5 = DiracSimplify[ChangeDimension[amprrtopsTopo5,4], InsideDiracTrace->True];
ampffsTopo6 = DiracSimplify[ChangeDimension[amprrtopsTopo6,4], InsideDiracTrace->True];



$Larin = True;
$BreitMaison = False;
ampff2vTopo1 = ampffvTopo1//.DiracTrace->TR;
ampff2vTopo2 = ampffvTopo2//.DiracTrace->TR;
ampff2vTopo3 = ampffvTopo3//.DiracTrace->TR;
ampff2sTopo4 = ampffsTopo4//.DiracTrace->TR;
ampff2sTopo5 = ampffsTopo5//.DiracTrace->TR;
ampff2sTopo6 = ampffsTopo6//.DiracTrace->TR;



(* F1 form factor *)
F1ampffvTopo1 = (Proj[\[Mu],\[Nu]][[1]] ChangeDimension[ampff2vTopo1, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F1ampffvTopo2 = (Proj[\[Mu],\[Nu]][[1]] ChangeDimension[ampff2vTopo2, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F1ampffvTopo3 = (Proj[\[Mu],\[Nu]][[1]] ChangeDimension[ampff2vTopo3, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F1ampffsTopo4 = (Proj[\[Mu],\[Nu]][[1]] ChangeDimension[ampff2sTopo4, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F1ampffsTopo5 = (Proj[\[Mu],\[Nu]][[1]] ChangeDimension[ampff2sTopo5, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F1ampffsTopo6 = (Proj[\[Mu],\[Nu]][[1]] ChangeDimension[ampff2sTopo6, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;



F1ampffvTopo11 = F1ampffvTopo1/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F1ampffvTopo21 = F1ampffvTopo2/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F1ampffvTopo31 = F1ampffvTopo3/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F1ampffsTopo41 = F1ampffsTopo4/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F1ampffsTopo51 = F1ampffsTopo5/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F1ampffsTopo61 = F1ampffsTopo6/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;



F1ampffvTopo12 = (Total[F1ampffvTopo11//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F1ampffvTopo22 = (Total[F1ampffvTopo21//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F1ampffvTopo32 = (Total[F1ampffvTopo31//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F1ampffsTopo42 = (Total[F1ampffsTopo41//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F1ampffsTopo52 = (Total[F1ampffsTopo51//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F1ampffsTopo62 = (Total[F1ampffsTopo61//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;



F1ampffvTopo13 = (((F1ampffvTopo12//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F1ampffvTopo23 = (((F1ampffvTopo22//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F1ampffvTopo33 = (((F1ampffvTopo32//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F1ampffsTopo43 = (((F1ampffsTopo42//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F1ampffsTopo53 = (((F1ampffsTopo52//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F1ampffsTopo63 = (((F1ampffsTopo62//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;




(*F1 UV part *)
F1ampffvTopo1UV = PaVeUVPart[F1ampffvTopo13]//Simplify
F1ampffvTopo2UV = PaVeUVPart[F1ampffvTopo23]//Simplify
F1ampffvTopo3UV = PaVeUVPart[F1ampffvTopo33]//Simplify
F1ampffsTopo4UV = PaVeUVPart[F1ampffsTopo43]//Simplify
F1ampffsTopo5UV = PaVeUVPart[F1ampffsTopo53]//Simplify
F1ampffsTopo6UV = PaVeUVPart[F1ampffsTopo63]//Simplify



F1ffUV = F1ampffvTopo1UV +  F1ampffvTopo2UV +  F1ampffvTopo3UV +  F1ampffsTopo4UV +  F1ampffsTopo5UV +  F1ampffsTopo6UV //Simplify



(*F2 form factor *)
F2ampffvTopo1 = (Proj[\[Mu],\[Nu]][[2]] ChangeDimension[ampff2vTopo1, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F2ampffvTopo2 = (Proj[\[Mu],\[Nu]][[2]] ChangeDimension[ampff2vTopo2, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F2ampffvTopo3 = (Proj[\[Mu],\[Nu]][[2]] ChangeDimension[ampff2vTopo3, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F2ampffsTopo4 = (Proj[\[Mu],\[Nu]][[2]] ChangeDimension[ampff2sTopo4, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F2ampffsTopo5 = (Proj[\[Mu],\[Nu]][[2]] ChangeDimension[ampff2sTopo5, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F2ampffsTopo6 = (Proj[\[Mu],\[Nu]][[2]] ChangeDimension[ampff2sTopo6, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;





F2ampffvTopo11 = F2ampffvTopo1/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F2ampffvTopo21 = F2ampffvTopo2/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F2ampffvTopo31 = F2ampffvTopo3/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F2ampffsTopo41 = F2ampffsTopo4/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F2ampffsTopo51 = F2ampffsTopo5/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F2ampffsTopo61 = F2ampffsTopo6/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;



F2ampffvTopo12 = (Total[F2ampffvTopo11//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F2ampffvTopo22 = (Total[F2ampffvTopo21//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F2ampffvTopo32 = (Total[F2ampffvTopo31//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F2ampffsTopo42 = (Total[F2ampffsTopo41//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F2ampffsTopo52 = (Total[F2ampffsTopo51//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F2ampffsTopo62 = (Total[F2ampffsTopo61//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;



F2ampffvTopo13 = (((F2ampffvTopo12//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F2ampffvTopo23 = (((F2ampffvTopo22//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F2ampffvTopo33 = (((F2ampffvTopo32//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F2ampffsTopo43 = (((F2ampffsTopo42//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F2ampffsTopo53 = (((F2ampffsTopo52//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F2ampffsTopo63 = (((F2ampffsTopo62//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;



(*F2 UV part *)
F2ampffvTopo1UV = PaVeUVPart[F2ampffvTopo13]//Simplify
F2ampffvTopo2UV = PaVeUVPart[F2ampffvTopo23]//Simplify
F2ampffvTopo3UV = PaVeUVPart[F2ampffvTopo33]//Simplify
F2ampffsTopo4UV = PaVeUVPart[F2ampffsTopo43]//Simplify
F2ampffsTopo5UV = PaVeUVPart[F2ampffsTopo53]//Simplify
F2ampffsTopo6UV = PaVeUVPart[F2ampffsTopo63]//Simplify



F2ffUV = F2ampffvTopo1UV +  F2ampffvTopo2UV +  F2ampffvTopo3UV +  F2ampffsTopo4UV +  F2ampffsTopo5UV +  F2ampffsTopo6UV //Simplify



(* F3 form factor *)
F3ampffvTopo1 = (Proj[\[Mu],\[Nu]][[3]] ChangeDimension[ampff2vTopo1, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F3ampffvTopo2 = (Proj[\[Mu],\[Nu]][[3]] ChangeDimension[ampff2vTopo2, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F3ampffvTopo3 = (Proj[\[Mu],\[Nu]][[3]] ChangeDimension[ampff2vTopo3, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F3ampffsTopo4 = (Proj[\[Mu],\[Nu]][[3]] ChangeDimension[ampff2sTopo4, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F3ampffsTopo5 = (Proj[\[Mu],\[Nu]][[3]] ChangeDimension[ampff2sTopo5, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;
F3ampffsTopo6 = (Proj[\[Mu],\[Nu]][[3]] ChangeDimension[ampff2sTopo6, D]//Contract)/.{eps1-> 0, eps2->0, eps3->0, eps4->0}/.ConventionNotation;




F3ampffvTopo11 = F3ampffvTopo1/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F3ampffvTopo21 = F3ampffvTopo2/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F3ampffvTopo31 = F3ampffvTopo3/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F3ampffsTopo41 = F3ampffsTopo4/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F3ampffsTopo51 = F3ampffsTopo5/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;
F3ampffsTopo61 = F3ampffsTopo6/.looplineardependences/.squareloopterms/.variables/.variables3//ExpandScalarProduct;



F3ampffvTopo12 = (Total[F3ampffvTopo11//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F3ampffvTopo22 = (Total[F3ampffvTopo21//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F3ampffvTopo32 = (Total[F3ampffvTopo31//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F3ampffsTopo42 = (Total[F3ampffsTopo41//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F3ampffsTopo52 = (Total[F3ampffsTopo51//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;
F3ampffsTopo62 = (Total[F3ampffsTopo61//TID[#, l, ToPaVe->True ]&])/.variables//Simplify;



F3ampffvTopo13 = (((F3ampffvTopo12//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F3ampffvTopo23 = (((F3ampffvTopo22//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F3ampffvTopo33 = (((F3ampffvTopo32//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F3ampffsTopo43 = (((F3ampffsTopo42//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F3ampffsTopo53 = (((F3ampffsTopo52//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;
F3ampffsTopo63 = (((F3ampffsTopo62//FeynAmpDenominatorExplicit)//SMPToSymbol)/.variables/.ConventionNotation//Simplify)/.variables2/.couplingreplace//Simplify;




(*F3 UV part *)
F3ampffvTopo1UV = PaVeUVPart[F3ampffvTopo13]//Simplify
F3ampffvTopo2UV = PaVeUVPart[F3ampffvTopo23]//Simplify
F3ampffvTopo3UV = PaVeUVPart[F3ampffvTopo33]//Simplify
F3ampffsTopo4UV = PaVeUVPart[F3ampffsTopo43]//Simplify
F3ampffsTopo5UV = PaVeUVPart[F3ampffsTopo53]//Simplify
F3ampffsTopo6UV = PaVeUVPart[F3ampffsTopo63]//Simplify



F3ffUV = F3ampffvTopo1UV +  F3ampffvTopo2UV +  F3ampffvTopo3UV +  F3ampffsTopo4UV +  F3ampffsTopo5UV +  F3ampffsTopo6UV //Simplify



data = <|"F1ampffvTopo13"->F1ampffvTopo13,
"F1ampffvTopo23"->F1ampffvTopo23,
"F1ampffvTopo33"->F1ampffvTopo33,
"F1ampffsTopo43"->F1ampffsTopo43,
"F1ampffsTopo53"->F1ampffsTopo53,
"F1ampffsTopo63"->F1ampffsTopo63,
"F2ampffvTopo13"->F2ampffvTopo13,
"F2ampffvTopo23"->F2ampffvTopo23,
"F2ampffvTopo33"->F2ampffvTopo33,
"F2ampffsTopo43"->F2ampffsTopo43,
"F2ampffsTopo53"->F2ampffsTopo53,
"F2ampffsTopo63"->F2ampffsTopo63,
"F3ampffvTopo13"->F3ampffvTopo13,
"F3ampffvTopo23"->F3ampffvTopo23,
"F3ampffvTopo33"->F3ampffvTopo33,
"F3ampffsTopo43"->F3ampffsTopo43,
"F3ampffsTopo53"->F3ampffsTopo53,
"F3ampffsTopo63"->F3ampffsTopo63|>
Save["FermionReduced.m", data]

