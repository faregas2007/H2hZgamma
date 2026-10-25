(* A0, B0, C0 and D0 in ONE expression, written the FeynCalc way: SMP atoms and the Unicode name \[Alpha].
   Structure only (a toy): the Delta poles of B0(s) - B0(t) cancel, A0 leaves  alpha^2 (s+t)/(s t) mt^2. *)
\[Alpha]^2*(SMP["m_t"]^4*D0[0, 0, 0, 0, s, t, SMP["m_t"]^2, SMP["m_t"]^2, SMP["m_t"]^2, SMP["m_t"]^2] + s*SMP["m_t"]^2*C0[0, 0, s, SMP["m_t"]^2, SMP["m_t"]^2, SMP["m_t"]^2] + B0[s, SMP["m_t"]^2, SMP["m_t"]^2] - B0[t, SMP["m_t"]^2, SMP["m_t"]^2] + (s + t)/(s*t)*A0[SMP["m_t"]^2])
