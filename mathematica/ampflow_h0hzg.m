(* ::Package:: *)

(* ampflow_h0hzg.m -- process module:  H0(q) -> h0(k1) Z(k2) gamma(k3)  in the 2HDM (report.pdf).

   FeynArts       topologies, field insertion (model THDM2), Feynman amplitudes
   FeynCalc       Dirac algebra, tensor reduction to A0 B0 C0 D0
   ampflow_dual.m dual projector: form factors F1 F2 F3 without further tensor algebra

   Load AFTER FeynCalc (with the FeynArts add-on), ampflow_ff.m, ampflow_dual.m, ampflow_couplings.m and ampflow_fermion.m.
   All names start with AFH0hZg (public) or af (internal).

   ---- Flow of a run (AFH0hZgRun) ----------------------------------------------------------------------------------------
     AFH0hZgDiagrams    ALL one-loop topologies of 1 -> 3 (nothing is excluded), fields inserted, couplings made symbolic
     AFH0hZgCells       diagrams split by loop content (group) and number of loop propagators (size): the cells
     per cell:          AFH0hZgFormFactors   one amplitude per diagram -> topology class (AFH0hZgTopologyClass)
                        -> contraction with the dual projector, TID, sum per class, G^-1, D -> 4, vertices back
     export             one file per (class, group, size), per class, and the total, in the format fc2lt reads

   ---- Topology classes (arXiv:1408.2534, appendix C.4) ------------------------------------------------------------------
   Every diagram is classified from its amplitude, by the propagators that do not carry the loop momentum ("tree
   propagators"); see AFH0hZgTopologyClass. The classes replace the topology exclusions of earlier versions
   (Tadpoles, Internal, SelfEnergies, Irreducible): everything is generated once, and the class says what a diagram is.

     Irreducible          no tree propagator: triangles, boxes, and loops that close on one vertex
     Reducible:<legs>     a tree propagator carries an external momentum (<legs> = photon, Z, h0) or a sum of external
                          momenta (internal). Z-gamma mixing on the photon leg is Reducible:photon (fig. 12, diagram 3).
     Tadpole              the loop hangs on a tree propagator of zero momentum
     OnShell:<leg>        external-leg correction whose tree propagator has the leg's own mass: 1/(k^2 - m^2) = 1/0. These
                          belong to the wave-function (LSZ) factors, are counted and NOT computed.
   Counterterms are not added: by appendix C.4 the on-shell Z-gamma mixing counterterm cancels the reducible diagram with the
   photon on shell, and the vertex counterterm equals the sum of the reducible diagrams (eq. C.13).

   Status: the FeynArts-facing calls (CreateTopologies, InsertFields, LoopFields, DiagramSelect, M$CouplingMatrices) follow
   FeynCalc's examples; they have not been executed (see docs/status.md).                                                      *)


(* ---------------------------------------------------------------------------------------------------------------------
   Fields (FeynArts THDM2 numbering) and the character encoding of the model files
   --------------------------------------------------------------------------------------------------------------------- *)

AFH0hZgFields = <|"h0" -> S[1], "H0" -> S[2], "Hp" -> S[5], "Gp" -> S[6], "W" -> V[3], "Z" -> V[2], "photon" -> V[1],
  "ghost" -> U[_], "fermion" -> F[__]|>;

(* Mathematica on Windows reads model files as WindowsANSI unless told otherwise; the UTF-8 Greek letters then come out as
   "\[CapitalIHat]\.b2". Set the encoding BEFORE the first InsertFields. *)
AFH0hZgUseUTF8[] := ($CharacterEncoding = "UTF-8"; AFLog["character encoding for model files: UTF-8"]);


(* ---------------------------------------------------------------------------------------------------------------------
   Names. FeynArts' THDM names -> the notation of examples/thdm/models/thdm.model and the sample amplitude.
   (thdm.model defines the FeynArts names as well, so "ConvertNames" -> False works too.)
   --------------------------------------------------------------------------------------------------------------------- *)

AFH0hZgConvention = {
  EL -> e, SW -> Sin[Subscript[\[Theta], W]], CW -> Cos[Subscript[\[Theta], W]], MW -> Subscript[m, W], MZ -> Subscript[m, Z],
  cosW -> Cos[Subscript[\[Theta], W]], sinW -> Sin[Subscript[\[Theta], W]],
  mW -> Subscript[m, W], mt -> Subscript[m, t],
  SMP["e"] -> e, SMP["sin_W"] -> Sin[Subscript[\[Theta], W]], SMP["cos_W"] -> Cos[Subscript[\[Theta], W]],
  SMP["m_W"] -> Subscript[m, W], SMP["m_Z"] -> Subscript[m, Z], SMP["m_t"] -> Subscript[m, t],
  CAB -> Cos[\[Alpha] + \[Beta]], CBA -> Cos[\[Beta] - \[Alpha]], SAB -> Sin[\[Alpha] + \[Beta]],
  SBA -> Sin[\[Beta] - \[Alpha]], S2B -> Sin[2 \[Beta]], SA -> Sin[\[Alpha]], CA -> Cos[\[Alpha]],
  C2B -> Cos[2 \[Beta]], S2A -> Sin[2 \[Alpha]], C2A -> Cos[2 \[Alpha]], SB -> Sin[\[Beta]], CB -> Cos[\[Beta]],
  Mh0 -> Subscript[m, h], MA0 -> Subscript[m, Subscript[A, 0]], MHH -> Subscript[m, H], MHp -> Subscript[m, Hp]};

(* FeynArts' Lambda5. Read off the vertices g_hhH0, g_hH0H0 of FeynArts' THDM2 and compared with the third derivatives of the
   potential in thdm.model: FeynArts' Lambda5 enters as M^2 = Lambda5 v^2/2, while the model file uses M^2 = m_A^2 + lambda_5 v^2
   with the standard lambda_5. If the card's lambda_5 is the standard one, FeynArts' Lambda5 is 2 (m_A^2 + lambda_5 v^2)/v^2.
   AFH0hZgCheckModelCouplings decides which holds; option "Lambda5" of AFH0hZgRun selects it ("Same": the card's value goes
   in unchanged, "TwoM2OverV2": the relation above). *)
AFH0hZgVev = 2 Subscript[m, W] Sin[Subscript[\[Theta], W]]/e;
AFH0hZgLambda5Rule["Same"] = {Lambda5 -> Subscript[\[Lambda], 5]};
AFH0hZgLambda5Rule["TwoM2OverV2"] = {Lambda5 -> 2 (Subscript[m, Subscript[A, 0]]^2 + Subscript[\[Lambda], 5] AFH0hZgVev^2)/AFH0hZgVev^2};
$AFH0hZgLambda5 = "Same";

AFH0hZgNames[expr_] := (FCGVToSymbol[expr] /. AFH0hZgConvention) /. AFH0hZgLambda5Rule[$AFH0hZgLambda5];


(* ---------------------------------------------------------------------------------------------------------------------
   Model couplings. The whole coupling section is made symbolic (ampflow_couplings.m): every vertex is a symbol g_{fields},
   and the original FeynArts expressions are put back on the finished form factors (AFCouplingsRollback). The scalar
   couplings of thdm.model (g_hhH0, g_hH0H0: third derivatives of the potential, vertex = -i g) can replace FeynArts' own
   expressions for those two vertices (AFH0hZgModelMap); FeynArts' own are the default (one consistent set of conventions).
   --------------------------------------------------------------------------------------------------------------------- *)

AFH0hZgModelMap[] := {
  AFCouplingsSymbolOf[{S[1], S[1], S[2]}] -> -I Subscript[g, hhH0],
  AFCouplingsSymbolOf[{S[1], S[2], S[2]}] -> -I Subscript[g, HoldForm[Subscript[h, 0] Subscript[H, 0] Subscript[H, 0]]]};

(* thdm.model, the formulas of docs/thdm.md: {g_hhH0, g_hH0H0} *)
AFH0hZgModelCouplingValues[] := Module[{v = AFH0hZgVev, M2},
  M2 = Subscript[m, Subscript[A, 0]]^2 + Subscript[\[Lambda], 5] v^2;
  {Cos[\[Beta] - \[Alpha]]/(v Sin[2 \[Beta]]) ((2 Subscript[m, h]^2 + Subscript[m, H]^2 - 3 M2) Sin[2 \[Alpha]] + M2 Sin[2 \[Beta]]),
   -Sin[\[Beta] - \[Alpha]]/(v Sin[2 \[Beta]]) ((Subscript[m, h]^2 + 2 Subscript[m, H]^2 - 3 M2) Sin[2 \[Alpha]] - M2 Sin[2 \[Beta]])}];

(* Random point for a numerical comparison: every atom (symbol or Subscript[...]) gets a value; angles and masses in (0.3, 1.2). *)
afRandomPoint[exprs_List] := Module[{subs, syms},
  subs = DeleteDuplicates[Cases[exprs, _Subscript, {0, Infinity}]];
  subs = Reverse[SortBy[subs, LeafCount]];      (* outer Subscripts first: Subscript[m, Subscript[A, 0]] before Subscript[A, 0] *)
  syms = DeleteDuplicates[Cases[exprs /. Thread[subs -> 1], s_Symbol /; !NumericQ[s] && Context[s] =!= "System`", {0, Infinity}]];
  Join[Thread[subs -> RandomReal[{0.3, 1.2}, Length[subs]]], Thread[syms -> RandomReal[{0.3, 1.2}, Length[syms]]]]
];

(* FeynArts' g_hhH0 and g_hH0H0 against the closed forms of thdm.model: (-I g_model) must equal the vertex. Returns True or stops
   with the numbers. Run it after AFCouplingsInit[]. *)
AFH0hZgCheckModelCouplings[] := Module[{fa, mod, pt, d},
  fa = AFH0hZgNames[{AFCouplingsValue[{S[1], S[1], S[2]}], AFCouplingsValue[{S[1], S[2], S[2]}]}];
  mod = -I AFH0hZgModelCouplingValues[];
  pt = afRandomPoint[Join[fa, mod]];
  d = N[(fa - mod) /. pt, 20];
  AFLog["model couplings, FeynArts minus thdm.model at a random point: ", d, "  (Lambda5 convention: ", $AFH0hZgLambda5, ")"];
  If[!And @@ (Abs[#] < 10^-10 & /@ d),
    AFFail["FeynArts' vertices g_hhH0 / g_hH0H0 differ from thdm.model. If only Lambda5 differs, set \"Lambda5\" -> \"TwoM2OverV2\" ",
      "(FeynArts' Lambda5 = 2 M^2/v^2); otherwise one of the two has a different convention."]];
  True
];


(* ---------------------------------------------------------------------------------------------------------------------
   Diagrams: ALL one-loop topologies of 1 -> 3, no ExcludeTopologies. What a diagram is (irreducible, self-energy on a leg,
   tadpole, ...) is decided later by AFH0hZgTopologyClass, not by the topology list it came from.
   --------------------------------------------------------------------------------------------------------------------- *)

(* "Couplings":  "Symbolic"  the loaded model's couplings are made symbolic in memory (AFCouplingsApply) before the amplitudes are built
                 "Original"  FeynArts' own vertices (large amplitudes)
                 "ModelFile" the model is already the symbolic one (AFCouplingsInstallModel -> Model -> "THDM2sym"); the rollback
                             rules are read from "CouplingDir" (AFCouplingsWrite / AFCouplingsLoad) *)
Options[AFH0hZgDiagrams] = {
  "Model" -> "THDM2",
  "Restrictions" -> {NoGeneration1, NoGeneration2, NoElectronHCoupling, NoLightFHCoupling},
  "ExcludeParticles" -> {V[5], F[1], F[2], -F[1], -F[2]},
  "Couplings" -> "Symbolic",
  "CouplingDir" -> None,
  "VerifyCouplings" -> True};

AFH0hZgDiagrams[OptionsPattern[]] := Module[{f = AFH0hZgFields, mode = OptionValue["Couplings"], model = OptionValue["Model"], diagrams},
  AFRequire[];
  If[!MemberQ[{"Symbolic", "ModelFile", "Original"}, mode],
    AFFail["AFH0hZgDiagrams: \"Couplings\" must be \"Symbolic\", \"ModelFile\" or \"Original\""]];
  If[mode === "ModelFile" && OptionValue["CouplingDir"] === None,
    AFFail["\"Couplings\" -> \"ModelFile\" needs \"CouplingDir\" (files from AFCouplingsWrite)"]];

  diagrams = InsertFields[CreateTopologies[1, 1 -> 3],
    {f["H0"]} -> {{f["h0"]}, {f["Z"]}, {f["photon"]}}, InsertionLevel -> {Particles},
    Model -> model, Restrictions -> OptionValue["Restrictions"], ExcludeParticles -> OptionValue["ExcludeParticles"]];

  (* the first InsertFields loads the model, so the couplings can only be touched now *)
  Switch[mode,
    "Symbolic",  AFCouplingsInit[]; If[OptionValue["VerifyCouplings"], AFCouplingsVerify[]]; AFCouplingsApply[],
    "ModelFile", AFCouplingsLoad[OptionValue["CouplingDir"], StringReplace[model, "sym" ~~ EndOfString -> ""]],
    "Original",  Null];
  diagrams
];


(* ---------------------------------------------------------------------------------------------------------------------
   Cells. Report section 6: the diagrams are grouped by what runs in the loop and by the number of loop propagators.

     group Fermion   closed fermion loop (the top quark; any other quark the model leaves in)   (colour by SUNSimplify, ampflow_fermion.m)
           H         charged Higgs only                (gauge independent)
           HGWu      charged Higgs with W / G / ghost  (gauge dependent, mixed)
           GWu       W / G / ghost, no charged Higgs   (gauge dependent)
           Other     everything else (neutral loops, ...); kept so that the groups are a partition of ALL diagrams
     size  Single (1 propagator, A0)   Self (2)   Triangle (3)   Box (4)       (report eq. 32)

   The loop size relies on LoopFields returning one entry per loop propagator; AFH0hZgCells checks that the cells add up.
   --------------------------------------------------------------------------------------------------------------------- *)

$AFH0hZgLoopSizes = <|"Single" -> 1, "Self" -> 2, "Triangle" -> 3, "Box" -> 4|>;

afLoopHas[pat_] := Function[!FreeQ[LoopFields[##], pat]];
afLoopSize[n_Integer] := Function[Length[LoopFields[##]] === n];
afSplit[diags_, test_] := With[{sel = DiagramSelect[diags, test]}, {sel, DiagramComplement[diags, sel]}];     (* {selected, rest} *)

AFH0hZgGroups[diags_] := Module[{f = AFH0hZgFields, gaugeLike, fermion, rest, hp, hMixed, hOnly, gauge, other},
  gaugeLike = f["W"] | f["Gp"] | f["ghost"];
  {fermion, rest} = afSplit[diags, afLoopHas[f["fermion"]]];
  {hp, rest} = afSplit[rest, afLoopHas[f["Hp"]]];
  {hMixed, hOnly} = afSplit[hp, afLoopHas[gaugeLike]];
  {gauge, other} = afSplit[rest, afLoopHas[gaugeLike]];
  <|"Fermion" -> fermion, "H" -> hOnly, "HGWu" -> hMixed, "GWu" -> gauge, "Other" -> other|>
];

AFH0hZgSizes[group_] := Association[KeyValueMap[#1 -> DiagramSelect[group, afLoopSize[#2]] &, $AFH0hZgLoopSizes]];

afDiagramCount[diags_] := Length[CreateFeynAmp[diags]];

(* <|{group, size} -> <|"Diagrams" -> ..., "Count" -> n|>|>, empty cells left out. Stops if the cells do not add up to all diagrams. *)
AFH0hZgCells[diags_] := Module[{cells = <||>, groups = AFH0hZgGroups[diags], sizes, n, total},
  Do[
    sizes = AFH0hZgSizes[groups[g]];
    Do[
      n = afDiagramCount[sizes[t]];
      If[n > 0, cells[{g, t}] = <|"Diagrams" -> sizes[t], "Count" -> n|>],
      {t, Keys[sizes]}],
    {g, Keys[groups]}];
  total = afDiagramCount[diags];
  If[Total[#["Count"] & /@ Values[cells]] =!= total,
    AFFail["AFH0hZgCells: ", total, " diagrams, but the cells add up to ", Total[#["Count"] & /@ Values[cells]],
      "  -- LoopFields does not return one entry per loop propagator in this FeynArts version"]];
  AFLog["diagram census {group, size} -> count (", total, " diagrams): ", Normal[#["Count"] & /@ cells]];
  cells
];


(* ---------------------------------------------------------------------------------------------------------------------
   Topology classes
   --------------------------------------------------------------------------------------------------------------------- *)

(* external leg -> {name used in labels, mass} *)
AFH0hZgLegs = <|k1 -> {"h0", Subscript[m, h]}, k2 -> {"Z", Subscript[m, Z]}, k3 -> {"photon", 0}|>;

(* the propagators of an amplitude as {momentum, mass^2}; FeynCalc writes them as PropagatorDenominator[q, m] or, after
   FeynAmpDenominator normalisation, StandardPropagatorDenominator[q, 0, -m^2, {1, 1}] *)
afPropagators[amp_] := DeleteDuplicates[Join[
  Cases[amp, PropagatorDenominator[q_, m_] :> {q, m^2}, {0, Infinity}],
  Cases[amp, StandardPropagatorDenominator[q_, _, m2_, _] :> {q, -m2}, {0, Infinity}]]];

(* tree propagators: those without the loop momentum *)
afTreePropagators[amp_, loop_] := Select[afPropagators[amp], FreeQ[First[#], Momentum[loop, ___]] &];

afZeroMomentumQ[q_] := MatchQ[q, 0 | Momentum[0, ___]];

(* label of one tree propagator {q, m^2}: the leg whose momentum it carries ("h0", "Z", "photon"), "OnShell:<leg>" if its mass is
   the leg's own, "internal" for anything else (a sum of external momenta) *)
afTreeLabel[{q_, msq_}] := Module[{legs = DeleteDuplicates[Cases[q, Momentum[p : (k1 | k2 | k3), ___] :> p, {0, Infinity}]], leg},
  If[Length[legs] === 1 && MatchQ[q, Momentum[_, ___] | -Momentum[_, ___]],
    leg = AFH0hZgLegs[First[legs]];
    If[PossibleZeroQ[AFH0hZgNames[msq] - leg[[2]]^2], "OnShell:" <> leg[[1]], leg[[1]]],
    "internal"]];

(* amp: one FeynCalc amplitude of one diagram, loop momentum `loop`. Returns the class label described in the header:
   "Irreducible", "Tadpole", "Reducible:<legs>" (legs joined by "+"), "OnShell:<leg>". *)
AFH0hZgTopologyClass[amp_, loop_: l] := Module[{tree = afTreePropagators[amp, loop], labels, onShell},
  Which[
    tree === {}, "Irreducible",
    And @@ (afZeroMomentumQ[First[#]] & /@ tree), "Tadpole",
    True,
      labels = Sort[DeleteDuplicates[afTreeLabel /@ tree]];
      onShell = Select[labels, StringStartsQ[#, "OnShell:"] &];
      If[onShell =!= {}, First[onShell], "Reducible:" <> StringRiffle[labels, "+"]]]
];


(* ---------------------------------------------------------------------------------------------------------------------
   One cell -> form factors
   --------------------------------------------------------------------------------------------------------------------- *)

(* FeynCalc's PaVe objects -> the LoopTools-named functions. Argument orders agree (documented for FeynCalc: C0[p10, p12, p20, m0, m1, m2],
   D0[p10, p12, p23, p30, p20, p13, m0..m3], squared masses); fc2lt passes arguments through to LoopTools unchanged. *)
AFPaVeToScalar[expr_] := expr /. {
  PaVe[0, {}, {m_}, ___] :> A0[m],
  PaVe[0, {p_}, {m1_, m2_}, ___] :> B0[p, m1, m2],
  PaVe[0, {p1_, p2_, p3_}, {m1_, m2_, m3_}, ___] :> C0[p1, p2, p3, m1, m2, m3],
  PaVe[0, {p1_, p2_, p3_, p4_, p5_, p6_}, {m1_, m2_, m3_, m4_}, ___] :> D0[p1, p2, p3, p4, p5, p6, m1, m2, m3, m4]};

(* one FeynCalc amplitude per diagram: momenta k1, k2, k3, open indices mu, nu, divided by (2 Pi)^4 I *)
afH0hZgAmps[amps_] := Module[{amp0},
  amp0 = FCFAConvert[amps, IncomingMomenta -> {qH}, OutgoingMomenta -> {k1, k2, k3},
    LorentzIndexNames -> {mu, nu, rho, sigma, delta, lambda}, LoopMomenta -> {l}, UndoChiralSplittings -> True,
    ChangeDimension -> D, DropSumOver -> True, SMP -> True, List -> True,
    SUNIndexNames -> {a1, b1, c1, d1, f1, e1, g1, h1}, SUNFIndexNames -> {w1, v1, z1, x1, m1, n1, q1, r1}];
  (FCReplaceMomenta[#, {qH -> k1 + k2 + k3}] & /@ amp0)/((2 Pi)^4 I)
];

(* the fermion group of a set of diagrams through several gamma5 schemes (see AFFermionSchemeCheck) *)
AFH0hZgFermionSchemeCheck[diags_, schemes_List : {"NDR", "Larin"}, gaugeRules_ : {GaugeXi[_] -> 1}] :=
  AFFermionSchemeCheck[afH0hZgAmps[CreateFeynAmp[diags, PreFactor -> 1, Truncated -> True, GaugeRules -> gaugeRules]], mu, nu, l, schemes];

(* raw projection (PaVe, D symbolic, original FeynArts names) -> finished form factors {F1, F2, F3}; o: the option values *)
afFinish[raw_, o_Association] := Module[{f = raw, pole},
  If[o["ConvertNames"], f = AFH0hZgNames[f]];
  f = AFDualGramInverse[] . f;
  f = AFLimitTo4[AFPaVeToScalar[#]] & /@ f;
  If[o["UseDelta"], f = AFPutDelta /@ f];
  pole = AFPoleCoefficient /@ f;                     (* with the g symbols still in: short *)
  If[o["RollBack"] && AssociationQ[AFCouplings],
    f = AFCouplingsRollback[#, "Keep" -> o["KeepCouplings"], "Map" -> o["MapCouplings"]] & /@ f;
    If[o["ConvertNames"], f = AFH0hZgNames /@ f]];
  <|"F" -> f, "Pole" -> pole|>
];

Options[AFH0hZgFormFactors] = {
  "GaugeRules" -> {GaugeXi[_] -> 1},      (* Feynman gauge, as in the report (R_xi, xi = 1) *)
  "ConvertNames" -> True,
  "UseDelta" -> True,
  "RollBack" -> True,                     (* put the original vertices back (False: keep the g symbols, e.g. for inspection) *)
  "KeepCouplings" -> {},                  (* coupling symbols not rolled back *)
  "MapCouplings" -> {},                   (* substitutions for chosen coupling symbols (AFH0hZgModelMap[]) *)
  "Fermion" -> False,                     (* closed fermion loop: colour by SUNSimplify, traces and gamma5 by ampflow_fermion.m *)
  "Scheme" -> "NDR"};                     (* gamma5 scheme for the traces: "NDR", "Larin" or "BMHV" *)

(* diags: FeynArts diagrams of ONE cell. Every diagram goes through the same steps: contract with the three CP-even vectors,
   TID the scalar functions, sum per topology class; G^-1 once per class; D -> 4; the vertices back. Diagrams of the OnShell
   classes are counted and left out.
   Returns <|"n" -> diagrams, "F" -> {F1, F2, F3} (all classes), "Pole", "Couplings", "Skipped" -> <|class -> count|>,
             "ByClass" -> <|class -> <|"n", "F", "Pole"|>|>|>, or None for an empty cell. *)
AFH0hZgFormFactors[diags_, OptionsPattern[]] := Module[{o, amps, n, labels, isOnShell, keptAmps, keptLabels, raws, byClass, res},
  o = Association[Table[name -> OptionValue[name], {name, Keys[Association[Options[AFH0hZgFormFactors]]]}]];
  amps = CreateFeynAmp[diags, PreFactor -> 1, Truncated -> True, GaugeRules -> o["GaugeRules"]];
  n = Length[amps];
  If[n === 0, Return[None]];

  amps = afH0hZgAmps[amps];
  labels = AFH0hZgTopologyClass /@ amps;
  AFLog["topology classes of ", n, " diagrams: ", Normal[Counts[labels]]];
  AFLog["tree propagators {class, mass^2}: ",
    DeleteDuplicates[Join @@ MapThread[Function[{amp, class}, {class, AFH0hZgNames[Last[#]]} & /@ afTreePropagators[amp, l]], {amps, labels}]]];

  isOnShell = StringStartsQ[#, "OnShell"] & /@ labels;
  keptAmps = Pick[amps, isOnShell, False];
  keptLabels = Pick[labels, isOnShell, False];
  If[keptAmps === {},
    Return[<|"n" -> n, "F" -> {0, 0, 0}, "Pole" -> {0, 0, 0}, "Couplings" -> {}, "ByClass" -> <||>, "Skipped" -> Counts[labels]|>]];

  raws = If[o["Fermion"],
    AFFermionProjectRawList[keptAmps, mu, nu, l, "Scheme" -> o["Scheme"]],     (* colour, traces, gamma5, eps drop, TID *)
    AFDualProjectLoopRaw[#, mu, nu, l] & /@ keptAmps];                         (* bosonic loops: no trace, no eps *)
  byClass = Total /@ GroupBy[Transpose[{keptLabels, raws}], First -> Last];

  res = Association[KeyValueMap[#1 -> Append[afFinish[#2, o], "n" -> Count[keptLabels, #1]] &, byClass]];
  <|"n" -> n,
    "F" -> Total[#["F"] & /@ Values[res]],
    "Pole" -> Total[#["Pole"] & /@ Values[res]],
    "Couplings" -> If[AssociationQ[AFCouplings], AFCouplingsInventory[raws], {}],
    "Skipped" -> Counts[Pick[labels, isOnShell]],
    "ByClass" -> res|>
];


(* ---------------------------------------------------------------------------------------------------------------------
   Run
   --------------------------------------------------------------------------------------------------------------------- *)

(* |pole| / (sum of |terms|) at a random point; 0 for an identically vanishing pole. *)
afPoleSize[p_] := Module[{base, rest, terms, vals},
  If[PossibleZeroQ[p], Return[0]];
  base = Thread[{a, b, c, x, y} -> RandomReal[{0.3, 1.2}, 5]];
  base = Append[base, \[CapitalDelta] -> (AFDualDeltaPoly /. base)];
  rest = afRandomPoint[{p /. base}];
  terms = If[Head[Expand[p]] === Plus, List @@ Expand[p], {p}];
  vals = N[terms /. Join[base, rest], 25];
  Abs[Total[vals]]/Max[Total[Abs[vals]], 10^-300]
];

(* res: <|{group, size} -> AFH0hZgFormFactors result|>  ->  <|{class, group, size} -> {F1, F2, F3}|> *)
afClassCells[res_Association] := Association @ Flatten @ KeyValueMap[
  Function[{cell, r}, KeyValueMap[Function[{class, v}, Prepend[cell, class] -> v["F"]], r["ByClass"]]], res];

(* the cells in the selection, form factors per cell; returns {res, timings}. Timing rows: {group, size, cell diagrams, used, s, estimated cell s}. *)
afRunCells[cells_Association, groups_, sizes_, trial_, ffOpts_List] := Module[{res = <||>, timings = {}, g, t, cnt, used, sel, tm, r},
  Do[
    {g, t} = cell;
    If[(groups =!= All && !MemberQ[groups, g]) || (sizes =!= All && !MemberQ[sizes, t]), Continue[]];
    cnt = cells[cell]["Count"];
    used = If[trial === None, cnt, Min[trial, cnt]];
    sel = If[trial === None, cells[cell]["Diagrams"], DiagramExtract[cells[cell]["Diagrams"], Range[used]]];
    {tm, r} = AbsoluteTiming[AFH0hZgFormFactors[sel, "Fermion" -> (g === "Fermion"), Sequence @@ ffOpts]];
    If[r === None, Continue[]];
    res[cell] = r;
    AppendTo[timings, {g, t, cnt, used, Round[tm], Round[tm cnt/used]}];
    AFLog[g, "/", t, ": ", used, " of ", cnt, " diagrams in ", Round[tm], " s; classes ", Normal[#["n"] & /@ r["ByClass"]],
      "; not computed ", Normal[r["Skipped"]], "; UV pole of F1..F3 ", r["Pole"], "; terms in F1..F3: ", LeafCount /@ r["F"]],
    {cell, Keys[cells]}];
  {res, timings}
];

afLogClasses[res_Association] := Module[{computed, skipped},
  computed = Merge[Function[r, #["n"] & /@ r["ByClass"]] /@ Values[res], Total];
  skipped = Merge[#["Skipped"] & /@ Values[res], Total];
  AFLog["diagrams per topology class: ", Normal[computed]];
  If[Length[skipped] > 0,
    AFLog["NOT computed (external-leg corrections with the leg's own propagator on shell; they belong to the wave-function factors): ", Normal[skipped]]];
  If[MemberQ[Keys[afClassCells[res]], {"Irreducible", _, "Single"}],
    AFLog["WARNING: one-propagator loops are classified Irreducible: contact loops, or tadpoles whose zero-momentum line is not visible in the amplitude; inspect them with Paint"]];
];

afH0hZgHeader[what_String, i_Integer, trial_] := "H0 -> h0 Z gamma, " <> what <>
  If[trial === None, "", " (TRIAL: first " <> ToString[trial] <> " diagrams per cell)"] <>
  "; generated by ampflow_h0hzg.m. Form factor F" <> ToString[i] <> " (coefficient of structure P" <> ToString[i] <>
  ", see ampflow_dual.m); inputs: a b (c x y Delta from the model)";

(* h0hzg_<parts joined by _>_F<i>.m ; ":" and "+" of the class labels become "_" *)
afH0hZgFile[dir_String, parts_List, i_Integer] :=
  FileNameJoin[{dir, StringRiffle[Join[{"h0hzg"}, StringReplace[parts, {":" -> "_", "+" -> "_"}]], "_"] <> "_F" <> ToString[i] <> ".m"}];

afExportForms[dir_String, parts_List, what_String, F_List, trial_] :=
  Do[AFExportAmplitude[afH0hZgFile[dir, parts, i], F[[i]], afH0hZgHeader[what, i, trial]], {i, 3}];

(* files per (class, group, size) and per class *)
afExportCells[dir_String, res_Association, trial_] := Module[{cells = afClassCells[res], byClass},
  KeyValueMap[afExportForms[dir, #1, #1[[1]] <> " / " <> #1[[2]] <> " loops / " <> #1[[3]], #2, trial] &, cells];
  byClass = Total /@ GroupBy[Normal[cells], (First[First[#]] &) -> Last];
  KeyValueMap[afExportForms[dir, {#1}, #1 <> ", all loop groups", #2, trial] &, byClass];
];

Options[AFH0hZgRun] = Join[Options[AFH0hZgDiagrams], Options[AFH0hZgFormFactors],
  {"ExportDir" -> Automatic, "PerGroup" -> True, "Groups" -> All, "Sizes" -> All, "Lambda5" -> "Same",
   "CheckModelCouplings" -> True, "UseModelCouplings" -> False,
   (* "Trial" -> n: only the first n diagrams of every cell, exported to <ExportDir>/trial, with a timing table and an estimate of the
      full run. No sum over classes, no UV test (they need all diagrams). *)
   "Trial" -> None}];

(* Full run: <|{group, size} -> AFH0hZgFormFactors result, ..., "Total" -> {F1, F2, F3}|> and writes
     <dir>/h0hzg_<class>_<group>_<size>_F<i>.m   one per class, loop group and size (i = 1..3; "PerGroup" -> False leaves these out)
     <dir>/h0hzg_<class>_F<i>.m                  the sum over groups and sizes of one class
     <dir>/h0hzg_F<i>.m                          the sum over everything that was computed
   Trial run: the same cells with the first n diagrams, files in <dir>/trial, and "Timings" -> rows {group, size, cell diagrams, used, s, estimated cell s}. *)
AFH0hZgRun[opts : OptionsPattern[]] := Module[{trial = OptionValue["Trial"], diags, cells, dir, res, timings, total, pole},
  AFH0hZgUseUTF8[];
  $AFH0hZgLambda5 = OptionValue["Lambda5"];
  diags = AFH0hZgDiagrams[FilterRules[{opts}, Options[AFH0hZgDiagrams]]];
  If[AssociationQ[AFCouplings] && OptionValue["CheckModelCouplings"], AFH0hZgCheckModelCouplings[]];
  cells = AFH0hZgCells[diags];

  dir = OptionValue["ExportDir"];
  If[dir === Automatic, dir = If[ValueQ[$AFExportDir], $AFExportDir, FileNameJoin[{Directory[], "export"}]]];
  If[trial =!= None, dir = FileNameJoin[{dir, "trial"}]; AFLog["TRIAL RUN: first ", trial, " diagram(s) per cell, files in ", dir]];

  {res, timings} = afRunCells[cells, OptionValue["Groups"], OptionValue["Sizes"], trial,
    Join[If[OptionValue["UseModelCouplings"], {"MapCouplings" -> AFH0hZgModelMap[]}, {}], FilterRules[{opts}, Options[AFH0hZgFormFactors]]]];
  If[Length[res] === 0, AFFail["AFH0hZgRun: no diagrams survived the selection"]];
  afLogClasses[res];

  If[trial =!= None,
    afExportCells[dir, res, trial];                   (* the export guard checks symbols and heads: problems show up here, early *)
    AFLog["trial timings {group, size, cell diagrams, used, seconds, estimated cell seconds}: ", timings];
    AFLog["estimated time of the full run: about ", Round[Total[timings[[All, 6]]]/60], " min (diagram times vary; the box cells dominate)"];
    Return[Append[res, <|"Timings" -> timings|>]]];

  (* UV finiteness of the sum (report: the pole cancels once the gauge couplings of eq. 39 hold; here every vertex is FeynArts' own,
     so it is a numerical test at random parameter points: the pole coefficient against the size of its terms) *)
  total = Total[#["F"] & /@ Values[res]];
  pole = AFPoleCoefficient /@ total;
  AFLog["UV pole of the total F1..F3, relative size at a random point (must be ~1e-15): ", afPoleSize /@ pole];
  If[Max[afPoleSize /@ pole] > 10^-8,
    AFLog["WARNING: the total is not UV finite: a diagram class is missing, or the couplings do not obey the relations of the report"]];

  If[OptionValue["PerGroup"], afExportCells[dir, res, None]];
  afExportForms[dir, {}, "all classes", total, None];
  Append[res, <|"Total" -> total|>]
];
