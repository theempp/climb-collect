"""Main's exit volumes, server section, publish ui and context diff (C20/T4) on the real compact layout; no Studio or world writes."""
from service_harness import *
main = (ROOT/'mountain/server/Main.server.luau').read_text(encoding='utf-8')
def between(start, end):
    return main[main.index(start):main.index(end)]
body += '\nlocal HomeLayout=' + module('mountain/shared/HomeLayout.luau')
body += '\ngame.ReplicatedStorage.MountainShared.CompactGeometry=' + module('mountain/shared/CompactGeometry.luau')
body += '\nlocal FreeClimb=' + module('mountain/world/FreeClimb.luau')
body += r'''
local vector={}
local function v(x,y,z) return setmetatable({X=x,Y=y,Z=z},vector) end
vector.__sub=function(a,b) return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
-- Axis-aligned stand-ins: every exit and GuardianBounds box is built unrotated.
local function cf(x,y,z) return {Position=v(x,y,z),PointToObjectSpace=function(self,q) return q-self.Position end} end
local function part(name,frame,size) return {Name=name,CFrame=frame,Size=size,IsA=function(_,class) return class=='BasePart' end} end
local function folder(children) return {GetChildren=function() return children end,FindFirstChild=function(_,name) for _,c in ipairs(children) do if c.Name==name then return c end end;return nil end} end
-- As FreeClimb.build: one GuardianBounds box per compact section.
local g=FreeClimb.layout();local boxes={}
for k,s in ipairs(g.sections) do local b=s.bounds;table.insert(boxes,part(tostring(k),cf((b.minX+b.maxX)/2,(b.minY+b.maxY)/2,(b.minZ+b.maxZ)/2),v(b.maxX-b.minX,b.maxY-b.minY,b.maxZ-b.minZ))) end
-- As HomePromenade.apply: West/East cleared, the one remaining exit spans the basin at the gate line.
local span=HomeLayout.span();local gy=HomeLayout.groundY
local promenadeExit=part('SanctuaryExit',cf(HomeLayout.gate.x,gy+22,HomeLayout.gate.z),v(span.maxX-span.minX+120,44,18))
local world={SanctuaryExits=folder({promenadeExit}),GuardianBounds=folder(boxes)}
function world:FindFirstChild(name) return rawget(self,name) end
'''
body += '\n' + between('-- Exit volumes are final', 'local home=require(')
body += r'''
check(#exitBoxes==1,'promenade_world_has_one_exit')
check(exitBoxes[1].cframe==promenadeExit.CFrame and exitBoxes[1].size==promenadeExit.Size,'exit_box_carries_cframe_and_size')
for k,s in ipairs(g.sections) do
 check(sectionOf(v(s.entry.x,s.entry.y+1,s.entry.z-4))==k,'entry_in_section_'..k)
 check(sectionOf(v(s.terrace.x,s.terrace.y+1,s.terrace.z))==k,'terrace_in_section_'..k)
end
for _,e in ipairs(g.eggs) do check(sectionOf(v(e.position.x,e.position.y+1,e.position.z))==e.section,'nest_'..e.id..'_in_its_section') end
check(sectionOf(v(4096,gy+3,0))==nil,'sanctuary_is_outside_every_section')
check(sectionOf(v(5000,gy+3,-400))==nil,'off_face_is_outside_every_section')
local legacy={};function legacy:FindFirstChild() return nil end
local saved=world;world=legacy;check(sectionOf(v(4096,100,-400))==nil,'no_bounds_folder_gives_nil');world=saved
'''
body += r'''
local sent={}
local function send(player,kind,data) table.insert(sent,{player=player,kind=kind,data=data}) end
local profiles={};local roots={}
local P={get=function(player) return profiles[player] end,mode='memory'}
local BatRules={grantUnlocks=function() return {} end}
local UIProtocol=Protocol
local Explorer=ExplorerRules
local workspace={GetServerTimeNow=function() return 1000 end}
local B={cooldowns=function() return {},0 end}
local tycoonWorld={update=function() end}
local bats=nil
local home={plot=function() return 1 end,inSanctuary=function(position) return position.Z>HomeLayout.northZ end}
local function root(player) return roots[player] end
local function nearestEgg() return nil end
local function atHome() return false end
local function atRefuge() return false end
local function nearCheckpoint() return false end
local function rebuildTeam() end
local contextSnapshots={}
'''
body += '\n' + between('local function publish(player,visual)', 'B.init(')
body += 'local function contextTick(player,p,rr,contextDue)\n' + between('  if p and contextDue then', '  if p and rr and h and h.Health>0 then') + 'end\n'
body += r'''
local function lastOf(player,kind) for i=#sent,1,-1 do if sent[i].player==player and sent[i].kind==kind then return sent[i].data end end;return nil end
local function count(player,kind) local n=0;for _,e in ipairs(sent) do if e.player==player and e.kind==kind then n+=1 end end;return n end
local s2=g.sections[2];local inTwo={Position=v(s2.terrace.x,s2.terrace.y+1,s2.terrace.z)}
local late={UserId=77};profiles[late]=Rules.newProfile(100);roots[late]=inTwo
publish(late)
local ui=lastOf(late,'state').ui
check(ui.exits==exitBoxes and #ui.exits==1 and ui.exits[1].size==promenadeExit.Size,'late_joiner_state_ui_has_exits')
check(ui.section==2,'state_ui_has_server_section')
check(ui.explorer and ui.explorer.xp==0 and ui.explorer.level==1 and ui.explorer.into==0 and ui.explorer.need==60 and ui.explorer.cap==49980,'state_ui_has_explorer_summary')
local rootless={UserId=78};profiles[rootless]=Rules.newProfile(100)
publish(rootless);check(lastOf(rootless,'state').ui.section==false and #lastOf(rootless,'state').ui.exits==1,'no_root_section_false_exits_still_sent')
contextTick(late,profiles[late],roots[late],true)
local c=lastOf(late,'context')
check(count(late,'context')==1 and c.exits==exitBoxes and #c.exits==1 and c.section==2,'late_joiner_first_context_has_exits_and_section')
contextTick(late,profiles[late],roots[late],true);check(count(late,'context')==1,'unchanged_context_not_resent')
contextTick(late,profiles[late],roots[late],false);check(count(late,'context')==1,'context_waits_for_due_tick')
local s3=g.sections[3];roots[late]={Position=v(s3.terrace.x,s3.terrace.y+1,s3.terrace.z)}
contextTick(late,profiles[late],roots[late],true);c=lastOf(late,'context')
check(count(late,'context')==2 and c.section==3 and #c.exits==1 and c.inSanctuary==false,'section_change_alone_sends_context')
local merged={section=3};roots[late]={Position=v(4096,gy+3,0)}
contextTick(late,profiles[late],roots[late],true);c=lastOf(late,'context')
check(count(late,'context')==3 and c.section==false and c.inSanctuary==true,'leaving_sections_sends_false')
for key,value in pairs(c) do merged[key]=value end
check(not merged.section,'client_merge_clears_previous_section')
print('PASS '..checks..' Main context and section checks')
'''
with tempfile.TemporaryDirectory(prefix='run-context-') as directory:
    target=Path(directory)/'tests.luau'
    target.write_text(body,encoding='utf8')
    subprocess.run([str(CLI),str(target)],check=True)
