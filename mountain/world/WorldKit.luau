-- World kit (home-base S2, s1-plan §3b): candy-glass prop builders as code, no baked protos.
-- Kit.<item>(parent, cframe, opts) -> Model; cframe = ground point, +Y up. Model attribute `Parts` = BasePart count.
-- Recipes: design/homebase-world-style-intel.md B3-B7. Colours only from WorldStyle (lint: tools/world_style_lint.py).
-- All parts Anchored, CanTouch false, CanCollide false (intel B names no collider for these items; opts.collide=true
-- turns it on for blocking callers, OPEN until S3). DEC#2 chunky + rounded: stubby fat stems, big heads, soft forms
-- built as dome = wide short Cylinder + Ball sunk on it. S2 answer: unions allowed, always CanCollide false.
-- Kit.useUnions (default true): on a server/Studio, soft forms merge per colour via GeometryService:UnionAsync
-- (pcall; on failure the plain parts stay). A union counts as 1 part; plain path stays within the same caps.
local S=require(game.ReplicatedStorage.MountainShared.WorldStyle)
local Kit={}
local M=Enum.Material
local MAT={SmoothPlastic=M.SmoothPlastic,Neon=M.Neon,Glass=M.Glass}
local function rgb(c) if type(c)=='string' then c=assert(S.color[c],c) end;return Color3.fromRGB(c[1],c[2],c[3]) end -- WorldStyle rgb helper
Kit.rgb=rgb
local UP=CFrame.Angles(0,0,math.pi/2) -- Cylinder axis is X; this stands it on Y.
local function model(parent,name,cf)
 local m=Instance.new('Model');m.Name=name;m.WorldPivot=cf;m:SetAttribute('Parts',0);m.Parent=parent;return m
end
-- shape: 'Block' | 'Ball' | 'Cyl' (vertical cylinder; size = (d, h)) ; mat: S.material key or material name.
local function part(m,name,shape,size,cf,color,mat,opts)
 local p=Instance.new('Part');p.Name=name
 if shape=='Cyl' then p.Shape=Enum.PartType.Cylinder;p.Size=Vector3.new(size.Y,size.X,size.X);p.CFrame=cf*UP
 elseif shape=='TiltCyl' then p.Shape=Enum.PartType.Cylinder;p.Size=Vector3.new(size.Y,size.X,size.X);p.CFrame=cf
 elseif shape=='Ball' then p.Shape=Enum.PartType.Ball;p.Size=Vector3.one*size.X;p.CFrame=cf
 else p.Size=size;p.CFrame=cf end
 p.Color=rgb(color);p.Material=MAT[S.material[mat] or mat]
 if p.Material==M.Glass then p.Transparency=S.glassT end
 p.Anchored=true;p.CanTouch=false;p.CanCollide=opts~=nil and opts.collide==true;p.CastShadow=p.Material~=M.Neon
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=m;m:SetAttribute('Parts',m:GetAttribute('Parts')+1);return p
end
local function v(x,y) return Vector3.new(x,y or x,x) end
Kit.useUnions=true
local function canUnion()
 if not Kit.useUnions then return false end
 local ok,r=pcall(function() return game:GetService('RunService'):IsServer() end);return ok and r==true
end
-- Merge `ps` (same model) into one union per colour (keeps multi-colour items): UsePartColor true, CanCollide false.
local function soften(m,name,ps)
 if not canUnion() or #ps<2 then return end
 local groups,order={},{}
 for _,p in ps do local k=p.Color:ToHex();if not groups[k] then groups[k]={};table.insert(order,k) end;table.insert(groups[k],p) end
 for _,k in order do local g=groups[k]
  if #g>=2 then
   local ok,res=pcall(function() local G=game:GetService('GeometryService')
    return G:UnionAsync(g[1],{table.unpack(g,2)},{SplitApart=false}) end)
   local u=ok and res and res[1]
   if u then
    u.Name=name;u.UsePartColor=true;u.Color=g[1].Color;u.Material=g[1].Material;u.Transparency=g[1].Transparency
    u.Anchored=true;u.CanTouch=false;u.CanCollide=false;u.CastShadow=g[1].CastShadow;u.Parent=m
    for _,p in g do p:Destroy() end
    m:SetAttribute('Parts',m:GetAttribute('Parts')-#g+1)
   end
  end
 end
end
-- Soft dome: wide short skirt Cylinder (d, t) on cf + Ball (d*.86) centred on the skirt top. Returns both parts.
local function dome(m,name,d,t,cf,color,mat,opts)
 local a=part(m,name,'Cyl',v(d,t),cf*CFrame.new(0,t/2,0),color,mat,opts)
 local b=part(m,name,'Ball',v(d*.86),cf*CFrame.new(0,t,0),color,mat,opts)
 return a,b
end -- (d, h) for Cyl, (d) for Ball
local function at(cf,x,y,z) return cf*CFrame.new(x,y,z) end
local function motion(p,token) p:SetAttribute('WorldMotion',token);return p end -- driver = WorldFx (S6)
-- B4 pill billboard (homebase-intel A8: h 25, padX 9, r11, stroke 1.5, FO 12, MaxDistance 45, no AlwaysOnTop).
local function pill(adornee,text,stroke,offset)
 local b=Instance.new('BillboardGui');b.Name='Pill';b.Size=UDim2.fromOffset(160,25) -- 160 = legacy container width (A8), REC
 b.StudsOffset=offset or Vector3.new(0,3,0);b.MaxDistance=S.sign.maxDistance;b.AlwaysOnTop=false;b.LightInfluence=0;b.Adornee=adornee
 local f=Instance.new('Frame');f.Size=UDim2.fromScale(1,1);f.BackgroundColor3=rgb('signNight');f.BackgroundTransparency=S.signT;f.Parent=b
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,S.sign.radius);c.Parent=f
 local s=Instance.new('UIStroke');s.Thickness=S.sign.stroke;s.Color=rgb(stroke or 'signStroke');s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=f
 local pd=Instance.new('UIPadding');pd.PaddingLeft=UDim.new(0,9);pd.PaddingRight=UDim.new(0,9);pd.Parent=f
 local t=Instance.new('TextLabel');t.Name='Label';t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text or ''
 t.TextColor3=rgb('signText');t.TextSize=S.sign.textSize;t.Font=Enum.Font[S.fonts.body];t.TextTruncate=Enum.TextTruncate.AtEnd;t.Parent=f
 -- TODO(atlas): A8 text outline (1 px `outline` T.2) has no world-style A/B row; 7th instance left out.
 b.Parent=adornee;return b
end

-- B3 globe lamp: foot + collar (lip) with a soft Ball shoulder, pole (vi), ctaHi ring, Neon globe. Every 3rd lamp pink.
-- Chunk pass: pole d 2 (was .9) h 6.4 (was 9), globe d 3.6 (was 2.4); 6 plain parts, 5 with the collar union.
function Kit.globeLamp(parent,cf,opts)
 opts=opts or {};local k=opts.scale or 1;local m=model(parent,'GlobeLamp',cf)
 part(m,'Foot','Cyl',v(3.4*k,.8*k),at(cf,0,.4*k,0),'lampCollar','body')
 part(m,'Pole','Cyl',v(2*k,6.4*k),at(cf,0,4*k,0),'lampPole','body',opts)
 local c=part(m,'Collar','Cyl',v(3.2*k,.7*k),at(cf,0,7.55*k,0),'lampCollar','body')
 local d=part(m,'Collar','Ball',v(3*k),at(cf,0,7.4*k,0),'lampCollar','body') -- rounded underside of the globe base
 part(m,'Ring','Cyl',v(3.6*k,.45*k),at(cf,0,8.1*k,0),'lampRing','body') -- B3 ring material unstated: SmoothPlastic, REC
 local pink=(opts.index or 1)%3==0
 motion(part(m,'Globe','Ball',v(3.6*k),at(cf,0,9.9*k,0),pink and 'globePink' or 'globeWarm','trim'),'globePulse')
 soften(m,'GlobeBase',{c,d})
 return m
end
-- B4 pill sign. opts.adornee (BasePart) else an invisible 1-part anchor at cframe; opts.text, opts.stroke (colour key).
function Kit.pillSign(parent,cf,opts)
 opts=opts or {};local m=model(parent,'PillSign',cf);local a=opts.adornee
 if not a then a=part(m,'Anchor','Block',v(.2),cf,'signNight','body');a.Transparency=1;a.CanQuery=false;a.CastShadow=false end
 pill(a,opts.text,opts.stroke,opts.offset);return m
end
-- B4 habitat plaque: lip post + foot, Glass T.25 glass.from plaque (S0.7). opts.text adds the pill in front.
function Kit.plaque(parent,cf,opts)
 opts=opts or {};local m=model(parent,'Plaque',cf)
 part(m,'Foot','Cyl',v(2.4,.6),at(cf,0,.3,0),'plaquePost','body')
 part(m,'Post','Cyl',v(1.3,3.2),at(cf,0,2.2,0),'plaquePost','body',opts) -- chunk pass: d 1.3 (was .6)
 local g=part(m,'Plaque','Block',Vector3.new(4.2,1.6,.3),at(cf,0,4.4,0),'plaque','accent')
 if opts.text then pill(g,opts.text,nil,Vector3.new(0,0,0)) end -- pill billboard on the plaque, no extra part
 return m
end
-- B5 pen fence on the 15x12 pad: tint floor, 6 round posts (4 corners + 2 gate posts, 4-wide front opening at -Z),
-- 4 Ball caps on the corners (chunk pass: posts d 1.5, caps d 2, rails d 1; B5 h 3.2 kept), rails on 3 sides. opts.pen = 1..6 (S0.6 order); opts.w, opts.d override 15 x 12.
function Kit.fence(parent,cf,opts)
 opts=opts or {};local c=S.pens[opts.pen or 1];local w,d=opts.w or 15,opts.d or 12;local m=model(parent,'Fence',cf)
 local hw,hd,h=w/2,d/2,3.2
 part(m,'Floor','Block',Vector3.new(w,.2,d),at(cf,0,.1,0),c,'body')
 for i,x in {-hw,hw} do for j,z in {-hd,hd} do
  part(m,'Post','Cyl',v(1.5,h),at(cf,x,h/2,z),c,'body',opts)
  part(m,'Cap','Ball',v(2),at(cf,x,h+.4,z),c,'body')
 end end
 for _,x in {-2,2} do part(m,'GatePost','Cyl',v(1.5,h),at(cf,x,h/2,-hd),c,'body',opts) end
 local y=h*.7
 part(m,'RailBack','TiltCyl',v(1,w),at(cf,0,y,hd),c,'body',opts)
 part(m,'RailLeft','TiltCyl',v(1,d),at(cf,-hw,y,0)*CFrame.Angles(0,math.pi/2,0),c,'body',opts)
 part(m,'RailRight','TiltCyl',v(1,d),at(cf,hw,y,0)*CFrame.Angles(0,math.pi/2,0),c,'body',opts)
 -- B5 "front open 4": front corner-to-gate-post rails are not in the 17-part recipe; left open. Atlas to confirm.
 return m
end
-- B6 coin marker on an EMPTY decor stand (S2 answer): lavText stand + lip ring, gold coin + Neon gold.hi rim,
-- T.5 Neon halo, price pill (gold stroke). opts.price (number), opts.halo=false drops the halo.
function Kit.coinMarker(parent,cf,opts)
 opts=opts or {};local m=model(parent,'CoinMarker',cf)
 part(m,'StandLip','Cyl',v(3.4,.3),at(cf,0,.15,0),'coinStandLip','body')
 part(m,'Stand','Cyl',v(3,.6),at(cf,0,.6,0),'coinStand','body')
 local face=at(cf,0,2.6,0)*CFrame.Angles(0,math.pi/2,0) -- coin face toward -Z (TiltCyl axis X turned to Z)
 part(m,'Coin','TiltCyl',v(2.2,.8),face,'coin','body') -- no intel C token for coin motion
 part(m,'Rim','TiltCyl',v(2.5,.5),face,'coinRim','trim')
 if opts.halo~=false then local hl=part(m,'Halo','Ball',v(3.4),face,'coinHalo','trim');hl.Transparency=S.haloT;hl.CanQuery=false end
 pill(m.Coin,opts.price and (tostring(opts.price)..' coins') or '','coinStroke',Vector3.new(0,2.4,0))
 return m
end

-- B7 flora and decor (12 types, each <= 8 parts). DEC#2 chunk pass: stems ~2.4x thicker and shorter, heads ~1.5x,
-- fillers knee-to-waist (1.5-3.5) on a 5-stud avatar.
function Kit.lollipopTree(parent,cf,opts) -- #1 trunk lavText, canopy go2 (opts.pink -> pk), 2 ctaHi swirl bands
 opts=opts or {};local m=model(parent,'LollipopTree',cf)
 part(m,'Trunk','Cyl',v(2.2,4.6),at(cf,0,2.3,0),'lavText','body',opts)
 part(m,'Canopy','Ball',v(9),at(cf,0,8.4,0),opts.pink and 'pk' or 'go2','body')
 part(m,'Band','TiltCyl',v(9.4,.9),at(cf,0,8.4,0)*CFrame.Angles(0,0,.35),'ctaHi','body')
 part(m,'Band','TiltCyl',v(9.4,.9),at(cf,0,8.4,0)*CFrame.Angles(0,math.pi/2,-.35),'ctaHi','body')
 return m
end
function Kit.swirlTree(parent,cf,opts) -- #2 trunk + 3 stacked tilted discs pk / vi / ctaHi, radius stepping in (soft bevel)
 opts=opts or {};local m=model(parent,'SwirlTree',cf)
 part(m,'Trunk','Cyl',v(2.2,5),at(cf,0,2.5,0),'lavText','body',opts) -- TODO(atlas): B7 #2 trunk colour unstated; lavText from #1
 for i,c in {'pk','vi','ctaHi'} do
  part(m,'Swirl','TiltCyl',v(10.5-i*2.2,1.5),at(cf,0,4.4+i*1.5,0)*CFrame.Angles(0,i*1.1,math.pi/2+.18),c,'body')
 end
 return m
end
function Kit.cloudTree(parent,cf,opts) -- #3 trunk + 3 Balls go / go2 (catalog 'sapling'); canopy unions per colour
 opts=opts or {};local m=model(parent,'CloudTree',cf)
 part(m,'Trunk','Cyl',v(2.2,4),at(cf,0,2,0),'lavText','body',opts) -- TODO(atlas): B7 #3 trunk colour unstated; lavText from #1
 local a=part(m,'Puff','Ball',v(6.9),at(cf,0,6.6,0),'go2','body')
 local b=part(m,'Puff','Ball',v(5.1),at(cf,-3,7.6,.9),'go','body')
 local c=part(m,'Puff','Ball',v(4.8),at(cf,2.8,8,-.8),'go','body')
 soften(m,'Canopy',{a,b,c})
 return m
end
function Kit.gumdrop(parent,cf,opts) -- #4 2 soft domes (skirt + sunk Ball), rcg top stops; opts.tint 1..3 rotates the order
 opts=opts or {};local m=model(parent,'Gumdrop',cf);local t=(opts.tint or 1)-1
 for i,s in {{0,0,4.6},{2.9,1.2,3.4}} do
  local a,b=dome(m,'Drop',s[3],s[3]*.22,at(cf,s[1],0,s[2]),S.gumdrop[(i+t-1)%3+1],'body',opts)
  soften(m,'Drop',{a,b})
 end
 return m
end
function Kit.puffHedge(parent,cf,opts) -- #5 lip base + 4 Balls, go2 with go tips (catalog 'hedge'); puffs union per colour
 opts=opts or {};local m=model(parent,'PuffHedge',cf);local ps={}
 part(m,'Base','Block',Vector3.new(10,1,3.4),at(cf,0,.5,0),'lip','body',opts)
 for i,x in {-3.6,-1.2,1.2,3.6} do
  table.insert(ps,part(m,'Puff','Ball',v(3.8),at(cf,x,2.4+(i%2)*.35,0),i%2==0 and 'go' or 'go2','body',opts))
 end
 soften(m,'Puffs',ps)
 return m
end
function Kit.boulder(parent,cf,opts) -- #6 lavText soft dome + sunk pinkText Ball (catalog 'boulder'); dome unions
 opts=opts or {};local m=model(parent,'CandyBoulder',cf)
 local a,b=dome(m,'Stone',6.4,1.2,cf,'lavText','body',opts)
 part(m,'Stone','Ball',v(3.8),at(cf,3.1,.7,1.2),'pinkText','body',opts)
 soften(m,'Stone',{a,b})
 return m
end
function Kit.bloomBed(parent,cf,opts) -- #7 lip bed + 2 go2 stem mounds + 5 flower Balls pk / gold / flare (catalog 'bed')
 opts=opts or {};local m=model(parent,'BloomBed',cf)
 part(m,'Bed','Block',Vector3.new(8.4,1.1,4.2),at(cf,0,.55,0),'lip','body',opts)
 for _,x in {-2,2} do part(m,'Stems','Ball',v(3.6),at(cf,x,1.3,0),'go2','body') end -- stems as mounds: 8-part cap
 local f={{-3.2,'pk'},{-1.6,'gold'},{0,'flare'},{1.6,'pk'},{3.2,'gold'}}
 for i,e in f do part(m,'Bloom','Ball',v(1.7),at(cf,e[1],2.9+(i%2)*.4,(i%2-.5)*.9),e[2],'body') end
 return m
end
function Kit.mushroom(parent,cf,opts) -- #8 text stem + pinkText cap (skirt Cylinder + Ball dome), top ~3.4 (waist)
 opts=opts or {};local m=model(parent,'MushroomPuff',cf)
 part(m,'Stem','Cyl',v(1.8,2),at(cf,0,1,0),'text','body',opts)
 dome(m,'Cap',3.8,.6,at(cf,0,1.8,0),'pinkText','body')
 return m
end
function Kit.gemCluster(parent,cf,opts) -- #9 3 Neon tilted cylinders flare / pk / go, tallest ~3.2
 opts=opts or {};local m=model(parent,'GemCluster',cf)
 local g={{0,0,0,'flare',4},{1.2,.5,.5,'pk',3},{-1.1,-.7,-.4,'go',2.5}}
 for _,e in g do part(m,'Gem','TiltCyl',v(1.7,e[5]),at(cf,e[1],e[5]*.4,e[2])*CFrame.Angles(e[3],0,math.pi/2+e[3]),e[4],'trim') end
 return m
end
function Kit.daisy(parent,cf,opts) -- #10 3 text discs on stems, gold centres on the 2 tallest (8 = B7 cap)
 opts=opts or {};local m=model(parent,'DaisyPatch',cf)
 for i,e in {{0,0,2.6},{1.6,.9,2.1},{-1.4,1,1.6}} do
  part(m,'Stem','Cyl',v(.5,e[3]),at(cf,e[1],e[3]/2,e[2]),'go2','body') -- TODO(atlas): B7 #10 stem colour unstated; go2 from #7
  part(m,'Petals','Cyl',v(2.2,.4),at(cf,e[1],e[3]+.2,e[2]),'text','body')
  if i<3 then part(m,'Centre','Ball',v(.9),at(cf,e[1],e[3]+.4,e[2]),'gold','body') end -- B7 #10 gold centre
 end
 -- TODO(atlas): a 3rd centre would be part 9 > the B7 <= 8 rule; the smallest daisy has none.
 return m
end
Kit.globe=Kit.globeLamp -- #11 = B3 (catalog 'lantern')
function Kit.gemBasin(parent,cf,opts) -- #12 lip basin + lip pedestal + Glass flare water + Neon flare gem (catalog 'basin')
 opts=opts or {};local m=model(parent,'GemBasin',cf)
 part(m,'Basin','Cyl',v(6.6,1.6),at(cf,0,.8,0),'lip','body',opts)
 part(m,'Water','Cyl',v(5.6,.2),at(cf,0,1.65,0),'water','accent').CanQuery=false
 part(m,'Pedestal','Cyl',v(1.8,1.4),at(cf,0,2.4,0),'lip','body')
 part(m,'Gem','Ball',v(2),at(cf,0,3.8,0),'flare','trim') -- static: C has no basin token
 return m
end
-- Item list for QA (kit_sheet.luau): builder key = S.caps.kit key.
Kit.items={'globeLamp','pillSign','plaque','fence','coinMarker','lollipopTree','swirlTree','cloudTree','gumdrop','puffHedge',
 'boulder','bloomBed','mushroom','gemCluster','daisy','gemBasin'}
return Kit
