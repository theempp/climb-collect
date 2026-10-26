-- Temporary actual-client walking/damage acceptance; no teleport or HP grants.
local ST=game:GetService('StudioTestService');local Players=game.Players
local P=require(game.ServerScriptService.MountainServer.Profiles)
local command=Instance.new('RemoteFunction');command.Name='FreeClimbQACommand';command.Parent=game.ReplicatedStorage
local result={mode=P.mode,checks=0,failures={},hazards={}}
local function check(ok,label) result.checks+=1;if not ok then table.insert(result.failures,label) end end
local ok,err=pcall(function()
 local deadline=os.clock()+100;local player
 repeat task.wait(1);player=Players:GetPlayers()[1] until (player and P.get(player) and player.Character and player.Character:FindFirstChild('HumanoidRootPart')) or os.clock()>deadline
 assert(player,'player loaded');task.wait(6)
 local function walk(x,y,z)
  local r=command:InvokeClient(player,'walk',Vector3.new(x,y,z));assert(r.ok,'walk: '..tostring(r.reason)..' '..tostring(r.position))
 end
 local start=player.Character:GetPivot().Position
 walk(4096,3,start.Z);walk(4096,17,-100);walk(4096,20,-220)
 for k=1,6 do
  local terrace=16+k*64;local entry=-210-(k-1)*200
  walk(4096,terrace+3,entry-130)
  local h=player.Character.Humanoid;local before=h.Health
  local hazard=workspace.ImpossibleMountain.Dynamics['Hazard_'..k]
  walk(4168,terrace+3,entry-154)
  local untilTime=os.clock()+12;local phases={}
  repeat phases[hazard:GetAttribute('Phase')]=true;task.wait(.1) until h.Health<before or os.clock()>untilTime
  local after=h.Health
  check(after<before and after>0,'section '..k..' actual hazard damage and survival')
  result.hazards[k]={kind=hazard:GetAttribute('Hazard'),before=before,after=after,phases=phases,position=tostring(player.Character:GetPivot().Position)}
  walk(4096,terrace+3,entry-130)
 end
 check(P.get(player).run==nil and #P.get(player).creatures==3,'no grants from hazard traversal')
 check(command:InvokeClient(player,'audit').hud==1,'one HUD after six hazards')
end)
if not ok then table.insert(result.failures,tostring(err)) end
result.ok=#result.failures==0;ST:EndTest(result)
