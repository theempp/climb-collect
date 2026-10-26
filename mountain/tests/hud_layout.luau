local P=require('../shared/UIPresentation')
assert(type(P.hudLayout)=='function','E+B responsive geometry is missing')
local count=0
local function overlap(a,b) return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h end
for _,v in ipairs({{666,316},{750,343},{844,339},{1179,761},{1920,1021}}) do
 for _,touch in ipairs({false,true}) do
  local w,h=table.unpack(v)
  local obstacles=if touch then {{x=-100,y=h/3,w=w*.55,h=h},{x=w-95,y=h-90,w=70,h=70}} else {}
  local l=P.hudLayout(w,h,obstacles)
  for _,key in ipairs({'status','journey','menu','quickCreatures','quickMountain','navigation','team','context','dodge','ability','sprint'}) do
   local r=l[key]
   assert(r.x>=0 and r.y>=0 and r.x+r.w<=w and r.y+r.h<=h,key..' outside '..w..'x'..h)
   for _,o in ipairs(obstacles) do assert(not overlap(r,o),key..' overlaps native control') end
   count+=1
  end
  assert(l.team.w>=3*64,'Three prominent touch slots required')
  assert(not overlap(l.dodge,l.sprint),'Sprint and dodge overlap')
  assert(not overlap(l.team,l.context),'Context obscures team')
 end
end
assert(P.horizontalNavigation(762,true),'Touch tablets need navigation above joystick gesture region')
assert(P.horizontalNavigation(450,false),'Intermediate-height horizontal navigation')
assert(not P.horizontalNavigation(1022,false),'Desktop sidebar retained')
print('PASS '..count..' E+B layout checks')
