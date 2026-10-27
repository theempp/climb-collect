-- Catalog species that have finished production offspring assets (ReplicatedStorage.MountainAssets.Offspring).
-- Sample: Blossom Rabbit (Floravelle family, Collection-v004) presents Mossbun. Others keep procedural art.
local O={
 mossbun={creature='blossom-rabbit-creature',egg='blossom-rabbit-egg',hatch='blossom-rabbit-hatch',carry='blossom-rabbit',
  companionScale=.9,
  -- Uploaded Animation asset ids per clip (0 = not uploaded; Studio falls back to the local KeyframeSequence).
  clips={Idle=0,Move=0,Run=0,Turn=0,Reveal=0,Carried=0,Happy=0},revealScale=.8,eggHeight=3.9,runSpeed=19,turnRate=1.6},
}
function O.get(species) return O[species] end
return O
