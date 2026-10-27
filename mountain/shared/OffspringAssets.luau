-- Catalog species that have finished production offspring assets (ReplicatedStorage.MountainAssets.Offspring).
-- Sample: Blossom Rabbit (Floravelle family, Collection-v004) presents Mossbun. Others keep procedural art.
local O={
 mossbun={creature='blossom-rabbit-creature',egg='blossom-rabbit-egg',hatch='blossom-rabbit-hatch',carry='blossom-rabbit',
  companionScale=.9,
  -- Uploaded Animation asset ids per clip (owner account, uploaded 2026-10-26; 0 = not uploaded, Studio falls back to the local KeyframeSequence).
  clips={Idle=76817189963125,Move=126079378129091,Run=72223759322382,Turn=118799649097983,Reveal=82754906786976,Carried=118211324273081,Happy=88972364527437},
  revealScale=.8,eggHeight=3.9,runSpeed=19,turnRate=1.6},
}
function O.get(species) return O[species] end
return O
