from pathlib import Path
p=Path(__file__).resolve().parents[1]/'src/core/server/Camps.luau'
s=p.read_text()
a=s.index('\t-- locker requests')
b=s.index('\tctx.handlers.lockerClose',a)
s=s[:a]+''' -- Locker transfers commit both locations atomically, preserving item records.
 local function transfer(plr,p,take)
  local session=ctx.sessions[plr]
  local camp=openLocker[plr]
  if not session or not camp or not nearLocker(plr,camp) or type(p.uid)~="string" or #p.uid>128 then return end
  local tx="locker:"..game:GetService("HttpService"):GenerateGUID(false)
  local r=ctx.transaction(plr,tx,function(d)
   d.lockers[camp]=d.lockers[camp] or {}
   local from=take and d.lockers[camp] or d.cargo
   local to=take and d.cargo or d.lockers[camp]
   local i,it=ctx.Cargo.locate(from,p.uid)
   if not it then return {ok=false,reason="missing"} end
   local cap=take and d.slots or (C.LOCKER_SLOTS[d.tents[camp] or 1] or 1)
   if ctx.Cargo.used(to)+(it.slots or 1)>cap then return {ok=false,reason="full"} end
   table.remove(from,i) table.insert(to,it)
   return {ok=true}
  end,function() ctx.invChanged(plr) ctx.toast(plr,take and "Retrieved. Carry it to the Foothold bank." or "Stored safely at this camp. Return here to retrieve it.","good") end)
  if not r.ok then ctx.toast(plr,r.reason=="full" and "Not enough room." or "Waiting for saving; the transfer is not confirmed.","warn") end
 end
 ctx.handlers.lockerStore=function(plr,p) transfer(plr,p,false) end
 ctx.handlers.lockerTake=function(plr,p) transfer(plr,p,true) end
 ctx.handlers.shuttle=function(plr)
  local session=ctx.sessions[plr]
  local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
  local camp=root and campOfPos(root.Position)
  if not session or not camp or not hum or hum.FloorMaterial==Enum.Material.Air then return end
  local state=plr.Character:GetAttribute("CC_TraversalState")
  if state and state~="ground" then return end
  local sp=workspace:FindFirstChildOfClass("SpawnLocation")
  if not sp or not ctx.Traversal then return end
  -- Arrival is the entrance/spawn terrace. Cargo stays carried; no automatic banking.
  ctx.transaction(plr,"shuttle:"..game:GetService("HttpService"):GenerateGUID(false),function(d)
   d.expedition.returnedAt=Clock.now() d.expedition.returnFrom=camp
   return {ok=true}
  end,function()
   if api then api.SetCheckpoint:Invoke(plr,nil) end
   ctx.Traversal.travel(plr,sp.Position+Vector3.new(0,4,0),"shuttle")
   ctx.toast(plr,"Foothold entrance. Your cargo is with you; walk to the campfire bank.","good")
   ctx.push(plr)
  end)
 end
''' +s[b:]
s=s.replace('local function teleport(plr, pos)\n', 'local function teleport(plr, pos)\n\tif ctx.Traversal then ctx.Traversal.travel(plr,pos+Vector3.new(0,4,0),"resume") return end\n')
s=s.replace('\tst.resumeOffer =', ''' local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
 local nearby=root and campOfPos(root.Position)
 if nearby then st.travelOffer={camp=nearby,label=campPads[nearby].label,available=true} end
 st.lockers={}
 if s then for name,items in pairs(s.data.lockers) do table.insert(st.lockers,{camp=name,label=campPads[name] and campPads[name].label or name,count=#items}) end end
 st.resumeOffer =''')
s=s.replace('if not ctx.sessions[plr] then\n', 'if not Prompts.validate(p,plr) or not ctx.sessions[plr] then\n',1)
# Camp unlock must survive reconnect before travel or new rewards.
s=s.replace('s.data.highestCamp = idx\n\t\t\t\t\ts.dirty = true','s.data.highestCamp = idx\n\t\t\t\t\ts.dirty = true\n\t\t\t\t\tctx.saveSoon(s)')
p.write_text(s,encoding='utf-8')
print('Camps persistent transfers and shuttle installed')
