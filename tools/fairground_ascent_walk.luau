-- Actual WalkSpeed-12 / traversal-controller route run. No position writes or progress injection.
-- Run as a temporary server Script in Play. Poll its Status and Detail attributes.
local RS=game.ReplicatedStorage;local H=game.HttpService;local p=game.Players:GetPlayers()[1];local ch=p.Character;local h=ch:WaitForChild('Humanoid');local root=ch.HumanoidRootPart
local bridge=game.ServerStorage.CC_DevBridge;local started=os.clock();local fall0=p:GetAttribute('CC_Falls') or 0
local function req(action,payload) bridge:Invoke('request',{name=p.Name,action=action,payload=payload}) end
local function flat(v) return v*Vector3.new(1,0,1) end
local function walk(at,jump)
 script:SetAttribute('Target',tostring(at));pcall(function()root:SetNetworkOwner(nil)end)
 local start=os.clock();local limit=(flat(root.Position-at).Magnitude/12)*2+5;local jumped=false
 h:MoveTo(at);if jump then h.Jump=true end
 while flat(root.Position-at).Magnitude>2.2 do
  if os.clock()-start>limit then error('walk stalled '..tostring(at)..' at '..tostring(root.Position)) end
  if h.Health<=0 or (p:GetAttribute('CC_Falls') or 0)>fall0 then error('ordinary fall interrupted ascent') end
  if os.clock()-start>2 and not jumped and flat(root.AssemblyLinearVelocity).Magnitude<1 then h.Jump=true;jumped=true end
  h:MoveTo(at);task.wait(.15)
 end
end
local function climb(sec)
 walk(Vector3.new(table.unpack(sec.entry)));req('traversal',{action='clip'});task.wait(.3)
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
local function route(name)
 local points={};for line in RS.CC_Route[name].Value:gmatch('[^;]+') do local x,y,z,s=line:match('([^,]+),([^,]+),([^,]+),([^,]+)');table.insert(points,{at=Vector3.new(tonumber(x),tonumber(y)+3,tonumber(z)),s=tonumber(s)}) end
 local track=RS.CC_Track:FindFirstChild(name);track=track and H:JSONDecode(track.Value) or {}
 table.sort(track,function(a,b)return a.s0<b.s0 end)
 local cur=0
 local function portion(a,b) for _,point in points do if point.s>=a and point.s<b then walk(point.at);script:SetAttribute('Detail',name..' • '..math.floor(point.s)..' studs') end end end
 for _,segment in track do
  portion(cur,segment.s0)
  for i,node in segment.nodes do
   script:SetAttribute('Detail',name..':'..segment.id..':'..i)
   local sv=RS.CC_TraversalDefs:FindFirstChild(name..':'..segment.id..':'..i)
   if sv then climb(H:JSONDecode(sv.Value))
   elseif node.p then walk(Vector3.new(table.unpack(node.p))+Vector3.yAxis*2,node.k=='jump')
   elseif node.k=='wait' then task.wait(2)
   elseif node.k=='descend' then error('unmapped descent requires manual input') end
  end
  cur=math.max(cur,segment.s1)
 end
 portion(cur,math.huge)
end
script:SetAttribute('Status','running')
local ok,err=pcall(function()
 h.WalkSpeed=12
 walk(Vector3.new(0,52,1900));walk(Vector3.new(-227.2,52,1812.2));task.wait(1)
 route('Shepherd');route('SummitStair')
 walk(Vector3.new(0,3175,0));walk(Vector3.new(-30,3175,0))
 for flight=0,3 do for i=0,13 do walk(Vector3.new(-30+flight*12,3175+(flight*13+i)*1.5,flight%2==0 and -i*3.5 or -45.5+i*3.5)) end end
 walk(Vector3.new(40,3255,12));task.wait(3)
 local st=H:JSONDecode(bridge:Invoke('snapshot',{})).result;assert(st.summit.result,'no confirmed summit; inspect eligibility')
end)
script:SetAttribute('Status',ok and 'complete' or 'stopped');script:SetAttribute('Detail',ok and 'validated entire ascent' or tostring(err));script:SetAttribute('Seconds',os.clock()-started)
