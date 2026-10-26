# Independent review — October 26, 2026

One initial P2: true→false→true within80ms dropped the last press. Real service regression failed before the fix, passed after accepting changed boolean intent and retaining duplicate-true pacing. Final independent review found no remaining important issue; movement14/carry8/entrances19 independently pass.

Live investigation found current R15 AnimationConstraint joints. Official docs confirm Transform writes in PreSimulation. Real-source pose tests failed on those joints before the guard fix and passed afterward. PostSimulation evidence confirms carry matrices with a full-weight running track and physical speed24.3.
