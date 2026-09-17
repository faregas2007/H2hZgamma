(* ::Package:: *)

(* ::Input:: *)
(*(*self energy Higgs*)TwoPointsDiagrams = DiagramExtract[diagrams, TwoPoints];*)
(*SelfH = DiagramExtract[TwoPointsDiagrams, {1}];*)


(* ::Input:: *)
(*Paint[SelfH, Numbering->Simple, SheetHeader->None, ColumnsXRows->{1,1}];*)
(**)


(* ::Input:: *)
(*Clear[ampsSelf]*)
(*ampsSelf = CreateFeynAmp[SelfH, Truncated->True, GaugeRules->{_FAGaugeXi->1}];*)
(*ampsSelf = FCFAConvert[ampsSelf, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},*)
(*LoopMomenta-> {l},  ChangeDimension->D, UndoChiralSplittings->True, DropSumOver->True , TransversePolarizationVectors->{k1, k2}, List->True, *)
(*SMP->True, LorentzIndexNames->{\[Mu], \[Nu], \[Rho], \[Sigma], \[Delta], \[Lambda]}, SUNIndexNames->{a,b,c,d,f,e,g,h},SUNFIndexNames-> {w,v,z,x,m,n,q,r}*)
(*]/.ConventionNotation//Contract//FCTraceFactor//Simplify;*)
(**)


(* ::Input:: *)
(*F1self = P1[\[Mu],\[Nu]]ampsSelf // Contract//Expand;*)
(*F2self = P2[\[Mu],\[Nu]] ampsSelf // Contract//Expand;*)
(*F3self = P3[\[Mu],\[Nu]] ampsSelf // Contract//Expand;*)
(**)


(* ::Input:: *)
(*f1selfreduced =F1self/.squareloopterms/.looplineardependences;*)
(*f2selfreduced = F2self/.squareloopterms/.looplineardependences;*)
(*f3selfreduced = F3self/.squareloopterms/.looplineardependences;*)
(**)


(* ::Input:: *)
(*f1selfres = f1selfreduced//TID[#, l, ToPaVe->True]&//Simplify;*)
(*f2selfres = f2selfreduced// TID[#, l, ToPaVe->True]&//Simplify;*)
(*f3selfres = f3selfreduced// TID[#, l, ToPaVe->True]& //Simplify;*)


(* ::Input:: *)
(*f1self =  f1selfres/.Kinematics/.InvariantKinematics;*)
(*f2self =  f2selfres/.Kinematics/.InvariantKinematics;*)
(*f3self =  f3selfres/.Kinematics/.InvariantKinematics;*)
(**)


(* ::Input:: *)
(*f1Hself = Total[f1self]//Simplify*)
(*f2Hself = Total[f2self]//Simplify*)
(*f3Hself = Total[f3self]//Simplify*)
(**)


(* ::Input:: *)
(*Clear[F1self, F2self, F3self, f1selfreduced, f2selfreduced, f3selfreduced, f1selfres, f2selfres, f3selfres, f1self, f2self, f3self];*)
(**)


(* ::Input:: *)
(*(*Triangles Higgs*)*)
(*trianglewithoutW = DiagramSelect[DiagramExtract[diagrams, TriangleList], FreeQ[LoopFields[##],  V[3]]&];*)


(* ::Input:: *)
(*trianglewithoutH = DiagramSelect[DiagramExtract[diagrams, TriangleList], FreeQ[LoopFields[##],  S[5]]&];*)
(*triangleH = DiagramSelect[trianglewithoutW, FreeQ[LoopFields[##], S[6]]&];*)


(* ::Input:: *)
(*Paint[triangleH, Numbering->Simple, SheetHeader->None, ColumnsXRows->{2,2}];*)
(**)


(* ::Input:: *)
(*Clear[ampsTriangle]*)
(*ampsTriangle = CreateFeynAmp[triangleH, Truncated->True, GaugeRules->{_FAGaugeXi->1} ];*)
(*ampsTriangle = FCFAConvert[ampsTriangle, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},*)
(*LoopMomenta->{l}, ChangeDimension-> D, UndoChiralSplittings-> True, *)
(*DropSumOver->True, TransversePolarizationVectors->{k1, k2}, List->True,*)
(*SMP->True, LorentzIndexNames->{\[Mu],\[Nu],\[Rho], \[Delta], \[Lambda]},  SUNIndexNames->{a,b,c,d,e,f,g,h}, SUNFIndexNames->{w, v, z, x, m, n , q, r}]/.ConventionNotation//Contract//FCTraceFactor//Simplify;*)


(* ::Input:: *)
(*F1tr = P1[\[Mu],\[Nu]]ampsTriangle // Contract//Expand;*)
(*F2tr = P2[\[Mu],\[Nu]] ampsTriangle // Contract//Expand;*)
(*F3tr = P3[\[Mu],\[Nu]] ampsTriangle // Contract//Expand;*)


(* ::Input:: *)
(*f1trreduced =F1tr/.squareloopterms/.looplineardependences;*)
(*f2trreduced = F2tr/.squareloopterms/.looplineardependences;*)
(*f3trreduced = F3tr/.squareloopterms/.looplineardependences;*)
(**)


(* ::Input:: *)
(*f1trres = f1trreduced//TID[#, l, ToPaVe->True]&//Simplify;*)
(*f2trres = f2trreduced// TID[#, l, ToPaVe->True]&//Simplify;*)
(*f3trres = f3trreduced// TID[#, l, ToPaVe->True]& //Simplify;*)


(* ::Input:: *)
(*f1tr =  f1trres/.Kinematics/.InvariantKinematics;*)
(*f2tr =  f2trres/.Kinematics/.InvariantKinematics;*)
(*f3tr =  f3trres/.Kinematics/.InvariantKinematics;*)


(* ::Input:: *)
(*f1Htr = Total[f1tr]//Simplify*)
(*f2Htr = Total[f2tr]//Simplify*)
(*f3Htr = Total[f3tr]//Simplify*)
(**)


(* ::Input:: *)
(*Clear[F1tr, F2tr, F3tr, f1trreduced, f2trreduced, f3trreduced, f1trres, f2trres, f3trres, f1tr, f2tr, f3tr];*)
(**)


(* ::Input:: *)
(*(* Boxes Higgs *)*)
(*BoxesDiagrams = DiagramExtract[diagrams, BoxesList];*)
(*BoxesWithH = DiagramSelect[BoxesDiagrams,*)
(*!FreeQ[LoopFields[##], S[5]]&];*)
(*BoxesWithFermion =  DiagramSelect[BoxesDiagrams,*)
(*!FreeQ[LoopFields[##], F[3, {3, _}]]&];*)
(*BoxesWithoutW =  DiagramSelect[BoxesDiagrams,*)
(*FreeQ[LoopFields[##], V[3]]&];*)


(* ::Input:: *)
(*BoxesWithoutWG = DiagramSelect[BoxesWithoutW, FreeQ[LoopFields[##],  S[6]]&];*)
(*BoxesWithoutWGt = DiagramComplement[BoxesWithoutWG, BoxesWithFermion];*)
(*BoxesWithoutWGtu = DiagramSelect[BoxesWithoutWGt, FreeQ[LoopFields[##], U[_]]&];*)


(* ::Input:: *)
(*BoxesH = BoxesWithoutWGtu;*)


(* ::Input:: *)
(*Paint[BoxesH, Numbering->Simple, SheetHeader->None, ColumnsXRows->{3,3}];*)


(* ::Input:: *)
(*Clear[ampsBoxes]*)
(*ampsBoxes = CreateFeynAmp[BoxesH, Truncated->True, GaugeRules->{_FAGaugeXi->1}];*)
(*ampsBoxes = FCFAConvert[ampsBoxes, IncomingMomenta->{q}, OutgoingMomenta->{k1, k2, k3},*)
(*LoopMomenta-> {l},  ChangeDimension->D, UndoChiralSplittings->True, DropSumOver->True , TransversePolarizationVectors->{k1, k2}, List->True, *)
(*SMP->True, LorentzIndexNames->{\[Mu], \[Nu], \[Rho], \[Sigma], \[Delta], \[Lambda]}, SUNIndexNames->{a,b,c,d,f,e,g,h},SUNFIndexNames-> {w,v,z,x,m,n,q,r}*)
(*]/.ConventionNotation//Contract//FCTraceFactor//Simplify;*)


(* ::Input:: *)
(*F1box = P1[\[Mu],\[Nu]] ampsBoxes // Contract // Expand;*)
(*F2box = P2[\[Mu],\[Nu]] ampsBoxes // Contract // Expand;*)
(*F3box = P3[\[Mu],\[Nu]] ampsBoxes // Contract // Expand;*)


(* ::Input:: *)
(*f1boxreduced =F1box/.squareloopterms/.looplineardependences;*)
(*f2boxreduced = F2box/.squareloopterms/.looplineardependences;*)
(*f3boxreduced = F3box/.squareloopterms/.looplineardependences;*)


(* ::Input:: *)
(*f1boxres = f1boxreduced//TID[#, l, ToPaVe->True]&//Simplify;*)
(*f2boxres = f2boxreduced// TID[#, l, ToPaVe->True]&//Simplify;*)
(*f3boxres = f3boxreduced// TID[#, l, ToPaVe->True]& //Simplify;*)
(**)


(* ::Input:: *)
(*f1box =  f1boxres/.Kinematics/.InvariantKinematics;*)
(*f2box =  f2boxres/.Kinematics/.InvariantKinematics;*)
(*f3box =  f3boxres/.Kinematics/.InvariantKinematics;*)


(* ::Input:: *)
(*f1Hbox = Total[f1box]//Simplify*)
(*f2Hbox = Total[f2box]//Simplify*)
(*f3Hbox = Total[f3box]//Simplify*)


(* ::Input:: *)
(*Clear[F1box, F2box, F3box, f1boxreduced, f2boxreduced, f3boxreduced, f1boxres, f2boxres, f3boxres, f1box, f2box, f3box];*)
(**)


(* ::Input:: *)
(*f1H = f1Hself + f1Htr + f1Hbox//Simplify;*)
(*f2H = f2Hself + f2Htr + f2Hbox//Simplify;*)
(*f3H = f3Hself + f3Htr + f3Hbox//Simplify;*)


(* ::Input:: *)
(*PaVeUVPart[f1H]/.D->4 - 2\[Epsilon]//Series[#, {\[Epsilon], 0, -1}]&*)
(*PaVeUVPart[f2H]/.D->4 - 2\[Epsilon]//Series[#, {\[Epsilon], 0, -1}]&*)
(*PaVeUVPart[f3H]/.D->4 - 2\[Epsilon]//Series[#, {\[Epsilon], 0, -1}]&*)



