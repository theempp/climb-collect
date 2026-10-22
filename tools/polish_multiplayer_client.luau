-- Disposable actual-client QA agent. Never included in the saved place or sync manifest.
local P=game.Players.LocalPlayer
local rpc=game.ReplicatedStorage:WaitForChild('PolishMultiplayerRPC',60)
local remotes=game.ReplicatedStorage:WaitForChild('CC_Remotes')
local received={};local latest
remotes.CoreFx.OnClientEvent:Connect(function(v) if v.kind=='profileInspect' then received[v.requestId]=v end end)
remotes.CoreState.OnClientEvent:Connect(function(v) latest=v end)
local function waitFor(fn,seconds)
 local deadline=os.clock()+seconds;repeat local v=fn();if v then return v end;task.wait(.05) until os.clock()>deadline
end
local input
local function key(k)
 input=input or game.UserInputService:CreateVirtualInput();input:SendKey(true,k);task.wait(.1);input:SendKey(false,k)
end
rpc.OnClientInvoke=function(action,arg)
 local ok,value=pcall(function()
  local gui=P.PlayerGui:WaitForChild('CC_CoreUI',20)
  if action=='ready' then return {name=P.Name,userId=P.UserId,client=game.RunService:IsClient(),gui=gui~=nil} end
  if action=='view' then
   local other=game.Players:GetPlayerByUserId(arg);local at=other.Character.Head.Position
   workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
   workspace.CurrentCamera.CFrame=CFrame.lookAt(P.Character.HumanoidRootPart.Position+Vector3.new(0,6,14),at)
   task.wait(2);local tags={};for _,v in gui:GetChildren() do if v.Name=='ExplorerTag' then table.insert(tags,{enabled=v.Enabled,adornee=v.Adornee and v.Adornee.Parent.Name}) end end;return tags
  end
  if action=='inspect' then
   local id='qa:'..tostring(os.clock());remotes.CoreRequest:FireServer('profileInspect',{subjectUserId=arg,requestId=id})
   return waitFor(function()return received[id]end,5) or {status='timeout'}
  end
  if action=='clickTag' then
   local tag=waitFor(function()return gui:FindFirstChild('ExplorerTag')end,4);assert(tag,'tag absent')
   local at=workspace.CurrentCamera:WorldToViewportPoint(tag.Adornee.Position+tag.StudsOffsetWorldSpace)
   local button=tag:FindFirstChildOfClass('TextButton');local xy=button.AbsolutePosition+button.AbsoluteSize/2
   local inset=game.GuiService:GetGuiInset();local log={absolute=tostring(xy),projected=tostring(at),inset=tostring(inset),active=button.Active,enabled=tag.Enabled,viewport=tostring(workspace.CurrentCamera.ViewportSize),events={}}
   for _,event in {'MouseEnter','MouseButton1Down','Activated'} do button[event]:Connect(function()table.insert(log.events,event)end) end
   input=input or game.UserInputService:CreateVirtualInput()
   for i,pos in {Vector2.new(at.X,at.Y),Vector2.new(at.X,at.Y)+inset} do
    input:SendMousePosition(pos);task.wait(.2);input:SendMouseButton(pos,Enum.UserInputType.MouseButton1,true);task.wait(.1);input:SendMouseButton(pos,Enum.UserInputType.MouseButton1,false)
    if waitFor(function()local p=gui:FindFirstChild('Portfolio');return p and p.Visible end,.7) then log.open=true;log.candidate=i;return log end
   end
   return log
  end
  if action=='close' then key(Enum.KeyCode.Escape);task.wait(.2);return not gui.Portfolio.Visible end
  if action=='r3' then key(Enum.KeyCode.ButtonR3);return waitFor(function()return gui.Portfolio.Visible end,3)==true end
  if action=='space' then key(Enum.KeyCode.Space);task.wait(.4) end
  if action=='snapshot' or action=='space' then
   local f=workspace:FindFirstChild('PersonalSummitScene');local st=latest and latest.summit
   return {scene=f~=nil,camera=tostring(workspace.CurrentCamera.CameraType),presentation=P:GetAttribute('CC_SummitPresentation'),result=st and st.result and st.result.id,skipBound=game.ContextActionService:GetAllBoundActionInfo().CC_SummitSkip~=nil}
  end
  if action=='leave' then task.delay(.2,function()game:GetService('StudioTestService'):LeaveTest()end);return true end
 end)
 if ok then return {ok=true,value=value} else return {ok=false,value=tostring(value)} end
end
