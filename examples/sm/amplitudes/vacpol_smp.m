(* The same physics as vacpol_fermion, written the way FeynCalc exports it: SMP[...] atoms, a Unicode pi, and e^2
   instead of alpha. The tests require its numbers to equal vacpol_fermion's (e^2 = 4 pi alpha, m_t = mf). *)
-(SMP["e"]^2/(16 π^2))*(4/3)*Nc*Qf^2*(-(s + 2*SMP["m_t"]^2)*B0[s, SMP["m_t"]^2, SMP["m_t"]^2] + 2*SMP["m_t"]^2*B0[0, SMP["m_t"]^2, SMP["m_t"]^2] + s/3)
