(* ::Package:: *)

(* 03_h0_hzgamma.m

   Process   H0(k1+k2+k3) -> h0(k1) Z(k2) gamma(k3)       one loop, 2HDM (FeynArts model THDM2), Feynman gauge.

   FeynArts   : topologies, field insertion, amplitude          (ampflow_h0hzg.m)
   FeynCalc   : Dirac algebra, tensor reduction to PaVe         (ampflow_h0hzg.m)
   Physics    : A^{mu nu} = F1 P1 + F2 P2 + F3 P3 (+ F4 eps^{mu nu k1 k2}); the dual projector gives each F_i directly
                (ampflow_dual.m; report.pdf sections 3-4); D -> 4 keeps the rational terms
   Topologies : ALL one-loop topologies of 1 -> 3, classified per diagram: Irreducible, Reducible_<photon|Z|h0|none|multiple>,
                OnShell_<leg> (external-leg corrections on the leg's own mass shell: flagged, computed, not in the default total).
   Output     : $AFExportDir/h0hzg_<class>_<group>_<size>_F<i>.m   per class, loop group (Fermion, H, HGWu, GWu, Other) and size
                                                                   (Single, Self, Triangle, Box)
                $AFExportDir/h0hzg_<class>_F<i>.m          the sum over groups and sizes for one class
                $AFExportDir/h0hzg_F<i>.m                  the sum over the classes without OnShell, i = 1, 2, 3
                plain A0 B0 C0 D0 expressions in a, b (and c, x, y, Delta, the couplings from examples/thdm/models/thdm.model)
                that fc2lt translates to C++; Sum_pol |A|^2 = AFDualSumSquared[{F1, F2, F3}] (report eqs. 18, 29, 30).
   Work files : $AFExportDir/work/diagrams/*.m  one per diagram (stage 1), work/cells/*.m  one per class and cell (stage 2).
                A run that stops, fails or is killed is simply started again: what is on disk is not recomputed. A diagram that
                failed leaves work/diagrams/<...>.m.failed with the reason.

   Run order:   wolframscript -file 00_dual_projector_check.m      (algebra of the projector, couplings, fermion helpers; seconds)
                wolframscript -file 03_h0_hzgamma.m                 (TRIAL by default: first 2 diagrams per cell, files in export/trial)
                AF_MODE=full wolframscript -file 03_h0_hzgamma.m    (the long one, after the trial looks right)

   Environment (all optional):
     AF_MODE=full|trial   AF_TRIAL=n        trial size
     AF_GROUPS=H,Fermion  AF_SIZES=Box      only these cells
     AF_STAGE=Diagrams|Combine|All          stage 1 only / stage 2 only / both
     AF_SHARD=2/4                           this process does every 4th diagram, starting with the 2nd (stage 1; then AF_STAGE=Combine)
     AF_ONERROR=Stop                        stop at the first failing diagram (default: skip it and go on)
     AF_TIMELIMIT=600                       seconds per diagram
     AF_RECOMPUTE=1                         ignore the files already written
     AF_ROLLBACK=1                          put the model expressions into the forms (default: the symbols g_{...} stay, see h0hzg_couplings*.m)
     AF_APARTFF=0                           no ApartFF before TID (default: on)
     AF_SCHEMECHECK=0                       no gamma5 scheme comparison in the trial run (default: on)
   Verbosity (environment variable VERBOSE):
     VERBOSE=1   (default)                  one line per diagram, cell, stage
     VERBOSE=2 wolframscript -file 03_h0_hzgamma.m      also one line per step inside every diagram (conversion, trace, contraction,
                                            ApartFF, TID, kinematics, names), with seconds and size
     AF_LAMBDA5=TwoM2OverV2                 FeynArts' Lambda5 = 2 M^2/v^2 (default Same: the card's lambda_5 unchanged)

   Set $AFExportDir to <workspace>/amplitudes before running (default ./export) and list the files in a scan:
       scan b linspace 1000 30000 200 ;  set a 5000 ;  amplitudes h0hzg_F1 h0hzg_F2 h0hzg_F3
   (the sum Sum_pol |A|^2 is then formed from the three columns; AFDualSumSquared prints the Gram weights.)                   *)

$LoadAddOns = {"FeynArts"};
<< FeynCalc`
$FAVerbose = 0;

scriptDir = If[$InputFileName =!= "", DirectoryName[$InputFileName], NotebookDirectory[]];
Do[Get[FileNameJoin[{scriptDir, file}]],
  {file, {"ampflow_ff.m", "ampflow_dual.m", "ampflow_couplings.m", "ampflow_fermion.m", "ampflow_h0hzg.m", "ampflow_h0hzg_run.m"}}];
AFRequire[];
AFLog["verbosity ", $AFVerbose, "   (VERBOSE=2: step lines inside every diagram)"];
If[Environment["AF_APARTFF"] === "0", $AFDualApartFF = False];

If[!AFDualSelfTest[], AFFail["the dual projector self test failed: stop before the long run"]];

(* the environment -> options of AFH0hZgRun *)
env[name_String] := If[StringQ[Environment[name]] && Environment[name] =!= "", Environment[name], None];
envList[name_String] := If[env[name] === None, All, StringSplit[env[name], ","]];
trial = If[env["AF_MODE"] === "full", None, If[env["AF_TRIAL"] === None, 2, ToExpression[env["AF_TRIAL"]]]];

runOptions = Join[
  {"Trial" -> trial, "Groups" -> envList["AF_GROUPS"], "Sizes" -> envList["AF_SIZES"],
   "Couplings" -> "Symbolic", "Lambda5" -> If[env["AF_LAMBDA5"] === None, "Same", env["AF_LAMBDA5"]],
   "ExportDir" -> If[ValueQ[$AFExportDir], $AFExportDir, FileNameJoin[{scriptDir, "export"}]]},
  If[env["AF_STAGE"] =!= None, {"Stage" -> env["AF_STAGE"]}, {}],
  If[env["AF_SHARD"] =!= None, {"Shard" -> ToExpression /@ StringSplit[env["AF_SHARD"], "/"]}, {}],
  If[env["AF_ONERROR"] =!= None, {"OnError" -> env["AF_ONERROR"]}, {}],
  If[env["AF_TIMELIMIT"] =!= None, {"TimeLimit" -> ToExpression[env["AF_TIMELIMIT"]]}, {}],
  If[env["AF_RECOMPUTE"] =!= None, {"Recompute" -> True}, {}],
  If[env["AF_ROLLBACK"] === "1", {"RollBack" -> True}, {}],
  If[env["AF_SCHEMECHECK"] === "0", {"SchemeCheck" -> False}, {}]];

(* "Couplings" -> "Symbolic": the whole coupling section of THDM2 is made symbolic for the diagram work and rolled back on the finished
   form factors. "Lambda5" -> "Same" | "TwoM2OverV2": see ampflow_h0hzg.m; the model-coupling check stops the run if the choice is wrong. *)
result = AFH0hZgRun[Sequence @@ runOptions];

Which[
  result["Total"] =!= None, AFLog["Sum_pol |A|^2 = ", AFDualSumSquared[result["Total"]]],
  result["Failed"] =!= {}, AFLog["finished with failures (listed above); rerun to retry them"],
  True, AFLog["finished; no total written (trial, partial stage, or incomplete cells). Start the full run with AF_MODE=full."]];
