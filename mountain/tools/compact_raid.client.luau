-- Sandstone entry may drop six studs before the arrival check.
-- Natural summit raid -> cargo escape through all six sections, followed by six hazards.
local p=game.Players.LocalPlayer;local h=p.Character.Humanoid;local rr=h.RootPart
local remotes=game.ReplicatedStorage.MountainRemotes;local w=workspace.ImpossibleMountain
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local state;local replies={};local serial=0;local log={};local started=os.clock();local failed=false;local messages={}
local event=remotes.Event.OnClientEvent:Connect(function(kind,data) if kind=='state' then state=data elseif kind=='toast' then table.insert(messages,{elapsed=os.clock()-started,text=data}) end end)
local response=remotes.UIResult.OnClientEvent:Connect(function(r) replies[r.id]=r end)
local function publish(done)
 workspace:SetAttribute('MountainQA_QualityRaid',game.HttpService:JSONEncode({done=done,passed=done and not failed,log=log,messages=messages,elapsed=os.clock()-started,health=h.Health}))
end
local function check(ok,label,data)
 table.insert(log,{ok=ok==true,label=label,data=data,position=tostring(rr.Position),speed=h.WalkSpeed});failed=failed or not ok;publish(not ok);return ok
end
local function request(action,payload)
 serial+=1;local id='mountainquality:'..serial;remotes.UIRequest:FireServer(id,action,payload)
 local deadline=os.clock()+5;repeat task.wait(.05) until replies[id] or os.clock()>deadline
 return replies[id]
end
local function compact(q)
 if q.Z> -210 then return q end
 local result=Vector3.new(4096,16,-210)+(q-Vector3.new(4096,16,-210))*.85
 if q.X==4038 or q.X==4154 then result=Vector3.new(q.X,result.Y,result.Z) end
 return result
end
local function walk(q,label,verticalTolerance)
 q=compact(q)
 local begin=os.clock();local timeout=(rr.Position-q).Magnitude/10+12
 repeat h:MoveTo(q);task.wait(.12) until Vector3.new(rr.Position.X-q.X,0,rr.Position.Z-q.Z).Magnitude<2.4 or os.clock()-begin>timeout or h.Health<=0
 return check(h.Health>0 and Vector3.new(rr.Position.X-q.X,0,rr.Position.Z-q.Z).Magnitude<3 and math.abs(rr.Position.Y-q.Y)<(verticalTolerance or 5),label,{seconds=os.clock()-begin})
end
task.spawn(function()
 local ok,err=pcall(function()
  request('State');task.wait(.3);local ownedBefore=#state.creatures
  remotes.SprintRequest:FireServer(true);task.wait(.3)
  if rr.Position.Z>-160 then
   for _,q in {Vector3.new(3438,3.1,-48),Vector3.new(3738,31.1,-108),Vector3.new(3960,31.1,-166),Vector3.new(3960,31.1,-182),Vector3.new(3960,19.1,-210),Vector3.new(4090,19.1,-210)} do if not walk(q,'entrance') then return end end
  end
  for k=1,6 do local y=16+(k-1)*64;local z=-210-(k-1)*200
   for _,d in {40,80,124,170} do if not walk(Vector3.new(4090,y+64*math.min(d/120,1)+3,z-d),k..':approach') then return end end
  end
  if not walk(Vector3.new(4038,403,-1384),'summit egg') then return end
  for i=1,8 do local strikeAt=os.clock();local r=request('Strike','raid:6:1');if not check(r and r.ok,'summit strike '..i,r) then return end;if i<8 then task.wait(math.max(0,.49-(os.clock()-strikeAt))) end end
  task.wait(.14)
  if not check(state.run and state.run.phase=='revealed' and #state.creatures==ownedBefore,'reveal is not ownership',{run=state.run,roster=#state.creatures}) then return end
  local id=state.run.id;local pickup=request('Pickup',id)
  if not check(pickup and pickup.ok,'pickup through ordinary request',pickup) then return end
  h:MoveTo(compact(Vector3.new(4038,403,-1336)));task.wait(.1)
  if not check(p.Character:GetAttribute('CarryingCreature')==true and math.abs(h.WalkSpeed-24.3)<.01,'cargo sprint speed unchanged',h.WalkSpeed) then return end
  if not walk(Vector3.new(4038,403,-1336),'carry clear of guardian') then return end
  if not walk(Vector3.new(4090,403,-1334),'carry join downhill lane') then return end
  for k=6,1,-1 do local y=16+(k-1)*64;local z=-210-(k-1)*200
   for _,d in {124,80,40,2} do
    if not walk(Vector3.new(4090,y+64*math.min(d/120,1)+3,z-d),k..':cargo descent') then return end
    if not check(p.Character:GetAttribute('CarryingCreature')==true,'cargo retained '..k..':'..d) then return end
   end
  end
  if not walk(Vector3.new(4090,19,-160),'physical sanctuary return') then return end
  task.wait(1);request('State');task.wait(.3)
  if not check(state.run==nil and #state.creatures==ownedBefore+1,'physical exit secures exactly one',{before=ownedBefore,after=#state.creatures,run=state.run}) then return end
  remotes.SprintRequest:FireServer(false);task.wait(.3)
  -- Encounter each unchanged hazard using actual damage and ordinary walk-only escape.
  for k=1,6 do local y=16+k*64;local z=-210-(k-1)*200
   if not walk(Vector3.new(4090,y+3,z-126),k..':hazard approach') then return end
   local hazard=w.Dynamics['Hazard_'..k];local before=h.Health
   if not walk(Vector3.new(4168,y+3,z-154),k..':hazard entry',if k==3 then 9 else 5) then return end
   local deadline=os.clock()+12;local phases={}
   repeat phases[hazard:GetAttribute('Phase')]=true;task.wait(.1) until h.Health<before-2 or os.clock()>deadline
   if not check(h.Health>0 and h.Health<before-2,k..':hazard damage and survival',{before=before,after=h.Health,phases=phases}) then return end
   if k==3 then
    -- Wait for an actual drop before testing the repaired ramp without jumping.
    local untilTime=os.clock()+12;repeat task.wait(.1) until rr.Position.Y<16+(y-16)*.85+1 or os.clock()>untilTime
    if not check(rr.Position.Y<16+(y-16)*.85+1,'sandstone drop exercised',rr.Position.Y) then return end
    if not walk(Vector3.new(4168,y+3,z-177),'sandstone walk-only recovery') then return end
   end
   if not walk(Vector3.new(4090,y+3,z-130),k..':hazard escape') then return end
  end
  publish(true)
 end)
 if not ok then check(false,'probe error',tostring(err));publish(true) end
 event:Disconnect();response:Disconnect()
end)
return 'Natural summit raid, six-section cargo escape, and hazard probe started'
