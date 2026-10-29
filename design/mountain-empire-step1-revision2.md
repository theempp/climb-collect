# Step1 revision2 — enlarged plots

2026-10-24. User explicitly selected180×220-stud plots and60 studs of front walking space. These dimensions supersede the110×120 plot footprint and narrow access treatment in the original blueprint for this revision. Still blockout only; no authorization for detailed construction or gameplay.

Saved place: `redesign/step1-revision2/MountainEmpire.Step1.LargerPlots.rbxl`. Original Step1 review and checkpoint remain hash-unchanged. Resize source: `redesign/step1-revision2/resize.luau` (run once on original Step1).

Eight180×220 plots,8-stud buffers,1496 total frontage; plot centers X=-658,-470,-282,-94,94,282,470,658. Plot area39,600 square studs versus13,200 previously (3×). Rear lodge markers remain35×30, moved to Z200. Front walking surface occupies X=-748..748,Z=-60..0. Gate/ramp group moved42 studs toward the mountain; terrace remains Y16 and ramp slope unchanged. Surrounding basin widened and deepened to fit. Three gates remain centered. No detailed architecture/landscaping or gameplay added.

Verified: eight plot size assertions and375 front walking-surface raycasts passed. Saved binary contains163 anchored blockout parts (145 Parts,8 spawns,10 wedges), down from172 because the front access strips were consolidated. Streaming stays enabled. Screenshots and navigation evidence are stored alongside the new place. Physical mobile/eight-client testing and hosted8-player capacity remain unresolved, as in Step1.

Tradeoff: outer plot fronts are now658 studs from the row center; the extra space increases travel to central gates. A route via the nearest ramp is approximately722 studs from an outer plot front (~45s at16studs/s), plus roughly11s from rear spawn. These are geometric estimates, not human timing.

STOP for review of the revised blockout.

Final verification:5/5 natural-spawn avatar walking legs passed from outer Plot01 through its enlarged courtyard onto/across the front walking space; no teleport injection. Review and checkpoint SHA256:0739107ebf395d077f4733d8410b23ce99d3cb080c3fa504ade5d79338f7daba. Screenshots:aerial.jpg and player-level.jpg in revision2 folder.

