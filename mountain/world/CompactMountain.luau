-- One-time baked-world migration. Terrain is handled by the separate edit recipe.
local M={version=1}
-- Safe correction for the initial compact diagnostic; never rescale its terrain/parts.
function M.restoreEncounterClearance(root)
 for k=1,6 do for side=1,2 do
  local pad=assert(root.Interactions:FindFirstChild('raid:'..k..':'..side),'Missing raid nest')
  local x=4096+(if side==1 then -58 else 58)
  pad.CFrame+=Vector3.new(x-pad.Position.X,0,0)
 end end
 root:SetAttribute('CompactEncounterClearanceVersion',1)
end
function M.apply(root)
 if root:GetAttribute('CompactMountainVersion')==M.version then M.restoreEncounterClearance(root);return end
 local G=require(game.ReplicatedStorage.MountainShared.CompactGeometry)
 local origin=Vector3.new(4096,16,-210)
 local function mapped(v) return origin+(v-origin)*G.scale end
 local protected={};local counts={ground=0,props=0}
 local function translateTree(node,pivot)
  local delta=mapped(pivot)-pivot
  for _,p in node:GetDescendants() do if p:IsA('BasePart') then p.CFrame+=delta;protected[p]=true;counts.props+=1 end end
  if node:IsA('BasePart') then node.CFrame+=delta;protected[node]=true;counts.props+=1 end
 end
 -- Keep actors and every hazard's animated assembly at authored scale.
 for _,m in root.Encounters:GetChildren() do if m:IsA('Model') then
  local k=m:GetAttribute('Kingdom')
  local pivot=if k then Vector3.new(4096,16+k*64,-210-(k-1)*200-185) else m:GetPivot().Position
  translateTree(m,pivot)
 end end
 for _,p in root.Dynamics:GetChildren() do if p:IsA('BasePart') then translateTree(p,p.Position) end end
 for _,folder in {root.Interactions,root.Checkpoints} do
  for _,p in folder:GetChildren() do if p:IsA('BasePart') then
   local old=p.Position;translateTree(p,old)
   if p.Name:match('^raid:') then p.CFrame+=Vector3.new(old.X-p.Position.X,0,0) end
   if p:GetAttribute('ArenaX') then local a=mapped(Vector3.new(p:GetAttribute('ArenaX'),p:GetAttribute('ArenaY'),p:GetAttribute('ArenaZ')));p:SetAttribute('ArenaX',a.X);p:SetAttribute('ArenaY',a.Y);p:SetAttribute('ArenaZ',a.Z) end
  end end
 end
 for _,p in root:GetDescendants() do if p:IsA('BasePart') and not protected[p] then
  -- Sanctuary exits/frontage stay at their original coordinates.
  if p:IsDescendantOf(root.SanctuaryExits) or (root:FindFirstChild('MountainApproaches') and p:IsDescendantOf(root.MountainApproaches)) or p.Name=='SanctuaryApproach' or p.Name=='ExitLantern' then continue end
  p.CFrame=CFrame.new(mapped(p.Position))*p.CFrame.Rotation;p.Size*=G.scale
  if p.Name=='OpenAscent' or p.Name=='DownhillLane' then p.Size=Vector3.new(G.escapeWidth,p.Size.Y,p.Size.Z) end
  counts.ground+=1
 end end
 -- The original side entrances still meet the narrower face with ample clearance.
 root:SetAttribute('CompactMountainVersion',M.version)
 root:SetAttribute('CompactScale',G.scale)
 root:SetAttribute('CompactReport',game.HttpService:JSONEncode(counts))
 M.restoreEncounterClearance(root)
 return counts
end
return M
