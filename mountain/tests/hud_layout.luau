local P=require('../shared/UIPresentation')
assert(type(P.hudLayout)=='function','E+B responsive geometry is missing')
local count=0
local function overlap(a,b) return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h end
-- 685x280 = Galaxy S25 Ultra safe root; its thumbstick region starts at y93, inside the default navigation row.
for _,v in ipairs({{666,316},{750,343},{844,339},{685,280},{1179,761},{1920,1021}}) do
 for _,touch in ipairs({false,true}) do
 for _,bar in ipairs({false,true}) do
  local w,h=table.unpack(v)
  local obstacles=if touch then {{x=-100,y=h/3,w=w*.55,h=h},{x=w-95,y=h-90,w=70,h=70}} else {}
  -- Roblox topbar row above the safe root (core buttons occupy the left 164 px).
  local topbar=if bar then {x=164,y=-58,w=w-164,h=58} else nil
  local l=P.hudLayout(w,h,obstacles,touch,topbar)
  -- HUD v2: the top strip carries navigation, so it must clear the status pill, gear and journey card.
  for _,key in ipairs({'menu','quickCreatures','quickMountain','navigation'}) do for _,other in ipairs({'status','settings','journey'}) do if key~='navigation' or l.horizontalNavigation then assert(not overlap(l[key],l[other]),key..' overlaps '..other) end end end
  for _,key in ipairs({'status','journey','menu','quickCreatures','quickMountain','navigation','settings','team','context','dodge','ability','sprint'}) do
   local r=l[key]
   if l.crowdedNavigation and (key=='quickCreatures' or key=='quickMountain') then continue end
   if l.crowdedNavigation and key~='status' and key~='journey' and key~='navigation' then assert(not overlap(r,l.status),key..' overlaps status') end
   if l.crowdedNavigation and key=='menu' then assert(not overlap(r,l.journey),'menu overlaps journey') end
   local inBar=bar and (key=='status' or key=='settings' or key=='menu' or key=='quickCreatures' or key=='quickMountain')
   if inBar then assert(r.y>=topbar.y and r.y+r.h<=topbar.y+topbar.h and r.x>=topbar.x and r.x+r.w<=w,key..' outside the topbar row')
   else assert(r.x>=0 and r.y>=0 and r.x+r.w<=w and r.y+r.h<=h,key..' outside '..w..'x'..h) end
   for i,o in ipairs(obstacles) do
    -- Owner 2026-10-27: team + context are centred on screen, so only they may sit over the left joystick gesture zone.
    if not (i==1 and (key=='team' or key=='context')) then assert(not overlap(r,o),key..' overlaps native control') end
   end
   count+=1
  end
  assert(l.team.w>=3*64,'Three prominent touch slots required')
  assert(not overlap(l.dodge,l.sprint),'Sprint and dodge overlap')
  assert(not overlap(l.team,l.context),'Context obscures team')
  assert(math.abs(l.team.x+l.team.w/2-w/2)<1 and math.abs(l.context.x+l.context.w/2-w/2)<1,'Team and context are centred')
  assert(l.topbar==bar,'Topbar row used whenever it is available')
  if bar then
   assert(l.status.y==topbar.y+12 and l.settings.y==topbar.y+12,'Pill and gear level with the core buttons')
   assert(l.settings.x+l.settings.w==w-12 and l.settings.w==44,'Gear flush right, core-button size')
   for _,key in ipairs({'menu','quickCreatures','quickMountain'}) do assert(l[key].y==topbar.y+12 and l[key].w==44 and l[key].x>=topbar.x+8,key..' in the topbar row beside the core buttons') end
   assert(l.quickMountain.x+44<l.status.x,'Left tiles clear the coin pill')
  end
 end
 end
end
assert(P.horizontalNavigation(762,true),'Touch tablets need navigation above joystick gesture region')
assert(P.horizontalNavigation(450,false),'Intermediate-height horizontal navigation')
assert(not P.horizontalNavigation(1022,false),'Desktop sidebar retained')
print('PASS '..count..' E+B layout checks')
