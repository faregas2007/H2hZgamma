(* ::Package:: *)

(* ampflow_couplings.m -- the coupling section of a FeynArts model as symbols g_{fields}, and back.

   Why. The vertex expressions of a FeynArts model (M$CouplingMatrices) are long functions of the mixing angles and masses. An
   amplitude that carries them is huge and hard to read. With every vertex a symbol  g_{fields}  the amplitude stays small (the
   diagram shows which vertex enters where); the original expressions are put back once, on the finished coefficients.

   Use, after the model is loaded (the first InsertFields loads it):

     AFCouplingsInit[]             build the symbolic section and the rollback rules from M$CouplingMatrices
     AFCouplingsVerify[]           exact check: symbolic section /. rollback == original, entry by entry
     AFCouplingsApply[]            M$CouplingMatrices = symbolic section      (AFCouplingsRestore[]: the original again)
     ... CreateFeynAmp, TID, projection ...
     AFCouplingsRollback[expr]     the original vertices back (options "Keep": symbols to leave, "Map": symbols to replace first)

     AFCouplingsSave[file] / AFCouplingsLoad[file]    keep the rollback rules in one file, for a later session
     AFCouplingsInstallModel[]     write THDMsym.mod = THDM.mod with the symbolic section (Model -> "THDMsym")

   Naming. The vertex of the fields (a, b, c) is  Subscript[g, Row[{a, b, c}]]  with the names of AFCouplingFieldNames; an
   antiparticle is -name:  h0 H+ H-  ->  g_{h0 H (-H)}. A coupling matrix with several non-zero entries (left/right-handed,
   several Lorentz structures) gets one symbol per entry, Subscript[g, Row[{a, b, c}], Row[{row, col}]]. Numbers stay numbers.

   Flavour and colour. IndexDelta and CKM factors stay OUTSIDE the symbol, so FeynCalc still sums the colour index and contracts
   the flavour deltas. The symbol takes the free index variables of what is left as arguments, g_{...}[j1, o1], and its rollback is
   the pattern rule g_{...}[j1_, o1_] :> expression.                                                                         *)


(* ---------------------------------------------------------------------------------------------------------------------
   1. Names
   --------------------------------------------------------------------------------------------------------------------- *)

(* FeynArts field -> name in the notation of the report / thdm.model (THDM2 numbering) *)
AFCouplingFieldNames = <|
  F[1] -> \[Nu], F[2] -> l, F[3] -> u, F[4] -> d,
  V[1] -> \[Gamma], V[2] -> Z, V[3] -> W,
  S[1] -> Subscript[h, 0], S[2] -> Subscript[H, 0], S[3] -> Subscript[A, 0], S[4] -> Subscript[G, 0], S[5] -> H, S[6] -> G,
  U[1] -> Subscript[u, \[Gamma]], U[2] -> Subscript[u, Z], U[3] -> Subscript[u, "-"], U[4] -> Subscript[u, "+"]|>;

$afUnknownFields = {};

afFieldName[-f_] := -afFieldName[f];
afFieldName[(kind : (F | S | V | U))[n_Integer, ___]] :=
  If[KeyExistsQ[AFCouplingFieldNames, kind[n]],
    AFCouplingFieldNames[kind[n]],
    AppendTo[$afUnknownFields, kind[n]]; Subscript[ToString[kind] <> "f", n]];

(* Row keeps the names as written: no reordering, no h0 h0 -> h0^2, no cancelling of -H against H (a Times inside HoldForm
   is an Orderless head, a poor identity for pattern matching; a Row is plain structure) *)
AFCouplingsSymbolOf[fields_List] := Subscript[g, Row[afFieldName /@ fields, " "]];

afEntrySymbol[Subscript[g, vertex_], {row_, col_}] := Subscript[g, vertex, Row[{row, col}, " "]];


(* ---------------------------------------------------------------------------------------------------------------------
   2. One model entry   C[fields] == matrix   ->   {symbolic entry, {symbol -> rollback rule, ...}}
   --------------------------------------------------------------------------------------------------------------------- *)

(* the symbols inside the {...} of indexed fields: j1, o1, ... *)
(* ONLY the first index of a field, the generation: F[3, {j1, o1}] -> j1. The second one is the colour index. A coupling symbol
   g[j1, o1] would carry a colour index as an argument; FCFAConvert turns it into a SUNFIndex inside the symbol, and SUNSimplify then
   fails ("Failed to properly isolate the color algebraic expressions"). The colour dependence of a vertex sits in IndexDelta, which
   stays outside the symbol; Mass[F[3,{j1,o1}]] does not depend on the colour. *)
afIndexVariables[lhs_] := Select[
  DeleteDuplicates[Cases[lhs, (F | S | V | U)[_, {j_, ___}] :> j, {0, Infinity}]],
  Head[#] === Symbol &];

(* factor e = structure * reduced: IndexDelta / CKM factors on one side, the coupling proper on the other *)
afSplitIndexFactors[e_] := Module[{factors = If[Head[e] === Times, List @@ e, {e}], isIndexFactor},
  isIndexFactor = MatchQ[#, _IndexDelta | CKM[__] | Conjugate[CKM[__]]] &;
  {Times @@ Select[factors, isIndexFactor], Times @@ Select[factors, !isIndexFactor[#] &]}
];

(* one matrix element -> {new element, {symbol -> rule}} ; numbers are kept, with no rule.
   `symbol` is the vertex symbol (with the suffix of the entry when the vertex has several). *)
afConvertElement[e_, symbol_, indexVars_List] := Module[{structure, reduced, args, pattern},
  If[NumericQ[e], Return[{e, {}}]];
  {structure, reduced} = afSplitIndexFactors[e];
  args = Select[indexVars, !FreeQ[reduced, #] &];
  If[args === {},
    {structure symbol, {symbol -> (symbol -> reduced)}},
    pattern = symbol @@ (Pattern[#, Blank[]] & /@ args);
    (* With puts the pattern and the expression into the rule before RuleDelayed holds it *)
    {structure symbol @@ args, {symbol -> With[{lhs = pattern, rhs = reduced}, RuleDelayed[lhs, rhs]]}}]
];

afConvertEntry[lhs_C == rhs_] := Module[{fields = List @@ lhs, indexVars, vertex, matrix, nSymbols, converted},
  indexVars = afIndexVariables[lhs];
  vertex = AFCouplingsSymbolOf[fields];
  matrix = If[ListQ[rhs], rhs, {{rhs}}];
  nSymbols = Count[Flatten[matrix], e_ /; !NumericQ[e]];
  converted = MapIndexed[
    afConvertElement[#1, If[nSymbols > 1, afEntrySymbol[vertex, #2], vertex], indexVars] &, matrix, {2}];
  {lhs == If[ListQ[rhs], converted[[All, All, 1]], converted[[1, 1, 1]]], Flatten[converted[[All, All, 2]]]}
];
afConvertEntry[other_] := {other, {}};


(* ---------------------------------------------------------------------------------------------------------------------
   3. Init / apply / restore / verify
   --------------------------------------------------------------------------------------------------------------------- *)

(* <|"Original", "Symbolic" -> lists of entries, "Rules" -> <|symbol -> rule|>, "Applied" -> True / False|> *)
AFCouplings = None;

AFCouplingsInit[] := Module[{original, converted, rules, duplicates},
  If[!ValueQ[M$CouplingMatrices], AFFail["AFCouplingsInit: no model loaded (M$CouplingMatrices is empty); call it after InsertFields"]];
  If[AssociationQ[AFCouplings] && AFCouplings["Applied"],
    AFLog["couplings already symbolic; keeping the stored original"]; Return[AFCouplings]];

  original = M$CouplingMatrices;
  $afUnknownFields = {};
  converted = afConvertEntry /@ original;
  rules = Flatten[converted[[All, 2]]];
  duplicates = Select[Tally[First /@ rules], #[[2]] > 1 &];
  If[duplicates =!= {}, AFFail["AFCouplingsInit: two entries got the same symbol (name clash): ", duplicates[[All, 1]]]];
  If[$afUnknownFields =!= {},
    AFLog["WARNING: fields without a name in AFCouplingFieldNames (generic names used): ", DeleteDuplicates[$afUnknownFields]]];

  AFCouplings = <|"Original" -> original, "Symbolic" -> converted[[All, 1]], "Rules" -> Association[rules], "Applied" -> False|>;
  AFLog["couplings: ", Length[original], " vertices, ", Length[rules], " symbols"];
  AFCouplings
];

AFCouplingsApply[] := (
  If[!AssociationQ[AFCouplings], AFCouplingsInit[]];
  M$CouplingMatrices = AFCouplings["Symbolic"];
  AFCouplings["Applied"] = True;
  AFLog["M$CouplingMatrices is symbolic"]);

AFCouplingsRestore[] := If[AssociationQ[AFCouplings],
  M$CouplingMatrices = AFCouplings["Original"];
  AFCouplings["Applied"] = False;
  AFLog["M$CouplingMatrices is the original"]];

(* exact: every symbolic vertex goes back to its original, and no symbol survives *)
AFCouplingsVerify[] := Module[{back, differing},
  If[!AssociationQ[AFCouplings], AFFail["AFCouplingsVerify: AFCouplingsInit[] first"]];
  back = AFCouplings["Symbolic"] /. Values[AFCouplings["Rules"]];
  differing = Flatten[Position[
    MapThread[And @@ (PossibleZeroQ /@ Flatten[{Together[#1[[2]] - #2[[2]]]}]) &, {back, AFCouplings["Original"]}], False]];
  If[differing =!= {},
    Print["[ampflow] first differing entry: rolled back = ", InputForm[back[[differing[[1]], 2]]],
      "   original = ", InputForm[AFCouplings["Original"][[differing[[1]], 2]]]];
    Print["[ampflow] rule keys = ", InputForm[Keys[AFCouplings["Rules"]]]];
    AFFail["AFCouplingsVerify: rollback differs from the original in entries ", differing, " (first: ", AFCouplings["Original"][[differing[[1]], 1]], ")"]];
  If[!FreeQ[back, Subscript[g, _Row, ___]], AFFail["AFCouplingsVerify: a coupling symbol survived the rollback"]];
  AFLog["coupling rollback verified for all ", Length[back], " vertices"];
  True
];


(* ---------------------------------------------------------------------------------------------------------------------
   4. Rollback
   --------------------------------------------------------------------------------------------------------------------- *)

(* the vertices of fermions contain Mass[F[n, {j}]] : the masses of the class descriptions *)
afMassRules[] := Module[{rules = {}, classes = If[ValueQ[M$ClassesDescription], M$ClassesDescription, {}], field, mass},
  Do[
    field = class[[1]];
    mass = Cases[class[[2]], (Mass -> m_) :> m];
    If[mass =!= {} && MatchQ[field, (F | S | V | U)[_Integer]],
      With[{kind = Head[field], n = field[[1]], m = First[mass]},
        AppendTo[rules, If[ListQ[m],
          Mass[kind[n, {j_Integer, ___}]] :> m[[j]],     (* one mass per generation *)
          Mass[kind[n, ___]] :> m]]]],
    {class, classes}];
  rules
];

Options[AFCouplingsRollback] = {"Keep" -> {}, "Map" -> {}};

(* "Map": rules  symbol -> replacement  applied first (for symbols the model file defines, e.g. g_hhH0 -> -I g_model);
   "Keep": symbols left in place *)
AFCouplingsRollback[expr_, OptionsPattern[]] := Module[{keep = OptionValue["Keep"], map = OptionValue["Map"], rules},
  If[!AssociationQ[AFCouplings], AFFail["AFCouplingsRollback: AFCouplingsInit[] first"]];
  rules = Values[KeyDrop[AFCouplings["Rules"], Join[keep, First /@ map]]];
  ((expr /. map) /. rules) /. afMassRules[]
];

(* the original expression behind the vertex with these fields (one entry, no indices) *)
AFCouplingsValue[fields_List] := Module[{rule = Lookup[AFCouplings["Rules"], AFCouplingsSymbolOf[fields], None]},
  If[rule === None, AFFail["AFCouplingsValue: no vertex with fields ", fields, " (field order matters: use the order of the model file)"]];
  rule[[2]]
];


(* ---------------------------------------------------------------------------------------------------------------------
   5. Files. ASCII only: every non-ASCII character is written as its \[Name], so no encoding problem can break the Greek letters.
   --------------------------------------------------------------------------------------------------------------------- *)

afWriteAscii[file_String, text_String] := (
  Quiet[CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  Export[file, text, "Text", CharacterEncoding -> "ASCII"];
  AFLog["wrote ", file];
  file);

(* all that a later session needs for AFCouplingsRollback (no model load needed) *)
AFCouplingsSave[file_String] := (
  If[!AssociationQ[AFCouplings], AFCouplingsInit[]];
  afWriteAscii[file, ToString[KeyTake[AFCouplings, {"Original", "Symbolic", "Rules"}], InputForm, PageWidth -> Infinity]]);

(* the model is then expected to be the symbolic one already (Model -> "THDMsym"), so M$CouplingMatrices is not touched *)
AFCouplingsLoad[file_String] := (
  AFCouplings = Append[Get[file], "Applied" -> True];
  AFLog["loaded ", Length[AFCouplings["Rules"]], " coupling symbols from ", file]);

(* <model>.mod -> <newName>.mod: the original model file, then the symbolic section on top of it. Then
   InsertFields[..., Model -> newName] builds the diagrams with symbolic vertices from the start, and nothing depends on WHEN
   FeynArts reads M$CouplingMatrices. *)
AFCouplingsInstallModel[model_String : "THDM", newName_String : "THDMsym", outputDir_ : Automatic] := Module[{dirs, file, dir},
  If[!AssociationQ[AFCouplings], AFCouplingsInit[]];
  dirs = Select[Flatten[{
    If[ValueQ[FeynArts`$ModelPath], FeynArts`$ModelPath, {}],
    FileNameJoin[{$UserBaseDirectory, "Applications", "FeynCalc", "FeynArts", "Models"}],
    FileNameJoin[{$UserBaseDirectory, "Applications", "FeynArts", "Models"}]}], StringQ[#] && DirectoryQ[#] &];
  file = FirstCase[Flatten[FileNames[model <> ".mod", dirs]], _String, None];
  If[file === None, AFFail["AFCouplingsInstallModel: ", model, ".mod not found in ", dirs]];
  dir = If[outputDir === Automatic, DirectoryName[file], outputDir];
  afWriteAscii[FileNameJoin[{dir, newName <> ".mod"}],
    "Get[\"" <> file <> "\"];\n" <>
    "M$ModelName = \"" <> newName <> "\";\n" <>
    "M$CouplingMatrices = " <> ToString[AFCouplings["Symbolic"], InputForm, PageWidth -> Infinity] <> ";"]
];


(* ---------------------------------------------------------------------------------------------------------------------
   6. Self test on a small made-up model section (no FeynArts, no model file): a scalar vertex, a gauge vertex, a chiral pair
   with IndexDelta, a Yukawa vertex with Mass[...] and colour, a vertex with three Lorentz structures, a zero entry, an unnamed
   field. Checks the symbols, the exact rollback, that IndexDelta stays outside the symbol, the Mass rules, Keep / Map.
   --------------------------------------------------------------------------------------------------------------------- *)

AFCouplingsSelfTest[] := Module[{results = {}, check, savedM, savedC, savedA, sym, hhH, expr},
  check[name_String, ok_] := (AppendTo[results, TrueQ[ok]];
    Print["[ampflow] coupling check ", If[TrueQ[ok], "OK      ", "FAILED  "], name]);
  savedM = If[ValueQ[M$CouplingMatrices], M$CouplingMatrices, None];
  savedC = If[ValueQ[M$ClassesDescription], M$ClassesDescription, None];
  savedA = AFCouplings;
  AFCouplings = None;
  M$ClassesDescription = {F[2] == {Mass -> {me, mm, ml}}, S[1] == {Mass -> mh}};
  M$CouplingMatrices = {
    C[S[1], S[1], S[2]] == {{-I EL c1}},
    C[S[5], -S[5], V[1]] == {{I EL}},
    C[-F[2, {j1}], F[2, {j2}], V[2]] == {{-I EL a1 IndexDelta[j1, j2]}, {-I EL a2 IndexDelta[j1, j2]}},
    C[-F[3, {j1, o1}], F[3, {j2, o2}], S[1]] == -I EL Mass[F[3, {j1, o1}]] IndexDelta[j1, j2] IndexDelta[o1, o2] {{1}, {1}},
    C[V[3], -V[3], V[1], V[2]] == {{k1c, k2c, k3c}},
    C[S[1], S[2], S[3], S[4]] == {{0}},
    C[S[9], S[9], S[1]] == {{b9}}};
  sym = AFCouplingsInit[];
  hhH = AFCouplingsSymbolOf[{S[1], S[1], S[2]}];

  check["one symbol per non-numeric entry (1 + 1 + 2 + 2 + 3 + 0 + 1 = 10)", Length[sym["Rules"]] === 10];
  check["antiparticle is written -name", !FreeQ[AFCouplingsSymbolOf[{S[5], -S[5], V[1]}], Times[-1, H]]];
  check["rollback is exact for every vertex", AFCouplingsVerify[]];
  check["IndexDelta stays outside the symbol; the symbol carries the generation index only",
    !FreeQ[sym["Symbolic"][[4, 2]], IndexDelta[j1, j2]] && !FreeQ[sym["Symbolic"][[4, 2]], Subscript[g, _Row, ___][j1]]];
  check["numeric entries are untouched", sym["Symbolic"][[6, 2]] === {{0}}];
  check["a field without a name still gets a symbol", !FreeQ[sym["Symbolic"][[7]], _Subscript]];
  AFCouplingsApply[];
  check["Apply / Restore swap M$CouplingMatrices", M$CouplingMatrices === sym["Symbolic"] && (AFCouplingsRestore[]; M$CouplingMatrices === sym["Original"])];
  expr = {hhH, Mass[F[2, {3}]]};
  check["Rollback: vertex -> original, Mass[F[2,{3}]] -> ml", AFCouplingsRollback[expr] === {-I EL c1, ml}];
  check["Keep leaves a symbol, Map substitutes one",
    AFCouplingsRollback[expr, "Keep" -> {hhH}][[1]] === hhH && AFCouplingsRollback[expr, "Map" -> {hhH -> -I gx}][[1]] === -I gx];

  AFCouplings = savedA;
  M$CouplingMatrices =.; M$ClassesDescription =.;
  If[savedM =!= None, M$CouplingMatrices = savedM];
  If[savedC =!= None, M$ClassesDescription = savedC];
  And @@ results
];
