(* ::Package:: *)

(* ampflow_h0hzg.m -- process module:  H0(q) -> h0(k1) Z(k2) gamma(k3)  in the 2HDM (report.pdf).

   FeynArts       topologies, field insertion (model THDM2), Feynman amplitudes
   FeynCalc       Dirac algebra, tensor reduction to A0 B0 C0 D0
   ampflow_dual.m dual projector: form factors F1 F2 F3 without further tensor algebra

   This file: the physics of the process (names, model check, diagrams, groups, topology classes) and the computation of ONE
   diagram. The long run over all diagrams (checkpoints, resume, export) is ampflow_h0hzg_run.m.
   Load AFTER FeynCalc (with the FeynArts add-on), ampflow_ff.m, ampflow_dual.m, ampflow_couplings.m and ampflow_fermion.m.
   All names start with AFH0hZg (public) or af (internal).

   ---- What one diagram goes through (AFH0hZgDiagramLinear) -------------------------------------------------------------
     amplitude (FeynArts, symbolic vertices) -> FeynCalc -> topology class -> contraction with the three CP-even vectors of
     the dual projector -> TID to A0 B0 C0 D0 -> names -> linear form over the scalar integrals.
   The linear form is what is saved per diagram. Everything after it (sum over diagrams, G^-1, D -> 4, vertices back) works on
   coefficients; see ampflow_h0hzg_run.m.

   ---- Topologies and classes (arXiv:1408.2534, appendix C.4) -------------------------------------------------------------
   ALL one-loop topologies of 1 -> 3 are generated (nothing excluded); FeynArts itself drops what the model does not allow at
   the field insertion. Each diagram is classified from its amplitude by its tree propagators (those without the loop momentum):

     Irreducible          no tree propagator: triangles, boxes, loops that close on one vertex
     Reducible:photon     the tree propagator carries k3   (Z-gamma mixing on the photon leg, fig. 12 diagram 3)
     Reducible:Z          ... carries k2
     Reducible:h0         ... carries k1
     Reducible:none       tree propagators, none of them an external leg (tadpoles, internal self-energies, ...)
     Reducible:multiple   tree propagators on more than one external leg
     OnShell:<leg>        a tree propagator on the leg k_i with the leg's own mass: 1/(k_i^2 - m^2) is singular at the physical
                          point. FLAGGED as a group of its own, computed like the others; the singularity is for the
                          amplitude writer / C++ side. Not part of the default total.
   Counterterms are not added: by C.4 the on-shell Z-gamma mixing counterterm cancels the reducible diagram with the photon
   on shell, and the vertex counterterm equals the sum of the reducible diagrams (eq. C.13).

   Status: the FeynArts-facing calls (CreateTopologies, InsertFields, LoopFields, DiagramSelect, M$CouplingMatrices) follow
   FeynCalc's examples; they have not been executed (see docs/status.md).                                                      *)


(* ---------------------------------------------------------------------------------------------------------------------
   Fields (FeynArts THDM numbering) and the character encoding of the model files
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

(* FeynArts' Lambda5. Read off the vertices g_hhH0, g_hH0H0 of FeynArts' THDM and compared with the third derivatives of the
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
   Diagrams: ALL one-loop topologies of 1 -> 3, no ExcludeTopologies. What a diagram is (irreducible, reducible, ...) is decided
   afterwards by AFH0hZgTopologyClass, not by the topology list it came from.
   --------------------------------------------------------------------------------------------------------------------- *)

(* "Couplings":  "Symbolic"  the loaded model's couplings are made symbolic in memory (AFCouplingsApply) before the amplitudes are built
                 "Original"  FeynArts' own vertices (large amplitudes)
                 "ModelFile" the model is already the symbolic one (AFCouplingsInstallModel -> Model -> "THDMsym"); the rollback
                             rules are read from "CouplingFile" (AFCouplingsSave) *)
Options[AFH0hZgDiagrams] = {
  "Model" -> "THDM",
  "Restrictions" -> {NoGeneration1, NoGeneration2, NoElectronHCoupling, NoLightFHCoupling},
  "ExcludeParticles" -> {V[5], F[1], F[2], -F[1], -F[2]},
  "Couplings" -> "Symbolic",
  "CouplingFile" -> None,
  "VerifyCouplings" -> True};

AFH0hZgDiagrams[opts___] := Module[{cfg = AFOptions[AFH0hZgDiagrams, {opts}], f = AFH0hZgFields, diagrams, topologies, insert},
  AFRequire[];
  If[!MemberQ[{"Symbolic", "InMemory", "ModelFile", "Original"}, cfg["Couplings"]],
    AFFail["AFH0hZgDiagrams: \"Couplings\" must be \"Symbolic\", \"InMemory\", \"ModelFile\" or \"Original\""]];
  If[cfg["Couplings"] === "ModelFile" && cfg["CouplingFile"] === None,
    AFFail["\"Couplings\" -> \"ModelFile\" needs \"CouplingFile\" (written by AFCouplingsSave)"]];

  topologies = CreateTopologies[1, 1 -> 3];
  insert[model_String] := InsertFields[topologies,
    {f["H0"]} -> {{f["h0"]}, {f["Z"]}, {f["photon"]}}, InsertionLevel -> {Particles},
    Model -> model, Restrictions -> cfg["Restrictions"], ExcludeParticles -> cfg["ExcludeParticles"]];

  diagrams = insert[cfg["Model"]];       (* the first InsertFields loads the model, so its couplings can only be read now *)

  (* "Symbolic": FeynArts reads M$CouplingMatrices when the model is initialised, so changing it in memory afterwards does not reach
     CreateFeynAmp (the amplitudes then carry the full expressions: that is what the first trial run showed). The symbolic section is
     therefore written to <Model>sym.mod (AFCouplingsInstallModel) and the diagrams are inserted again with that model.
     "InMemory": the old way (AFCouplingsApply), kept for comparison. *)
  Switch[cfg["Couplings"],
    "Symbolic",  AFCouplingsInit[]; If[cfg["VerifyCouplings"], AFCouplingsVerify[]];
                 AFCouplingsInstallModel[cfg["Model"], cfg["Model"] <> "sym"];
                 diagrams = insert[cfg["Model"] <> "sym"];
                 AFLog["diagrams inserted with the model ", cfg["Model"] <> "sym", " (symbolic couplings)"],
    "InMemory",  AFCouplingsInit[]; If[cfg["VerifyCouplings"], AFCouplingsVerify[]]; AFCouplingsApply[],
    "ModelFile", AFCouplingsLoad[cfg["CouplingFile"]],
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
     size  Single (1 loop propagator, A0)   Self (2)   Triangle (3)   Box (4)       (report eq. 32)

   A cell is one (group, size): <|"Diagrams" -> FeynArts diagrams, "Count" -> n|>. The loop size relies on LoopFields returning
   one entry per loop propagator; AFH0hZgSizes stops if a diagram fits no size.
   --------------------------------------------------------------------------------------------------------------------- *)

$AFH0hZgLoopSizes = <|"Single" -> 1, "Self" -> 2, "Triangle" -> 3, "Box" -> 4|>;

afLoopHas[pat_] := Function[!FreeQ[LoopFields[##], pat]];
afLoopSize[n_Integer] := Function[Length[LoopFields[##]] === n];
afSplit[diags_, test_] := With[{sel = DiagramSelect[diags, test]}, {sel, DiagramComplement[diags, sel]}];     (* {selected, rest} *)
afDiagramCount[diags_] := Length[CreateFeynAmp[diags]];

AFH0hZgGroups[diags_] := Module[{f = AFH0hZgFields, gaugeLike, fermion, rest, hp, hMixed, hOnly, gauge, other},
  gaugeLike = f["W"] | f["Gp"] | f["ghost"];
  {fermion, rest} = afSplit[diags, afLoopHas[f["fermion"]]];
  {hp, rest} = afSplit[rest, afLoopHas[f["Hp"]]];
  {hMixed, hOnly} = afSplit[hp, afLoopHas[gaugeLike]];
  {gauge, other} = afSplit[rest, afLoopHas[gaugeLike]];
  <|"Fermion" -> fermion, "H" -> hOnly, "HGWu" -> hMixed, "GWu" -> gauge, "Other" -> other|>
];

AFH0hZgSizes[group_] := Module[{sizes = <||>, rest = group},
  KeyValueMap[Function[{name, n}, {sizes[name], rest} = afSplit[rest, afLoopSize[n]]], $AFH0hZgLoopSizes];
  If[afDiagramCount[rest] > 0,
    AFFail["AFH0hZgSizes: diagrams with other than 1 to 4 loop propagators (LoopFields does not mean what is assumed in this FeynArts version)"]];
  sizes
];

(* <|{group, size} -> <|"Diagrams", "Count"|>|>, empty cells left out *)
AFH0hZgCells[diags_] := Module[{cells = <||>, groups = AFH0hZgGroups[diags], sizes, n},
  Do[
    sizes = AFH0hZgSizes[groups[g]];
    Do[
      n = afDiagramCount[sizes[t]];
      If[n > 0, cells[{g, t}] = <|"Diagrams" -> sizes[t], "Count" -> n|>],
      {t, Keys[sizes]}],
    {g, Keys[groups]}];
  AFLog["diagram census {group, size} -> count (", Total[#["Count"] & /@ Values[cells]], " diagrams): ", Normal[#["Count"] & /@ cells]];
  (* the cells are a partition of ALL diagrams: nothing missing, nothing counted twice *)
  With[{total = afDiagramCount[diags], inCells = Total[#["Count"] & /@ Values[cells]]},
    If[total =!= inCells,
      AFFail["census: FeynArts has ", total, " diagrams but the cells (group x size) hold ", inCells, " -- a diagram is missing or counted twice"],
      AFLog["census OK: all ", total, " diagrams are in exactly one cell"]]];
  cells
];


(* ---------------------------------------------------------------------------------------------------------------------
   Topology class of one diagram (see the header)
   --------------------------------------------------------------------------------------------------------------------- *)

(* external leg -> {name used in labels, mass} *)
AFH0hZgLegs = <|k1 -> {"h0", Subscript[m, h]}, k2 -> {"Z", Subscript[m, Z]}, k3 -> {"photon", 0}|>;

(* the propagators of an amplitude as {momentum, mass^2}; FeynCalc writes them as PropagatorDenominator[q, m] or as
   StandardPropagatorDenominator[q, 0, -m^2, {1, 1}] *)
afPropagators[amp_] := DeleteDuplicates[Join[
  Cases[amp, PropagatorDenominator[q_, m_] :> {q, m^2}, {0, Infinity}],
  Cases[amp, StandardPropagatorDenominator[q_, _, m2_, _] :> {q, -m2}, {0, Infinity}]]];

(* tree propagators: those without the loop momentum *)
afTreePropagators[amp_, loop_] := Select[afPropagators[amp], FreeQ[First[#], Momentum[loop, ___]] &];

(* the external leg whose momentum q is (up to a sign), else None *)
afLegOf[q_] := Replace[q, {Momentum[p : (k1 | k2 | k3), ___] :> p, -Momentum[p : (k1 | k2 | k3), ___] :> p, _ -> None}];

(* amp: one FeynCalc amplitude of one diagram. Returns one of the labels of the header. *)
AFH0hZgTopologyClass[amp_, loop_ : l] := Module[{tree, onLegs, legs, leg, name, mass},
  tree = afTreePropagators[amp, loop];
  If[tree === {}, Return["Irreducible"]];
  onLegs = Select[{afLegOf[First[#]], Last[#]} & /@ tree, First[#] =!= None &];     (* {leg, mass^2} *)
  legs = DeleteDuplicates[First /@ onLegs];
  Which[
    legs === {}, "Reducible:none",
    Length[legs] > 1, "Reducible:multiple",
    True,
      {name, mass} = AFH0hZgLegs[First[legs]];
      If[AnyTrue[Last /@ onLegs, PossibleZeroQ[AFH0hZgNames[#] - mass^2] &], "OnShell:" <> name, "Reducible:" <> name]]
];


(* ---------------------------------------------------------------------------------------------------------------------
   One diagram
   --------------------------------------------------------------------------------------------------------------------- *)

(* FeynCalc's PaVe objects -> the LoopTools-named functions. Argument orders agree (documented for FeynCalc: C0[p10, p12, p20, m0, m1, m2],
   D0[p10, p12, p23, p30, p20, p13, m0..m3], squared masses); fc2lt passes arguments through to LoopTools unchanged. *)
AFPaVeToScalar[expr_] := expr /. {
  PaVe[0, {}, {m_}, ___] :> A0[m],
  PaVe[0, {p_}, {m1_, m2_}, ___] :> B0[p, m1, m2],
  PaVe[0, {p1_, p2_, p3_}, {m1_, m2_, m3_}, ___] :> C0[p1, p2, p3, m1, m2, m3],
  PaVe[0, {p1_, p2_, p3_, p4_, p5_, p6_}, {m1_, m2_, m3_, m4_}, ___] :> D0[p1, p2, p3, p4, p5, p6, m1, m2, m3, m4]};

(* FeynArts amplitude(s) -> FeynCalc: momenta k1, k2, k3, open indices mu, nu, divided by (2 Pi)^4 I. Returns a list. *)
afH0hZgAmps[feynArtsAmps_, gaugeRules_ : {GaugeXi[_] -> 1}] := Module[{amps},
  amps = FCFAConvert[feynArtsAmps, IncomingMomenta -> {qH}, OutgoingMomenta -> {k1, k2, k3},
    LorentzIndexNames -> {mu, nu, rho, sigma, delta, lambda}, LoopMomenta -> {l}, UndoChiralSplittings -> True,
    ChangeDimension -> D, DropSumOver -> True, SMP -> True, List -> True,
    SUNIndexNames -> {a1, b1, c1, d1, f1, e1, g1, h1}, SUNFIndexNames -> {w1, v1, z1, x1, m1, n1, q1, r1}];
  (* GaugeXi[S[1]] etc. survive CreateFeynAmp's GaugeRules inside the propagator masses: apply the rules once more *)
  ((FCReplaceMomenta[#, {qH -> k1 + k2 + k3}] & /@ amps) /. gaugeRules)/((2 Pi)^4 I)
];

(* The part of a diagram that costs time. feynArtsAmp: CreateFeynAmp of ONE diagram (PreFactor -> 1, Truncated -> True).
   cfg: "ConvertNames", "Scheme". Returns <|"Class" -> label, "Lin" -> linear form of {Pi_1.A, Pi_2.A, Pi_3.A}|>: PaVe reduced
   to A0 B0 C0 D0, D symbolic, thdm names, vertices still the symbols g_{...}. *)
(* The coupling symbols g_{fields}[generation] are headed expressions; FCLoopIntegralToPropagators (inside ApartFF and TID) could not
   extract the propagators from an expression containing them. While FeynCalc works they are plain atoms AFg$n. *)
afFreezeCouplings[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, s : (Subscript[g, _Row, ___][___] | Subscript[g, _Row, ___]) :> s, {0, Infinity}]];
  syms = SortBy[syms, -LeafCount[#] &];
  rules = MapIndexed[#1 -> Symbol["AFg$" <> ToString[First[#2]]] &, syms];
  {expr /. rules, Reverse /@ rules}];

AFH0hZgDiagramLinear[feynArtsAmp_, group_String, cfg_Association] := Module[{amp, class, raw, left, hasSymbols, allZero, back},
  amp = AFStep["FCFAConvert", First[afH0hZgAmps[feynArtsAmp, cfg["GaugeRules"]]]];
  {amp, back} = afFreezeCouplings[amp];
  AFLogV["coupling symbols frozen: ", Length[back]];
  class = AFH0hZgTopologyClass[amp];
  AFLogV["class ", class, ", amplitude leaves: ", LeafCount[amp]];
  raw = If[group === "Fermion",
    AFFermionProjectRaw[amp, mu, nu, l, "Scheme" -> cfg["Scheme"]],     (* colour, TRACES, gamma5, eps drop, ApartFF, TID *)
    AFDualProjectLoopRaw[amp, mu, nu, l]];                              (* bosonic loops: no trace, no eps *)
  If[cfg["ConvertNames"], raw = AFStep["names", AFH0hZgNames[raw]]];
  raw = AFStep["kin, PaVe", AFPaVeToScalar[AFDualKin[raw]]] /. back;
  If[!FreeQ[raw, _PaVe], AFFail["a PaVe function with indices is left after TID (only A0 B0 C0 D0 are handled)"]];

  (* guards: nothing but the scalar integrals, the parameters and the coupling symbols may be left *)
  left = AFLeftovers[raw];
  If[left =!= {}, AFFail["stage 1 result still contains ", left, " (an algebra step did not act; run it with VERBOSE=2)"]];
  hasSymbols = !FreeQ[raw, Subscript[g, _Row, ___]];
  allZero = And @@ (# === 0 & /@ Flatten[{raw}]);
  If[MemberQ[{"Symbolic", "ModelFile"}, cfg["Couplings"]] && !hasSymbols && !allZero,
    AFFail["the amplitude carries no coupling symbols g_{...} although \"Couplings\" is ", cfg["Couplings"],
      ": the model with symbolic couplings was not used"]];
  If[allZero, AFLog["  WARNING: the projection of this diagram is identically zero (", class, ")"]];
  <|"Class" -> class, "Lin" -> AFLinearForm[raw]|>
];

(* A sum of diagrams (linear form of the raw projections) -> the form factors {F1, F2, F3} as a linear form:
     G^-1 on the coefficient vectors, D -> 4 with the rational terms, Delta factored, vertices back, names.
   Every step works on one coefficient at a time. cfg: "UseDelta", "RollBack", "ConvertNames", "KeepCouplings", "MapCouplings". *)
AFH0hZgFinish[lin_Association, cfg_Association] := Module[{f = lin},
  f = AFStep["G^-1", (AFDualGramInverse[] . #) & /@ f];
  f = AFStep["D -> 4", AFLinearTo4[f]["Lin"]];
  If[cfg["UseDelta"], f = AFStep["Delta", Map[AFPutDelta, f, {2}]]];
  If[cfg["RollBack"] && AssociationQ[AFCouplings],
    f = AFStep["couplings back", Map[AFCouplingsRollback[#, "Keep" -> cfg["KeepCouplings"], "Map" -> cfg["MapCouplings"]] &, f, {2}]];
    If[cfg["ConvertNames"], f = Map[AFH0hZgNames, f, {2}]]];
  f
];

(* the fermion group of a set of diagrams through several gamma5 schemes (see AFFermionSchemeCheck) *)
AFH0hZgFermionSchemeCheck[diags_, schemes_List : {"NDR", "Larin"}, gaugeRules_ : {GaugeXi[_] -> 1}] :=
  AFFermionSchemeCheck[afH0hZgAmps[CreateFeynAmp[diags, PreFactor -> 1, Truncated -> True, GaugeRules -> gaugeRules], gaugeRules], mu, nu, l, schemes];
