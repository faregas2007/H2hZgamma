(* ::Package:: *)

(* 01_photon_selfenergy.m

   Process   gamma*(k) -> gamma*(k)       one-loop fermion loop (the top quark), FeynArts model SM.

   FeynArts   : topologies, field insertion, Feynman amplitude
   FeynCalc   : Dirac algebra, tensor reduction to Passarino-Veltman functions
   Physics    : Lorentz decomposition  Pi^{mu nu} = A g^{mu nu} + B k^mu k^nu
                Ward identity  k_mu Pi^{mu nu} = 0   ==>  A + k^2 B = 0   (transversality)
                one form factor  Pi(s):  Pi^{mu nu} = (s g^{mu nu} - k^mu k^nu) Pi(s)
   Output     : export/vacpol_ff_sigmaT.m   Sigma_T(s) = -s Pi(s)   (the convention of Denner, Fortschr. Phys. 41 (1993) 307)
                export/vacpol_ff_pi.m       Pi(s)
                -- plain A0 / B0 expressions that fc2lt translates to C++ (copy them into ../amplitudes/).

   Conventions:  the FeynArts amplitude (PreFactor -> 1, Truncated) is the value of the diagram, i.e. i Pi^{mu nu}.
                 The loop measure carries an implicit 1/(2 Pi)^D.  TID with ToPaVe returns  i Pi^2 x (PaVe functions),
                 so the amplitude in LoopTools normalisation is  TID result / (2 Pi)^4  = i/(16 Pi^2) x PaVe.
                 The colour sum was dropped by DropSumOver; it is restored below as the symbol Nc.

   Run:   wolframscript -file 01_photon_selfenergy.m                                                                 *)

$LoadAddOns = {"FeynArts"};
<< FeynCalc`
$FAVerbose = 0;

scriptDir = If[$InputFileName =!= "", DirectoryName[$InputFileName], NotebookDirectory[]];
Get[FileNameJoin[{scriptDir, "ampflow_ff.m"}]];
AFRequire[];
(* Where the exported amplitudes go: set $AFExportDir before running (e.g. to <workspace>/amplitudes); default ./export *)
exportDir = If[ValueQ[$AFExportDir], $AFExportDir, FileNameJoin[{scriptDir, "export"}]];


(* ---- 1. topologies and diagrams (FeynArts) -------------------------------------------------------------------- *)
(* One loop, one line in, one line out. Only fermion loops of the top quark are kept: no scalars, no Z/W, no ghosts,
   no leptons, no down-type quarks, no u and c.                                                                       *)
topos = CreateTopologies[1, 1 -> 1, ExcludeTopologies -> {Tadpoles, WFCorrections}];

diags = InsertFields[topos, {V[1]} -> {V[1]}, InsertionLevel -> {Particles},
  ExcludeParticles -> {S[_], V[2|3], U[_], F[1|2|4], F[3, {1|2}]}];

If[$FrontEnd =!= Null,
  Paint[diags, ColumnsXRows -> {1, 1}, Numbering -> Simple, SheetHeader -> None, ImageSize -> {256, 256}]];


(* ---- 2. the amplitude (FeynArts -> FeynCalc) ------------------------------------------------------------------- *)
(* Truncated: the external polarisation vectors are dropped, mu and nu stay open. D-dimensional. *)
amp0 = FCFAConvert[
  CreateFeynAmp[diags, PreFactor -> 1, Truncated -> True, GaugeRules -> {}],
  IncomingMomenta -> {k}, OutgoingMomenta -> {k}, LorentzIndexNames -> {mu, nu}, LoopMomenta -> {q},
  UndoChiralSplittings -> True, ChangeDimension -> D, DropSumOver -> True, SMP -> True];

amp1 = Nc Total[Flatten[{amp0}]];               (* DropSumOver removed the colour sum; Nc restores it *)

FCClearScalarProducts[];
ScalarProduct[k, k] = s;                         (* s = k^2: the variable the form factor is scanned in *)


(* ---- 3. Dirac algebra and tensor reduction (FeynCalc) -------------------------------------------------------- *)
amp2 = DiracSimplify[amp1];                      (* evaluates the Dirac trace of the closed fermion loop *)
amp3 = TID[amp2, q, ToPaVe -> True];             (* tensor integrals -> A0, B0 with D-dependent coefficients *)
piTensor = amp3/(2 Pi)^4/I;                      (* Pi^{mu nu}: the amplitude is i Pi^{mu nu}; (2 Pi)^-4 as explained above *)


(* ---- 4. Lorentz decomposition ---------------------------------------------------------------------------------- *)
structures = {MTD[mu, nu], FVD[k, mu] FVD[k, nu]};
{coefA, coefB} = AFLorentzCoefficients[piTensor, structures];


(* ---- 5. Ward identity and transversality ----------------------------------------------------------------------- *)
(* k_mu Pi^{mu nu} = k^nu (A + s B)  must vanish. In D dimensions A0 and B0(0,m,m) are not independent:
   B0(0,m,m) = (D-2)/(2m) A0(m).  Use it, then the residual must be zero.                                          *)
dimRelation = B0[0, m_, m_] :> (D - 2)/(2 m) A0[m];
wardResidual = Simplify[(coefA + s coefB) /. dimRelation];
If[wardResidual =!= 0, AFFail["Ward identity violated: A + s B = ", wardResidual]];
AFLog["Ward identity k_mu Pi^{mu nu} = 0 holds in D dimensions: A + s B = 0"];

(* So Pi^{mu nu} = B (k^mu k^nu - s g^{mu nu}) = (s g^{mu nu} - k^mu k^nu) Pi with Pi = -B. *)
piD = -coefB /. A0[m_] :> 2 m/(D - 2) B0[0, m, m];     (* keep B0(0,m,m), the form Denner uses *)


(* ---- 6. D -> 4 with the rational terms ----------------------------------------------------------------------------- *)
pi4 = AFLimitTo4[piD];
sigmaT = Simplify[-s pi4];
AFLog["Sigma_T(s) = ", sigmaT];
AFLog["coefficient of the UV pole Delta: ", AFPoleCoefficient[sigmaT]];


(* ---- 7. checks against the known result ---------------------------------------------------------------------------- *)
(* Denner: Sigma_T = -(alpha/4pi) (4/3) Nc Q^2 [ -(s+2m^2) B0(s,m,m) + 2 m^2 B0(0,m,m) + s/3 ].  The s dependence
   must be exactly this shape; the constant in front is printed for comparison with
   -SMP["e"]^2 Nc Q^2/(16 Pi^2)   (e^2 = 4 Pi alpha).                                                             *)
mt = SMP["m_t"];
shape = (4/3) (-(s + 2 mt^2) B0[s, mt^2, mt^2] + 2 mt^2 B0[0, mt^2, mt^2] + s/3);
AFShapeCheck["Sigma_T vs Denner", sigmaT, shape, {s}];
AFLog["expected UV pole: e^2 Nc Q^2 s/(12 Pi^2) -- compare with the line above"];


(* ---- 8. export for fc2lt ----------------------------------------------------------------------------------------------- *)
header = "Photon self-energy, fermion loop; generated by 01_photon_selfenergy.m (FeynArts + FeynCalc)";
AFExportAmplitude[FileNameJoin[{exportDir, "vacpol_ff_sigmaT.m"}], sigmaT,
  header <> ". Sigma_T(s) = -s Pi(s); input: s"];
AFExportAmplitude[FileNameJoin[{exportDir, "vacpol_ff_pi.m"}], Simplify[-sigmaT/s],
  header <> ". Pi(s); input: s"];
