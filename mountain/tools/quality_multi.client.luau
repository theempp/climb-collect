-- Temporary test client, injected only into a local Studio test; never packaged.
local RS=game:GetService('ReplicatedStorage')
local player=game.Players.LocalPlayer
local command=RS:WaitForChild('FreeClimbQACommand',120)
local remotes=RS:WaitForChild('MountainRemotes',120)
local replies={};local serial=0
remotes.UIResult.OnClientEvent:Connect(function(r) replies[r.id]=r end)
command.OnClientInvoke=function(action,data)
 if action=='stream' then
  player:RequestStreamAroundAsync(data,5);return {ok=true}
 elseif action=='walk' then
  local deadline=os.clock()+75
  local lastPosition;local lastProgress=os.clock();local jumps=0
  repeat
   local c=player.Character;local r=c and c:FindFirstChild('HumanoidRootPart');local h=c and c:FindFirstChildOfClass('Humanoid')
   if not r or not h or h.Health<=0 then return {ok=false,reason='dead'} end
   if (r.Position-data).Magnitude<5 then h:MoveTo(r.Position);return {ok=true,position=tostring(r.Position),jumps=jumps} end
   if not lastPosition or (r.Position-lastPosition).Magnitude>1 then lastPosition=r.Position;lastProgress=os.clock()
   elseif os.clock()-lastProgress>1.5 then h.Jump=true;jumps+=1;lastProgress=os.clock() end
   h:MoveTo(data);task.wait(.3)
  until os.clock()>deadline
  return {ok=false,reason='walk timeout',position=tostring(player.Character:GetPivot().Position)}
 elseif action=='request' then
  serial+=1;local id='freeclimbqa:'..serial
  remotes.UIRequest:FireServer(id,data.action,data.payload)
  local untilTime=os.clock()+12
  repeat task.wait(.05) until replies[id] or os.clock()>untilTime
  return replies[id] or {ok=false,message='request timeout'}
 elseif action=='audit' then
  local hud=0;for _,v in ipairs(player.PlayerGui:GetChildren()) do if v.Name=='MountainHUD' then hud+=1 end end
  local guardian=workspace.ImpossibleMountain.Encounters.Guardian_1
  return {ok=true,hud=hud,guardianState=guardian:GetAttribute('GuardianState'),target=guardian:GetAttribute('TargetUserId'),health=player.Character.Humanoid.Health}
 elseif action=='leave' then
  task.delay(.25,function() game:GetService('StudioTestService'):LeaveTest() end)
  return {ok=true}
 end
 return {ok=false,reason='unknown command'}
end
RS:WaitForChild('FreeClimbQAReady'):FireServer()
