(* The mixture a reduced one-loop vertex has: a C0, a difference of B0 (the UV poles cancel) and an A0 that leaves
   one pole behind, so the divergent column is non-trivial:   Delta coefficient = alpha/Pi * mf^2 / s. *)
(alpha/Pi)*(mf^2*(s - 2*mf^2)*C0[0, 0, s, mf^2, mf^2, mf^2] + (s + 2*mf^2)*(B0[s, mf^2, mf^2] - B0[0, mf^2, mf^2]) + A0[mf^2]/s)
