-- Disposable local Play QA; actual traversal with day/start fixtures.
local RS=game.ReplicatedStorage;local H=game.HttpService;local p=game.Players:GetPlayers()[1];local ch=p.Character;local h=ch:WaitForChild('Humanoid');local root=ch.HumanoidRootPart
local bridge=game.ServerStorage.CC_DevBridge;local started=os.clock();local fall0=p:GetAttribute('CC_Falls') or 0

local function req(action,payload) bridge:Invoke('request',{name=p.Name,action=action,payload=payload}) end
local function flat(v) return v*Vector3.new(1,0,1) end
local function walk(at,jump,precise)
 script:SetAttribute('Target',tostring(at));pcall(function()root:SetNetworkOwner(nil)end)
 if jump then local landed=os.clock();h:MoveTo(root.Position);while h.FloorMaterial==Enum.Material.Air and os.clock()-landed<3 do task.wait(.05) end;task.wait(.1) end
 local start=os.clock();local limit=(flat(root.Position-at).Magnitude/12)*2+15;local lastJump=0
 h:MoveTo(at);if jump then h.Jump=true end
 while flat(root.Position-at).Magnitude>(precise and .7 or 2.2) do
  if os.clock()-start>limit then error('walk stalled '..tostring(at)..' at '..tostring(root.Position)) end
  if h.Health<=0 or (p:GetAttribute('CC_Falls') or 0)>fall0 then error('ordinary fall interrupted ascent') end
  if os.clock()-start>2 and os.clock()-lastJump>1.2 and h.FloorMaterial~=Enum.Material.Air and flat(root.AssemblyLinearVelocity).Magnitude<2 then h.Jump=true;lastJump=os.clock() end
  h:MoveTo(at);task.wait(.15)
 end
end
local function climb(sec)
 if ch:GetAttribute('CC_SectionId')~=sec.id then
  walk(Vector3.new(table.unpack(sec.entry)));task.wait(.8)
  for _=1,5 do req('traversal',{action='clip'});task.wait(.4);if ch:GetAttribute('CC_SectionId')==sec.id then break end end
 end
 assert(ch:GetAttribute('CC_SectionId')==sec.id,'wrong clip '..sec.id)
 for _=1,#sec.holds+20 do
  local mode=ch:GetAttribute('CC_TraversalState');if mode=='ground' then return end
  if mode=='hanging' then task.wait(2.1);req('traversal',{action='recover'})
  else
   local hold=sec.holds[ch:GetAttribute('CC_HoldIndex') or 1]
   if hold and (hold.stable or hold.alternative) and (ch:GetAttribute('CC_Stamina') or 100)<14 then task.wait(3) end
   req('traversal',{action='step',hand=ch:GetAttribute('CC_NextHand'),choice='stable'})
  end
  task.wait(.55)
 end
 error('climb incomplete '..sec.id)
end

local function call(action,payload) return H:JSONDecode(bridge:Invoke(action,payload or {})).result end
local rows={}
script:SetAttribute('Status','running')
local ok,err=pcall(function()
 for _,offset in {86400,172800} do
  call('clock',{offset=offset});call('move',{x=-60,y=53,z=2032});task.wait(1)
  root=p.Character.HumanoidRootPart;ch=p.Character;h=ch.Humanoid;root:SetNetworkOwner(nil);fall0=p:GetAttribute('CC_Falls') or 0
  req('practiceDailyStart',{timed=true});task.wait(.3)
  local before=call('snapshot');assert(before.dailyPractice.active,'daily start')
  local stages=before.dailyPractice.sections
  for i,id in stages do
   script:SetAttribute('Detail',id..' • '..i..'/'..#stages)
   if i>1 and id=='Practice:2' and stages[i-1]=='Practice:3' then
    walk(Vector3.new(-104,100,2006.5))
    local steps={};for _,v in workspace.World.TrainingYard:GetChildren() do if v.Name=='Step' and v.Position.Y>=59.1 then table.insert(steps,v) end end
    table.sort(steps,function(a,b)return a.Position.Y>b.Position.Y end)
    for _,v in steps do walk(v.Position+Vector3.yAxis*3) end
    walk(Vector3.new(-88,62,2011));walk(Vector3.new(-88,62,2016))
   end
   climb(H:JSONDecode(RS.CC_TraversalDefs[id].Value));task.wait(.8)
   local state=call('snapshot');assert(i==#stages or state.dailyPractice.active,'attempt canceled before finish')
  end
  task.wait(1);local after=call('snapshot');assert(not after.dailyPractice.active and after.dailyPractice.stamps==before.dailyPractice.stamps+1,'one confirmed stamp')
  table.insert(rows,{stages=#stages,before=before.dailyPractice,after=after.dailyPractice,training=after.gear.training,position=tostring(root.Position),kind='actual traversal inputs and physical loop; UTC offset/start position are fixtures'})
 end
end)
script:SetAttribute('Status',ok and 'complete' or 'failed');script:SetAttribute('Detail',ok and 'three- and five-stage circuits passed' or tostring(err))
local report={ok=ok,error=not ok and tostring(err) or nil,rows=rows,position=tostring(root.Position),attributes=ch:GetAttributes()}
local result=Instance.new('StringValue');result.Name='Report';result.Value=H:JSONEncode(report);result.Parent=script
-- Export Report from an authorized Studio command; ordinary Scripts cannot toggle HttpEnabled.
