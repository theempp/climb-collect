-- P7 G (owner 2026-10-28, plan §22): band one-shots never animate into the keep-clear centre M. MotionBand keys (the ones
-- client/UI/Motion.luau plays) sampled every 1/480 s: box + decor never reach below the static bottom for any box, decor or
-- camera-shake setting; a held in part ends in the built state; at the six sizes every animated band piece ends at M's top
-- at the latest (static seats from UIPresentation, the same ones hud_layout checks).
local B=require('../shared/MotionBand')
local P=require('../shared/UIPresentation')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local EPS=1e-6
-- Any box / decor: the rule is per piece (own px), independent of the screen.
for name,sp in pairs(B.spec) do
 for _,w in ipairs({20,167,245,612}) do for _,h in ipairs({20,59,86.6,125,180}) do for _,e in ipairs({0,5,20,34}) do for _,k in ipairs({0,1}) do
  local d,t=B.worst(sp,w,h,e,k)
  check(d<=EPS,string.format('%s %gx%g e%g k%d reaches %.3f px below its static bottom at %.3f s',name,w,h,e,k,d,t))
  local keys=sp.keys(w,h,e,k)
  check(keys[#keys][1]==sp.dur,name..' keys span the token duration')
  if sp.inEnd then
   local v=B.state(B.tracks(keys,sp.ease),sp.inEnd)
   check(v.s==1 and v.x==0 and v.y==0 and v.r==0 and (v.a==nil or v.a==1),name..' held in part ends in the built state')
  end
 end end end end
end
-- The carry pop-up shrinks in place (owner): no x travel, scale only falls after 2.0 s, gone at the end.
do local tr=B.tracks(B.spec['carry.pop'].keys(300,78,26,1),'out');check(tr.x==nil,'carry pop-up has no flight path')
 local v=B.state(tr,2.5);check(v.s==0 and v.a==0 and v.y==0,'carry pop-up ends shrunk and faded in place') end
-- The six sizes (no topbar, no touch, HUD scale M): lowest animated extent vs M's top, virtual px (>= 0 = clear).
local SIZES={{749,330},{844,390},{932,430},{1024,700},{1180,780},{1600,860}}
local report={}
for _,v in ipairs(SIZES) do
 local w,h=v[1],v[2];local s=P.hudScale(.5,w)
 local l=P.hudLayout(w,h,{},false,nil,{scale=s,screen={x=0,y=0,w=w,h=h}});local keep=l.band.keep;local Mz=l.zones.M
 local function low(name,bw,bh,e,f) local d=B.worst(B.spec[name],bw,bh,e,1);return d*f end
 local g={}
 local _,wr,pr=P.bandRun(l,241,185,125,27)
 g.word=keep-(wr.y+wr.h+low('run.slam',241,125,0,wr.f))
 g.pill=keep-(pr.y+pr.h+low('run.awake',185,27,0,pr.f))
 local k=P.bandShock(l,wr,125,wr.x+wr.w/2);g.ring=keep-(k.y+k.h+low('run.shock',k.w,k.h,20,1)) -- glow included (strict)
 local b=P.bandSlot(l,300,59);g.banner=keep-(b.y+b.h+low('banner',300,59,0,b.f))
 local c=P.bandSlot(l,300,78);g.pop=keep-(c.y+c.h+low('carry.pop',300,78,0,c.f))
 local m=P.bandSlot(l,300,105);g.sub=keep-(m.y+m.h+low('moment',300,20,0,m.f));g.title=keep-(m.y+77*m.f+low('moment',300,77,0,m.f))
 for key,gap in pairs(g) do check(gap>=-EPS,w..'x'..h..' '..key..' enters M by '..(-gap)) end
 local cta=P.bandCollect(l,m)
 if cta.below then check(cta.y+cta.h+low('moment.collect',190,46,6,1)<=keep+EPS,w..'x'..h..' Collect (above M) grows into M')
 else check(cta.y>=Mz.y+Mz.h-EPS and B.worst(B.spec['moment.collect'],190,46,6,1)<=EPS,w..'x'..h..' Collect (below M) grows into M') end -- s <= 1 about its centre: top never rises
 report[w]=g
end
local a,b=report[749],report[844]
print(string.format('PASS %d band motion checks (gap to M top 749/844: word %.1f/%.1f pill %.1f/%.1f ring %.1f/%.1f pop %.1f/%.1f)',
 n,a.word,b.word,a.pill,b.pill,a.ring,b.ring,a.pop,b.pop))
