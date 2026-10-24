local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local p=game.Players.LocalPlayer
local h=p.Character:WaitForChild('Humanoid')
local rr=p.Character:WaitForChild('HumanoidRootPart')
local start=os.clock();local log={}
local function walk(pos,label)
 local begin=os.clock();local timeout=(rr.Position-pos).Magnitude/10+16
 while (rr.Position-pos).Magnitude>5 and os.clock()-begin<timeout do
  h:MoveTo(pos);workspace.CurrentCamera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,10,17),pos);task.wait(.35)
 end
 local ok=(rr.Position-pos).Magnitude<=5
 table.insert(log,{label=label,ok=ok,seconds=os.clock()-begin,position=tostring(rr.Position),target=tostring(pos)})
 workspace:SetAttribute('MountainQA_Walk',game.HttpService:JSONEncode({log=log,elapsed=os.clock()-start,done=not ok}))
 return ok
end
for i=0,42 do
 local q=C.route(1,i/48);local pos=Vector3.new(q.x,q.y+3,q.z)
 if i>0 and i%12==0 then
  local next=C.route(1,(i+1)/48);pos+=Vector3.new(next.x-q.x,0,next.z-q.z).Unit*3
 end
 if not walk(pos,'route'..i) then return end
end
workspace:SetAttribute('MountainQA_Walk',game.HttpService:JSONEncode({log=log,elapsed=os.clock()-start,done=true,passed=true}))
