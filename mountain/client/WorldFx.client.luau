-- World-motion driver (home-base P7; homebase-style-s1-plan §3c "the one world-motion driver"). Timing, shape and caps come
-- from Motion.tokens['world.*'] (kind='world'), colours from WorldStyle only, materials from S.material. Today one effect:
-- world.tierup (homebase-intel §D beats, §F pool rules; homebase-world-style-intel §C). Later world tokens (gate gem, globe /
-- crest pulse, intel §C) join as another FX entry with the same start / step / finish shape.
-- Perf (intel §F): one client-only pool, created lazily and reused; one RenderStepped connection that exists only while an
-- effect runs; one workspace:BulkMoveTo per frame; no tweens. Effect time = (server now - TierUpAt) * k, k = Motion.speed()
-- read once at start (the server's swap delay uses the same k), so live k = 1 is real time.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local shared=RS:WaitForChild('MountainShared');shared:WaitForChild('MotionBand')
local S=require(shared:WaitForChild('WorldStyle'))
local M=require(script.Parent:WaitForChild('UI'):WaitForChild('Motion'))
local player=Players.LocalPlayer
local function rgb(t) return Color3.fromRGB(t[1],t[2],t[3]) end;local function hsv(h,s,v) return Color3.fromHSV(h,s,v) end -- WorldStyle rgb helper
-- Colour pass between two WorldStyle colours in HSV (owner fix: an RGB blend of blue -> gold greys out midway): hue the short way
-- round, saturation / value linear; a, b = precomputed {h,s,v}; cw 0 / 1 return the exact WorldStyle colours c0 / c1.
local function blend(c0,c1,a,b,w)
 if w<=0 then return c0 elseif w>=1 then return c1 end
 local dh=(b[1]-a[1]+.5)%1-.5
 return hsv((a[1]+dh*w)%1,a[2]+(b[2]-a[2])*w,a[3]+(b[3]-a[3])*w)
end
local UP,FLAT=Vector3.yAxis,CFrame.Angles(math.pi/2,0,0) -- FLAT: a CylinderHandleAdornment's axis (Z) turned vertical
local function span(b,t) return (t-b[1])/(b[2]-b[1]) end
local function aids() return RS:GetAttribute('StudioAids')==true end
local function warnOnce(e,what,err) if not e.warned then e.warned=true;warn('WorldFx '..what..': '..tostring(err)) end end

-- Pool (shared by every world effect; one full effect owns it at a time). Parts: Anchored, no collide / touch / query / shadow.
local pool={cubes={},orbs={},rings={},anchor=nil,folder=nil,owner=nil}
local ARC=nil -- CylinderHandleAdornment.Angle supported (beat 1 arcs); probed on the first ring
local function folder()
 if not pool.folder then local f=Instance.new('Folder');f.Name='WorldFxPool';f.Parent=workspace;pool.folder=f end
 return pool.folder
end
local function newPart(name,shape,d,mat)
 local p=Instance.new('Part');p.Name=name;p.Shape=shape;p.Size=Vector3.one*d;p.Material=Enum.Material[mat]
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Transparency=1
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=folder();return p
end
local function newRing(i)
 local a=Instance.new('CylinderHandleAdornment');a.Name='Ring'..i;a.Adornee=pool.anchor;a.Color3=rgb(S.color.text) -- beat 1 "thin white ring lines"
 a.Height=M.tokens['world.tierup'].shape.ringH;a.Radius=1;a.InnerRadius=0;a.Transparency=1;a.Visible=false;a.AlwaysOnTop=false
 if ARC==nil then ARC=pcall(function() a.Angle=360 end) end
 a.Parent=folder();return a
end
local function grow(list,n,make) while #list<n do table.insert(list,make(#list+1)) end end
local function release()
 for _,p in ipairs(pool.cubes) do p.Transparency=1 end
 for _,p in ipairs(pool.orbs) do p.Transparency=1 end
 for _,a in ipairs(pool.rings) do a.Visible=false end
 pool.owner=nil
end

-- Effects (any FX) and the one frame step.
local active={} -- effect -> true
local conn
local FX={}
local publish
local function finish(e)
 if not active[e] then return end;active[e]=nil
 local ok,err=pcall(e.fx.finish,e);if not ok then warnOnce(e,'finish',err) end
 if pool.owner==e then release() end
 publish()
end
local function tick()
 local parts,cfs,ended={},{},nil
 for e in pairs(active) do
  local t=(workspace:GetServerTimeNow()-e.at)*e.k
  if t>=e.fx.endT then ended=ended or {};table.insert(ended,e)
  else
   local n=#parts;local ok,err=pcall(e.fx.step,e,t,parts,cfs)
   if not ok then for i=#parts,n+1,-1 do parts[i]=nil;cfs[i]=nil end;warnOnce(e,'step',err);ended=ended or {};table.insert(ended,e) end
  end
 end
 if #parts>0 then workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged) end
 if ended then for _,e in ipairs(ended) do finish(e) end end
 if next(active)==nil and conn then conn:Disconnect();conn=nil;publish() end -- rest = 0 connections
end
local function run(e) active[e]=true;if not conn then conn=Run.RenderStepped:Connect(tick) end;publish() end

-- Studio probe (StudioAids only): _G.CC_WORLDFX for this VM, and the same counts as WorldFxPool attributes for other VMs.
publish=function()
 if not aids() then return end
 local n,own=0,pool.owner;for _ in pairs(active) do n+=1 end
 local st={active=n,stepping=conn~=nil,cubes=if own then #own.cubes else 0,orbs=if own then #own.orbs else 0,rings=if own then #pool.rings else 0,
  poolCubes=#pool.cubes,poolOrbs=#pool.orbs,owner=if own then own.plot.Name else nil}
 _G.CC_WORLDFX=st
 local f=folder();for k,v in pairs(st) do f:SetAttribute(k,v) end;if not own then f:SetAttribute('owner',nil) end
end

-- world.tierup ----------------------------------------------------------------------------------------------------------
local TK=M.tokens['world.tierup']
local B,SH,EZ=TK.beats,TK.shape,TK.ease
local ROLES={'body','roof','ridge','gem'} -- WorldStyle S.tier roles; cube i keeps role i (mod 4) old -> new
-- A tier role colour; palace has no single roof: its roof cubes cycle the 4 roofBands stops (intel §C "T4 cycles 4 prism stops").
local function roleColor(key,role,i)
 local t=key and S.tier[key];if not t then return nil end
 local v=t[role];if v==nil and role=='roof' and t.roofBands then local b=t.roofBands;v=b[((i-1)//4)%#b+1] end
 return v and rgb(v)
end
local function partsOf(m) local l={};if m then for _,d in ipairs(m:GetDescendants()) do if d:IsA('BasePart') then table.insert(l,d) end end end;return l end
-- House visibility, local only: which = 'old' | 'new'; LocalTransparencyModifier on every BasePart of that House.
local function setHouse(e,which,v)
 local l=e[which..'Parts'];if not l then return end
 for _,p in ipairs(l) do p.LocalTransparencyModifier=v end;e[which..'LTM']=v
end
local function bbox(m) local ok,cf,size=pcall(m.GetBoundingBox,m);if ok and size.Magnitude>0 then return {cf=cf,size=size} end;return nil end
local byPlot={} -- plot -> tier-up effect

local tierup={endT=TK.endT}
FX['world.tierup']=tierup
local function arrive(e,m,seen)
 if m==e.old or m==e.new then return end
 if e.new then setHouse(e,'new',0) end -- a second rebuild mid-effect: give the previous one back
 e.new=m;e.newParts=partsOf(m);e.bbNew=nil;e.newLTM=0
 table.insert(e.conns,m.DescendantAdded:Connect(function(d) if d:IsA('BasePart') and e.newParts then table.insert(e.newParts,d);d.LocalTransparencyModifier=e.newLTM or 0 end end))
 local t=(workspace:GetServerTimeNow()-e.at)*e.k
 if e.mode=='full' then if t<B.reconstruct[1] then setHouse(e,'new',1) end -- hidden until the reconstruct beat (step reveals it)
 elseif seen then setHouse(e,'new',1);table.insert(e.fades,{w='new',from=1,t0=t,dur=TK.reducedFade}) end -- Reduce: .15 s crossfade
end
-- Full -> crossfade (Reduce turned on mid-effect, or an own-plot effect took the pool): hidden Houses fade back in .15 s.
local function downgrade(e)
 if e.mode~='full' then return end
 if pool.owner==e then release() end
 e.mode='fade';e.cubes={};e.orbs={};local t=(workspace:GetServerTimeNow()-e.at)*e.k
 for _,w in ipairs({'old','new'}) do local v=e[w..'LTM'];if v and v>0 then table.insert(e.fades,{w=w,from=v,t0=t,dur=TK.reducedFade}) end end
 publish()
end
local function acquire(e,caps)
 pool.owner=e
 grow(pool.cubes,caps.cubes,function(i) return newPart('Cube'..i,Enum.PartType.Block,SH.cube,S.material.body) end)
 grow(pool.orbs,caps.orbs,function(i) return newPart('Orb'..i,Enum.PartType.Ball,SH.orb,S.material.trim) end)
 if not pool.anchor then pool.anchor=newPart('RingAnchor',Enum.PartType.Block,SH.ringH,S.material.body) end
 grow(pool.rings,TK.rings,newRing)
 local rng=Random.new(math.floor(e.at*1000)%2147483647) -- same cloud on every client for one raise
 local tau=2*math.pi;local n=caps.cubes;local bb=e.bb
 for i=1,n do
  local role=ROLES[(i-1)%#ROLES+1];local c1=roleColor(e.to,role,i)
  local th=(i-1)/n*tau+rng:NextNumber(-SH.cloudJitter,SH.cloudJitter)
  local u=Vector3.new(rng:NextNumber(-SH.fill,SH.fill),rng:NextNumber(-SH.fill,SH.fill),rng:NextNumber(-SH.fill,SH.fill))
  local c={p=pool.cubes[i],c0=roleColor(e.from,role,i) or c1,c1=c1,th=th,ph=(th/tau)%1,
   r=e.half*SH.cloud*(1+rng:NextNumber(-SH.cloudJitter,SH.cloudJitter)),h=e.y0+bb.size.Y*rng:NextNumber(SH.cloudLow,SH.cloudHigh),
   p0=bb.cf:PointToWorldSpace(u*bb.size/2),q=Vector3.new(rng:NextNumber(-SH.fill,SH.fill),rng:NextNumber(-SH.fill,SH.fill),rng:NextNumber(-SH.fill,SH.fill)),
   s=B.deconstruct[1]+rng:NextNumber()*SH.lagMax,tx=rng:NextNumber(-SH.tumble,SH.tumble),ty=rng:NextNumber(-SH.tumble,SH.tumble),cw=0,on=false}
  c.v0={c.c0:ToHSV()};c.v1={c.c1:ToHSV()};c.p.Transparency=1;c.p.Color=c.c0;table.insert(e.cubes,c)
 end
 local g0,g1=roleColor(e.from,'gem',1),roleColor(e.to,'gem',1)
 for j=1,caps.orbs do
  local o={p=pool.orbs[j],c0=g0 or g1,c1=g1,th=(j-1)/caps.orbs*tau,ph=rng:NextNumber(),h=e.y0+bb.size.Y*rng:NextNumber(SH.orbLow,SH.orbHigh),cw=0,on=false}
  o.v0={o.c0:ToHSV()};o.v1={o.c1:ToHSV()};o.p.Transparency=1;o.p.Color=o.c0;table.insert(e.orbs,o)
 end
 e.placeAnchor=true
end

function tierup.start(plot)
 local at,from,to=plot:GetAttribute('TierUpAt'),plot:GetAttribute('TierUpFrom'),plot:GetAttribute('TierUpTo')
 if type(at)~='number' or type(to)~='string' or not S.tier[to] then return end
 local prev=byPlot[plot];if prev then if prev.at==at and active[prev] then return end;finish(prev) end -- a new raise restarts cleanly
 local k=M.speed();local t=(workspace:GetServerTimeNow()-at)*k
 if t>=TK.endT then return end -- old raise (late join)
 local root=plot:FindFirstChild('TycoonProduction');if not root then return end
 local h=root:FindFirstChild('House')
 local own=plot.Name==string.format('Plot_%02d',math.floor(tonumber(player:GetAttribute('SanctuaryPlot')) or 0))
 if not own then
  local ch=player.Character;local hrp=ch and ch:FindFirstChild('HumanoidRootPart')
  local at3=if h then h:GetPivot().Position else root:GetPivot().Position
  if not hrp or (hrp.Position-at3).Magnitude>TK.visitorRange then return end -- farther: the server swap only
 end
 local e={fx=tierup,plot=plot,root=root,at=at,k=k,from=from,to=to,own=own,conns={},fades={},cubes={},orbs={}}
 local joinNew=h and h:GetAttribute('Tier')==to and from~=to -- joined after the server swap
 if h and not joinNew then e.old=h;e.oldParts=partsOf(h);e.oldLTM=0 end
 local caps=M.worldCaps(own);local bb=h and bbox(h)
 local full=caps.cubes>0 and bb~=nil and (pool.owner==nil or (own and not pool.owner.own))
 if full then
  if pool.owner then downgrade(pool.owner) end
  e.mode='full';e.bb=bb;e.cx,e.cy,e.cz=bb.cf.Position.X,bb.cf.Position.Y,bb.cf.Position.Z;e.y0=h:GetPivot().Position.Y -- pivot = floor top
  e.half=.5*math.max(bb.size.X,bb.size.Z);acquire(e,caps)
 else e.mode='fade' end
 table.insert(e.conns,root.ChildAdded:Connect(function(c) if c.Name=='House' then arrive(e,c,true) end end))
 if joinNew then arrive(e,h,false) end
 byPlot[plot]=e;run(e)
end

local function ring(a,on,r,w,tr,spin,arc)
 if not a then return end
 if not on then if a.Visible then a.Visible=false end;return end
 a.InnerRadius=0;a.Radius=r;a.InnerRadius=math.max(0,r-w);a.Transparency=tr;a.CFrame=CFrame.Angles(0,spin,0)*FLAT;a.Visible=true
 if ARC then a.Angle=arc end
end
local function cloud(e,c,t,sc)
 local a=c.th+SH.spin*(t-B.deconstruct[1]);local r=c.r*sc
 return Vector3.new(e.cx+math.cos(a)*r,e.cy+(c.h-e.cy)*sc,e.cz+math.sin(a)*r)
end
local function scaleAt(t)
 if t<B.contract[1] then return 1 elseif t<B.contract[2] then return 1+(SH.contract-1)*M.eased(EZ.contract,span(B.contract,t)) end
 return SH.contract
end
local function stepFull(e,t,parts,cfs)
 local rec,dec=B.reconstruct,B.deconstruct
 -- Houses: old hidden from the deconstruct beat; the arriving one stays hidden until reconstruct, then fades in (never a pop).
 if e.old and not e.oldHid and t>=dec[1] then e.oldHid=true;setHouse(e,'old',1) end
 if e.new then
  if t<rec[1] then if e.newLTM~=1 then setHouse(e,'new',1) end
  elseif t<rec[2] then setHouse(e,'new',1-M.eased(EZ.reveal,span(rec,t)))
  elseif e.newLTM~=0 then setHouse(e,'new',0) end
 end
 if e.placeAnchor and pool.anchor then e.placeAnchor=false;parts[#parts+1]=pool.anchor;cfs[#cfs+1]=CFrame.new(e.cx,e.y0+SH.ringH/2,e.cz) end
 -- Rings: 1-2 orbit rings (beats 1-6) + the shockwave (beat 3).
 local R=pool.rings;local rA,rB=e.half*SH.ringStart,e.half*SH.ringOrbit
 local r=if t<B.anticipation[1] then rA elseif t<B.anticipation[2] then rA+(rB-rA)*M.eased(EZ.widen,span(B.anticipation,t)) else rB
 local w=if t<dec[1] then SH.ringLine elseif t<dec[2] then SH.ringLine+(SH.ringThick-SH.ringLine)*span(dec,t) else SH.ringThick
 local tr
 if t<B.idle[2] then tr=1+(SH.ringT-1)*math.clamp(span(B.idle,t),0,1)
 elseif t<B.swirl[1] then tr=SH.ringT
 elseif t<rec[1] then tr=SH.ringT+SH.ringPulse*(.5+.5*math.sin(2*math.pi*(t-B.swirl[1])/TK.pulse))
 elseif t<rec[2] then tr=SH.ringT+(1-SH.ringT)*span(rec,t)
 else tr=1 end
 local arc=360*M.eased(EZ.widen,span(B.idle,t))
 ring(R[1],tr<1,r,w,tr,SH.ringSpin*t,arc);ring(R[2],tr<1,r+SH.ringGap,w,tr,-SH.ringSpin*t,arc)
 if t>=dec[1] and t<dec[2] then local u=span(dec,t);ring(R[3],true,e.half*(SH.shockFrom+(SH.shockTo-SH.shockFrom)*M.eased(EZ.shock,u)),SH.ringThick,M.eased(EZ.fade,u),0,360)
 else ring(R[3],false) end
 -- Cubes: spawn across the old House box at deconstruct, lift into the donut, swirl + recolour, contract, settle into the new box.
 local sc=scaleAt(t);local fadeFrom=rec[2]-SH.cubeFade*(rec[2]-rec[1])
 if t>=rec[1] and not e.bbNew and e.new then e.bbNew=bbox(e.new) end
 local bq=e.bbNew or e.bb;local sw=B.swirl[2]-B.swirl[1]-SH.wave
 for _,c in ipairs(e.cubes) do
  local p=c.p
  if t<dec[1] or t>=rec[2] then if c.on then c.on=false;p.Transparency=1 end
  else
   local pos
   if t<c.s then pos=c.p0
   elseif t<dec[2] then local u=(t-c.s)/(dec[2]-c.s);pos=c.p0:Lerp(cloud(e,c,t,1),M.eased(EZ.lift,u))+UP*SH.lift*math.sin(math.pi*u)
   elseif t<rec[1] then pos=cloud(e,c,t,sc)
   else pos=cloud(e,c,t,sc):Lerp(bq.cf:PointToWorldSpace(c.q*bq.size/2),M.eased(EZ.settle,span(rec,t))) end
   local spin=math.max(0,t-c.s);local cf=CFrame.new(pos)*CFrame.Angles(c.tx*spin,c.ty*spin,0)
   parts[#parts+1]=p;cfs[#cfs+1]=cf
   local a=if t>=fadeFrom then (t-fadeFrom)/(rec[2]-fadeFrom) else 0
   if not c.on or a>0 then c.on=true;p.Transparency=a end
   local cw=math.clamp((t-B.swirl[1]-SH.wave*c.ph)/sw,0,1) -- the colour pass runs round the donut (wave)
   if cw~=c.cw then c.cw=cw;p.Color=blend(c.c0,c.c1,c.v0,c.v1,cw) end
  end
 end
 -- Orbs: swirl + contract only; glow = the pulse-period transparency breath; tier gem old -> new.
 local o0,o1=B.swirl[1],B.contract[2]
 for _,o in ipairs(e.orbs) do
  local p=o.p
  if t<o0 or t>=o1 then if o.on then o.on=false;p.Transparency=1 end
  else
   o.on=true
   local a=o.th+SH.orbSpin*(t-o0);local rr=e.half*SH.orbR*sc
   parts[#parts+1]=p;cfs[#cfs+1]=CFrame.new(e.cx+math.cos(a)*rr,e.cy+(o.h-e.cy)*sc,e.cz+math.sin(a)*rr)
   local vis=math.min(1,(t-o0)/SH.orbIn);if t>=B.contract[1] then vis*=1-span(B.contract,t) end
   p.Transparency=1-vis*(1-SH.ringPulse*(.5+.5*math.sin(2*math.pi*(t/TK.pulse+o.ph))))
   local cw=math.clamp(span(B.swirl,t),0,1);if cw~=o.cw then o.cw=cw;p.Color=blend(o.c0,o.c1,o.v0,o.v1,cw) end
  end
 end
end
function tierup.step(e,t,parts,cfs)
 if e.mode=='full' and M.reduced() then downgrade(e) end -- Reduce mid-effect: skip to the crossfade
 if e.mode=='full' then stepFull(e,t,parts,cfs) end
 for i=#e.fades,1,-1 do
  local f=e.fades[i];local u=(t-f.t0)/f.dur
  if u>=1 then setHouse(e,f.w,0);table.remove(e.fades,i) else setHouse(e,f.w,f.from*(1-M.eased(EZ.fade,u))) end
 end
end
-- End (6.5 s, a new raise, a failure): every House this effect touched gets LocalTransparencyModifier 0; pool parts hide.
function tierup.finish(e)
 for _,c in ipairs(e.conns) do c:Disconnect() end;table.clear(e.conns)
 setHouse(e,'old',0);setHouse(e,'new',0)
 local h=e.root and e.root.Parent and e.root:FindFirstChild('House');if h and h~=e.old and h~=e.new then for _,p in ipairs(partsOf(h)) do p.LocalTransparencyModifier=0 end end
 if byPlot[e.plot]==e then byPlot[e.plot]=nil end
end

-- Plot hooks: TierUpFrom / TierUpTo are set before TierUpAt (TycoonWorld setHome); a deferred read sees all three.
local hooked={}
local function startSafe(plot) local ok,err=pcall(tierup.start,plot);if not ok then warn('WorldFx tierup start: '..tostring(err)) end end
local function hook(plot)
 if hooked[plot] or not plot:IsA('Model') or not string.match(plot.Name,'^Plot_%d%d$') then return end
 hooked[plot]=true
 plot:GetAttributeChangedSignal('TierUpAt'):Connect(function() task.defer(startSafe,plot) end)
 if plot:GetAttribute('TierUpAt')~=nil then task.defer(startSafe,plot) end
end
if aids() then publish() end
task.spawn(function()
 local plots=workspace:WaitForChild('Sanctuary'):WaitForChild('SanctuaryPlots')
 plots.ChildAdded:Connect(hook);for _,p in ipairs(plots:GetChildren()) do hook(p) end
end)
