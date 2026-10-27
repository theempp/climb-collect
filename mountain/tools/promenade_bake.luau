-- Edit only, on a fresh copy of CompactMountain.Review02 after promenade_sync: rebuild the home base as the promenade.
assert(not game:GetService('RunService'):IsRunning(),'Edit only')
assert(game.Name:find('HomePromenade',1,true),'Not the home-base promenade review')
local H=require(game.ServerStorage.MountainWorld.HomePromenade:Clone())
local sanctuary,world=workspace.Sanctuary,workspace.ImpossibleMountain
local before=0;for _,d in world:GetDescendants() do if d:IsA('BasePart') then before+=1 end end
local t=os.clock();local parts=H.apply(sanctuary,world)
local terrain=H.terrain()
local after,sanctuaryParts=0,0
for _,d in world:GetDescendants() do if d:IsA('BasePart') then after+=1 end end
for _,d in sanctuary:GetDescendants() do if d:IsA('BasePart') then sanctuaryParts+=1 end end
return {apply=parts,terrain=terrain,worldPartsBefore=before,worldPartsAfter=after,sanctuaryParts=sanctuaryParts,seconds=os.clock()-t}
