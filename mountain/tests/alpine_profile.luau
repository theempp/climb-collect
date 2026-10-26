local ok,P=pcall(require,'../shared/AlpineProfile')
assert(ok,'Altitude/landscape profile must exist')
local n=0
local function check(v,msg) assert(v,msg);n+=1 end
for _,p in {{4096,400,0},{0,400,-700},{4096,400,-2000},{4096,0,-500}} do
 check(P.intensity(p[1],p[2],p[3])==0,'outside mountain/under entrance is clear')
end
local old=0
for y=16,600,1 do
 local v=P.intensity(4096,y,-1000)
 check(v>=old and v>=0 and v<=1,'intensity smoothly grows with altitude')
 check(v-old<.015,'no altitude step flash');old=v
end
local G=require('../shared/CompactGeometry');local summit=G.point({x=4096,y=400,z=-1300})
check(P.intensity(summit.x,summit.y,summit.z)>.95,'compact summit has full effect')
for z=-210,-1410,-1 do
 local a=P.ground(0,z);local b=P.ground(0,z-1)
 for i=1,3 do check(a[i]>=0 and a[i]<=255 and math.abs(a[i]-b[i])<8,'continuous bounded ground palette') end
end
check(P.intensity(4096,300,-211)<.1,'entry boundary fades')
print('PASS '..n..' alpine profile checks')
