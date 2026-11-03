(* ::Package:: *)

(* ampflow_couplings.m -- the WHOLE coupling section of a FeynArts model, as symbols, and back.

   Why. The vertex expressions of a FeynArts model (M$CouplingMatrices) are long functions of the mixing angles and masses.
   An amplitude that carries them is huge, hard to check by eye and impossible to re-parametrise. Converting every vertex to a
   symbol  g_{fields}  makes the amplitude small and readable (the diagrams show which vertex enters where); the original
   expressions are put back at the end, once, on the finished form factors.

   What it does:
     AFCouplingsInit[]            read M$CouplingMatrices / M$ClassesDescription, build the symbolic section and the rollback
     AFCouplingsVerify[]          (symbolic /. rollback) == original, entry by entry; unique, complete names
     AFCouplingsApply[]           M$CouplingMatrices = symbolic          AFCouplingsRestore[]  = original again
     AFCouplingsRollback[expr]    put the original expressions back (all, or all but "Keep"; "Map" substitutes chosen ones)
     AFCouplingsInventory[expr]   which coupling symbols an expression contains, how often, and what each stands for
     AFCouplingsWrite / Load      ASCII files (named characters as \[Name], no encoding problems)
     AFCouplingsInstallModel[]    write the symbolic model as a model file of its own (THDM2 -> THDM2sym)

   Naming:  the vertex of fields (a, b, c) is  Subscript[g, HoldForm[a b c]]  with the field names of AFCouplingFieldNames, an
   antiparticle is -name:  h0 H+ H-  ->  g_{h0 H (-H)}.  A coupling matrix with several non-zero entries (left/right-handed,
   several Lorentz structures) gets one symbol per entry:  Subscript[g, HoldForm[a b c], HoldForm[row col]].
   Entries that are numbers (0, 1, ...) are left as they are.

   Flavour and colour. Fermion vertices carry IndexDelta[j1, j2], CKM[j1, j2] and flavour dependent masses. IndexDelta and CKM
   stay OUTSIDE the symbol (so FeynCalc still sums the colour index and contracts the flavour deltas); what is left is the
   reduced coupling r, and the symbol takes the free index variables it depends on as arguments:  g_{...}[j1, j2].  Field names
   carry no indices (nu, l, u, d), so one symbol serves every generation; the rollback is a pattern rule
   g_{...}[j1_, j2_] :> r.                                                                                                 *)


(* ---------------------------------------------------------------------------------------------------------------------
   Field names, keyed by FeynArts field (the notation of the report / thdm.model; THDM2 numbering)
   --------------------------------------------------------------------------------------------------------------------- *)

AFCouplingFieldNames = <|
  F[1] -> \[Nu], F[2] -> l, F[3] -> u, F[4] -> d,
  V[1] -> \[Gamma], V[2] -> Z, V[3] -> W,
  S[1] -> Subscript[h, 0], S[2] -> Subscript[H, 0], S[3] -> Subscript[A, 0], S[4] -> Subscript[G, 0], S[5] -> H, S[6] -> G,
  U[1] -> Subscript[u, \[Gamma]], U[2] -> Subscript[u, Z], U[3] -> Subscript[u, "-"], U[4] -> Subscript[u, "+"]|>;

afUnknownName[h_, n_] := (Sow[h[n], "afUnknownField"]; Subscript[ToString[h] <> "f", n]);
afFieldName[-f_] := -afFieldName[f];
afFieldName[(h : (F | S | V | U))[n_Integer, ___]] := Lookup[AFCouplingFieldNames, h[n], afUnknownName[h, n]];

(* free index variables of the vertex: the symbols inside the {...} of indexed fields *)
afIndexVars[lhs_] := Select[DeleteDuplicates[Flatten[Cases[lhs, (F | S | V | U)[_, l_List] :> l, {0, Infinity}]]], Head[#] === Symbol &];

(* product of the index structures IndexDelta / CKM, and the rest *)
afStructure[e_, idx_List] := Module[{facs, s},
  If[idx === {}, Return[{1, e}]];
  facs = If[Head[e] === Times, List @@ e, {e}];
  s = Times @@ Select[facs, MatchQ[#, _IndexDelta | CKM[__] | Conjugate[CKM[__]]] &];
  {s, e/s}
];

afEntrySymbol[base_, 1, _] := base;                  (* a single non-zero entry: no suffix *)
afEntrySymbol[Subscript[g, h_], n_, {r_, k_}] := Subscript[g, h, HoldForm[r k]];


(* ---------------------------------------------------------------------------------------------------------------------
   One model entry  C[fields] == matrix   ->   {symbolic entry, {name -> rollback rule, ...}}
   --------------------------------------------------------------------------------------------------------------------- *)

afBuildEntry[lhs_C == rhs_] := Module[{fields = List @@ lhs, idx, base, mat, scalar, nNon, newMat, rules = {}},
  idx = afIndexVars[lhs];
  base = AFCouplingsSymbolOf[fields];
  scalar = !ListQ[rhs];
  mat = If[scalar, {{rhs}}, rhs];
  nNon = Count[Flatten[mat], e_ /; !NumericQ[e]];
  newMat = MapIndexed[
    Function[{e, pos},
      Module[{s, r, args, sym, rule},
        If[NumericQ[e], e,
          {s, r} = afStructure[e, idx];
          args = Select[idx, !FreeQ[r, #] &];
          sym = afEntrySymbol[base, nNon, pos];
          rule = If[args === {},
            sym -> r,
            With[{lhsP = sym @@ (Pattern[#, Blank[]] & /@ args), rr = r}, RuleDelayed[lhsP, rr]]];
          AppendTo[rules, sym -> rule];
          s If[args === {}, sym, sym @@ args]]]],
    mat, {2}];
  {lhs == If[scalar, newMat[[1, 1]], newMat], rules}
];
afBuildEntry[other_] := {other, {}};


(* ---------------------------------------------------------------------------------------------------------------------
   Init / apply / restore / verify
   --------------------------------------------------------------------------------------------------------------------- *)

AFCouplings = None;                               (* <|"Original", "Symbolic", "Rules" -> <|name -> rule|>, "Applied" -> True/False|> *)

AFCouplingsInit[] := Module[{orig, built, sym, rules, allRules, unknown, dup},
  If[!ValueQ[M$CouplingMatrices], AFFail["AFCouplingsInit: no model loaded (M$CouplingMatrices is empty); call it after InsertFields / InitializeModel"]];
  If[AssociationQ[AFCouplings] && AFCouplings["Applied"],
    AFLog["couplings already symbolic; keeping the stored original"]; Return[AFCouplings]];
  orig = M$CouplingMatrices;
  {built, unknown} = Reap[afBuildEntry /@ orig, "afUnknownField"];
  unknown = If[unknown === {}, {}, DeleteDuplicates[First[unknown]]];
  If[unknown =!= {}, AFLog["WARNING: fields without a name in AFCouplingFieldNames (generic names used): ", unknown]];
  sym = built[[All, 1]];
  allRules = Flatten[built[[All, 2]]];
  dup = Select[Tally[allRules[[All, 1]]], #[[2]] > 1 &];
  If[dup =!= {}, AFFail["AFCouplingsInit: two entries got the same symbol (name clash): ", dup[[All, 1]]]];
  rules = Association[allRules];
  AFCouplings = <|"Original" -> orig, "Symbolic" -> sym, "Rules" -> rules, "Applied" -> False|>;
  AFLog["couplings: ", Length[orig], " vertices, ", Length[rules], " symbols"];
  AFCouplings
];

AFCouplingsApply[] := (If[!AssociationQ[AFCouplings], AFCouplingsInit[]];
  M$CouplingMatrices = AFCouplings["Symbolic"]; AFCouplings["Applied"] = True;
  AFLog["M$CouplingMatrices is symbolic"]);
AFCouplingsRestore[] := (If[AssociationQ[AFCouplings],
  M$CouplingMatrices = AFCouplings["Original"]; AFCouplings["Applied"] = False; AFLog["M$CouplingMatrices is the original"]]);

AFCouplingsRules[] := Values[AFCouplings["Rules"]];

(* Exact check: every symbolic vertex goes back to its original; no symbol survives. *)
AFCouplingsVerify[] := Module[{back, bad, zeroQ},
  zeroQ[x_] := And @@ (PossibleZeroQ /@ Flatten[{Together[x]}]);
  If[!AssociationQ[AFCouplings], AFFail["AFCouplingsVerify: AFCouplingsInit[] first"]];
  back = AFCouplings["Symbolic"] /. AFCouplingsRules[];
  bad = Flatten[Position[MapThread[zeroQ[#1[[2]] - #2[[2]]] &, {back, AFCouplings["Original"]}], False]];
  If[bad =!= {}, AFFail["AFCouplingsVerify: rollback differs from the original in entries ", bad, " (first: ", AFCouplings["Original"][[bad[[1]], 1]], ")"]];
  If[!FreeQ[back, Subscript[g, HoldForm[__], ___]], AFFail["AFCouplingsVerify: a coupling symbol survived the rollback"]];
  AFLog["coupling rollback verified for all ", Length[back], " vertices"];
  True
];


(* ---------------------------------------------------------------------------------------------------------------------
   Rollback and inventory
   --------------------------------------------------------------------------------------------------------------------- *)

Options[AFCouplingsRollback] = {"Keep" -> {}, "Map" -> {}};

(* "Map": rules  symbol -> replacement  applied first (use them for symbols the model file defines, e.g.
   Subscript[g, HoldForm[...]] -> -I Subscript[g, hhH0]); "Keep": symbols left in place (no rollback).                      *)
AFCouplingsRollback[expr_, OptionsPattern[]] := Module[{rules, keep = OptionValue["Keep"], map = OptionValue["Map"]},
  If[!AssociationQ[AFCouplings], AFFail["AFCouplingsRollback: AFCouplingsInit[] first"]];
  rules = Values[KeyDrop[AFCouplings["Rules"], Join[keep, map[[All, 1]]]]];
  ((expr /. map) /. rules) /. AFCouplingsMassRules[]
];

(* the symbol of the vertex with these fields, and the original expression behind it (single-entry, non-indexed vertices) *)
AFCouplingsSymbolOf[fields_List] := Subscript[g, Replace[Hold @@ (afFieldName /@ fields), Hold[args__] :> HoldForm[Times[args]]]];
AFCouplingsValue[fields_List] := Module[{r = Lookup[AFCouplings["Rules"], AFCouplingsSymbolOf[fields], None]},
  If[r === None, AFFail["AFCouplingsValue: no vertex with fields ", fields, " (field order matters: use the order of the model file)"]];
  r[[2]]];

(* Mass[F[n, {j, ...}]] and friends, from the class descriptions: the rolled-back vertices of fermions contain them. *)
AFCouplingsMassRules[] := Module[{cls = If[ValueQ[M$ClassesDescription], M$ClassesDescription, {}], rules = {}},
  Do[Module[{f = c[[1]], m = Cases[c[[2]], (Mass -> mm_) :> mm]},
      If[m =!= {} && MatchQ[f, (F | S | V | U)[_Integer]],
        m = First[m];
        AppendTo[rules, If[ListQ[m],
          With[{h = Head[f], n = f[[1]], ml = m}, Mass[h[n, {j_Integer, ___}]] :> ml[[j]]],
          With[{h = Head[f], n = f[[1]], mm = m}, Mass[h[n, ___]] :> mm]]]]],
    {c, cls}];
  rules];

afCouplingBase[s_] := If[MatchQ[s, _Subscript], s, Head[s]];

AFCouplingsInventory[expr_] := Module[{found, tally},
  found = Cases[expr, Subscript[g, HoldForm[__], ___] | Subscript[g, HoldForm[__], ___][___], {0, Infinity}];
  tally = Tally[afCouplingBase /@ found];
  Table[<|"Symbol" -> t[[1]], "Count" -> t[[2]], "Value" -> Lookup[AFCouplings["Rules"], t[[1]], Missing["not a vertex symbol"]]|>, {t, tally}]
];


(* ---------------------------------------------------------------------------------------------------------------------
   Files. ASCII only: every non-ASCII character is written as its \[Name]. This replaces the plainGreekRules repair of
   plain-Greek repair rules: the broken Greek letters came from exporting / importing with the wrong character encoding.     *)

afWrite[file_String, header_String, text_String] := (
  Quiet[CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  Export[file, "(* " <> header <> " *)\n" <> text <> "\n", "Text", CharacterEncoding -> "ASCII"]; AFLog["wrote ", file]; file);

AFCouplingsWrite[dir_String, name_String : "THDM2"] := Module[{},
  If[!AssociationQ[AFCouplings], AFCouplingsInit[]];
  afWrite[FileNameJoin[{dir, name <> "_couplings_symbolic.m"}], "symbolic M$CouplingMatrices of " <> name <> "; generated by ampflow_couplings.m",
    "M$CouplingMatrices = " <> ToString[AFCouplings["Symbolic"], InputForm, PageWidth -> Infinity] <> ";"];
  afWrite[FileNameJoin[{dir, name <> "_couplings_rollback.m"}], "rollback rules (coupling symbol -> original vertex) of " <> name <> "; generated by ampflow_couplings.m",
    "AFCouplingsLoadedRules = " <> ToString[AFCouplings["Rules"], InputForm, PageWidth -> Infinity] <> ";"];
  afWrite[FileNameJoin[{dir, name <> "_couplings_original.m"}], "original M$CouplingMatrices of " <> name <> " as loaded; generated by ampflow_couplings.m",
    "AFCouplingsLoadedOriginal = " <> ToString[AFCouplings["Original"], InputForm, PageWidth -> Infinity] <> ";"];
];

(* Restore the state from the files (no model load needed for the rollback: useful for a later session). *)
AFCouplingsLoad[dir_String, name_String : "THDM2"] := Module[{},
  Get[FileNameJoin[{dir, name <> "_couplings_symbolic.m"}]];
  Get[FileNameJoin[{dir, name <> "_couplings_rollback.m"}]];
  Get[FileNameJoin[{dir, name <> "_couplings_original.m"}]];
  AFCouplings = <|"Original" -> AFCouplingsLoadedOriginal, "Symbolic" -> M$CouplingMatrices, "Rules" -> AFCouplingsLoadedRules, "Applied" -> True|>;
  AFLog["loaded ", Length[AFCouplings["Rules"]], " coupling symbols from ", dir]
];


(* ---------------------------------------------------------------------------------------------------------------------
   The symbolic section as a model file of its own: <model>.mod -> <new>.mod with the M$CouplingMatrices block replaced.
   Then   InsertFields[..., Model -> "THDM2sym"]   builds the diagrams with symbolic vertices from the start, and
   nothing depends on when FeynArts reads M$CouplingMatrices.                                                              *)

(* index of the closing brace that matches the opening one at position i0 (strings and (* *) comments are skipped) *)
afMatchBrace[chars_List, i0_Integer] := Module[{i = i0, depth = 0, n = Length[chars], inStr = False, inCom = False, res = None},
  While[i <= n && res === None,
    Which[
      inCom, If[chars[[i]] === "*" && i < n && chars[[i + 1]] === ")", inCom = False; i++],
      inStr, If[chars[[i]] === "\\", i++, If[chars[[i]] === "\"", inStr = False]],
      chars[[i]] === "\"", inStr = True,
      chars[[i]] === "(" && i < n && chars[[i + 1]] === "*", inCom = True; i++,
      chars[[i]] === "{", depth++,
      chars[[i]] === "}", depth--; If[depth === 0, res = i]];
    i++];
  If[res === None, AFFail["afMatchBrace: no matching brace"]];
  res
];

Options[AFCouplingsInstallModel] = {"ModelFile" -> Automatic, "OutputDir" -> Automatic};

AFCouplingsInstallModel[model_String : "THDM2", newName_String : "THDM2sym", OptionsPattern[]] := Module[
  {file = OptionValue["ModelFile"], dirs, text, chars, pos, start, brace, endB, out, outDir},
  If[!AssociationQ[AFCouplings], AFCouplingsInit[]];
  If[file === Automatic,
    dirs = Select[Flatten[{
      If[ToExpression["ValueQ[FeynArts`$ModelPath]"], ToExpression["FeynArts`$ModelPath"], {}],
      If[ToExpression["ValueQ[FeynArts`$FeynArtsDir]"], FileNameJoin[{ToExpression["FeynArts`$FeynArtsDir"], "Models"}], {}],
      FileNameJoin[{$UserBaseDirectory, "Applications", "FeynCalc", "FeynArts", "Models"}],
      FileNameJoin[{$UserBaseDirectory, "Applications", "FeynArts", "Models"}]}], StringQ[#] && DirectoryQ[#] &];
    file = FirstCase[Flatten[FileNames[model <> ".mod", dirs]], _String, None]];
  If[file === None || !FileExistsQ[file], AFFail["AFCouplingsInstallModel: model file ", model, ".mod not found; pass \"ModelFile\" -> path"]];
  text = Import[file, "Text", CharacterEncoding -> "UTF-8"];
  pos = StringPosition[text, "M$CouplingMatrices"];
  If[pos === {}, AFFail["AFCouplingsInstallModel: no M$CouplingMatrices in ", file]];
  start = pos[[1, 1]];
  chars = Characters[text];
  brace = start + First[First[StringPosition[StringTake[text, {start, StringLength[text]}], "{"]]] - 1;
  endB = afMatchBrace[chars, brace];
  (* swallow a trailing ";" if there is one *)
  If[endB < Length[chars] && chars[[endB + 1]] === ";", endB++];
  out = StringTake[text, {1, start - 1}] <> "M$CouplingMatrices = " <>
    ToString[AFCouplings["Symbolic"], InputForm, PageWidth -> Infinity] <> ";" <> StringTake[text, {endB + 1, StringLength[text]}];
  out = StringReplace[out, "M$ModelName = \"" <> model <> "\"" -> "M$ModelName = \"" <> newName <> "\""];
  outDir = If[OptionValue["OutputDir"] === Automatic, DirectoryName[file], OptionValue["OutputDir"]];
  Export[FileNameJoin[{outDir, newName <> ".mod"}], out, "Text", CharacterEncoding -> "UTF-8"];
  AFLog["wrote model file ", FileNameJoin[{outDir, newName <> ".mod"}], "  -> use  Model -> \"", newName, "\"  in InsertFields"];
  FileNameJoin[{outDir, newName <> ".mod"}]
];


(* ---------------------------------------------------------------------------------------------------------------------
   Self test on a small made-up model section (no FeynArts, no model file): scalar vertex, gauge vertex, chiral pair with
   IndexDelta, a Yukawa vertex with Mass[...] and colour, a vertex with three Lorentz structures, a zero entry, an unnamed field.
   Checks the symbols, the rollback (exact), that IndexDelta stays outside the symbol, the Mass rules, Keep / Map.            *)

AFCouplingsSelfTest[] := Module[{res = {}, add, saveM, saveC, saveA, sym, t, fields, expr},
  add[name_String, ok_] := (AppendTo[res, TrueQ[ok]]; Print["[ampflow] coupling check ", If[TrueQ[ok], "OK      ", "FAILED  "], name]);
  saveM = If[ValueQ[M$CouplingMatrices], M$CouplingMatrices, None]; saveA = AFCouplings;
  saveC = If[ValueQ[M$ClassesDescription], M$ClassesDescription, None];
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
  add["one symbol per non-numeric entry (1 + 1 + 2 + 2 + 3 + 0 + 1 = 10)", Length[sym["Rules"]] === 10];
  add["vertex symbol = Subscript[g, HoldForm[fields]], antiparticle as -name",
    MemberQ[Keys[sym["Rules"]], AFCouplingsSymbolOf[{S[5], -S[5], V[1]}]] &&
    !FreeQ[AFCouplingsSymbolOf[{S[5], -S[5], V[1]}], Times[-1, H]]];
  add["rollback is exact for every vertex", AFCouplingsVerify[]];
  t = sym["Symbolic"][[4, 2]];
  add["IndexDelta stays outside the symbol; the symbol carries the free index", !FreeQ[t, IndexDelta[j1, j2]] && !FreeQ[t, Subscript[g, HoldForm[__], ___][j1, o1]]];
  add["numeric entries are untouched", sym["Symbolic"][[6, 2]] === {{0}}];
  add["a field without a name is reported and still gets a unique symbol", !FreeQ[sym["Symbolic"][[7]], Subscript["Sf", 9]] || !FreeQ[sym["Symbolic"][[7]], _Subscript]];
  AFCouplingsApply[];
  add["Apply / Restore swap M$CouplingMatrices", M$CouplingMatrices === sym["Symbolic"] && (AFCouplingsRestore[]; M$CouplingMatrices === sym["Original"])];
  expr = {AFCouplingsSymbolOf[{S[1], S[1], S[2]}], Mass[F[2, {3}]]};
  add["AFCouplingsRollback: vertex -> original, Mass[F[2,{3}]] -> ml", AFCouplingsRollback[expr] === {-I EL c1, ml}];
  add["Keep leaves a symbol, Map substitutes one",
    AFCouplingsRollback[expr, "Keep" -> {AFCouplingsSymbolOf[{S[1], S[1], S[2]}]}][[1]] === expr[[1]] &&
    AFCouplingsRollback[expr, "Map" -> {AFCouplingsSymbolOf[{S[1], S[1], S[2]}] -> -I gx}][[1]] === -I gx];
  add["inventory counts the symbols", Length[AFCouplingsInventory[{expr[[1]], expr[[1]]}]] === 1];
  AFCouplings = saveA;
  M$CouplingMatrices =.; M$ClassesDescription =.;
  If[saveM =!= None, M$CouplingMatrices = saveM]; If[saveC =!= None, M$ClassesDescription = saveC];
  And @@ res
];
