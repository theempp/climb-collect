-- Full scene is replicated with streaming disabled in the saved review.
local Players=game:GetService('Players')
local CP=game:GetService('ContentProvider')
local p=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='MountainArrival';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=10000
local bg=Instance.new('Frame');bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(20,35,32);bg.Parent=gui
local title=Instance.new('TextLabel');title.AnchorPoint=Vector2.new(.5,.5);title.Position=UDim2.fromScale(.5,.4);title.Size=UDim2.fromScale(.85,.12);title.BackgroundTransparency=1;title.Text='CLIMB & COLLECT';title.TextColor3=Color3.fromRGB(232,238,217);title.Font=Enum.Font.GothamBold;title.TextScaled=true;title.Parent=bg
local limit=Instance.new('UITextSizeConstraint');limit.MaxTextSize=32;limit.MinTextSize=14;limit.Parent=title
local status=title:Clone();status.Position=UDim2.fromScale(.5,.54);status.Size=UDim2.fromScale(.86,.12);status.Font=Enum.Font.Gotham;status.Text='Preparing the mountain…';status.UITextSizeConstraint.MaxTextSize=18;status.Parent=bg
local retry=Instance.new('TextButton');retry.AnchorPoint=Vector2.new(.5,.5);retry.Position=UDim2.fromScale(.5,.72);retry.Size=UDim2.new(.55,0,0,48);retry.Text='Retry loading';retry.Font=Enum.Font.GothamBold;retry.TextSize=18;retry.BackgroundColor3=Color3.fromRGB(176,207,162);retry.Visible=false;retry.Parent=bg
local size=Instance.new('UISizeConstraint');size.MaxSize=Vector2.new(300,48);size.Parent=retry
gui.Parent=p:WaitForChild('PlayerGui')
local controls,R
local running=false;local started=os.clock()
local function attempt()
 if running then return end;running=true;retry.Visible=false;status.Text='Preparing the mountain…'
 local t=os.clock();local done=false;local failures=0;local completed=0;local scene=false
 local worker=task.spawn(function()
  local ok,err=pcall(function()
  controls=require(p.PlayerScripts:WaitForChild('PlayerModule')):GetControls();controls:Disable()
  R=require(game.ReplicatedStorage:WaitForChild('MountainShared'):WaitForChild('ArrivalReadiness'))
  while not game:IsLoaded() do task.wait(.1) end
  local world=workspace:WaitForChild('ImpossibleMountain')
  while not world:GetAttribute('ArrivalReady') do task.wait(.1) end
  assert(not workspace.StreamingEnabled,'Full residency review requires streaming disabled')
  scene=true
  local assets={};for _,v in world:GetDescendants() do if v:IsA('BasePart') or v:IsA('Decal') or v:IsA('Texture') or v:IsA('ParticleEmitter') then table.insert(assets,v) end end
  for first=1,#assets,120 do
   local batch={};for i=first,math.min(first+119,#assets) do table.insert(batch,assets[i]) end
   local ok=pcall(function() CP:PreloadAsync(batch,function(_,s) if s~=Enum.AssetFetchStatus.Success then failures+=1 end end) end)
   if not ok then failures+=1 end
   completed=math.min(first+119,#assets);status.Text=string.format('Preparing scenery · %d / %d',completed,#assets)
   if failures>0 then break end
   task.wait()
  end
  done=true
  end)
  if not ok then failures+=1;workspace:SetAttribute('MountainArrivalError',tostring(err)) end
 end)
 -- Independent watchdog also covers dependencies before the policy module arrives.
 local function stateNow()
  if failures>0 then return 'retry' end
  if not R then return if os.clock()-t>=25 then 'retry' else 'loading' end
  return R.state(scene,done,os.clock()-t,failures)
 end
 repeat task.wait(.1) until stateNow()~='loading'
 local state=stateNow()
 if state=='ready' then
  workspace:SetAttribute('MountainArrivalSeconds',os.clock()-started);workspace:SetAttribute('MountainArrivalReady',true)
  workspace:SetAttribute('MountainArrivalFailure',nil);workspace:SetAttribute('MountainArrivalError',nil)
  controls:Enable();gui:Destroy()
 else
  pcall(task.cancel,worker);status.Text='Scenery is taking longer to load. Check your connection and retry.';retry.Visible=true
  workspace:SetAttribute('MountainArrivalFailure',failures>0 and 'asset' or 'timeout')
 end
 running=false
end
retry.Activated:Connect(function() task.spawn(attempt) end)
task.spawn(attempt)
