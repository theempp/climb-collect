-- Catches broken joins, excessive pitch, blocked escape, and an unwalkable pit exit.
local S=require('../world/MountainSurface')
local n=0
local function check(v,label) assert(v,label);n+=1 end
for k=1,6 do
 for x=-172,172,4 do
  check(math.abs(S.height(k,x,0))<.001,'mountain entry joins prior terrace')
  check(math.abs(S.height(k,x,120)-64)<.001,'ascent joins 64-stud terrace')
 end
 for d=0,120,2 do
  for x=-172,172,4 do
   local h=S.height(k,x,d)
   check(h>=-.001 and h<=64.001,'surface remains inside existing tier height')
   if math.abs(x)<=16 then check(math.abs(h-64*d/120)<.001,'straight escape remains grade-continuous') end
   if d<120 then check(math.abs(S.height(k,x,d+1)-h)<.82,'walkable longitudinal surface grade') end
   if x<172 then check(math.abs(S.height(k,x+1,d)-h)<.5,'walkable transverse surface grade') end
  end
 end
end
-- This path must climb out of the 6-stud sandstone catch without a jump.
local p=S.sandstoneRecovery()
check(p[1].x==4168 and p[1].y==202 and p[1].z==-764,'catch-floor start independently derived from baseline')
check(p[#p].y==208 and p[#p].z<=-775,'recovery reaches rear terrace')
for i=2,#p do
 local a,b=p[i-1],p[i];local d=math.sqrt((b.x-a.x)^2+(b.z-a.z)^2)
 check(d>0 and math.abs(b.y-a.y)/d<.65,'no jump needed for pit recovery')
end
check(S.height(1,-88,56)>64*56/120+2,'left climb gains a distinct bench instead of identical planar slope')
check(S.height(2,88,56)~=S.height(1,88,56),'biome terrain rhythms vary within shared climb limits')
print('PASS '..n..' mountain surface geometry checks')
