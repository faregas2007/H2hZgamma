(* ::Package:: *)
(* 00_dual_projector_check.m

   Checks the algebra of ampflow_dual.m. Needs FeynCalc only (no FeynArts, no model, a few seconds):
     * the Gram matrix of the three structures, contracted by FeynCalc, against the closed form of the report (eq. 25)
     * det G = -(D-3) Delta^3/y  (eq. 26),  G.G^-1 = 1
     * the dual projector reproduces F_i from  Sum_j F_j P_j  exactly in D dimensions
     * CP-even and CP-odd structures do not mix, Proj_odd recovers F4
     * the photon Ward identity of the structures
     * the linear forms over A0..D0 and D -> 4 with the rational terms, against results known by hand
     * the coupling conversion (ampflow_couplings.m) on a small made-up model section: symbols, exact rollback, Keep / Map
   Exit status 1 if anything fails, so it can be run before every long job.

   Run:   wolframscript -file 00_dual_projector_check.m                                                                    *)

$FeynCalcStartupMessages = False;
<< FeynCalc`

scriptDir = If[$InputFileName =!= "", DirectoryName[$InputFileName], NotebookDirectory[]];
Get[FileNameJoin[{scriptDir, "ampflow_ff.m"}]];
Get[FileNameJoin[{scriptDir, "ampflow_dual.m"}]];
Get[FileNameJoin[{scriptDir, "ampflow_couplings.m"}]];
Get[FileNameJoin[{scriptDir, "ampflow_fermion.m"}]];

ok = AFLinearSelfTest[] && AFDualSelfTest[] && AFCouplingsSelfTest[] && AFFermionSelfTest[];
If[ok,
  AFLog["all dual projector and coupling checks passed"],
  AFFail["dual projector / coupling checks failed (see the lines above)"]];
