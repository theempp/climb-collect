local R=require(game.ReplicatedStorage.CC_Core.DailyPracticeRules)
local D={};local ctx;local active={};local opened={};local station
local function root(p) return p.Character and p.Character:FindFirstChild('HumanoidRootPart') end
local function inside(p)
 local r=root(p);if not r then return false end
 local yard=workspace.World.TrainingYard;local cf=yard.StartGate.CFrame;local q=cf:PointToObjectSpace(r.Position)
 return math.abs(q.X)<25 and q.Z<25 and q.Z> -48 and q.Y> -12 and q.Y<65
end
function D.canUseSection(p,i)
 local a=active[p];return a and not a.finishing and a.day==R.dayKey(ctx.Clock.now()) and a.sections[a.next]=='Practice:'..i and inside(p) or false
end
function D.cancel(p) local a=active[p];if not a or not a.finishing then active[p]=nil end end
local function finish(p,a)
 local s=ctx.sessions[p];if s~=a.session or a.inFlight or a.pending then return end
 if s.pending or s.busy or s.saving or s.outcomePending then return end
 a.inFlight=true
 local res=ctx.transaction(p,'dailypractice:'..p.UserId..':'..a.day,function(d)
  if R.dayKey(ctx.Clock.now())~=a.day then return {ok=false,reason='newDay'} end
  local result=R.credit(d,a.day,{target=R.target})
  if a.timed then local old=d.dailyPractice.bestByChallenge[a.id];d.dailyPractice.bestByChallenge[a.id]=old and math.min(old,a.elapsed) or a.elapsed end
  return result
 end,function(result)
  if active[p]==a then active[p]=nil end
  if ctx.sessions[p]~=s then return end
  ctx.toast(p,result.credited and ('Daily stamp saved • '..result.stamps..' / 7') or 'Daily practice complete. Today’s stamp is already saved.','good');ctx.push(p)
 end)
 a.inFlight=false;a.pending=res.pending==true
 if not res.ok and not res.pending and res.reason=='newDay' then active[p]=nil;ctx.toast(p,'A new UTC day began. Start today’s new circuit.','info') end
end
function D.init(c)
 ctx=c;local anchors=require(script.Parent.LobbyAnchors).resolve(workspace.World);station=anchors.PracticeStart
 local P=require(script.Parent.Prompts)
 local pr=P.make(station,{Name='DailyPracticePrompt',ActionText='Free daily circuit',ObjectText='Earn an expedition pennant',HoldDuration=0,MaxActivationDistance=12})
 pr.KeyboardKeyCode=Enum.KeyCode.F;pr.GamepadKeyCode=Enum.KeyCode.ButtonY
 pr.Triggered:Connect(function(p) if P.validate(pr,p) then opened[p]=true;ctx.fx(p,{kind='practiceDailyOpen'});ctx.push(p) end end)
 ctx.handlers.practiceDailyStart=function(p,v)
  local r=root(p);local s=ctx.sessions[p];local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if not s or not r or not hum or hum.Health<=0 or hum.FloorMaterial==Enum.Material.Air or (r.Position-station.Position).Magnitude>18 or (active[p] and active[p].finishing) then return end
  if ctx.Training.cancel and not ctx.Training.cancel(p) then return end
  local day=R.dayKey(ctx.Clock.now());local desc=R.descriptor(day)
  active[p]={day=day,id=desc.id,sections=desc.sections,next=1,started=ctx.Clock.now(),timed=v.timed==true,session=s}
  opened[p]=false;ctx.toast(p,'Daily circuit started. Follow the numbered walls in order.','info');ctx.push(p)
 end
 ctx.handlers.practiceDailyCancel=function(p) D.cancel(p);opened[p]=false;ctx.push(p) end
 ctx.on('traversalSection',function(p,id)
  local a=active[p];if not a or a.finishing or ctx.sessions[p]~=a.session or a.day~=R.dayKey(ctx.Clock.now()) then return end
  if R.advance(a,id,inside(p)) and a.next>#a.sections then a.finishing=true;a.elapsed=math.max(1,ctx.Clock.now()-a.started);finish(p,a) end
  ctx.push(p)
 end)
 task.spawn(function() while true do task.wait(.5);for p,a in active do
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if a.finishing then finish(p,a)
  elseif not h or h.Health<=0 or not inside(p) or a.day~=R.dayKey(ctx.Clock.now()) then active[p]=nil;ctx.toast(p,'Daily attempt ended. Start again at the practice crag.','info');ctx.push(p) end
 end end end)
end
function D.state(p,st)
 local s=ctx.sessions[p];if not s then return end
 local day=R.dayKey(ctx.Clock.now());local desc=R.descriptor(day);local a=active[p];local d=s.data.dailyPractice
 st.dailyPractice={day=day,challengeId=desc.id,sections=desc.sections,resetAt=desc.resetAt,stamps=d.stamps,milestoneTarget=7,milestoneOwned=d.milestoneGranted,active=a~=nil,timed=a and a.timed,elapsed=a and math.max(0,ctx.Clock.now()-a.started),next=a and a.next,status=a and (a.finishing and 'saving' or 'active') or (d.lastCreditedDay==day and 'replay' or 'ready'),open=opened[p]==true}
end
function D.onLeave(p) active[p]=nil;opened[p]=nil end
return D
