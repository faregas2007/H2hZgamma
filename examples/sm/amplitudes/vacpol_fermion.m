(* One-loop photon self-energy from a fermion loop, transverse part (conventions as in
   Denner, Fortschr. Phys. 41 (1993) 307).  Toy export in FeynCalc InputForm: only A0/B0.
   The Delta-pole is  alpha/(3 Pi) Nc Qf^2 s  -- the tests check exactly that.            *)
-(alpha/(4*Pi))*(4/3)*Nc*Qf^2*(-(s + 2*mf^2)*B0[s, mf^2, mf^2] + 2*mf^2*B0[0, mf^2, mf^2] + s/3)
