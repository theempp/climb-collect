from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def change(path,old,new):
 p=ROOT/path;s=p.read_text(encoding='utf-8');assert old in s,(path,old);p.write_text(s.replace(old,new),encoding='utf-8')
change('src/core/server/Camps.luau','summit.active or summit.pendingResult','summit.active or summit.pendingResult or summit.lobbyResume')
change('src/core/server/DropPacks.luau','s.data.expedition.summit.active or s.data.expedition.summit.pendingResult','s.data.expedition.summit.active or s.data.expedition.summit.pendingResult or s.data.expedition.summit.lobbyResume')
change('src/core/server/ExpeditionRun.luau','st.nextSeq+=1;st.active=a;','st.nextSeq+=1;st.active=a;st.lobbyResume=nil;')
change('src/core/server/ExpeditionRun.luau',"  local i=tonumber(name:match('^Camp(%d)$'));if i then E.observe(p,{kind='camp',index=i}) elseif name=='Merge' then E.observe(p,{kind='merge'}) end", "  local i=tonumber(name:match('^Camp(%d)$'));if i then E.observe(p,{kind='camp',index=i}) elseif name=='Merge' then E.observe(p,{kind='merge'}) end\n  local a=live[p];if a and not a.invalid then a.lastCheckpoint=name;sync(p) end")
change('src/core/server/ExpeditionRun.luau',"  if a and a.lastPos and not d.pendingResult and not s.data.expedition.homeReturn then ctx.Traversal.travel(p,Vector3.new(table.unpack(a.lastPos)),'reconnect') end", """  if a and not d.pendingResult then
   -- Restore only previously earned allowance; SetCheckpoint does not emit progress evidence.
   if a.lastMilestone>0 then api.SetCheckpoint:Invoke(p,'Camp'..a.lastMilestone) end
   if a.lastCheckpoint then api.SetCheckpoint:Invoke(p,a.lastCheckpoint)
   elseif a.merge then api.SetCheckpoint:Invoke(p,'Merge') end
   if a.lastPos and not s.data.expedition.homeReturn then ctx.Traversal.travel(p,Vector3.new(table.unpack(a.lastPos)),'reconnect') end
  end""")
change('src/core/server/SummitFinish.luau','local route=a.startRoute;',"local route=table.find({'Shepherd','Waterfall'},a.currentRoute) and a.currentRoute or a.startRoute;")
change('src/core/server/SummitFinish.luau','t.returnedThrough=math.max(t.returnedThrough,result.seq);t.returnIntent=true;', 't.returnedThrough=math.max(t.returnedThrough,result.seq);t.returnIntent=true;t.lobbyResume=true;')
change('src/core/server/SummitFinish.luau',"function S.state(p,st)\n local s=ctx.sessions[p];local t=s and s.data.expedition.summit\n st.summit={status=finishing[p] and 'saving' or (t and t.pendingResult and 'confirmed' or 'idle'),result=t and copy(t.pendingResult)}", """function S.state(p,st)
 local s=ctx.sessions[p];local t=s and s.data.expedition.summit
 local pending=s and s.pending and tostring(s.pending.tx or s.pending.id or ''):match('^summit:')
 st.summit={status=(finishing[p] or pending) and 'saving' or (t and t.pendingResult and 'confirmed' or 'idle'),result=t and copy(t.pendingResult)}""")
change('src/core/server/SummitFinish.luau',"   else arrive(p,s,st.pendingResult.id);ctx.push(p) end\n  end)\n end\nend", """   else arrive(p,s,st.pendingResult.id);ctx.push(p) end
  end)
 elseif st and st.lobbyResume and not st.active and not s.data.expedition.homeReturn then
  task.delay(2,function()
   if ctx.sessions[p]~=s or not st.lobbyResume or st.active then return end
   game.ServerStorage.CC_CheckpointAPI.SetCheckpoint:Invoke(p,nil)
   ctx.Traversal.travel(p,require(script.Parent.LobbyAnchors).resolve(workspace.World).Return.Position+Vector3.yAxis*3,'summitReturn')
  end)
 end
end""")
change('src/core/server/PublicProfile.luau','frameId=d.portfolio.frameId','frameId=(Earned[d.portfolio.frameId] and d.expedition.earnedCosmetics and d.expedition.earnedCosmetics[d.portfolio.frameId]) and d.portfolio.frameId or \'\'')
