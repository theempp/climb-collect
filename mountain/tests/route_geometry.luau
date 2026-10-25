local C=require('../shared/Catalog')
local n=0
local function check(ok,label) assert(ok,label);n+=1 end
local quadrants={}
for k=1,6 do
 local first=C.route(k,0);local last=C.route(k,1)
 check(last.angle-first.angle<math.pi,'a kingdom must not carve a complete retaining ring')
 check(first.y==16+(k-1)*136 and last.y==16+k*136,'server progression heights stay compatible')
 if k<6 then
  local nextStart=C.route(k+1,0)
  check(math.abs(last.x-nextStart.x)+math.abs(last.z-nextStart.z)+math.abs(last.y-nextStart.y)<.001,'no gap at kingdom boundary')
 end
 local q=C.route(k,.875)
 for _,angle in ipairs(C.guardianColumnAngles(k)) do
  local dot=math.cos(angle-q.angle-math.pi)
  check(dot<=0 or 38*math.abs(math.sin(angle-q.angle-math.pi))>13,'arena approach has avatar clearance past columns')
 end
 quadrants[math.floor((q.angle%(2*math.pi))/(math.pi/2))]=true
 for i=1,48 do
  local a=C.route(k,(i-1)/48);local b=C.route(k,i/48)
  local d=math.sqrt((a.x-b.x)^2+(a.z-b.z)^2)
  check(d>=4 and d<=75,'segment length supports a walkable trail: '..k..'/'..i..' length '..d)
  if i%12~=0 then check((b.y-a.y)/d<=.28,'non-ladder slope remains walkable') end
  if i%12==0 then check(C.ladderSetback(k,i)<=d-2 and C.ladderSetback(k,i)>=2,'ladder sits within its approach, not behind it') end
 end
end
local count=0;for _ in pairs(quadrants) do count+=1 end
check(count>=4,'arenas must occupy distinct sides rather than one stacked face')
print('Route geometry checks passed: '..n)
