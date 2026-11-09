(* ::Package:: *)

(* 02_higgs_diphoton.m

   Process   H(pH) -> gamma(k1) gamma(k2)      one-loop top-quark triangle, FeynArts model SM.

   FeynArts   : topologies, field insertion, Feynman amplitude
   FeynCalc   : Dirac algebra, tensor reduction to Passarino-Veltman functions (C0, B0, A0)
   Physics    : full Lorentz decomposition (5 structures) of the amputated tensor M^{mu nu}
                Ward identities  k1_mu M^{mu nu} = 0,  k2_nu M^{mu nu} = 0   ==>  E = G = 0,  A + (k1.k2) B = 0
                polarisation vectors are transverse (eps1.k1 = eps2.k2 = 0): only g^{mu nu} and k2^mu k1^nu survive, and by the
                Ward identity they combine into ONE form factor:
                    M^{mu nu} = F(s) ( g^{mu nu} k1.k2 - k2^mu k1^nu ),     s = pH^2 = 2 k1.k2
   Output     : export/hgg_ff_A.m  A(s) = coefficient of g^{mu nu}  (~ mt^2 (2 + (4 mt^2 - s) C0): the fermion-triangle shape)
                export/hgg_ff.m    F(s) = 2 A(s)/s                   (built from C0; no UV pole: asserted)

   Conventions: as in 01_photon_selfenergy.m. The amplitude is i M^{mu nu}; the (2 Pi)^-4 and Nc are put in by hand.

   Run:   wolframscript -file 02_higgs_diphoton.m                                                                      *)

$LoadAddOns = {"FeynArts"};
<< FeynCalc`
$FAVerbose = 0;

scriptDir = If[$InputFileName =!= "", DirectoryName[$InputFileName], NotebookDirectory[]];
Get[FileNameJoin[{scriptDir, "ampflow_ff.m"}]];
AFRequire[];
(* Where the exported amplitudes go: set $AFExportDir before running (e.g. to <workspace>/amplitudes); default ./export *)
exportDir = If[ValueQ[$AFExportDir], $AFExportDir, FileNameJoin[{scriptDir, "export"}]];


(* ---- 1. topologies and diagrams (FeynArts) --------------------------------------------------------------------- *)
(* Triangle with a top loop: both orientations of the fermion line. W, Goldstone and other-fermion loops are excluded. *)
topos = CreateTopologies[1, 1 -> 2, ExcludeTopologies -> {Tadpoles, WFCorrections}];

diags = InsertFields[topos, {S[1]} -> {V[1], V[1]}, InsertionLevel -> {Particles},
  ExcludeParticles -> {S[2|3], V[2|3], U[_], F[1|2|4], F[3, {1|2}]}];

If[$FrontEnd =!= Null,
  Paint[diags, ColumnsXRows -> {2, 1}, Numbering -> Simple, SheetHeader -> None, ImageSize -> {512, 256}]];


(* ---- 2. the amplitude ------------------------------------------------------------------------------------------- *)
amp0 = FCFAConvert[
  CreateFeynAmp[diags, PreFactor -> 1, Truncated -> True, GaugeRules -> {}],
  IncomingMomenta -> {pH}, OutgoingMomenta -> {k1, k2}, LorentzIndexNames -> {mu, nu}, LoopMomenta -> {q},
  UndoChiralSplittings -> True, ChangeDimension -> D, DropSumOver -> True, SMP -> True];

amp1 = Nc Total[Flatten[{amp0}]] // FCReplaceMomenta[#, {pH -> k1 + k2}] &;     (* colour factor; momentum conservation *)

FCClearScalarProducts[];
ScalarProduct[k1, k1] = 0;                       (* on-shell photons *)
ScalarProduct[k2, k2] = 0;
ScalarProduct[k1, k2] = s/2;                     (* s = pH^2 = 2 k1.k2 *)


(* ---- 3. Dirac algebra and tensor reduction ---------------------------------------------------------------------- *)
amp2 = DiracSimplify[amp1];
amp3 = TID[amp2, q, ToPaVe -> True];
mTensor = amp3/(2 Pi)^4/I;                       (* M^{mu nu}: the amplitude is i M^{mu nu} *)


(* ---- 4. Lorentz decomposition and Ward identities ---------------------------------------------------------------- *)
(* Which photon carries mu? FeynArts numbers the outgoing legs in order, so mu belongs to k1 and nu to k2, but the
   Ward identity decides: try the assignment, and the swapped one if it fails.                                       *)
dimRelation = B0[0, m_, m_] :> (D - 2)/(2 m) A0[m];

decompose[ka_, kb_] := Module[{structures, coefs},
  structures = {MTD[mu, nu], FVD[kb, mu] FVD[ka, nu], FVD[ka, mu] FVD[kb, nu], FVD[ka, mu] FVD[ka, nu], FVD[kb, mu] FVD[kb, nu]};
  coefs = AFLorentzCoefficients[mTensor, structures];     (* {A, B, C, E, G} *)
  {coefs, Simplify[{coefs[[4]], coefs[[5]], coefs[[1]] + (s/2) coefs[[2]]} /. dimRelation]}
];

{{coefs, residuals}, kaKb} = Module[{try1 = decompose[k1, k2], try2},
  If[try1[[2]] === {0, 0, 0}, {try1, {k1, k2}},
    try2 = decompose[k2, k1];
    If[try2[[2]] === {0, 0, 0}, AFLog["mu is attached to k2, not k1 (swapped assignment passes)"]; {try2, {k2, k1}},
      AFFail["Ward identities violated for both index assignments. Residuals {E, G, A + (k1.k2) B}: ", try1[[2]], " and ", try2[[2]],
        "  -- a diagram is missing or the reduction failed"]]]
];
AFLog["Ward identities hold in D dimensions: E = G = 0 and A + (k1.k2) B = 0  (index mu <-> ", First[kaKb], ")"];


(* ---- 5. the form factor ----------------------------------------------------------------------------------------------- *)
(* Transverse polarisations keep g^{mu nu} (A) and kb^mu ka^nu (B); the Ward identity gives A = -(ka.kb) B, so
   M^{mu nu} = A (g^{mu nu} - kb^mu ka^nu/(ka.kb)) = F (g^{mu nu} ka.kb - kb^mu ka^nu)  with  F = A/(ka.kb) = 2 A/s.
   A itself is the quantity with the nice shape; F = 2A/s.                                                        *)
coefAD = coefs[[1]] /. A0[m_] :> 2 m/(D - 2) B0[0, m, m];


(* ---- 6. D -> 4 ------------------------------------------------------------------------------------------------------------ *)
coefA = AFCanonicalC0[AFLimitTo4[coefAD]] // Simplify;
formFactor = Simplify[2 coefA/s];
AFLog["A(s) = ", coefA];
AFLog["F(s) = 2 A/s = ", formFactor];
If[AFPoleCoefficient[coefA] =!= 0, AFFail["the amplitude has a UV pole: ", AFPoleCoefficient[coefA]]];
AFLog["no UV pole, as it must be for H -> gamma gamma"];


(* ---- 7. check against the known shape ---------------------------------------------------------------------------------- *)
(* A(s) is proportional to  mt^2 ( 2 + (4 mt^2 - s) C0(0,0,s; mt,mt,mt) ) = (s/4) A_1/2(tau),  tau = s/(4 mt^2)  (the standard
   fermion-triangle function). The coupling in front, ~ e^3 Q^2 Nc/(sW MW), is printed by the shape check.            *)
mt = SMP["m_t"];
shape = mt^2 (2 + (4 mt^2 - s) C0[0, 0, s, mt^2, mt^2, mt^2]);
AFShapeCheck["A(s) vs the fermion-triangle shape", coefA, shape, {s}];


(* ---- 8. export for fc2lt ------------------------------------------------------------------------------------------------- *)
AFExportAmplitude[FileNameJoin[{exportDir, "hgg_ff_A.m"}], coefA,
  "H -> gamma gamma, top loop; generated by 02_higgs_diphoton.m (FeynArts + FeynCalc). A(s): coefficient of g^{mu nu} in M^{mu nu}; input: s"];
AFExportAmplitude[FileNameJoin[{exportDir, "hgg_ff.m"}], formFactor,
  "H -> gamma gamma, top loop; generated by 02_higgs_diphoton.m (FeynArts + FeynCalc). F(s) = 2A/s in M^{mu nu} = F (g^{mu nu} k1.k2 - k2^mu k1^nu); input: s"];
