-- Promenade review Edit session only: sync every runtime source from this checkout (served on 8861).
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before syncing')
assert(game.Name:find('HomePromenade',1,true),'Not the home-base promenade review')
local Http=game:GetService('HttpService');local base='http://127.0.0.1:8861/'
local was=Http.HttpEnabled;Http.HttpEnabled=true
local manifest,sources
local ok,err=pcall(function()
 manifest=Http:JSONDecode(Http:GetAsync(base..'evidence/homebase_promenade_2026-10-26/sync-manifest.json'))
 sources={};for i,row in manifest do sources[i]=Http:GetAsync(base..row[4]);assert(#sources[i]>20,'Empty '..row[4]) end
end)
Http.HttpEnabled=was;assert(ok,err)
local changed,same={},0
local function norm(s) return (s:gsub('\r\n','\n'):gsub('%s+$','')) end
for i,row in manifest do
 local parent=game;for piece in row[1]:gmatch('[^.]+') do parent=assert(parent:FindFirstChild(piece),'Missing '..piece) end
 local inst=parent:FindFirstChild(row[2])
 if inst and inst.ClassName~=row[3] then inst:Destroy();inst=nil end
 if inst and norm(inst.Source)==norm(sources[i]) then same+=1 else
  if not inst then inst=Instance.new(row[3]);inst.Name=row[2];inst.Parent=parent end
  inst.Source=sources[i];table.insert(changed,row[4])
 end
end
return {total=#manifest,unchanged=same,changed=changed}
