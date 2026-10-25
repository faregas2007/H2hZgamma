(* STAND-IN, written by hand: NOT produced by FeynArts/FeynCalc (they were not available where this repo was developed).
   It shows the format 01_photon_selfenergy.m writes and what its result must be: the transverse photon self-energy
   Sigma_T(s) = -(e^2 Nc Q^2/(16 Pi^2)) (4/3) [ -(s + 2 m^2) B0(s,m,m) + 2 m^2 B0(0,m,m) + s/3 ],
   with FeynCalc's SMP atoms (e, Q_u, m_t) instead of ampflow's own symbols. it equals
   vacpol_fermion numerically. If the script's real output differs from this, the script (or its conventions) is wrong. *)
(-4*SMP["e"]^2*Nc*SMP["Q_u"]^2*(s/3 - (s + 2*SMP["m_t"]^2)*B0[s, SMP["m_t"]^2, SMP["m_t"]^2] + 2*SMP["m_t"]^2*B0[0, SMP["m_t"]^2, SMP["m_t"]^2]))/(48*Pi^2)
