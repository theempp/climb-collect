-- Actual WalkSpeed-12 / traversal-controller route run. No position writes or progress injection.
-- Run as a temporary server Script in Play. Poll its Status and Detail attributes.
local RS=game.ReplicatedStorage;local H=game.HttpService;local p=game.Players:GetPlayers()[1];local ch=p.Character;local h=ch:WaitForChild('Humanoid');local root=ch.HumanoidRootPart
local bridge=game.ServerStorage.CC_DevBridge;local started=os.clock();local fall0=p:GetAttribute('CC_Falls') or 0
local resume=script:GetAttribute('ResumeSection');local resumeDistance=script:GetAttribute('ResumeDistance')
local function req(action,payload) bridge:Invoke('request',{name=p.Name,action=action,payload=payload}) end
local function flat(v) return v*Vector3.new(1,0,1) end
local function walk(at,jump,precise)
 script:SetAttribute('Target',tostring(at));pcall(function()root:SetNetworkOwner(nil)end)
 if jump then local landed=os.clock();h:MoveTo(root.Position);while h.FloorMaterial==Enum.Material.Air and os.clock()-landed<3 do task.wait(.05) end;task.wait(.1) end
 local start=os.clock();local limit=(flat(root.Position-at).Magnitude/12)*2+15;local lastJump=0
 h:MoveTo(at);if jump then h.Jump=true end
 -- Humanoid.MoveTo considers targets reached within roughly one stud; do not
 -- demand sub-stud convergence and mislabel a successful stop as blocked terrain.
 while flat(root.Position-at).Magnitude>(precise and 1.6 or 2.2) do
  if os.clock()-start>limit then error('walk stalled '..tostring(at)..' at '..tostring(root.Position)) end
  if h.Health<=0 or (p:GetAttribute('CC_Falls') or 0)>fall0 then error('ordinary fall interrupted ascent') end
  if os.clock()-start>2 and os.clock()-lastJump>1.2 and h.FloorMaterial~=Enum.Material.Air and flat(root.AssemblyLinearVelocity).Magnitude<2 then h.Jump=true;lastJump=os.clock() end
  h:MoveTo(at);task.wait(.15)
 end
end
local function climb(sec)
 if ch:GetAttribute('CC_SectionId')~=sec.id then
  req('traversal',{action='clip'});task.wait(.2)
  if ch:GetAttribute('CC_SectionId')~=sec.id then walk(Vector3.new(table.unpack(sec.entry)));task.wait(.8) end
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
local function route(name)
 local points={};for line in RS.CC_Route[name].Value:gmatch('[^;]+') do local x,y,z,s=line:match('([^,]+),([^,]+),([^,]+),([^,]+)');table.insert(points,{at=Vector3.new(tonumber(x),tonumber(y)+3,tonumber(z)),s=tonumber(s)}) end
 local track=RS.CC_Track:FindFirstChild(name);track=track and H:JSONDecode(track.Value) or {}
 table.sort(track,function(a,b)return a.s0<b.s0 end)
 local cur=0
 local crossedClearance=false;local crossedUpper=false;local crossedRidge=false;local crossedCliff=false;local crossedHigh=false
 local function portion(a,b)
  for _,point in points do
   if point.s>=math.max(a,resumeDistance or 0) and point.s<b then
    if name=='Shepherd' and point.s>=5801.9 and point.s<5892.9 then
     if not crossedClearance then
      for _,v in require(game.ServerStorage.CC_Generators.ShepherdClearanceWalk).points do walk(Vector3.new(table.unpack(v))+Vector3.yAxis*3) end
      crossedClearance=true
     end
    elseif name=='Shepherd' and point.s>=5941.1 and point.s<6132.3 then
     if not crossedUpper then
      for _,v in require(game.ServerStorage.CC_Generators.ShepherdClearanceWalk).secondPoints do walk(Vector3.new(table.unpack(v))+Vector3.yAxis*3) end
      crossedUpper=true
     end
    elseif name=='Shepherd' and point.s>=8616 and point.s<8756.9 then
     if not crossedRidge then
      for _,v in require(game.ServerStorage.CC_Generators.ShepherdClearanceWalk).thirdPoints do walk(Vector3.new(table.unpack(v))+Vector3.yAxis*3) end
      crossedRidge=true
     end
    elseif name=='Shepherd' and point.s>=9268.3 and point.s<9345.6 then
     if not crossedCliff then
      for _,v in require(game.ServerStorage.CC_Generators.ShepherdClearanceWalk).fourthPoints do walk(Vector3.new(table.unpack(v))+Vector3.yAxis*3) end
      crossedCliff=true
     end
    elseif name=='Shepherd' and point.s>=9369.3 and point.s<10203 then
     if not crossedHigh then
      for _,v in require(game.ServerStorage.CC_Generators.ShepherdClearanceWalk).fifthPoints do walk(Vector3.new(table.unpack(v))+Vector3.yAxis*3) end
      crossedHigh=true
     end
    else walk(point.at) end
    script:SetAttribute('Detail',name..' • '..math.floor(point.s)..' studs')
   end
  end
 end
 for _,segment in track do
  if resumeDistance and segment.s1<resumeDistance then cur=segment.s1;continue end
  local firstNode=1
  if resume then
   firstNode=nil;for i in segment.nodes do if name..':'..segment.id..':'..i==resume then firstNode=i;break end end
   if not firstNode then cur=math.max(cur,segment.s1);continue end
   resume=nil
  else portion(cur,segment.s0) end
  for i,node in segment.nodes do
   if i<firstNode then continue end
   script:SetAttribute('Detail',name..':'..segment.id..':'..i)
   local sv=RS.CC_TraversalDefs:FindFirstChild(name..':'..segment.id..':'..i)
   if sv then climb(H:JSONDecode(sv.Value))
   elseif node.p then
    local nextDef=RS.CC_TraversalDefs:FindFirstChild(name..':'..segment.id..':'..(i+1))
    local inClipRange=nextDef and (root.Position-Vector3.new(table.unpack(H:JSONDecode(nextDef.Value).entry))).Magnitude<7
    -- Humans can clip from the authored range without walking into the rock face.
    if not inClipRange then walk(Vector3.new(table.unpack(node.p))+Vector3.yAxis*2,node.k=='jump' or (i>1 and RS.CC_TraversalDefs:FindFirstChild(name..':'..segment.id..':'..(i-1))~=nil),segment.nodes[i+1] and segment.nodes[i+1].k=='jump' and node.k=='walk') end
   elseif node.k=='wait' then task.wait(2)
   elseif node.k=='descend' then error('unmapped descent requires manual input') end
  end
  cur=math.max(cur,segment.s1)
 end
 portion(cur,math.huge);resumeDistance=nil
end
script:SetAttribute('Status','running')
local ok,err=pcall(function()
 h.WalkSpeed=12
 if not resume and not resumeDistance then for _,point in require(RS.CC_Core.LobbyApproaches)[1].points do walk(Vector3.new(table.unpack(point))+Vector3.yAxis*3) end;walk(Vector3.new(-227.2,52,1812.2));task.wait(1) end
 route('Shepherd');route('SummitStair')
 walk(Vector3.new(0,3175,0));walk(Vector3.new(-30,3175,0))
 for flight=0,3 do for i=0,13 do walk(Vector3.new(-30+flight*12,3175+(flight*13+i)*1.5,flight%2==0 and -i*3.5 or -45.5+i*3.5)) end end
 walk(Vector3.new(40,3255,12));task.wait(3)
 local st=H:JSONDecode(bridge:Invoke('snapshot',{})).result;assert(st.summit.result,'no confirmed summit; inspect eligibility')
end)
script:SetAttribute('Status',ok and 'complete' or 'stopped');script:SetAttribute('Detail',ok and 'validated entire ascent' or tostring(err));script:SetAttribute('Seconds',os.clock()-started)
