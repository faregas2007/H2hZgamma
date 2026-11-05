(* ::Package:: *)

(* ampflow_h0hzg_run.m -- the long run of H0 -> h0 Z gamma, in steps that are saved, logged, skippable and restartable.

   Hundreds of diagrams are too much for one evaluation: a single wrong diagram would lose everything, and a wrong output is hard
   to trace. The run is therefore split in two stages that communicate through files in the WORK directory.

   Stage 1 "Diagrams"  one file per diagram     <work>/diagrams/<group>_<size>_<nnnn>.m
       FeynArts amplitude -> projection -> TID -> linear form over A0 B0 C0 D0 (AFH0hZgDiagramLinear). The expensive part.
       A diagram whose file exists (same FeynArts amplitude, same options) is not computed again. A diagram that fails (AFFail,
       time limit) is logged, leaves a <file>.failed with the reason, and is skipped (or stops the run: "OnError" -> "Stop");
       the next run tries it again, and only it.
   Stage 2 "Combine"   one file per cell and class <work>/cells/<class>_<group>_<size>.m, and the exported amplitudes
       The diagrams of a cell are summed class by class as coefficients; then AFH0hZgFinish (G^-1, D -> 4, vertices back).
       A cell with a missing diagram is not combined. Finished cells are reused when their diagrams did not change.

   Exported files (the format fc2lt reads), in <export>:
       h0hzg_<class>_<group>_<size>_F<i>.m     per class, loop group and size (i = 1, 2, 3)
       h0hzg_<class>_F<i>.m                    the sum over the cells of one class
       h0hzg_F<i>.m                            the sum over the "TotalClasses" (default: all but OnShell), with the UV test

   Several processes can share the diagrams: run Stage "Diagrams" with "Shard" -> {i, n} in n processes on the same work directory
   (each does the diagrams with Mod[index - 1, n] == i - 1), then one run with "Stage" -> "Combine".          *)


(* ---------------------------------------------------------------------------------------------------------------------
   Options
   --------------------------------------------------------------------------------------------------------------------- *)

Options[AFH0hZgRun] = Join[Options[AFH0hZgDiagrams], {
  (* physics and numerics *)
  "Lambda5" -> "Same",                     (* "Same" | "TwoM2OverV2", see ampflow_h0hzg.m *)
  "CheckModelCouplings" -> True,
  "UseModelCouplings" -> False,            (* thdm.model's g_hhH0, g_hH0H0 instead of FeynArts' *)
  "GaugeRules" -> {GaugeXi[_] -> 1},       (* Feynman gauge, as in the report *)
  "ConvertNames" -> True,
  "Scheme" -> "NDR",                       (* gamma5 scheme of the fermion loops: "NDR" | "Larin" | "BMHV" *)
  "UseDelta" -> True,                      (* factor powers of Delta out of the coefficients *)
  "RollBack" -> False,                     (* False (default): the exported forms keep the symbols g_{fields}; the values are put in by the C++ side
                                             (.slha files), see h0hzg_couplings*.m. True: the original model expressions are substituted *)
  "SchemeCheck" -> True,                   (* trial runs: the first fermion diagrams in the schemes of SchemeSchemes, differences logged *)
  "SchemeSchemes" -> {"NDR", "Larin"},
  "KeepCouplings" -> {},                   (* coupling symbols not rolled back *)
  "MapCouplings" -> {},                    (* substitutions for chosen coupling symbols *)
  (* what to run *)
  "Groups" -> All, "Sizes" -> All,         (* e.g. "Groups" -> {"H"}, "Sizes" -> {"Triangle"} *)
  "Trial" -> None,                         (* n: only the first n diagrams of each cell, files in <export>/trial *)
  "Stage" -> "All",                        (* "All" | "Diagrams" | "Combine" *)
  "Shard" -> {1, 1},                       (* {i, n} *)
  (* behaviour *)
  "OnError" -> "Skip",                     (* "Skip" | "Stop" *)
  "TimeLimit" -> Infinity,                 (* seconds per diagram (stage 1) and per class of a cell (stage 2) *)
  "Recompute" -> False,                    (* ignore the files already written *)
  "TotalClasses" -> Automatic,             (* classes in h0hzg_F<i>.m; Automatic: every class but OnShell:* *)
  (* places *)
  "ExportDir" -> Automatic,                (* default: $AFExportDir, else ./export *)
  "WorkDir" -> Automatic}];                (* default: <ExportDir>/work *)


(* ---------------------------------------------------------------------------------------------------------------------
   Files
   --------------------------------------------------------------------------------------------------------------------- *)

afName[parts_List] := StringRiffle[StringReplace[parts, {":" -> "_", "+" -> "_"}], "_"];
afDiagramFile[work_, g_, t_, i_] := FileNameJoin[{work, "diagrams", afName[{g, t, IntegerString[i, 10, 4]}] <> ".m"}];
afCellFile[work_, class_, g_, t_] := FileNameJoin[{work, "cells", afName[{class, g, t}] <> ".m"}];

(* written as ASCII (\[Name] for Greek letters) to a temporary file first, so that an interrupted run never leaves half a file *)
afSave[file_String, data_] := Module[{tmp = file <> ".tmp"},
  Quiet[CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  Export[tmp, ToString[data, InputForm, PageWidth -> Infinity], "Text", CharacterEncoding -> "ASCII"];
  RenameFile[tmp, file, OverwriteTarget -> True]
];
afLoad[file_String] := If[FileExistsQ[file], Quiet[Check[Get[file], $Failed]], $Failed];
afWriteText[file_String, text_String] := (
  Quiet[CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  Export[file, text, "Text"]);

(* what a diagram's file depends on besides the FeynArts amplitude (which is hashed itself) *)
$afCodeVersion = 5;     (* raise it when stage 1 changes: files of an older version are recomputed *)
afConfigKey[cfg_Association] := Hash[{KeyTake[cfg, {"Model", "Restrictions", "ExcludeParticles", "Couplings", "GaugeRules", "ConvertNames", "Scheme", "Lambda5"}],
  $afCodeVersion, $AFDualApartFF}, "SHA256", "HexString"];
(* ... and what a finished cell depends on *)
afFinishKey[cfg_Association] := Hash[{afConfigKey[cfg], KeyTake[cfg, {"UseDelta", "RollBack", "KeepCouplings", "MapCouplings"}]}, "SHA256", "HexString"];

afSelected[cfg_Association, g_, t_] :=
  (cfg["Groups"] === All || MemberQ[cfg["Groups"], g]) && (cfg["Sizes"] === All || MemberQ[cfg["Sizes"], t]);
afCellSize[cell_Association, cfg_Association] := If[cfg["Trial"] === None, cell["Count"], Min[cfg["Trial"], cell["Count"]]];


(* ---------------------------------------------------------------------------------------------------------------------
   Stage 1: one diagram
   --------------------------------------------------------------------------------------------------------------------- *)

(* -> <|"Status" -> "cached" | "done" | "failed", "Class", "Seconds", "Message"|> *)
afDiagramStep[cell_Association, g_, t_, i_, cfg_Association, work_] := Module[{file, amp, key, old, t0, result},
  file = afDiagramFile[work, g, t, i];
  amp = CreateFeynAmp[DiagramExtract[cell["Diagrams"], {i}], PreFactor -> 1, Truncated -> True, GaugeRules -> cfg["GaugeRules"]];
  key = Hash[{amp, afConfigKey[cfg]}, "SHA256", "HexString"];

  old = If[cfg["Recompute"], $Failed, afLoad[file]];
  If[AssociationQ[old] && old["Key"] === key,
    Return[<|"Status" -> "cached", "Class" -> old["Class"], "Seconds" -> 0, "Message" -> ""|>]];

  t0 = AbsoluteTime[];
  result = AFGuarded[AFH0hZgDiagramLinear[amp, g, cfg], cfg["TimeLimit"]];
  If[First[result] === "ok",
    afSave[file, <|"Key" -> key, "Config" -> afConfigKey[cfg], "Group" -> g, "Size" -> t, "Index" -> i,
      "Class" -> Last[result]["Class"], "Lin" -> Last[result]["Lin"]|>];
    Quiet[DeleteFile[file <> ".failed"]];
    <|"Status" -> "done", "Class" -> Last[result]["Class"], "Seconds" -> AbsoluteTime[] - t0, "Message" -> ""|>,
    afWriteText[file <> ".failed", Last[result]];
    <|"Status" -> "failed", "Class" -> "?", "Seconds" -> AbsoluteTime[] - t0, "Message" -> Last[result]|>]
];

(* all diagrams of the selected cells (of this shard) -> <|{group, size, i} -> step result|> *)
afRunDiagrams[cells_Association, cfg_Association, work_] := Module[{status = <||>, g, t, n, st, shard, nShards, tStart = AbsoluteTime[]},
  {shard, nShards} = cfg["Shard"];
  Catch[
    Do[
      {g, t} = cell;
      If[!afSelected[cfg, g, t], Continue[]];
      n = afCellSize[cells[cell], cfg];
      AFLog["stage 1: cell ", g, "/", t, ", ", n, " diagrams"];
      Do[
        If[Mod[i - 1, nShards] =!= shard - 1, Continue[]];
        st = afDiagramStep[cells[cell], g, t, i, cfg, work];
        status[{g, t, i}] = st;
        AFLog["  ", g, "/", t, "  ", i, "/", n, "  ", st["Status"], "  ", st["Class"],
          If[st["Status"] === "done", "  " <> ToString[Round[st["Seconds"], 0.1]] <> " s", ""], st["Message"]];
        If[st["Status"] === "failed" && cfg["OnError"] === "Stop", Throw[Null, "AFStop"]],
        {i, n}],
      {cell, Keys[cells]}],
    "AFStop"];
  AFLog["stage 1 finished in ", Round[AbsoluteTime[] - tStart], " s: ",
    Count[status, _?(#["Status"] === "done" &)], " computed, ", Count[status, _?(#["Status"] === "cached" &)], " cached, ",
    Count[status, _?(#["Status"] === "failed" &)], " failed"];
  status
];


(* ---------------------------------------------------------------------------------------------------------------------
   Stage 2: one cell
   --------------------------------------------------------------------------------------------------------------------- *)

afH0hZgHeader[what_String, i_Integer, trial_] := "H0 -> h0 Z gamma, " <> what <>
  If[trial === None, "", " (TRIAL: first " <> ToString[trial] <> " diagrams per cell)"] <>
  "; generated by ampflow_h0hzg.m. Form factor F" <> ToString[i] <> " (coefficient of structure P" <> ToString[i] <>
  ", see ampflow_dual.m); inputs: a b (c x y Delta from the model)";

(* h0hzg_<parts>_F<i>.m *)
afH0hZgFile[dir_String, parts_List, i_Integer] := FileNameJoin[{dir, afName[Join[{"h0hzg"}, parts]] <> "_F" <> ToString[i] <> ".m"}];

(* the three form factors of a linear form to their three files *)
afExportForms[dir_String, parts_List, what_String, lin_Association, trial_] :=
  Do[AFExportAmplitude[afH0hZgFile[dir, parts, i], AFFromLinear[lin, i], afH0hZgHeader[what, i, trial]], {i, 3}];

(* The diagrams of one cell, class by class -> <|"Missing" -> indices, "Forms" -> <|class -> form factors as linear form|>,
   "Failed" -> messages|>. Nothing is combined while a diagram is missing. *)
afCombineCell[g_, t_, n_, cfg_Association, work_, dir_] := Module[
  {data, missing, byClass, items, keys, file, old, finished, exported, forms = <||>, failed = {},
   fkey = afFinishKey[cfg], ckey = afConfigKey[cfg]},
  data = Table[afLoad[afDiagramFile[work, g, t, i]], {i, n}];
  missing = Select[Range[n], !(AssociationQ[data[[#]]] && data[[#]]["Config"] === ckey) &];
  If[missing =!= {},
    AFLog["stage 2: cell ", g, "/", t, " NOT combined, diagrams missing, failed or computed with other options: ", missing];
    Return[<|"Missing" -> missing, "Forms" -> <||>, "Failed" -> {}|>]];

  byClass = GroupBy[data, #["Class"] &];
  AFLog["stage 2: cell ", g, "/", t, ": ", n, " diagrams in the classes ", Normal[Length /@ byClass]];
  Do[
    items = byClass[class];
    keys = Sort[#["Key"] & /@ items];
    file = afCellFile[work, class, g, t];
    old = If[cfg["Recompute"], $Failed, afLoad[file]];

    If[AssociationQ[old] && old["Keys"] === keys && old["FinishKey"] === fkey,
      finished = {"ok", old["Lin"]};
      AFLog["  ", class, ": finished form factors taken from ", file],
      finished = AFGuarded[AFH0hZgFinish[AFLinearSum[#["Lin"] & /@ items], cfg], cfg["TimeLimit"]];
      If[First[finished] === "ok",
        afSave[file, <|"Keys" -> keys, "FinishKey" -> fkey, "Lin" -> Last[finished]|>];
        AFLog["  ", class, ": ", Length[items], " diagrams -> ", Length[Last[finished]], " integrals, ", LeafCount[Last[finished]], " leaves"]]];

    If[First[finished] === "ok",
      exported = AFGuarded[afExportForms[dir, {class, g, t}, class <> " / " <> g <> " loops / " <> t, Last[finished], cfg["Trial"]], cfg["TimeLimit"]];
      If[First[exported] === "ok", forms[class] = Last[finished], finished = exported]];

    If[First[finished] === "fail",
      AppendTo[failed, g <> "/" <> t <> " " <> class <> ": " <> Last[finished]];
      AFLog["  ", class, ": FAILED, skipped"]],
    {class, Keys[byClass]}];
  <|"Missing" -> {}, "Forms" -> forms, "Failed" -> failed|>
];

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

(* coefficient of the UV pole Delta of a finished linear form: a vector {F1, F2, F3} *)
afLinearPole[lin_Association] := Total[KeyValueMap[AFUVPole[#1] #2 &, lin]];



(* ---------------------------------------------------------------------------------------------------------------------
   Counting. Three checks that nothing is missing and nothing is counted twice:
     1  census (ampflow_h0hzg.m): FeynArts' total = sum over the cells (group x size)
     2  ledger: per cell, the diagram files on disk (ok / failed / missing), and the same diagrams per topology class
     3  duplicates: two diagram files with the same Key are the same amplitude computed twice
   --------------------------------------------------------------------------------------------------------------------- *)
afLedger[cells_Association, cfg_Association, work_] := Module[{rows = {}, data, ok, failed, keys = {}, classCount = <||>, dup, total = 0, used = 0, n, failedList = {}, ff},
  Do[
    If[!afSelected[cfg, cell[[1]], cell[[2]]], Continue[]];
    n = afCellSize[cells[cell], cfg];
    data = Table[afLoad[afDiagramFile[work, cell[[1]], cell[[2]], i]], {i, n}];
    ok = Count[data, _Association];
    failed = Count[Table[FileExistsQ[afDiagramFile[work, cell[[1]], cell[[2]], i] <> ".failed"], {i, n}], True];
    Do[ff = afDiagramFile[work, cell[[1]], cell[[2]], i] <> ".failed";
      If[FileExistsQ[ff], AppendTo[failedList, {cell[[1]], cell[[2]], i, StringReplace[StringTrim[Import[ff, "Text"]], "\n" -> " "]}]], {i, n}];
    keys = Join[keys, Cases[data, a_Association :> a["Key"]]];
    Scan[(classCount[#["Class"]] = Lookup[classCount, #["Class"], 0] + 1) &, Cases[data, _Association]];
    total += cells[cell]["Count"]; used += n;
    AppendTo[rows, {cell[[1]], cell[[2]], n, ok, failed, n - ok - failed}],
    {cell, Keys[cells]}];
  AFLog["ledger {group, size, diagrams, done, failed, missing}:"];
  Scan[AFLog["    ", #] &, rows];
  AFLog["ledger totals: ", used, " selected diagrams (", total, " in the selected cells), ", Total[rows[[All, 4]]], " done, ",
    Total[rows[[All, 5]]], " failed, ", Total[rows[[All, 6]]], " missing;   per class: ", Normal[classCount],
    "   (sum ", Total[Values[classCount]], If[Total[Values[classCount]] === Total[rows[[All, 4]]], " = done: OK)", " != done: CHECK)"]];
  (* the failed diagrams, one per line, with the call that extracts each from the cell (cells[{group, size}]["Diagrams"]) *)
  afWriteText[FileNameJoin[{work, "failed_diagrams.txt"}],
    "# group, size, number in the cell, reason.  Extract: DiagramExtract[<cell diagrams>, {number}]  (cells from AFH0hZgCells; same order as the file names Group_Size_NNNN)\n" <>
    StringRiffle[StringRiffle[ToString /@ #, ", "] & /@ failedList, "\n"] <> "\n"];
  AFLog["failed diagrams (", Length[failedList], ") listed in ", FileNameJoin[{work, "failed_diagrams.txt"}]];
  dup = Select[Tally[keys], #[[2]] > 1 &];
  If[dup =!= {}, AFLog["WARNING: ", Length[dup], " amplitude(s) appear in more than one diagram file (counted twice): the Keys ", dup[[All, 1]]],
    AFLog["no amplitude appears twice"]];
  rows
];

(* trial run: the first fermion diagrams through the gamma5 schemes; one line with the verdict *)
afSchemeCheckTrial[cells_Association, cfg_Association] := Module[{cell, n, r},
  cell = SelectFirst[Keys[cells], First[#] === "Fermion" && afSelected[cfg, "Fermion", Last[#]] &, None];
  If[cell === None, Return[Null]];
  n = Min[2, cells[cell]["Count"]];
  AFLog["scheme check (trial): ", cfg["SchemeSchemes"], " on the first ", n, " diagrams of ", cell];
  r = AFGuarded[AFH0hZgFermionSchemeCheck[DiagramExtract[cells[cell]["Diagrams"], Range[n]], cfg["SchemeSchemes"], cfg["GaugeRules"]], cfg["TimeLimit"]];
  If[First[r] === "fail", AFLog["scheme check FAILED: ", Last[r]]; Return[Null]];
  KeyValueMap[
    AFLog["  ", First[cfg["SchemeSchemes"]], " minus ", #1, ": ",
      If[And @@ (PossibleZeroQ[Together[#]] & /@ Flatten[{#2}]), "zero (scheme independent)",
        "NOT zero, leaves: " <> ToString[LeafCount[#2]] <> "   (rational terms of the scheme: understand them before using the result)"]] &,
    Association[Last[r]["Differences"]]]
];

(* coupling symbols used by the forms and the rules behind them: what the C++ / SLHA side needs when RollBack is False *)
afWriteCouplingFiles[dir_String, forms_Association] := Module[{syms},
  syms = Sort[DeleteDuplicates[Cases[forms, Subscript[g, _Row, ___], {0, Infinity}]]];
  afWriteAscii[FileNameJoin[{dir, "h0hzg_couplings.m"}], ToString[syms, InputForm, PageWidth -> Infinity]];
  AFCouplingsSave[FileNameJoin[{dir, "h0hzg_couplings_rollback.m"}]];
  AFLog["coupling symbols in the forms: ", Length[syms], " (list: h0hzg_couplings.m; their model expressions: h0hzg_couplings_rollback.m)"]
];

(* ---------------------------------------------------------------------------------------------------------------------
   The run
   --------------------------------------------------------------------------------------------------------------------- *)

(* Returns <|"Status" -> stage 1 results, "Forms" -> <|{class, group, size} -> linear form of F1, F2, F3|>,
             "ClassForms" -> <|class -> linear form|>, "Total" -> {F1, F2, F3} or None, "Failed" -> messages|>. *)
AFH0hZgRun[opts___] := Module[
  {cfg, diags, cells, dir, work, trial, status = <||>, forms = <||>, classForms, totalLin, total = None, failed = {}, incomplete = False,
   classes, r, pole},
  cfg = AFOptions[AFH0hZgRun, {opts}];
  If[!MemberQ[{"All", "Diagrams", "Combine"}, cfg["Stage"]], AFFail["AFH0hZgRun: \"Stage\" must be \"All\", \"Diagrams\" or \"Combine\""]];
  If[!MemberQ[{"Skip", "Stop"}, cfg["OnError"]], AFFail["AFH0hZgRun: \"OnError\" must be \"Skip\" or \"Stop\""]];
  trial = cfg["Trial"];

  AFH0hZgUseUTF8[];
  $AFH0hZgLambda5 = cfg["Lambda5"];
  dir = cfg["ExportDir"];
  If[dir === Automatic, dir = If[ValueQ[$AFExportDir], $AFExportDir, FileNameJoin[{Directory[], "export"}]]];
  If[trial =!= None, dir = FileNameJoin[{dir, "trial"}]; AFLog["TRIAL RUN: first ", trial, " diagram(s) per cell, files in ", dir]];
  work = If[cfg["WorkDir"] === Automatic, FileNameJoin[{dir, "work"}], cfg["WorkDir"]];
  AFLog["export: ", dir, "   work: ", work, "   stage: ", cfg["Stage"], "   shard: ", cfg["Shard"]];

  diags = AFH0hZgDiagrams[Sequence @@ FilterRules[Normal[cfg], Options[AFH0hZgDiagrams]]];
  If[AssociationQ[AFCouplings] && cfg["CheckModelCouplings"], AFH0hZgCheckModelCouplings[]];
  If[cfg["UseModelCouplings"], cfg["MapCouplings"] = Join[cfg["MapCouplings"], AFH0hZgModelMap[]]];
  cells = AFH0hZgCells[diags];

  If[cfg["Stage"] =!= "Combine",
    status = afRunDiagrams[cells, cfg, work];
    If[trial =!= None && cfg["SchemeCheck"], afSchemeCheckTrial[cells, cfg]]];
  If[cfg["Shard"][[2]] === 1, afLedger[cells, cfg, work]];
  If[cfg["Stage"] === "Diagrams" || cfg["Shard"][[2]] > 1,
    If[cfg["Shard"][[2]] > 1 && cfg["Stage"] === "All", AFLog["several shards: stage 1 only; combine with \"Stage\" -> \"Combine\" afterwards"]];
    Return[<|"Status" -> status, "Forms" -> <||>, "ClassForms" -> <||>, "Total" -> None, "Failed" -> {}|>]];

  (* stage 2 *)
  Do[
    If[!afSelected[cfg, cell[[1]], cell[[2]]], Continue[]];
    r = afCombineCell[cell[[1]], cell[[2]], afCellSize[cells[cell], cfg], cfg, work, dir];
    If[r["Missing"] =!= {}, incomplete = True];
    failed = Join[failed, r["Failed"]];
    KeyValueMap[(forms[{#1, cell[[1]], cell[[2]]}] = #2) &, r["Forms"]],
    {cell, Keys[cells]}];

  classes = Union[First /@ Keys[forms]];
  classForms = Association[Table[
    class -> AFLinearSum[Values[KeySelect[forms, First[#] === class &]]], {class, classes}]];
  If[incomplete || failed =!= {},
    AFLog["WARNING: some cells are incomplete or failed; the sums per class and the total are NOT written. Fix or rerun, the finished work is kept."],
    Do[
      r = AFGuarded[afExportForms[dir, {class}, class <> ", all loop groups", classForms[class], trial], cfg["TimeLimit"]];
      If[First[r] === "fail", AppendTo[failed, "class " <> class <> ": " <> Last[r]]],
      {class, classes}];
    If[!cfg["RollBack"] && AssociationQ[AFCouplings] && classForms =!= <||>, afWriteCouplingFiles[dir, classForms]];
    If[trial === None,
      totalLin = AFLinearSum[Values[KeySelect[classForms,
        If[cfg["TotalClasses"] === Automatic, !StringStartsQ[#, "OnShell"] &, MemberQ[cfg["TotalClasses"], #] &]]]];
      If[totalLin === <||>,
        AFLog["no class selected for the total"],
        pole = afLinearPole[totalLin];
        AFLog["UV pole of the total F1..F3, relative size at a random point (must be ~1e-15): ", afPoleSize /@ pole];
        If[Max[afPoleSize /@ pole] > 10^-8,
          AFLog["WARNING: the total is not UV finite: a diagram class is missing, or the couplings do not obey the relations of the report"]];
        r = AFGuarded[afExportForms[dir, {}, "all computed classes", totalLin, None], cfg["TimeLimit"]];
        If[First[r] === "fail", AppendTo[failed, "total: " <> Last[r]], total = Table[AFFromLinear[totalLin, i], {i, 3}]]]]];

  If[failed =!= {}, AFLog["FAILED items:\n", StringRiffle[failed, "\n"]]];
  <|"Status" -> status, "Forms" -> forms, "ClassForms" -> classForms, "Total" -> total, "Failed" -> failed|>
];
