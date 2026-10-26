local ok,F=pcall(require,'../world/FreeClimb')
assert(ok and type(F.layout)=='function','free climb metadata exists')
local g=F.layout();local n=0
local function check(v,label) assert(v,label);n+=1 end
check(#g.sections==6 and #g.eggs==12 and #g.restPoints==18,'six open sections, two eggs each, three rests')
local last={x=4096,y=16,z=-210}
for k,s in ipairs(g.sections) do
 check(s.id==k and s.requiredWins==0,'all sections accessible without wins')
 check(s.entry.y==last.y and s.entry.z==last.z,'continuous ascent and descent')
 check((s.terrace.y-s.entry.y)/120<.6,'walkable return grade')
 check(s.escape.width>=24 and s.escape.x==4096,'direct readable escape lane')
 check(s.bounds.maxZ<-180 and s.bounds.minZ<s.bounds.maxZ,'guardian stays beyond exit')
 check(s.hazard.x~=s.escape.x and s.hazard.halfWidth<30,'alternate crossing remains clear')
 check(s.normalAltar and math.abs(s.normalAltar.x-s.terrace.x)<40,'normal altar within engagement range of defender')
 check(s.trialAltar and s.trialAltar.x~=s.normalAltar.x,'Trial owns its separate altar center')
 for _,e in ipairs(g.eggs) do if e.section==k then
  check(e.position.y==s.terrace.y and e.position.z<s.bounds.maxZ and e.position.z>s.bounds.minZ,'egg approach rests on terrace')
 end end
 last=s.finish
end
check(g.exit.z>-180 and g.exit.z+g.exit.depth/2<-145,'exit beyond mountain, before sanctuary gate')
print('PASS '..n..' free climb geometry checks')
