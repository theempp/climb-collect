-- Three finite practice lessons, validated by actual authored traversal completions; no countdown.
local HS=game:GetService("HttpService")
local Training={}
local ctx,station,Prompts
local open,active={},{}
local function near(plr)
 local p=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
 return station and p and (p.Position-station.Position).Magnitude<20
end
local function unlocked(d,i)
 local t=d.gear.training
 return i==1 or (t.unlocked and t.unlocked[tostring(i)]==true) or (t.level or 0)>=i
end
function Training.canUseSection(plr,i)
	local s=ctx.sessions[plr]
	return s~=nil and unlocked(s.data,i)
end
local function commitLesson(plr,a)
 if active[plr]~=a or not a.finishing or a.inFlight or a.awaitingConfirmation then return end
 local s=ctx.sessions[plr]
 if s~=a.session then active[plr]=nil return end
 if s.closing or s.lost or s.pending or s.busy or s.saving or s.outcomePending then return end
 a.inFlight=true
 local lesson=a.id
 local r=ctx.transaction(plr,"practicefinish:"..lesson..":"..plr.UserId,function(d)
  if not unlocked(d,lesson) then return {ok=false,reason="locked"} end
  d.gear.training.completed=d.gear.training.completed or {}
  if d.gear.training.completed[tostring(lesson)] then return {ok=true,repeatLesson=true} end
  d.gear.training.completed[tostring(lesson)]=true
  return {ok=true}
 end,function(result)
  if a.confirmed then return end
  a.confirmed=true
  if active[plr]==a then active[plr]=nil end
  if ctx.sessions[plr]~=s or not plr.Parent then return end
  ctx.Gear.dress(plr)
  if not result.dup then
   ctx.toast(plr,result.repeatLesson and "Practice complete. This lesson is already earned." or "Practice complete! Your finite stamina training advanced.","good")
  end
  ctx.push(plr)
 end)
 a.inFlight=false
 if r.pending then
  -- CoreService owns recovery and invokes the original callback after a durable receipt.
  a.awaitingConfirmation=true
 elseif not r.ok and r.reason~="busy" and not a.errorShown then
  a.errorShown=true
  ctx.toast(plr,"Your practice finish is waiting to save. Please keep this session open.","info")
 end
end
function Training.init(c)
 ctx=c Prompts=require(script.Parent.Prompts)
 local yard=workspace.World:FindFirstChild("TrainingYard")
 station=workspace.World:FindFirstChild("Fairground") and require(script.Parent.LobbyAnchors).resolve(workspace.World).PracticeStart or (yard and yard:FindFirstChild("StartGate"))
 if not station then warn("[CC] Practice station missing") return end
 local pr=Prompts.make(station,{Name="PracticePrompt",ActionText="Practice climbing",ObjectText="Home practice crag",HoldDuration=0,MaxActivationDistance=12})
 pr.Triggered:Connect(function(plr) if Prompts.validate(pr,plr) and ctx.sessions[plr] then open[plr]=true ctx.fx(plr,{kind="practice",open=true}) ctx.push(plr) end end)
 ctx.handlers.practiceClose=function(plr) open[plr]=nil ctx.push(plr) end
 ctx.handlers.practiceBuy=function(plr,p)
  local i=p.id local s=ctx.sessions[plr]
  if type(i)~="number" or i%1~=0 or i<1 or i>3 or not s or not near(plr) then return end
  local r=ctx.transaction(plr,"practicebuy:"..HS:GenerateGUID(false),function(d)
   if unlocked(d,i) then return {ok=false,reason="owned"} end
   if i>1 and not (d.gear.training.completed and d.gear.training.completed[tostring(i-1)]) and (d.gear.training.level or 0)<i-1 then return {ok=false,reason="previous"} end
   local cost=ctx.C.PRACTICE.costs[i]
   if d.coins<cost then return {ok=false,reason="coins"} end
   d.coins-=cost d.gear.training.unlocked=d.gear.training.unlocked or {} d.gear.training.unlocked[tostring(i)]=true
   return {ok=true}
  end,function() ctx.toast(plr,"Practice section unlocked permanently.","good") ctx.push(plr) end)
  if not r.ok and not r.pending then ctx.toast(plr,r.reason=="coins" and "Not enough Cairn Coins." or "Complete the previous section first.","info") end
 end
 ctx.handlers.practiceStart=function(plr,p)
  local i=p.id local s=ctx.sessions[plr]
  if type(i)~="number" or i%1~=0 or i<1 or i>3 or not s or not near(plr) or not unlocked(s.data,i) then return end
  if active[plr] and active[plr].finishing then
   ctx.toast(plr,"Your completed lesson is still saving. Please wait before starting another.","info")
   return
  end
  active[plr]={id=i,next=1,session=s}
  open[plr]=nil
  ctx.toast(plr,"Climb the practice walls in order. Take your time; the bell is your finish.","info")
  ctx.push(plr)
 end
 ctx.on("traversalSection",function(plr,id)
  local s=ctx.sessions[plr] local a=active[plr]
  if not s or not a or a.finishing or id~="Practice:"..a.next then return end
  a.next+=1
  if a.next<=a.id then return end
  a.finishing=true
  ctx.toast(plr,"Practice walls complete. Saving your training…","info")
  commitLesson(plr,a)
 end)
 task.spawn(function()
  while true do
   task.wait(0.5)
   for plr,a in pairs(active) do
    if a.finishing and not a.inFlight and not a.awaitingConfirmation then
     task.spawn(function() commitLesson(plr,a) end)
    end
   end
  end
 end)
end
function Training.state(plr,st)
 local s=ctx.sessions[plr] if not s then return end
 if open[plr] and not near(plr) then open[plr]=nil end
 if open[plr] then
  local sections={}
  for i=1,3 do table.insert(sections,{id=i,label=ctx.C.PRACTICE.labels[i],cost=ctx.C.PRACTICE.costs[i],gain=ctx.C.PRACTICE.gains[i],unlocked=unlocked(s.data,i),complete=s.data.gear.training.completed and s.data.gear.training.completed[tostring(i)] or false}) end
  st.practice={open=true,sections=sections,bonus=ctx.Gear.trainingBonus(s),cap=ctx.C.PRACTICE.staminaCap}
 end
end
function Training.onLeave(plr) open[plr]=nil active[plr]=nil end
return Training
