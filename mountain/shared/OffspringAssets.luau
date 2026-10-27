-- Catalog species that have finished production offspring assets (ReplicatedStorage.MountainAssets.Offspring).
-- Sample: Blossom Rabbit (Floravelle family, Collection-v004) presents Mossbun. Others keep procedural art.
local O={
 mossbun={creature='blossom-rabbit-creature',egg='blossom-rabbit-egg',hatch='blossom-rabbit-hatch',carry='blossom-rabbit',
  companionScale=.9,revealScale=.8,eggHeight=3.9,runSpeed=19,turnRate=1.6},
}
function O.get(species) return O[species] end
return O
