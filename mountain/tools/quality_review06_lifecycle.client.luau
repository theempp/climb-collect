-- Isolated lifecycle fixture AFTER the natural raid; server triggers one QA death.
-- Never include this fixture in the saved place or a traversal acceptance run.
local p=game.Players.LocalPlayer
local original=p.Character
local rows={}
local function count(parent,name)
 local n=0;for _,v in parent:GetChildren() do if v.Name==name then n+=1 end end;return n
end
task.spawn(function()
 local deadline=os.clock()+12
 repeat
  local char=p.Character;local h=char and char:FindFirstChildOfClass('Humanoid')
  local fx=workspace:FindFirstChild('LocalAltitudeAtmosphere')
  local enabled=0;local emitters=0
  if fx then for _,e in fx:GetDescendants() do if e:IsA('ParticleEmitter') then emitters+=1;if e.Enabled then enabled+=1 end end end end
  table.insert(rows,{alive=h~=nil and h.Health>0,respawned=char~=nil and char~=original,target=fx and fx:GetAttribute('Target'),enabled=enabled,emitters=emitters,folders=count(workspace,'LocalAltitudeAtmosphere'),tints=count(game.Lighting,'MountainAltitudeTint')})
  task.wait(.2)
 until os.clock()>deadline
 local death,respawn=false,false;local passed=true
 for i,r in rows do
  if i>3 and not r.alive then death=true;passed=passed and r.enabled==0 and r.target==0 end
  if r.respawned and r.alive then respawn=true end
  passed=passed and r.folders==1 and r.tints==1 and r.emitters==3
 end
 _G.Review06Lifecycle={passed=passed and death and respawn,deathObserved=death,respawnObserved=respawn,scope='Isolated server-triggered QA death after completed natural gameplay; no saved mutation',rows=rows}
end)
return 'Lifecycle observation running; trigger QA death after initial sample'
