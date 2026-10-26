local E=require('../world/MountainEntrances')
local g=E.layout();local checks=0
local function check(v,m) assert(v,m);checks+=1 end
check(#g.sides==2,'two additional entrances')
for _,s in ipairs(g.sides) do
 check(s.width>=48,'wide entrance')
 check(s.exitZ==-166,'same securing boundary')
 check(s.path[1].y==0 and s.path[#s.path].y==16,'ground to mountain continuity')
 check(s.path[#s.path-1].z<=-180 and s.path[#s.path-1].y>=28,'return ramp reaches terrace top before its north wall at -178')
 for i=2,#s.path do local a,b=s.path[i-1],s.path[i];local d=math.sqrt((a.x-b.x)^2+(a.z-b.z)^2);check(math.abs(a.y-b.y)/d<.6,'walkable grade') end
end
check(g.sides[1].x-g.sides[1].width/2<=3924 and g.sides[1].x+g.sides[1].width/2>=4006,'west exit meets center')
check(g.sides[2].x-g.sides[2].width/2<=4186 and g.sides[2].x+g.sides[2].width/2>=4268,'east exit meets center')
print('PASS '..checks..' entrance geometry checks')
