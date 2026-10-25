-- Run explicitly in Studio Server. Isolated models/profiles; never the live service.
local root=Instance.new('Folder');root.Name='TycoonVisualFixture';root.Parent=workspace
local count=0
local function check(v,m) assert(v,m);count+=1 end
local ok,result=pcall(function()
 local models={}
 for i=1,8 do
  local m=Instance.new('Model');m.Name='Fixture'..i;m.Parent=root;models[i]=m
  local floor=Instance.new('Part');floor.Name='Plot_180x220';floor.Size=Vector3.new(180,1,220);floor.CFrame=CFrame.new(i*200,-1000,0);floor.Anchored=true;floor.Parent=m
 end
 local W=require(game.ServerScriptService.MountainServer.TycoonWorld)
 local R=require(game.ReplicatedStorage.MountainShared.Rules);local T=R.tycoon
 local service=W.new({model=function(i) return models[i] end,plot=function(p) return p.slot end})
 local player={UserId=90000001,slot=1};local p=R.newProfile(0);T.ensure(p,0);T.assign(p,1,'c1',0)
 local plot=models[1].TycoonProduction
 service.update(player,p)
 check(plot.StorageFill_1.Transparency==1,'empty fill hidden')
 p.tycoon.habitats[1].eggs=15;p.tycoon.habitats[1].value=15;service.update(player,p)
 check(plot.StorageFill_1.Size.X==14 and plot.StorageFill_1.Transparency==0,'half full gauge')
 p.tycoon.habitats[1].eggs=30;p.tycoon.habitats[1].value=30;p.tycoon.levels.automation=5;service.update(player,p)
 check(plot.StorageFill_1.Size.X==28,'full gauge')
 check(string.find(plot.Habitat_1.BillboardGui.TextLabel.Text,'FULL')~=nil,'full text cue')
 check(plot.ProcessorArch.Transparency==0 and plot.CollectorStatus.Transparency==0,'upgraded silhouettes visible')
 service.clear(1)
 check(plot.StorageFill_1.Transparency==1,'clear removes old storage indication')
 check(plot.ConveyorSpine:GetAttribute('Automation')==0 and plot.ConveyorSpine:GetAttribute('OwnerUserId')==nil,'clear removes owner and automation')
 check(math.abs(plot.ProcessorArch.Transparency-.9)<1e-6,'clear hides old installed equipment')
 local replacement=R.newProfile(0);T.ensure(replacement,0);service.update({UserId=90000002,slot=1},replacement)
 check(plot.ConveyorSpine:GetAttribute('OwnerUserId')==90000002,'replacement owns display')
 check(plot.ConveyorSpine:GetAttribute('ActiveHabitats')==0,'replacement has no old producers')
 check(plot.StorageFill_1.Transparency==1 and math.abs(plot.Habitat_3.Transparency-.8)<1e-6,'replacement empty and locked states')
 local parts=0
 for _,v in ipairs(plot:GetDescendants()) do if v:IsA('BasePart') then
  parts+=1;check(not v.CanCollide and not v.CanTouch,'dressing cannot obstruct gameplay')
  local relative=models[1].Plot_180x220.CFrame:PointToObjectSpace(v.Position)
  check(math.abs(relative.X)+v.Size.X/2<=55 and math.abs(relative.Z+10)+v.Size.Z/2<=60,'inside approved footprint')
 end end
 return {checks=count,partsPerEmptyPlot=parts,scope='isolated Studio visual fixtures; no real player state modified'}
end)
root:Destroy()
assert(ok,result)
return result
