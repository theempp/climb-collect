-- Fresh-spawn optional-route test; movement, prompts and legal travel only.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local p=game.Players.LocalPlayer
local char=p.Character or p.CharacterAdded:Wait()
local h=char:WaitForChild('Humanoid');local rr=char:WaitForChild('HumanoidRootPart')
local w=workspace.ImpossibleMountain;local remotes=game.ReplicatedStorage.MountainRemotes
local state;local log={};local start=os.clock()
remotes.Event.OnClientEvent:Connect(function(kind,data)if kind=='state' then state=data end end)
local function record(label,ok,detail)
 table.insert(log,{label=label,ok=ok,detail=detail,elapsed=os.clock()-start,position=tostring(rr.Position)})
 workspace:SetAttribute('MountainQA_Branches',game.HttpService:JSONEncode({done=not ok,log=log}));return ok
end
local function walk(pos,label)
 local begin=os.clock();local timeout=(rr.Position-pos).Magnitude/9+15
 while (rr.Position-pos).Magnitude>4 and os.clock()-begin<timeout and h.Health>0 do h:MoveTo(pos);task.wait(.2) end
 return record(label,(rr.Position-pos).Magnitude<=4 and h.Health>0)
end
local function press(part)
 local camera=workspace.CurrentCamera;local previous=camera.CameraType;camera.CameraType=Enum.CameraType.Scriptable
 workspace.CurrentCamera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,7,13),part.Position);task.wait(.3)
 local q=part:FindFirstChildOfClass('ProximityPrompt');q:InputHoldBegin();task.wait(q.HoldDuration+.2);q:InputHoldEnd();task.wait(.4)
 camera.CameraType=previous
 remotes.Request:FireServer('State');task.wait(.2)
end
local function find(kind,id)
 for _,part in ipairs(w.Interactions:GetChildren()) do if part:GetAttribute('Kind')==kind and part:GetAttribute('Id')==id then return part end end
end
for i=script:GetAttribute('StartRoute') or 0,32 do
 local q=C.route(1,i/48);local pos=Vector3.new(q.x,q.y+3,q.z)
 if i>0 and i%12==0 then local b=C.route(1,(i+1)/48);pos+=Vector3.new(b.x-q.x,0,b.z-q.z).Unit*3 end
 if not walk(pos,'route:'..i) then return end
 if i==0 or i==24 then press(w.Checkpoints['1:'..(if i==0 then 'entrance' else 'recovery')]) end
 if i==14 or i==32 then
  local branch=if i==14 then 1 else 2
  local junction=C.route(1,if branch==1 then .29 else .66)
  local entry=Vector3.new(junction.x,junction.y+3,junction.z)
  if not walk(entry,'branch-junction:'..branch) then return end
  local terrace=entry+Vector3.new(math.cos(junction.angle),0,math.sin(junction.angle))*48
  if not walk(terrace,'branch-terrace:'..branch) then return end
  local discovery=find('Discovery','1:branch'..branch)
  if not walk(discovery.Position+Vector3.new(0,3,0),'branch:'..branch) then return end
  press(discovery)
  if not record('discovery:'..branch,state and state.discoveries['1:branch'..branch]==true) then return end
  local nest=find('Nest','1:nest'..branch)
  if not walk(nest.Position+Vector3.new(0,3,0),'nest:'..branch) then return end
  press(nest)
  if not record('egg:'..branch,state and #state.cargo>=1) then return end
  if branch==2 then
   local shortcut=find('Shortcut','1');if not walk(shortcut.Position+Vector3.new(0,3,0),'shortcut') then return end
   press(shortcut);if not record('attune',state and state.shortcuts['1']==true) then return end
   press(shortcut);task.wait(1)
   if not record('shortcut-travel',(rr.Position-w.Checkpoints['1:guardian'].Position).Magnitude<12) then return end
   press(w.Checkpoints['1:guardian'])
   if not record('extraction',state and #state.cargo==0 and #state.eggs>=2) then return end
  elseif not walk(pos,'return-to-route') then return end
 end
end
workspace:SetAttribute('MountainQA_Branches',game.HttpService:JSONEncode({done=true,passed=true,log=log,scope='Fresh spawn natural-avatar Blossom branches, nests, shortcut and extraction; no progression or position injection'}))
