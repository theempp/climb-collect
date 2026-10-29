local L=require('../shared/HomeLayout')
local n=0
local function check(v,label) n+=1;assert(v,label) end
local function close(a,b) return math.abs(a-b)<1e-6 end
local function overlap(a,b,gap) return a.minX<b.maxX+gap and b.minX<a.maxX+gap and a.minZ<b.maxZ+gap and b.minZ<a.maxZ+gap end
local function inside(a,b) return a.minX>=b.minX-1e-6 and a.maxX<=b.maxX+1e-6 and a.minZ>=b.minZ-1e-6 and a.maxZ<=b.maxZ+1e-6 end
local function box(x,z,w,d) return {minX=x-w/2,maxX=x+w/2,minZ=z-d/2,maxZ=z+d/2} end
check(L.version==2 and L.floorName=='Plot_80x100','layout C version and floor name')
check(#L.plots==8,'eight homes')
local span=L.span();local basin={minX=span.minX,maxX=span.maxX,minZ=span.minZ,maxZ=span.maxZ+76}
-- v1 basin kept (owner Q5): span is unchanged so the written berms and the gate-line exit still match.
check(close(span.minX,3881) and close(span.maxX,4311) and close(span.minZ,-178) and close(span.maxZ,436),'v1 basin span kept')
local west,east=0,0
for i,p in L.plots do
 if p.side<0 then west+=1 else east+=1 end
 -- Facing: each home's front points across the vertical street at the axis.
 local fx,fz=L.facing(i);check(close(fz,0) and close(fx,-p.side),'faces street '..i)
 local e=L.extent(i)
 check(close(e.maxX-e.minX,100) and close(e.maxZ-e.minZ,80),'80x100 footprint '..i)
 -- Plot edge sits exactly on the street edge.
 local inner=if p.side<0 then e.maxX else e.minX
 check(close(math.abs(inner-L.axisX),L.promenadeWidth/2),'street edge '..i)
 -- The gate plaza (40 deep) lies between the gate and every home.
 check(e.minZ>=L.gate.z+L.gate.towerDepth/2+L.gatePlaza-1e-6,'gate plaza clearance '..i)
 check(L.inSanctuary(p.x,p.z),'home inside sanctuary '..i)
 check(inside(e,basin),'home inside basin '..i)
 for j=i+1,8 do check(not overlap(e,L.extent(j),-1e-6),'no overlap '..i..':'..j) end
 -- Spawn sits in front, looks across the street (not at the gate); walk to the gate beats the old row.
 local sx,sz=L.spawnWorld(i);local lx,lz=L.spawnLook(i)
 check(close(lz,sz) and math.sign(lx-sx)==-p.side,'spawn faces street '..i)
 local d=L.gateDistance(i);check(d<L.previousFarthestWalk and d<=560,'gate distance '..i..' '..d)
 -- Mirror symmetry: odd (west) and even (east) plots of a row are reflections about the axis.
 if p.side>0 then local q=L.plots[i-1];check(q.row==p.row and close(q.z,p.z) and close(q.x+p.x,2*L.axisX),'mirror pair '..i) end
end
check(west==4 and east==4,'4 west, 4 east')
-- Rows: explicit z-centres, 16-stud shared garden strip inside a block, 56-wide H street between blocks.
check(close(L.rows[1],-74) and close(L.rows[2],22) and close(L.rows[3],158) and close(L.rows[4],254),'row centres -74/22/158/254')
check(close(L.southZ,294),'southZ 294')
check(close((L.rows[2]-L.plotWidth/2)-(L.rows[1]+L.plotWidth/2),L.strip) and close((L.rows[4]-L.plotWidth/2)-(L.rows[3]+L.plotWidth/2),L.strip),'strip 16 between paired plots')
check(close(L.cross.z0,L.rows[2]+L.plotWidth/2) and close(L.cross.z1,L.rows[3]-L.plotWidth/2) and close(L.cross.z1-L.cross.z0,56),'H street 56 between rows 2 and 3')
check(close(2*L.crossLane+L.channelWidth,L.crossWidth),'H street lanes+channel fill 56')
check(close(L.channelWidth+2*L.laneWidth,L.promenadeWidth),'channel+lanes fill vertical street')
check(2*L.laneWidth>=L.escapeWidth and 2*L.crossLane>=L.escapeWidth,'return walking width')
check(L.gate.opening>=L.promenadeWidth,'gate opening spans street')
check(not L.inSanctuary(L.axisX,L.gate.z-20) and L.inSanctuary(L.axisX,L.gate.z+12),'gate is the sanctuary boundary')
check(not L.inSanctuary(L.axisX,-210),'mountain entrance outside sanctuary')
local far=0;for i=1,8 do far=math.max(far,L.gateDistance(i)) end
check(math.abs(far-math.sqrt(45^2+420^2))<1e-6,'farthest walk 422 (plot 8)')
-- Commons: inside the basin, clear of every plot, inside the sanctuary test.
for name,r in L.commons do
 check(inside(r,basin),'commons in basin '..name)
 check(L.inSanctuary(r.minX+1,r.minZ+1) and L.inSanctuary(r.maxX-1,r.maxZ-1),'commons in sanctuary '..name)
 for i=1,8 do if overlap(r,L.extent(i),-1e-6) then check(false,'commons clear of plot '..name..':'..i) end end
end
local cm=L.commons
check(close(cm.gatePlaza.maxZ-cm.gatePlaza.minZ,40) and close(cm.gatePlaza.maxX-cm.gatePlaza.minX,110),'gate plaza 40x110')
check(close(cm.westEnd.maxX-cm.westEnd.minX,60) and close(cm.eastEnd.maxZ-cm.eastEnd.minZ,56),'end plazas 60x56')
check(inside(cm.westEnd,cm.westArm) and inside(cm.eastEnd,cm.eastArm),'end plazas close the arms')
check(cm.westEnd.maxX>=L.extent(1).minX-1e-6 and cm.eastEnd.minX<=L.extent(2).maxX+1e-6,'end plazas beyond plot rears')
check(L.crossPool<L.promenadeWidth and L.crossPool<L.crossWidth,'crossing pool inside crossing plaza')
check(inside(cm.crossing,cm.street),'crossing on the vertical street')
check(L.poolZ>L.southZ and close(L.poolZ,334),'south pool at southZ+40 (Q5)')
check(#L.gardens==4,'four shared garden strips')
for k,g in L.gardens do
 check(close(g.maxX-g.minX,L.plotDepth) and close(g.maxZ-g.minZ,L.strip),'garden 16x100 '..k)
 check(inside(g,basin),'garden in basin '..k)
 for i=1,8 do if overlap(g,L.extent(i),-1e-6) then check(false,'garden clear of plot '..k..':'..i) end end
 for name,r in L.commons do if overlap(g,r,-1e-6) then check(false,'garden clear of commons '..k..':'..name) end end
end
-- Plot-local contents: margin 2 inside the 80x100 plot, clearance 3 between top-level rects.
local c=L.contents;local hw,hd=L.plotWidth/2,L.plotDepth/2
local function fits(r) return r.minX>=-hw+2 and r.maxX<=hw-2 and r.minZ>=-hd+2 and r.maxZ<=hd-2 end
local rects={
 spawn=box(c.spawn.x,c.spawn.z,c.spawn.size,c.spawn.size),
 lodge={minX=c.lodge.x-c.lodge.width/2,maxX=c.lodge.x+c.lodge.width/2,minZ=c.lodge.z-c.lodge.depth/2,maxZ=c.lodge.z+c.lodge.depth/2+c.lodge.overhang},
 yard=c.yard,
 bank=box(c.bank.x,c.bank.z,c.bank.width,c.bank.depth),
 hatchery=box(c.hatchery.x,c.hatchery.z,c.hatchery.size,c.hatchery.size),
 pen=box(c.pen.x,c.pen.z,c.pen.size,c.pen.size),
 workout=box(c.workout.x,c.workout.z,c.workout.width,c.workout.depth),
}
for k,s in c.decor do rects['decor'..k]=box(s.x,s.z,c.decorSize,c.decorSize) end
-- Documented exception (plan §2): the bank plinth is joined to the spine end inside the yard.
local exception={['bank:yard']=true}
for name,r in rects do check(fits(r),'fits plot '..name) end
for a,ra in rects do for b,rb in rects do if a<b then
 local key=a..':'..b
 if exception[key] then check(overlap(ra,rb,0) and ra.minX>=c.yard.maxX-2,'bank joined to spine end')
 elseif overlap(ra,rb,3) then check(false,'content clearance '..key) end
end end end
check(rects.lodge.maxZ<=hd-2 and rects.lodge.minZ>rects.yard.maxZ,'lodge at the rear')
check(rects.spawn.minZ>=c.frontWall.z1,'spawn behind the front wall')
-- Front wall: entry gap clear of spawn; decor front row behind the wall.
check(2*c.frontWall.entryHalf>=c.spawn.size+6 and c.frontWall.entryHalf<L.plotWidth/2-4,'entry gap wider than spawn, wall either side')
for k=1,6 do check(rects['decor'..k].minZ>c.frontWall.z1,'front decor behind wall '..k) end
-- Six habitats: rims inside the yard, pairwise clear, two rows either side of the spine.
check(#c.habitats==6,'six habitats')
local spine=box(c.spine.x,c.spine.z,c.spine.width,c.spine.depth)
check(inside(spine,c.yard),'spine inside yard')
local rims={}
for k,h in c.habitats do
 rims[k]=box(h.x,h.z,c.habitat.rim.w,c.habitat.rim.d)
 check(inside(rims[k],c.yard),'habitat in yard '..k)
 check(not overlap(rims[k],spine,1-1e-6),'habitat clear of spine '..k)
 check(c.habitat.pad.w<c.habitat.rim.w and c.habitat.pad.d<c.habitat.rim.d,'pad inside rim '..k)
end
for a=1,6 do for b=a+1,6 do check(not overlap(rims[a],rims[b],1-1e-6),'habitats clear '..a..':'..b) end end
-- Machines ride the spine between the habitat rows.
check(#c.machines==3,'three machines')
for k,m in c.machines do check(inside(box(m.x,c.machine.z,c.machine.w,c.machine.d),spine),'machine on spine '..k) end
-- Services sit on the hatchery dais and the Beast pen.
for _,s in c.services do
 local host=if s.kind=='Incubator' then rects.hatchery else rects.pen
 check(inside(box(s.x,s.z,s.size,s.size),host),'service on its dais '..s.kind)
end
-- Fourteen unique decor slots.
check(#c.decor==14,'fourteen decor slots')
local seen={};for k,s in c.decor do local key=s.x..','..s.z;check(not seen[key],'decor unique '..k);seen[key]=true end
print(string.format('PASS %d home layout checks (farthest spawn-to-gate %.0f studs)',n,far))
