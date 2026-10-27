-- Edit-only authoring: derive Run, Turn and Happy KeyframeSequences from a rig's authored Move/Idle/Reveal/Carried.
-- Re-runnable: replaces previously derived clips. Source clips are never modified.
local Offspring=game.ReplicatedStorage.MountainAssets.Offspring
local function derive(model)
 local function find(name) return model:FindFirstChild('Rig|'..name,true) end
 local move,idle,reveal,carried=find('Move'),find('Idle'),find('Reveal'),find('Carried')
 assert(move and idle and reveal and carried,'Missing authored clips on '..model.Name)
 local home=move.Parent
 for _,name in {'Run','Turn','Happy'} do local old=home:FindFirstChild('Rig|'..name);if old then old:Destroy() end end
 local function scaled(cf,rot,pos)
  local axis,angle=cf:ToAxisAngle()
  local r=if math.abs(angle)<1e-6 then CFrame.identity else CFrame.fromAxisAngle(axis,angle*rot)
  return CFrame.new(cf.Position*pos)*r
 end
 local function retimed(source,name,timeScale,rot,rootLift)
  local k=source:Clone();k.Name='Rig|'..name;k.Loop=true;k.Priority=Enum.AnimationPriority.Action
  for _,kf in k:GetKeyframes() do
   kf.Time*=timeScale
   for _,pose in kf:GetDescendants() do if pose:IsA('Pose') then
    pose.CFrame=scaled(pose.CFrame,rot,if pose.Name=='Root' then rootLift else 1)
   end end
  end
  k.Parent=home;return k
 end
 -- Run: faster, longer strides, higher hops. Turn: small in-place steps; code supplies the yaw.
 retimed(move,'Run',.62,1.3,1.25)
 retimed(move,'Turn',.8,.55,.3)
 -- Happy: two hops; peaks use Reveal's excited head/ears and Carried's tucked legs.
 local function poseAt(seq,time)
  local best,dist=nil,math.huge
  for _,kf in seq:GetKeyframes() do if math.abs(kf.Time-time)<dist then best=kf;dist=math.abs(kf.Time-time) end end
  return best
 end
 local excited=poseAt(reveal,.75);local tucked=poseAt(carried,0);local rest=poseAt(idle,0)
 local happy=Instance.new('KeyframeSequence');happy.Name='Rig|Happy';happy.Loop=false;happy.Priority=Enum.AnimationPriority.Action
 local fromExcited={Head=true,EarL=true,EarR=true,Body=true,Tail00=true}
 for _,step in {{0,0},{.25,45},{.5,0},{.75,45},{1,0},{1.25,0}} do
  local kf=rest:Clone();kf.Time=step[1];kf.Parent=happy
  if step[2]>0 then
   for _,pose in kf:GetDescendants() do if pose:IsA('Pose') then
    local donor=if fromExcited[pose.Name] then excited elseif pose.Name:match('^Fore') or pose.Name:match('^Hind') then tucked else nil
    local match=donor and donor:FindFirstChild(pose.Name,true)
    if match then pose.CFrame=match.CFrame end
    if pose.Name=='Root' then pose.CFrame=CFrame.new(0,step[2],0)*pose.CFrame.Rotation end
    pose.EasingStyle=Enum.PoseEasingStyle.Cubic
   end end
  end
 end
 happy.Parent=home
 return {model.Name,#home:GetChildren()}
end
local results={}
for _,m in Offspring:GetChildren() do if m:GetAttribute('ReviewKind')=='creature' then table.insert(results,derive(m)) end end
return results
