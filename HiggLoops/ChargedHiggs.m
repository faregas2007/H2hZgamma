(* ::Package:: *)

(*self energy Higgs*)TwoPointsDiagrams = DiagramExtract[diagrams, TwoPoints];
SelfH = DiagramExtract[TwoPointsDiagrams, {1}];



Paint[SelfH, Numbering->Simple, SheetHeader->None, ColumnsXRows->{1,1}];



Clear[ampsSelf]
ampsSelf = CreateFeynAmp[SelfH, Truncated->True, GaugeRules->{_FAGaugeXi->1}];
ampsSelf = FCFAConvert[ampsSelf, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},
LoopMomenta-> {l},  ChangeDimension->D, UndoChiralSplittings->True, DropSumOver->True , TransversePolarizationVectors->{k1, k2}, List->True, 
SMP->True, LorentzIndexNames->{\[Mu], \[Nu], \[Rho], \[Sigma], \[Delta], \[Lambda]}, SUNIndexNames->{a,b,c,d,f,e,g,h},SUNFIndexNames-> {w,v,z,x,m,n,q,r}
]/.ConventionNotation//Contract//FCTraceFactor//Simplify;



F1self = ((((Proj[\[Mu],\[Nu]][[1]])ampsSelf // Contract//Expand)//.variables)/.Kinematics2)/.variables
F2self = (((Proj[\[Mu],\[Nu]][[2]] ampsSelf // Contract//Expand)//.variables)/.Kinematics2)/.variables
F3self = (((Proj[\[Mu],\[Nu]][[3]] ampsSelf) // Contract//Expand//.variables)/.Kinematics2)/.variables


f1selfreduced =F1self/.squareloopterms/.looplineardependences
f2selfreduced = F2self/.squareloopterms/.looplineardependences;
f3selfreduced = F3self/.squareloopterms/.looplineardependences;


f1selfres = f1selfreduced//TID[#, l, ToPaVe->True]&//Simplify
f2selfres = f2selfreduced// TID[#, l, ToPaVe->True]&//Simplify;
f3selfres = f3selfreduced// TID[#, l, ToPaVe->True]& //Simplify;


f1self =  f1selfres/.Kinematics2/.variables/.variables2
f2self =  f2selfres/.Kinematics2/.variables/.variables2
f3self =  f3selfres/.Kinematics2/.variables/.variables2


f1Hself = Total[f1self]//Simplify
f2Hself = Total[f2self]//Simplify
f3Hself = (Total[f3self]//Simplify)//.variables2//Simplify


Clear[F1self, F2self, F3self, f1selfreduced, f2selfreduced, f3selfreduced, f1selfres, f2selfres, f3selfres, f1self, f2self, f3self];




(*Triangles Higgs*)
trianglewithoutW = DiagramSelect[DiagramExtract[diagrams, TriangleList], FreeQ[LoopFields[##],  V[3]]&];
trianglewithoutH = DiagramSelect[DiagramExtract[diagrams, TriangleList], FreeQ[LoopFields[##],  S[5]]&];
triangleH = DiagramSelect[trianglewithoutW, FreeQ[LoopFields[##], S[6]]&];


Paint[triangleH, Numbering->Simple, SheetHeader->None, ColumnsXRows->{2,2}];



Clear[ampsTriangle]
ampsTriangle = CreateFeynAmp[triangleH, Truncated->True, GaugeRules->{_FAGaugeXi->1} ];
ampsTriangle = FCFAConvert[ampsTriangle, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},
LoopMomenta->{l}, ChangeDimension-> D, UndoChiralSplittings-> True, 
DropSumOver->True, TransversePolarizationVectors->{k1, k2}, List->True,
SMP->True, LorentzIndexNames->{\[Mu],\[Nu],\[Rho], \[Delta], \[Lambda]},  SUNIndexNames->{a,b,c,d,e,f,g,h}, SUNFIndexNames->{w, v, z, x, m, n , q, r}]/.ConventionNotation//Contract//FCTraceFactor//Simplify;



F1tr = (Proj[\[Mu],\[Nu]][[1]]ampsTriangle // Contract//Expand)//.variables;
F2tr = (Proj[\[Mu],\[Nu]][[2]] ampsTriangle // Contract//Expand)/.variables;
F3tr = (Proj[\[Mu],\[Nu]][[3]] ampsTriangle // Contract//Expand)/.variables;


f1trreduced =F1tr/.squareloopterms/.looplineardependences/.variables;
f2trreduced = F2tr/.squareloopterms/.looplineardependences/.variables;
f3trreduced = F3tr/.squareloopterms/.looplineardependences/.variables;


f1trres = f1trreduced//TID[#, l, ToPaVe->True]&//Simplify;
f2trres = f2trreduced// TID[#, l, ToPaVe->True]&//Simplify;
f3trres = f3trreduced// TID[#, l, ToPaVe->True]& //Simplify;


f1tr =  f1trres/.variables;
f2tr =  f2trres/.variables;
f3tr =  f3trres/.variables;


f1Htr = Total[f1tr]//Simplify;
f2Htr = Total[f2tr]//Simplify;
f3Htr = Total[f3tr]//Simplify;


Clear[F1tr, F2tr, F3tr, f1trreduced, f2trreduced, f3trreduced, f1trres, f2trres, f3trres, f1tr, f2tr, f3tr];



(* Boxes Higgs *)
BoxesDiagrams = DiagramExtract[diagrams, BoxesList];
BoxesWithH = DiagramSelect[BoxesDiagrams,
!FreeQ[LoopFields[##], S[5]]&];
BoxesWithFermion =  DiagramSelect[BoxesDiagrams,
!FreeQ[LoopFields[##], F[3, {3, _}]]&];
BoxesWithoutW =  DiagramSelect[BoxesDiagrams,
FreeQ[LoopFields[##], V[3]]&];
BoxesWithoutWG = DiagramSelect[BoxesWithoutW, FreeQ[LoopFields[##],  S[6]]&];
BoxesWithoutWGt = DiagramComplement[BoxesWithoutWG, BoxesWithFermion];
BoxesWithoutWGtu = DiagramSelect[BoxesWithoutWGt, FreeQ[LoopFields[##], U[_]]&];
BoxesH = BoxesWithoutWGtu;



Paint[BoxesH, Numbering->Simple, SheetHeader->None, ColumnsXRows->{3,3}];



Clear[ampsBoxes]
ampsBoxes = CreateFeynAmp[BoxesH, Truncated->True, GaugeRules->{_FAGaugeXi->1}];
ampsBoxes = FCFAConvert[ampsBoxes, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},
LoopMomenta-> {l},  ChangeDimension->D, UndoChiralSplittings->True, DropSumOver->True , TransversePolarizationVectors->{k1, k2}, List->True, 
SMP->True, LorentzIndexNames->{\[Mu], \[Nu], \[Rho], \[Sigma], \[Delta], \[Lambda]}, SUNIndexNames->{a,b,c,d,f,e,g,h},SUNFIndexNames-> {w,v,z,x,m,n,q,r}
]/.ConventionNotation//Contract//FCTraceFactor//Simplify;



F1box = Proj[\[Mu],\[Nu]][[1]] ampsBoxes // Contract;
F2box = Proj[\[Mu],\[Nu]][[1]] ampsBoxes // Contract;
F3box = Proj[\[Mu],\[Nu]][[1]] ampsBoxes // Contract;


f1boxreduced =F1box/.squareloopterms/.looplineardependences/.variables//Expand;
f2boxreduced = F2box/.squareloopterms/.looplineardependences/.variables//Expand;
f3boxreduced = F3box/.squareloopterms/.looplineardependences/.variables//Expand;



f1boxres = f1boxreduced//TID[#, l, ToPaVe->True]&//Simplify;
f2boxres = f2boxreduced// TID[#, l, ToPaVe->True]&//Simplify;
f3boxres = f3boxreduced// TID[#, l, ToPaVe->True]& //Simplify;



f1box =  f1boxres/.variables;
f2box =  f2boxres/.variables;
f3box =  f3boxres/.variables;



f1Hbox = Total[f1box]//Simplify
f2Hbox = Total[f2box]//Simplify
f3Hbox = Total[f3box]//Simplify


Clear[F1box, F2box, F3box, f1boxreduced, f2boxreduced, f3boxreduced, f1boxres, f2boxres, f3boxres, f1box, f2box, f3box];



(* ReducedSelfH *)
WFSelfWithH = DiagramSelect[WFSelfHDiagrams, !FreeQ[LoopFields[##], S[5]]&];
WFSelfH = DiagramExtract[WFSelfWithH, {1,2,5}];
WFSelfHWu = DiagramComplement[WFSelfwithH, WFSelfH];
WFSelfGWu = DiagramComplement[WFSelfHDiagrams, WFSelfwithH];
Paint[WFSelfH, Numbering->Simple, SheetHeader->None];


Clear[ampsReduced]
ampsReduced = CreateFeynAmp[WFSelfH, Truncated->True, GaugeRules->{_FAGaugeXi->1}];
ampsReduced = FCFAConvert[ampsReduced, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},
LoopMomenta-> {l},  ChangeDimension->D, UndoChiralSplittings->True, DropSumOver->True , TransversePolarizationVectors->{k1, k2}, List->True, 
SMP->True, LorentzIndexNames->{\[Mu], \[Nu], \[Rho], \[Sigma], \[Delta], \[Lambda]}, SUNIndexNames->{a,b,c,d,f,e,g,h},SUNFIndexNames-> {w,v,z,x,m,n,q,r}
]/.ConventionNotation//Contract//FCTraceFactor//Simplify;



F1reduced = Proj[\[Mu],\[Nu]][[1]] ampsReduced // Contract;
F2reduced = Proj[\[Mu],\[Nu]][[1]] ampsReduced // Contract;
F3reduced = Proj[\[Mu],\[Nu]][[1]] ampsReduced // Contract;



f1reducedreduced =F1reduced/.squareloopterms/.looplineardependences/.variables//Expand;
f2reducedreduced = F2reduced/.squareloopterms/.looplineardependences/.variables//Expand;
f3reducedreduced = F3reduced/.squareloopterms/.looplineardependences/.variables//Expand;



f1reduceds = f1reducedreduced//TID[#, l, ToPaVe->True]&//Simplify;
f2reduceds = f2reducedreduced// TID[#, l, ToPaVe->True]&//Simplify;
f3reduceds = f3reducedreduced// TID[#, l, ToPaVe->True]& //Simplify;



f1rr =  ((f1reduceds//PropagatorDenominatorExplicit)//SMPToSymbol)/.variables/.variables2;
f2rr =  ((f2reduceds//PropagatorDenominatorExplicit)//SMPToSymbol)/.variables/.variables2;
f3rr =  ((f3reduceds//PropagatorDenominatorExplicit)//SMPToSymbol)/.variables/.variables2;


f1Hrr = Total[f1rr]//Simplify
f2Hrr = Total[f2rr]//Simplify
f3Hrr = Total[f3rr]//Simplify


Clear[F1reduced, F2reduced, F3reduced, f1reducedreduced, f2reducedreduced, f3reducedreduced, f1rr, f2rr, f3rr];


f1H = f1Hself + f1Htr + f1Hbox + f1Hrr//Simplify;
f2H = f2Hself + f2Htr + f2Hbox + f2Hrr//Simplify;
f3H = f3Hself + f3Htr + f3Hbox + f3Hrr//Simplify;



PaVeUVPart[f1H]/.D->4 - 2\[Epsilon]//Series[#, {\[Epsilon], 0, -1}]&//Simplify
PaVeUVPart[f2H]/.D->4 - 2\[Epsilon]//Series[#, {\[Epsilon], 0, -1}]&//Simplify
PaVeUVPart[f3H]/.D->4 - 2\[Epsilon]//Series[#, {\[Epsilon], 0, -1}]&//Simplify


data = <|"f1Hself"-> f1Hself, 
		"f2Hself"->f2Hself, 
		"f3Hself"->f3Hself, 
		"f1Htr"->f1Htr, 
		"f2Htr"->f2Htr, 
		"f3Htr"->f3Htr, 
		"f1Hbox"->f1Hbox, 
		"f2Hbox"->f2Hbox, 
		"f3Hbox"->f3Hbox,
		"f1Hrr"->f1Hrr,
		"f2Hrr"->f2Hrr,
		"f3Hrr"->f3Hrr|>;
Save["HiggLoops.m", data]


Clear[data]


NotebookDirectory[]
<< "HiggLoops.m"


data["f1Hself"]
