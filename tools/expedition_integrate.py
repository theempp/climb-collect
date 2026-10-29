from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'src/runtime/CC_CoreService.server.luau'
s=p.read_text(encoding='utf-8')
start=s.index('---------------------------------------------------------------- deposit entry')
end=s.index('---------------------------------------------------------------- sessions',start)
s=s[:start]+'''---------------------------------------------------------------- durable transaction boundary
local completions = {} -- one callback for a pending durable transaction; world changes follow confirmation
local bankState = {}
local function finishCommit(plr,s,r)
 local pending=completions[s]
 if pending and r.ok then
  completions[s]=nil
  if pending.fn then local ok,err=pcall(pending.fn,r) if not ok then warn("[CC] committed effect: "..tostring(err)) end end
  ctx.invChanged(plr)
 end
end
function ctx.transaction(plr,tx,transform,committed)
 local s=ctx.sessions[plr]
 if not s or s.closing or s.lost then return {ok=false,reason="unavailable"} end
 if s.pending or s.busy or s.saving then return {ok=false,reason="busy"} end
 local r=profiles:transact(s,tx,transform)
 if r.ok then
  if committed then committed(r) end
 elseif r.pending then
  completions[s]={fn=committed,tx=tx}
  ctx.saveState[plr]="unavailable"
  plr:SetAttribute("CC_SaveState","unavailable")
 end
 ctx.push(plr)
 return r
end
local function atBank(plr)
 local part=ctx.Camps and ctx.Camps.bankPart
 local ch=plr.Character
 local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 return part and hrp and hum and hum.Health>0 and (hrp.Position-part.Position).Magnitude<=18
  and (not ctx.Traversal or not ctx.Traversal.canBank or ctx.Traversal.canBank(plr))
end
function ctx.deposit(plr,txId)
 local s=ctx.sessions[plr]
 if not s or not atBank(plr) then return {ok=false,reason="bank_distance"} end
 if type(txId)~="string" or #txId>128 then txId=nil end
 local function complete(r)
  bankState[plr]={status="success",message="Saved at the bank.",retryable=false}
  if not r.dup and ((r.creatures or 0)+(r.heartstones or 0))>0 then
   ctx.toast(plr,string.format("Banked %d creatures and %d Heartstones. Saved.",r.creatures or 0,r.heartstones or 0),"good")
   ctx.fx(plr,{kind="bank",res=r}) ctx.emit("bank",plr,r)
   plr:SetAttribute("CC_FirstBank",s.data.flags.firstBankAt>0)
  end
  ctx.invChanged(plr)
 end
 if s.pending then
  local r=profiles:recover(s)
  if r.ok then finishCommit(plr,s,r) end
  ctx.push(plr)
  return r
 end
 if ctx.saveState[plr]~="ok" or s.busy or s.saving then
  bankState[plr]={status="error",message="Saving is unavailable. Your cargo is safe; retry here.",retryable=true}
  ctx.push(plr) return {ok=false,reason="unavailable"}
 end
 bankState[plr]={status="saving",message="Saving your finds…",retryable=false} ctx.push(plr)
 local tx=txId or HttpService:GenerateGUID(false)
 local r=Bank.deposit(s,plr.UserId,tx)
 if r.ok then complete(r)
 elseif r.pending then
  completions[s]={fn=complete,tx=tx}
  bankState[plr]={status="uncertain",message="Confirming the save. Please wait or retry here.",retryable=true}
  ctx.saveState[plr]="unavailable" plr:SetAttribute("CC_SaveState","unavailable")
 else bankState[plr]={status="error",message="Could not bank. Your finds stay in your backpack.",retryable=true} end
 ctx.push(plr)
 return r
end

''' + s[end:]
# snapshot reads st.bank through ctx (local declaration is below snapshot)
s=s.replace('st.heartstones[#st.heartstones + 1] = { tier = h.tier, readyAt = h.readyAt, startedAt = h.startedAt }','st.heartstones[#st.heartstones + 1] = { uid=h.uid, tier=h.tier, progress=h.progress, required=h.required, ready=h.ready }')
s=s.replace('\tfor _, m in ipairs(ctx.modules) do\n\t\tif m.state then','\tst.bank = ctx.bankState and ctx.bankState[plr] or {status="idle"}\n\tst.settings = s and s.data.settings or nil\n\tst.journal = s and s.data.journal or {}\n\tfor _, m in ipairs(ctx.modules) do\n\t\tif m.state then',1)
s=s.replace('local bankState = {}','local bankState = {}\nctx.bankState=bankState',1)
s=s.replace('\tProg.refresh(s.data)\n\tInv.setCapacity(plr.UserId, s.data.slots)','\tProg.refresh(s.data)\n\tInv.bind(plr.UserId,s)\n\tInv.setCapacity(plr.UserId, s.data.slots)',1)
a=s.index('\tlocal hatched = Bank.ripen(s)',s.index('local function afterLoad'))
b=s.index('\tfor _, m in ipairs(ctx.modules)',a)
s=s[:a]+''' setSave(plr,"ok")
 plr:SetAttribute("CC_Tutorial",s.data.flags.tutorial)
 plr:SetAttribute("CC_FirstBank",s.data.flags.firstBankAt>0)
 for key,attr in pairs({textScale="CC_TextScale",reducedMotion="CC_ReducedMotion",timingAssist="CC_TimingAssist",headlampMode="CC_HeadlampMode"}) do
  plr:SetAttribute(attr,s.data.settings[key])
 end
 ctx.fx(plr,{kind="welcome",away=away,hatched={}})
''' + s[b:]
# Replace auto-ripen loop with pending receipt reconciliation.
a=s.index('task.spawn(function()\n\twhile true do\n\t\ttask.wait(2)')
b=s.index('Run.Heartbeat:Connect',a)
s=s[:a]+'''task.spawn(function()
 while true do
  task.wait(3)
  for plr,s in pairs(ctx.sessions) do
   if s.pending and not s.saving and not s.busy then
    local r=profiles:recover(s)
    if r.ok then finishCommit(plr,s,r) setSave(plr,"ok") end
   end
  end
 end
end)

''' +s[b:]
s=s.replace('if (failing or s.saveAgain or Clock.now()', 'if not s.pending and (failing or s.saveAgain or Clock.now()')
# Prevent state mutations while a transaction candidate is in flight. Traversal still runs.
needle='\tlocal h = ctx.handlers[action]\n\tif h then'
s=s.replace(needle,''' local s=ctx.sessions[plr]
 if s and (s.pending or s.busy or s.saving) and action~="traversal" and action~="bankRetry" then
  ctx.toast(plr,"Finishing a save. Please try again in a moment.","info") return
 end
 local h = ctx.handlers[action]
 if h then''',1)
s=s.replace('{ "Visuals", "DropPacks", "Camps", "Claims", "Nests", "Tutorial", "Gear", "Coop", "Training", "Weather" }','{ "Visuals", "Cargo", "DropPacks", "Camps", "Claims", "Nests", "Tutorial", "Gear", "Traversal", "Coop", "Training", "Home", "Discovery", "Weather" }')
# New handlers before module init (after all routing is defined).
needle='---------------------------------------------------------------- gameplay modules (B)'
s=s.replace(needle,'''ctx.handlers.bankRetry=function(plr) ctx.deposit(plr) end
ctx.handlers.settingsSet=function(plr,p)
 local allowed={textScale="CC_TextScale",reducedMotion="CC_ReducedMotion",timingAssist="CC_TimingAssist",headlampMode="CC_HeadlampMode"}
 if type(p.key)~="string" or not allowed[p.key] then return end
 local v=p.value
 if p.key=="textScale" then if type(v)~="number" or v~=v then return end v=math.clamp(v,0.9,1.3)
 elseif p.key=="headlampMode" then if v~="auto" and v~="on" and v~="off" then return end
 elseif type(v)~="boolean" then return end
 ctx.transaction(plr,"setting:"..HttpService:GenerateGUID(false),function(d) d.settings[p.key]=v return {ok=true} end,function()
  plr:SetAttribute(allowed[p.key],v) ctx.push(plr)
 end)
end

''' +needle)
# Make reset/rejoin test bridge useful for integration tests without client trust.
s=s.replace('\tctx.devHandlers.status = function()', ''' ctx.devHandlers.snapshot=function(plr) return ctx.snapshot(plr) end
 ctx.devHandlers.request=function(plr,p) local h=ctx.handlers[p.action] if h then return h(plr,p.payload or {}) end end
 ctx.devHandlers.move=function(plr,p)
  local pos=Vector3.new(p.x,p.y,p.z)
  if ctx.Traversal then ctx.Traversal.travel(plr,pos,"test") else plr.Character:PivotTo(CFrame.new(pos)) end
  return true
 end
 ctx.devHandlers.status = function()''')
s=s.replace('\t\ts.data = Profile.default()','\t\ts.data = Profile.default()\n\t\tInv.bind(plr.UserId,s)')
p.write_text(s,encoding='utf-8')
print('Integrated durable transaction boundary, recovery, snapshots and modules')
