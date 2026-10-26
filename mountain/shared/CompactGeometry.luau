-- Provisional Review07 dimensions, selected after measuring Review06.
-- Applies to ground and landscape, never to avatars, homes or encounter props.
local G={version=1,scale=.85,escapeWidth=32,hazardHalfWidth=16}
function G.point(p)
 return {x=4096+(p.x-4096)*G.scale,y=16+(p.y-16)*G.scale,z=-210+(p.z+210)*G.scale}
end
function G.original(p)
 return {x=4096+(p.x-4096)/G.scale,y=16+(p.y-16)/G.scale,z=-210+(p.z+210)/G.scale}
end
function G.layout(g)
 for _,s in g.sections do
  s.entry=G.point(s.entry);s.terrace=G.point(s.terrace);s.finish=G.point(s.finish)
  s.normalAltar=G.point(s.normalAltar);s.trialAltar=G.point(s.trialAltar)
  local h=G.point(s.hazard);s.hazard.x=h.x;s.hazard.y=h.y;s.hazard.z=h.z
  local b=s.bounds;local a=G.point({x=b.minX,y=b.minY,z=b.minZ});local c=G.point({x=b.maxX,y=b.maxY,z=b.maxZ})
  b.minX=a.x;b.minY=a.y;b.minZ=a.z;b.maxX=c.x;b.maxY=c.y;b.maxZ=c.z
 end
 for _,e in g.eggs do local x=e.position.x;e.position=G.point(e.position);e.position.x=x end
 for _,r in g.restPoints do r.position=G.point(r.position) end
 return g
end
return G
