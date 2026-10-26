local G=require('../shared/CompactGeometry')
local function close(a,b) assert(math.abs(a-b)<1e-6) end
local a=G.point({x=4096,y=16,z=-210});close(a.x,4096);close(a.y,16);close(a.z,-210)
local b=G.point({x=4096,y=400,z=-1410});assert(b.y<400 and b.z>-1410)
close((b.y-a.y)/(a.z-b.z),384/1200)
assert(G.scale>=.8 and G.scale<=.9)
local F=require('../world/FreeClimb');local g=F.layout()
assert(#g.sections==6 and #g.eggs==12 and #g.restPoints==18)
close(g.sections[6].finish.z,b.z);close(g.sections[6].finish.y,b.y)
for _,s in g.sections do assert(s.escape.width==32 and s.hazard.halfWidth==16) end
for _,e in g.eggs do close(math.abs(e.position.x-4096),58) end
print('PASS compact geometry: six connected sections, shorter route, preserved escape and hazard width')
