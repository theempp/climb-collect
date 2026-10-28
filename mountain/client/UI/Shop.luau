-- Glassbloom Shop (P5 task D). Values: climb&collect/design/hud-glassbloom-intel.md §1 tokens, §2 hero / buy() / ladder / ticket /
-- cpk() / pass() / bst() / egg() / skin() / note / wallet / shop panel (board L207-310, L631-640). Owner: plan §11 D6-D8, §14 G15, §17.
-- Section-jump hub: Screens owns the panel, tabs, scroll and jumps; this module fills them. No tweens: animated parts carry Motion=<§6>.
-- Every Robux button is W.buy(...,'robux',{productId=0}) = the disabled "Coming soon" ghost; only Meadow Egg and Candy Swirl (coins) buy.
local HttpService=game:GetService('HttpService')
local RunService=game:GetService('RunService')
local TextService=game:GetService('TextService')
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local EggOdds=require(game.ReplicatedStorage.MountainShared.EggOdds)
local ShopRules=require(game.ReplicatedStorage.MountainShared.ShopRules)
local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local Motion=require(script.Parent.Motion)
local Shop={}
local center,left=Enum.TextXAlignment.Center,Enum.TextXAlignment.Left
local function asset(id) return 'rbxassetid://'..id end
local function comma(n) local s=tostring(math.floor(n));local k;repeat s,k=s:gsub('^(%d+)(%d%d%d)','%1,%2') until k==0;return s end
local function textW(s,font,n) return math.ceil(TextService:GetTextSize(s,T.size(n),font,Vector2.new(1e4,1e4)).X)+1 end
local function lineH(font,n) return math.ceil(TextService:GetTextSize('Ag',T.size(n),font,Vector2.new(1e4,1e4)).Y) end
local function paraH(s,n,w) return math.ceil(TextService:GetTextSize(s,T.size(n),T.fontBody,Vector2.new(w,1e4)).Y)+1 end
-- Button width = label + 2 padX + 2 strokes (CSS border-box), capped to the room it has.
local function btnW(s,n,padX,st,cap) return math.min(textW(s,T.fontDisplay,n)+2*padX+2*st,cap or math.huge) end
local function decor(o) o:SetAttribute('Decor',true);return o end
local function corner(o,r) W.new('UICorner',o,{CornerRadius=if type(r)=='number' then UDim.new(0,math.max(0,r)) else r});return o end
local function frame(parent,name,props)
 props=props or {};props.Name=name;props.BorderSizePixel=0;if props.BackgroundTransparency==nil then props.BackgroundTransparency=1 end
 return W.new('Frame',parent,props)
end
-- UIStroke like the kit's (Border mode, BaseThickness/BaseTransparency for Controller.applyPreferences).
local function stroke(o,color,th,t)
 local s=W.new('UIStroke',o,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=color,Thickness=if T.prefs.highContrast then math.max(2,th) else th,Transparency=t or 0,LineJoinMode=Enum.LineJoinMode.Round})
 s:SetAttribute('BaseThickness',th);s:SetAttribute('BaseTransparency',t or 0);return s
end
-- One-line text that shrinks to its box (kit W.fit); `fixed` = the box was measured for this text, so no TextScaled / size constraint.
-- Body text gets the kit's 1 px ink outline when `ink` (W.text recipe, L48).
local function txt(parent,name,s,font,n,color,size,pos,align,ink,fixed)
 local l=W.new('TextLabel',parent,{Name=name,Size=size,Position=pos or UDim2.new(),BackgroundTransparency=1,Text=s,TextColor3=color or T.text,Font=font,TextSize=T.size(n),TextXAlignment=align or center})
 l:SetAttribute('BaseTextSize',n);if not fixed then l.TextScaled=true;W.new('UITextSizeConstraint',l,{MaxTextSize=T.size(n),MinTextSize=8}) end
 if ink then W.textStroke(l) end
 return l
end
-- LuckiestGuy + drop label dy px below (display text gets a drop, never an outline: W.text recipe, P§2).
local function display(parent,name,s,n,size,pos,drop,dy,dropT,color,align)
 local d=txt(parent,name..'Drop',s,T.fontDisplay,n,drop,size,(pos or UDim2.new())+UDim2.fromOffset(0,dy),align);d.ZIndex=1;d.TextTransparency=dropT or 0;decor(d)
 local l=txt(parent,name,s,T.fontDisplay,n,color,size,pos,align);l.ZIndex=2;return l
end
-- Wrapped FO block, height from TextService; returns label, height.
local function para(parent,name,s,n,w,pos,dimT,align)
 local h=paraH(s,n,w)
 local l=W.new('TextLabel',parent,{Name=name,Size=UDim2.fromOffset(w,h),Position=pos,BackgroundTransparency=1,Text=s,TextColor3=T.text,Font=T.fontBody,TextSize=T.size(n),TextWrapped=true,TextXAlignment=align or center,TextYAlignment=Enum.TextYAlignment.Top,TextTransparency=dimT or 0})
 l:SetAttribute('BaseTextSize',n);W.textStroke(l);return l,h
end
-- Kit layering (Widgets header): transparent border-box root (grid cell), Body inset by its stroke (CSS borders sit inside the box).
local function card(parent,name,r,s)
 local o=frame(parent,name);o:SetAttribute('CornerRadius',UDim.new(0,r))
 local b=corner(frame(o,'Body',{Size=UDim2.new(1,-2*s,1,-2*s),Position=UDim2.fromOffset(s,s),BackgroundTransparency=0,BackgroundColor3=T.text}),r-s)
 return o,b
end
-- U11 radial inside a rect-clipped frame (Conversions): centre (x,y) of a w×h box, transparent at `fade` × the farthest-corner distance.
local function radial(parent,rd,w,h)
 local d=math.sqrt((math.max(rd.x,1-rd.x)*w)^2+(math.max(rd.y,1-rd.y)*h)^2)*rd.fade*2
 return decor(W.new('ImageLabel',parent,{Name='Radial',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(rd.x,rd.y),Size=UDim2.fromOffset(d,d),BackgroundTransparency=1,Image=asset(T.images.radial),ImageColor3=rd.color,ImageTransparency=rd.t}))
end
-- W.ring(d,t,fill,trackT,inner) at p = 1, drawn statically: inner disc + the full fill stroke (the white track sits exactly under the
-- opaque full stroke, and the hidden half-arcs never show), 6 instances instead of 19. Same names as W.ring.
local function fullRing(parent,d,t,fill,inner)
 local f=frame(parent,'Ring',{Size=UDim2.fromOffset(d,d)})
 corner(frame(f,'Inner',{Size=UDim2.fromOffset(d-2*t,d-2*t),Position=UDim2.fromOffset(t,t),BackgroundTransparency=0,BackgroundColor3=inner}),T.r.circle)
 stroke(corner(frame(f,'Full',{Size=UDim2.fromOffset(d-2*t,d-2*t),Position=UDim2.fromOffset(t,t),ZIndex=2}),T.r.circle),fill,t,0)
 return f
end
local function robux(parent,w,pos,h,n,padX) return W.buy(parent,'Buy','R$','robux',UDim2.fromOffset(w,h or 32),pos,nil,{productId=0,n=n or T.t.buy,padX=padX or 12}) end
local soon=function(n,padX,cap) return btnW('Coming soon',n or T.t.buy,padX or 12,T.s.glass,cap) end
-- Real coin buy (D7, G15): two taps (CONFIRM 3 s, kit) -> Buy{item, receipt}; short -> "Need <shortfall>" and a tap jumps to Coins.
local function coinBuy(screen,parent,data,id,price,cap,pos)
 local coins=data.coins or 0;local label=comma(price)..' coins';local need='Need '..comma(math.max(0,price-coins))
 local w=btnW(label,T.t.buy,12,T.s.glass,cap);w=math.min(math.max(w,btnW('CONFIRM',T.t.buy,12,T.s.glass),btnW(need,T.t.buy,12,T.s.glass)),cap)
 return W.buy(parent,'Buy',label,'coin',UDim2.fromOffset(w,32),pos,function() screen:send('Buy',{item=id,receipt=HttpService:GenerateGUID(false)}) end,
  {short=coins<price,shortLabel=need,onShort=function() screen:jumpToSection('Coins') end}),w
end
-- Auto-fill grid (CSS repeat(auto-fill,minmax(min,1fr))): n = ⌊(W+gap)/(min+gap)⌋ equal columns; empty tracks stay empty.
local function columns(cw,minW,gap) local n=math.max(1,math.floor((cw+gap)/(minW+gap)));return n,math.floor((cw-gap*(n-1))/n) end
local function gridH(count,n,gap,cellH) return math.ceil(count/n)*(cellH+gap)-gap end
local function grid(parent,name,count,n,cell,gap,cellH)
 local g=frame(parent,name,{Size=UDim2.new(1,0,0,gridH(count,n,gap,cellH))})
 W.new('UIGridLayout',g,{CellSize=UDim2.fromOffset(cell,cellH),CellPadding=UDim2.fromOffset(gap,gap),SortOrder=Enum.SortOrder.LayoutOrder})
 return g
end
-- Trail preview (skin() L298-303, ticket L299): night T.35 r12, clipped; streak h10 70 % r6 gradStreak rc + glow rc 10 (Decor, Motion
-- trail.streak, static at x 0); bat icon centred (Motion trail.swing).
local function trail(parent,key,size,pos,icon)
 local rc=T.rarityColor[key].rc
 local t=corner(frame(parent,'Trail',{Size=size,Position=pos,BackgroundTransparency=T.wellT.trail,BackgroundColor3=T.night,ClipsDescendants=true}),T.r[12])
 local s=decor(frame(t,'Streak',{Size=UDim2.new(.7,0,0,10),Position=UDim2.new(0,0,.5,-5)}));s:SetAttribute('Motion','trail.streak')
 W.glow(s,s,T.glowRarity,rc,'streak')
 W.grad(corner(frame(s,'Bar',{Size=UDim2.fromScale(1,1),BackgroundTransparency=0,BackgroundColor3=T.text}),T.r[6]),T.gradStreak,rc)
 local b=W.icon(t,'Bat',UDim2.fromOffset(icon,icon),UDim2.new(.5,-icon/2,.5,-icon/2));b.ZIndex=2;b:SetAttribute('Motion','trail.swing')
 return t
end
-- Gold title (shop panel, L214-218): the panel() plate with gradGoldTitle, glowGoldTitle, lip/drop goldLip, left padding 44; chest 50 at
-- x -12 rotated -10°, its centre 58 % of its height above the plate centre (L215); U6 tails 24×30 at top 14, x -20 / right -20 (Rot 180).
function Shop.titlePlate(f,text)
 local p=W.ctaPlate(f,'TitleRibbon',text,UDim2.fromOffset(W.plateWidth(text,T.t.menuTitle,0)+44+20,42),UDim2.new(.5,0,0,-21),T.t.menuTitle,20,{grad=T.gradGoldTitle,glow=T.glowGoldTitle,lip=T.goldLip,padL=44})
 p.AnchorPoint=Vector2.new(.5,0);p.ZIndex=2;p:SetAttribute('Overhang',true)
 local ic=decor(W.icon(p,'Chest',UDim2.fromOffset(50,50),UDim2.fromOffset(-12,21-29)));ic.Rotation=-10;ic.ZIndex=3
 for i,pos in ipairs({UDim2.fromOffset(-20,14),UDim2.new(1,-4,0,14)}) do
  decor(W.new('ImageLabel',p,{Name='Tail',Size=UDim2.fromOffset(24,30),Position=pos,Rotation=if i==2 then 180 else 0,BackgroundTransparency=1,Image=asset(T.images.ribbonTail),ImageColor3=T.goldTail,ZIndex=-1}))
 end
 return p
end
-- Panel rays (L211-212): U2 rays.tint T.91, size = panel diagonal / .919, centred, rect-clipped to the panel body, behind the columns.
local function panelRays(f)
 local b=f:FindFirstChild('Body');if not b then return end
 local clip=decor(frame(b,'Rays',{Size=UDim2.fromScale(1,1),ClipsDescendants=true}))
 local d=math.sqrt(f.Size.X.Offset^2+f.Size.Y.Offset^2)/.919
 decor(W.new('ImageLabel',clip,{Name='Burst',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(d,d),BackgroundTransparency=1,Image=asset(T.images.rays),ImageColor3=T.raysTint,ImageTransparency=T.raysT.panel})):SetAttribute('Motion','rays.panel')
end
-- Wallet (Overhang, L219-221, L640): glass pill h30 r16 at top -15 / right 40; padding L30 R4, gap 6; coin 34 at x -4; FO 13 coins;
-- "+" 22 r7 gradMint, stroke 2 white, FO 15 goInk -> Coins.
local function wallet(screen,f,data)
 local s=comma(data.coins or 0);local tw=textW(s,T.fontBody,T.t.wallet);local st=T.s.glass;local h=30
 local w=st+30+tw+6+22+4+st
 local o=W.glass(f,'Wallet',UDim2.fromOffset(w,h),UDim2.new(1,-40-w,0,-15),{radius=T.r.btn,glow=T.glowGlass});o.ZIndex=3;o:SetAttribute('Overhang',true)
 local ic=decor(W.icon(o,'Coin',UDim2.fromOffset(34,34),UDim2.fromOffset(-4,(h-34)/2)));ic.ZIndex=2
 txt(o,'Value',s,T.fontBody,T.t.wallet,T.text,UDim2.fromOffset(tw,h),UDim2.fromOffset(st+30,0),left,true,true).ZIndex=2
 local p=W.new('TextButton',o,{Name='WalletPlus',Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-st-4-22,.5,-11),BackgroundTransparency=1,BorderSizePixel=0,Text='',AutoButtonColor=false,ZIndex=2})
 p:SetAttribute('QAControl',true);p:SetAttribute('Enabled',true);p:SetAttribute('CornerRadius',UDim.new(0,T.r[7]))
 local b=corner(frame(p,'Body',{Size=UDim2.new(1,-2*st,1,-2*st),Position=UDim2.fromOffset(st,st),BackgroundTransparency=0,BackgroundColor3=T.text}),T.r[7]-st)
 W.grad(b,T.gradMint);stroke(b,T.text,st,0)
 txt(p,'Label','+',T.fontBody,T.t.plus,T.goInk,UDim2.fromScale(1,1),nil,nil,nil,true).ZIndex=2
 W.bind(p,function() screen:jumpToSection('Coins',true) end);W.hit(p);W.focus(p) -- a tap glides (board goTo .plus, L663)
 return o
end
-- Sticky hero (L207, L222-241, L659): above the scroll; full / mini (CanvasPosition.Y > 8). No offer timer exists: no timer pill.
local function hero(screen,f)
 local W0=screen.scrollW-13;local top=3 -- the scroll content column (UIPadding 3/10/14/3)
 local o=frame(f,'Hero',{Position=UDim2.fromOffset(screen.scrollX+3,26+top),Size=UDim2.fromOffset(W0,84)});o:SetAttribute('CornerRadius',UDim.new(0,T.r.hero))
 W.glow(o,o,T.glowHero)
 -- Lip night T.3 5: the holo body is opaque, so a same-shape Frame +5 behind (Conversions).
 decor(corner(frame(o,'Lip',{Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(0,5),BackgroundTransparency=.3,BackgroundColor3=T.night,ZIndex=-1}),T.r.hero))
 -- Holo border (1f recipe, est.): CanvasGroup r20 holding a 4.8×-wide Frame with two colour cycles (13 keypoints at i/12), Rot 20.
 local holo=corner(W.new('CanvasGroup',o,{Name='Holo',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0}),T.r.hero)
 local cyc=decor(frame(holo,'Cycle',{Size=UDim2.fromScale(4.8,1),BackgroundTransparency=0,BackgroundColor3=T.text}));cyc:SetAttribute('Motion','holo')
 local k={};for i=0,12 do k[i+1]=ColorSequenceKeypoint.new(i/12,T.holo[i%6+1]) end
 W.new('UIGradient',cyc,{Color=ColorSequence.new(k),Rotation=T.gradHolo.rot})
 -- Inner r16, gradHero + gold radial (U11), rect clip.
 local inner=corner(frame(o,'Inner',{Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-8,1,-8),BackgroundTransparency=0,BackgroundColor3=T.text,ClipsDescendants=true,ZIndex=1}),T.r.btn)
 W.grad(inner,T.gradHero)
 local rad=radial(inner,T.gradHero.radial,0,0)
 local rays=decor(W.new('ImageLabel',inner,{Name='Rays',Size=UDim2.fromOffset(280,280),Position=UDim2.fromOffset(-70,-110),BackgroundTransparency=1,Image=asset(T.images.rays),ImageColor3=T.raysHero,ImageTransparency=T.raysT.hero}))
 rays:SetAttribute('Motion','rays.hero')
 -- Art (bottom-aligned, overlap -12): egg 56 (bob) + coin 36 (bob, delay .5) + chest 36.
 local art=frame(inner,'Art',{ZIndex=2})
 local egg=W.icon(art,'Egg',UDim2.fromOffset(56,56),UDim2.new());egg:SetAttribute('Motion','bob')
 local coin=W.icon(art,'Coin',UDim2.fromOffset(36,36),UDim2.fromOffset(44,20));coin:SetAttribute('Motion','bob');coin:SetAttribute('MotionDelay',.5)
 local chest=W.icon(art,'Chest',UDim2.fromOffset(36,36),UDim2.fromOffset(68,20))
 -- Middle: title LG 24 + drop 3 lip; tag "ONE TIME" h18 padX 8 r9 gold / goldInk FO 10; list pills h22 padX 8 r10 FO 11 night T.45,
 -- stroke 1 white T.75, gap 4/6, wrapping.
 local mid=frame(inner,'Info',{ZIndex=2})
 local title=display(mid,'Title','Starter Pack',T.t.heroTitle,UDim2.new(),nil,T.lip,3,0,T.text,left)
 local drop=mid:FindFirstChild('TitleDrop')
 local tagW=textW('ONE TIME',T.fontBody,T.t.tag)+16
 local tag=corner(frame(mid,'Tag',{Size=UDim2.fromOffset(tagW,18),BackgroundTransparency=0,BackgroundColor3=T.gold}),T.r[9])
 txt(tag,'Label','ONE TIME',T.fontBody,T.t.tag,T.goldInk,UDim2.fromScale(1,1),nil,nil,nil,true)
 local pills={}
 for i,s in ipairs({'Golden egg','5,000 coins','Auto-Bank 1 day'}) do
  local w=textW(s,T.fontBody,T.t.small)+16+2
  -- Border-box h22 (CSS border inside): the frame is inset 1 and its 1 px stroke draws outside it.
  local p=corner(frame(mid,'Item'..i,{Size=UDim2.fromOffset(w-2,20),BackgroundTransparency=T.wellT.hlist,BackgroundColor3=T.night}),T.r[10]-1)
  stroke(p,T.text,T.s.hair,.75);txt(p,'Label',s,T.fontBody,T.t.small,T.text,UDim2.new(1,-14,1,0),UDim2.fromOffset(7,0),center,true)
  pills[i]={frame=p,w=w}
 end
 local buy=robux(inner,soon(T.t.heroBuy,16),nil,40,T.t.heroBuy,16)
 buy.ZIndex=2
 local function textSize(l,n) l.TextSize=T.size(n);l:SetAttribute('BaseTextSize',n);local c=l:FindFirstChildOfClass('UITextSizeConstraint');if c then c.MaxTextSize=T.size(n) end end
 local function layout(mini)
  local py,px=if mini then 5 else 10,if mini then 10 else 12
  local a=if mini then 30 else 56;local artW=if mini then 30 else 104
  local n=if mini then T.t.heroTitleMini else T.t.heroTitle
  local bh,bn=if mini then 32 else 40,if mini then 16 else T.t.heroBuy
  local iw=W0-8;local bw=soon(bn,16,math.max(60,math.floor((iw-2*px)*.4)))
  local midW=math.max(40,iw-2*px-artW-bw-24)
  -- Title row: title (shrinks first) + gap 8 + tag.
  local th=lineH(T.fontDisplay,n);local tw=math.max(20,math.min(textW('Starter Pack',T.fontDisplay,n),midW-tagW-8))
  local rowH=math.max(th,18)
  title.Size=UDim2.fromOffset(tw,th);title.Position=UDim2.fromOffset(0,(rowH-th)/2);textSize(title,n)
  drop.Size=title.Size;drop.Position=title.Position+UDim2.fromOffset(0,3);textSize(drop,n)
  tag.Position=UDim2.fromOffset(tw+8,(rowH-18)/2)
  local x,y=0,rowH+6
  for _,p in ipairs(pills) do
   local w=math.min(p.w,midW);if x>0 and x+w>midW then x=0;y+=22+4 end
   p.frame.Size=UDim2.fromOffset(w-2,20);p.frame.Position=UDim2.fromOffset(x+1,y+1);p.frame.Visible=not mini;x+=w+6
  end
  local midH=if mini then rowH else y+22
  local ch=math.max(a,midH,bh);local ih=ch+2*py;local H=ih+8
  art.Size=UDim2.fromOffset(artW,a);art.Position=UDim2.fromOffset(px,py+(ch-a)/2)
  egg.Size=UDim2.fromOffset(a,a);coin.Visible=not mini;chest.Visible=not mini;Motion.visible(rays,not mini) -- LOW-mode rays (Motion) keep this wish
  mid.Size=UDim2.fromOffset(midW,midH);mid.Position=UDim2.fromOffset(px+artW+12,py+(ch-midH)/2)
  buy.Size=UDim2.fromOffset(bw,bh);buy.Position=UDim2.fromOffset(iw-px-bw,py+(ch-bh)/2)
  for _,c in ipairs(buy:GetChildren()) do if c:IsA('TextLabel') then textSize(c,bn) end end
  o.Size=UDim2.fromOffset(W0,H)
  local rd=T.gradHero.radial;local d=math.sqrt((math.max(rd.x,1-rd.x)*iw)^2+(math.max(rd.y,1-rd.y)*ih)^2)*rd.fade*2;rad.Size=UDim2.fromOffset(d,d)
  -- The scroll holder starts 4 px below the hero (board margin-bottom 4).
  screen:setScrollTop(top+H+4)
 end
 -- Full ↔ mini (§19, hero.mini): the layout switches at once, then the hero height glides old → new over .2 s ease-out with the
 -- scroll top following, and Inner's contents (all but its Radial background) fade in (hero.fade). Not on the first layout, and
 -- no fade while the panel itself is still fading in.
 local body=screen.body;local cur=nil
 local function glide(h) o.Size=UDim2.fromOffset(W0,h);screen:setScrollTop(top+h+4) end
 local function sync()
  local m=body.CanvasPosition.Y>8;if m==cur then return end
  local first=cur==nil;local oldH=o.Size.Y.Offset;cur=m;layout(m)
  if first then Motion.value(o,o.Size.Y.Offset,'hero.mini',glide,{instant=true});return end
  Motion.value(o,o.Size.Y.Offset,'hero.mini',glide,{from=oldH})
  if not Motion.playing(screen.shade) then for _,c in ipairs(inner:GetChildren()) do if c:IsA('GuiObject') and c~=rad then Motion.play(c,'hero.fade') end end end
 end
 sync();body:GetPropertyChangedSignal('CanvasPosition'):Connect(sync)
 return o
end
-- Sections are measured first (TextService only) and built later: each builder returns height, build(parent) -> frame. Shop.render
-- uses the heights to build the first view synchronously and the rest one section per frame (plan §6: no frame > 33 ms on open).
-- Free gifts ladder (L247-255, D6 inert): 4 columns gap 8, track 4 r2 at y 32 (x 10-90 %, go -> white T.8 at 50 %). Rung r16, padding
-- 6/4/8, gap 4, night T.4, stroke 1.5 white T.8; well 48 white T.9, icon 34. Done = group T.35 (per child), well goGlow. Ready = gold
-- stroke, glowReady, U11 gold T.35 well (pulse), icon 38, disabled Claim (ghost h22 padX 10 LG 13). Locked = timer label.
local function ladder(cx)
 local cw=cx.cw;local s=T.s.thin;local colW=(cw-24)/4
 local claimW=btnW('Claim',T.t.claim,10,T.s.glass,colW-2*s-8)
 local h=math.ceil(2*s+6+48+4+22+8)
 return h,function(parent)
  local o=frame(parent,'Ladder',{Size=UDim2.new(1,0,0,h)})
  local tr=corner(frame(o,'Track',{Size=UDim2.new(.8,0,0,4),Position=UDim2.new(.1,0,0,32),BackgroundTransparency=0,BackgroundColor3=T.text}),T.r[2])
  W.new('UIGradient',tr,{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.go),ColorSequenceKeypoint.new(.5,T.go),ColorSequenceKeypoint.new(.501,T.text),ColorSequenceKeypoint.new(1,T.text)}),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.501,.8),NumberSequenceKeypoint.new(1,.8)})})
  local function fade(t,g) return 1-(1-t)*(1-g) end -- CSS opacity on a group = per-child transparency (Conversions)
  for i,v in ipairs({{'done','Gift','Claimed'},{'done','Coin','Claimed'},{'ready','Gift'},{'locked','Chest','15 min'}}) do
   local state=v[1];local g=if state=='done' then .35 else 0
   local r=corner(frame(o,'Rung'..i,{Position=UDim2.fromOffset((i-1)*(colW+8)+s,s),Size=UDim2.fromOffset(colW-2*s,h-2*s),BackgroundTransparency=fade(T.wellT.rung,g),BackgroundColor3=T.night,ZIndex=2}),T.r.btn-s)
   if state=='ready' then stroke(r,T.gold,s,0);W.glow(o,r,T.glowReady) else stroke(r,T.text,s,fade(.8,g)) end
   local iw=colW-2*s;local well
   if state=='ready' then
    well=W.new('ImageLabel',r,{Name='Well',Size=UDim2.fromOffset(48,48),Position=UDim2.fromOffset((iw-48)/2,6),BackgroundTransparency=1,Image=asset(T.images.radial),ImageColor3=T.gold,ImageTransparency=.35})
    well:SetAttribute('Motion','pulse')
   else
    well=corner(frame(r,'Well',{Size=UDim2.fromOffset(48,48),Position=UDim2.fromOffset((iw-48)/2,6),BackgroundTransparency=if state=='done' then fade(.75,g) else .9,BackgroundColor3=if state=='done' then T.goGlow else T.text}),T.r.circle)
   end
   local a=if state=='ready' then 38 else 34
   local ic=W.icon(well,v[2],UDim2.fromOffset(a,a),UDim2.fromOffset((48-a)/2,(48-a)/2))
   local img=ic:FindFirstChild('Image');if img and g>0 then img.ImageTransparency=g end
   if state=='ready' then W.ghostOff(r,'Claim','Claim',UDim2.fromOffset(claimW,22),UDim2.fromOffset((iw-claimW)/2,58),T.t.claim,10)
   else
    local l=txt(r,'Label',v[3],T.fontBody,T.t.small,T.text,UDim2.new(1,-8,0,18),UDim2.fromOffset(4,58),center,true,true)
    if g>0 then l.TextTransparency=g;local st=l:FindFirstChildOfClass('UIStroke');st.Transparency=fade(.2,g);st:SetAttribute('BaseTransparency',st.Transparency) end
   end
  end
  return o
 end
end
-- Daily deal ticket (L256-260, L299, D6 inert): U5 fill + gradTicket, U10 ring gold T.25; 3 columns gap 12, padding 10/20; trail 76×54
-- (gold, bat 34 per L634); "Ember trail" LG 18 + drop 2 lip; desc FO 11 T.1; price = disabled buy. No struck was-price (no Robux prices).
local function ticket(cx)
 local cw=cx.cw;local bw=soon(nil,nil,math.floor(cw*.35));local midW=math.max(40,cw-40-76-24-bw)
 local desc='Gold sparks on every swing. Looks only.'
 local th=lineH(T.fontDisplay,T.t.ticketTitle);local dh=paraH(desc,T.t.small,midW)
 local h=math.max(54,th+dh,32)+20
 return h,function(parent)
  local o=frame(parent,'Ticket',{Size=UDim2.new(1,0,0,h)})
  local fill=W.new('ImageLabel',o,{Name='Fill',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.ticketFill),ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.ticketFill,SliceScale=.5})
  W.grad(fill,T.gradTicket)
  W.new('ImageLabel',o,{Name='Line',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.ticketLine),ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.ticketLine,SliceScale=.5,ImageColor3=T.gold,ImageTransparency=.25})
  trail(o,'gold',UDim2.fromOffset(76,54),UDim2.fromOffset(20,(h-54)/2),34).ZIndex=2
  local mid=frame(o,'Info',{Size=UDim2.fromOffset(midW,th+dh),Position=UDim2.fromOffset(20+76+12,(h-th-dh)/2),ZIndex=2})
  display(mid,'Title','Ember trail',T.t.ticketTitle,UDim2.new(1,0,0,th),nil,T.lip,2,0,T.text,left)
  para(mid,'Desc',desc,T.t.small,midW,UDim2.fromOffset(0,th),T.textDimT[2],left)
  robux(o,bw,UDim2.fromOffset(cw-20-bw,(h-32)/2)).ZIndex=2
  return o
 end
end
-- Coin packs (cpk(), L261-271): one row, bottom-aligned, gap 8, columns from min 104. Card r16, padding 8/6/10, gap 3, stroke 2 gold
-- T.45, gradCpk + gold radial; best = stroke white, glowBest, ribbon h18. Pile h46 (coin 34, overlap -17), amount LG 19 goldText + drop
-- 2 lip, "coins" FO 10.5 T.15, Robux buy (disabled). Heights are CSS min-heights (112/122/132/150): content taller than that wins.
local function coinPacks(cx)
 local cw=cx.cw;local n,w=columns(cw,104,8);n=math.max(n,4);w=math.floor((cw-8*(n-1))/n)
 local st=T.s.glass;local ah=lineH(T.fontDisplay,T.t.coinPack);local mh=lineH(T.fontBody,T.t.micro)
 local content=46+3+ah+3+mh+3+32
 local packs={{'1,000',1,nil,112},{'4,400',2,'+10%',122},{'9,600',3,'+20%',132},{'27,000',4,'+50%',150,true}}
 local hs,top={},0
 for i,p in ipairs(packs) do hs[i]=math.max(p[4],math.ceil(content+8+10+2*st+(if p[5] then 18-8+3 else 0)));top=math.max(top,hs[i]) end
 -- GAP: "Coming soon" (LG 16) is wider than a 104-125 px pack; the board has no rule (CSS would clip it), so the button is capped to the
 -- pack's content width and its label shrinks (kit W.fit).
 local bw=soon(nil,nil,w-2*st-12)
 return top,function(parent)
  local row=frame(parent,'CoinPacks',{Size=UDim2.new(1,0,0,top)})
  W.new('UIListLayout',row,{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
  for i,p in ipairs(packs) do
   local best=p[5]==true
   local o,b=card(row,'Pack'..i,T.r.btn,st);o.Size=UDim2.fromOffset(w,hs[i]);o.LayoutOrder=i
   if best then W.glow(o,o,T.glowBest) end
   stroke(b,if best then T.text else T.gold,st,if best then 0 else .45);W.grad(b,T.gradCpk);b.ClipsDescendants=true
   local bwid,bh=w-2*st,hs[i]-2*st
   radial(b,T.gradCpk.radial,bwid,bh)
   -- Bottom-up (justify flex-end): buy, "coins", amount, pile.
   local y=bh-10-32
   robux(b,bw,UDim2.fromOffset((bwid-bw)/2,y)).ZIndex=2
   y-=3+mh;txt(b,'Coins','coins',T.fontBody,T.t.micro,T.text,UDim2.new(1,-12,0,mh),UDim2.fromOffset(6,y),center,true,true).TextTransparency=T.textDimT[3]
   y-=3+ah;display(b,'Amount',p[1],T.t.coinPack,UDim2.new(1,-12,0,ah),UDim2.fromOffset(6,y),T.lip,2,0,T.goldText)
   y-=3+46
   local pw=34+17*(p[2]-1);local pile=frame(b,'Pile',{Size=UDim2.fromOffset(pw,46),Position=UDim2.fromOffset((bwid-pw)/2,y),ZIndex=2})
   for c=1,p[2] do W.icon(pile,'Coin',UDim2.fromOffset(34,34),UDim2.fromOffset((c-1)*17,12)).ZIndex=c end
   if best then
    -- Full-bleed ribbon (padding box top): the fill is rounded r14 on top only (taller rounded Frame cut by a rect clip).
    local rib=frame(b,'Ribbon',{Size=UDim2.new(1,0,0,18),ClipsDescendants=true,ZIndex=3})
    W.grad(decor(corner(frame(rib,'Fill',{Size=UDim2.new(1,0,0,18+T.r.btn),BackgroundTransparency=0,BackgroundColor3=T.text}),T.r.btn-st)),T.gradRibbon)
    txt(rib,'Label','BEST VALUE',T.fontBody,T.t.ribbon,T.ribbonInk,UDim2.fromScale(1,1),nil,nil,nil,true).ZIndex=2
   end
   if p[3] then local bu=W.burst(b,40,p[3]);bu.ZIndex=4;if best then bu.Position=UDim2.new(1,-4,0,24) end end
  end
  return row
 end
end
-- Passes (pass(), L272-279): grid min 122 gap 10. U3 fill + gradPass, U9 rim rc, hollow glowRarity 'pass' rc. Padding 12/8/18 (+3 rim),
-- gap 4. Orb 58 rcg + U8 gloss T.25 + stroke 3 white + glow 16, icon 36 (bob.pass). FOREVER h16 padX 7 r8 night T.25 FO 9.5 gold. Name
-- LG 15 + drop 2 lip, desc FO 11 T.1, Robux buy (disabled).
local function passes(cx)
 local items={{'gold','Coin','2× Coins','Tycoon income'},{'blue','Chest','Auto-Bank','Tycoon banks while you climb'},{'violet','EggCracked','Incubator +1','Hatch two eggs at once'},{'prism','Heart','VIP Lounge','Sanctuary rooftop. Cosmetic.'}}
 -- GAP: no before/after row: Tycoon gives eggs/h per habitat (snapshot.rate), not a coin income, and no 2× Coins rule exists.
 local n,cell=columns(cx.cw,122,10);local iw=cell-22;local nh=lineH(T.fontDisplay,T.t.passName);local bw=soon(nil,nil,iw)
 local cellH=0;for _,v in ipairs(items) do cellH=math.max(cellH,15+58+4+16+4+nh+4+paraH(v[4],T.t.small,iw)+4+32+21) end
 local fw=textW('FOREVER',T.fontBody,T.t.forever)+14
 return gridH(#items,n,10,cellH),function(parent)
  local g=grid(parent,'Passes',#items,n,cell,10,cellH)
  for i,v in ipairs(items) do
   local key,rc=v[1],T.rarityColor[v[1]].rc
   local o=frame(g,'Pass_'..v[3]:gsub('[^%w]',''),{LayoutOrder=i})
   W.glow(o,o,T.glowRarity,rc,'pass')
   W.grad(W.new('ImageLabel',o,{Name='Fill',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.shieldFill),ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.shieldFill,SliceScale=.5}),T.gradPass)
   W.new('ImageLabel',o,{Name='Rim',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.shieldLine),ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.shieldLine,SliceScale=.5,ImageColor3=rc})
   local orb=frame(o,'Orb',{Size=UDim2.fromOffset(58,58),Position=UDim2.new(.5,-29,0,15),ZIndex=2});orb:SetAttribute('Motion','bob.pass');orb:SetAttribute('CornerRadius',T.r.circle)
   W.glow(orb,orb,T.glowRarity,rc,'porb')
   local ob=corner(frame(orb,'Body',{Size=UDim2.new(1,-6,1,-6),Position=UDim2.fromOffset(3,3),BackgroundTransparency=0,BackgroundColor3=T.text}),T.r.circle)
   W.grad(ob,W.rarityGrad(key));stroke(ob,T.text,T.s.bold,0)
   W.new('ImageLabel',ob,{Name='Gloss',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.glossOrb),ImageTransparency=.25})
   W.icon(orb,v[2],UDim2.fromOffset(36,36),UDim2.fromOffset(11,11)).ZIndex=2
   local y=15+58+4
   local fv=corner(frame(o,'Forever',{Size=UDim2.fromOffset(fw,16),Position=UDim2.new(.5,-fw/2,0,y),BackgroundTransparency=T.wellT.forever,BackgroundColor3=T.night,ZIndex=2}),T.r[8])
   txt(fv,'Label','FOREVER',T.fontBody,T.t.forever,T.gold,UDim2.fromScale(1,1),nil,nil,nil,true)
   y+=16+4;display(o,'Name',v[3],T.t.passName,UDim2.fromOffset(iw,nh),UDim2.fromOffset(11,y),T.lip,2).ZIndex=3
   o:FindFirstChild('NameDrop').ZIndex=2
   y+=nh+4;local d,dh=para(o,'Desc',v[4],T.t.small,iw,UDim2.fromOffset(11,y),T.textDimT[2]);d.ZIndex=2
   y+=dh+4;robux(o,bw,UDim2.new(.5,-bw/2,0,y)).ZIndex=2
  end
  return g
 end
end
-- Boosts (bst(), L280-286): grid min 112 gap 10. U4 fill night T.45 + U9b rim white T.8 (SliceScale W/240 under 120 px). Padding
-- 10/6/12 (+1.5 rim), gap 4. Timer ring(62,4,go,.82,deep) full (no boost system: none active), icon 32. Name FO 13, desc FO 10.5 T.15.
local function boosts(cx)
 local items={{'Sprint','Coin Rush','15 min · tycoon ×1.5'},{'Egg','Hatch Speed','30 min · tycoon hatching'},{'Scroll','Egg Luck','30 min · tycoon rolls, odds shown first'}}
 local n,cell=columns(cx.cw,112,10);local s=T.s.thin;local iw=cell-12-2*s;local nh=lineH(T.fontBody,T.t.bstName);local bw=soon(nil,nil,iw)
 local cellH=0;for _,v in ipairs(items) do cellH=math.max(cellH,math.ceil(s+10+62+4+nh+4+paraH(v[3],T.t.micro,iw)+4+32+12+s)) end
 local scale=if cell<120 then cell/240 else .5
 return gridH(#items,n,10,cellH),function(parent)
  local g=grid(parent,'Boosts',#items,n,cell,10,cellH)
  for i,v in ipairs(items) do
   local o=frame(g,'Boost_'..v[2]:gsub('[^%w]',''),{LayoutOrder=i})
   W.new('ImageLabel',o,{Name='Fill',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.roundtopFill),ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.roundtopFill,SliceScale=scale,ImageColor3=T.night,ImageTransparency=T.wellT.bst})
   W.new('ImageLabel',o,{Name='Rim',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.roundtopLine),ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.roundtopLine,SliceScale=scale,ImageTransparency=.8})
   local ring=fullRing(o,62,4,T.go,T.deep);ring.Position=UDim2.new(.5,-31,0,s+10);ring.ZIndex=2
   W.icon(ring,v[1],UDim2.fromOffset(32,32),UDim2.fromOffset(15,15)).ZIndex=3
   local y=s+10+62+4
   txt(o,'Name',v[2],T.fontBody,T.t.bstName,T.text,UDim2.fromOffset(iw,nh),UDim2.fromOffset(6+s,y),center,true).ZIndex=2
   y+=nh+4;local d,dh=para(o,'Desc',v[3],T.t.micro,iw,UDim2.fromOffset(6+s,y),T.textDimT[3]);d.ZIndex=2
   y+=dh+4;robux(o,bw,UDim2.new(.5,-bw/2,0,y)).ZIndex=2
  end
  return g
 end
end
-- Eggs (egg(), L287-295, L308-310, D8): grid min 150 gap 10. Card r18, padding 8/8/12, gap 5, gradEggCard, stroke 1.5 white T.8.
-- Pedestal 96×92: plinth 88×20 (U11 heroFrom T.4 under U11 gold T.3 at 60 %), egg 62×78 with hollow glowRarity 'egg' rc (rarity by glow
-- only, G12) + "?" LG 30 + drop 2 outline T.3 (egg.wobble). Name LG 16 + drop 2 lip. Odds bar h8 r4 stroke 1 white T.6 from the real roll
-- table (EggOdds.display); legend FO 11 swatch 8 r2. Buy + ×3 (inert: ShopRules sells one at a time), gap 6, wrapping.
local oddsKey={Blue='blue',Gold='gold',Violet='violet',Prismatic='prism'}
local function eggs(cx)
 local screen,data=cx.screen,cx.data
 local items={{'blue','Meadow Egg','meadow_egg',2500},{'violet','Mystery Egg','mystery_egg'},{'gold','Golden Egg','golden_egg'}}
 local n,cell=columns(cx.cw,150,10);local s=T.s.thin;local iw=cell-16-2*s
 local nh=lineH(T.fontDisplay,T.t.eggName);local lh=lineH(T.fontBody,T.t.small)
 local x3=btnW('×3',T.t.buy3,9,T.s.glass)
 -- Per egg: legend entries and row breaks (flex-wrap, gap 2/10; one row is centred, wrapped rows start left).
 local plan,cellH={},0
 for i,v in ipairs(items) do
  local d=EggOdds.display(v[3]);local entries={}
  if d then for _,c in ipairs(d.colours) do if c.percent>0 then local s2=c.colour..' '..(if c.percent%1==0 then tostring(c.percent) else string.format('%.1f',c.percent))..'%';table.insert(entries,{key=oddsKey[c.colour],text=s2,pct=c.percent,w=12+textW(s2,T.fontBody,T.t.small)}) end end
  else table.insert(entries,{text='Odds TBD · Coming soon',w=textW('Odds TBD · Coming soon',T.fontBody,T.t.small)}) end
  local x,rows=0,1;for _,e in ipairs(entries) do e.w=math.min(e.w,iw);if x>0 and x+e.w>iw then x=0;rows+=1 end;e.x=x;e.row=rows;x+=e.w+10 end
  local bw=if v[4] then math.min(math.max(btnW(comma(v[4])..' coins',T.t.buy,12,T.s.glass),btnW('CONFIRM',T.t.buy,12,T.s.glass),btnW('Need '..comma(math.max(0,v[4]-(data.coins or 0))),T.t.buy,12,T.s.glass)),iw) else soon(nil,nil,iw)
  local wrap=bw+6+x3>iw
  plan[i]={odds=d,entries=entries,rows=rows,bw=bw,wrap=wrap}
  cellH=math.max(cellH,math.ceil(s+8+92+5+nh+10+8+8+rows*lh+2*(rows-1)+5+(if wrap then 32+6+32 else 32)+12+s))
 end
 return gridH(#items,n,10,cellH),function(parent)
  local g=grid(parent,'Eggs',#items,n,cell,10,cellH)
  for i,v in ipairs(items) do
   local rc,p=T.rarityColor[v[1]].rc,plan[i]
   local o,b=card(g,'Egg_'..v[3],T.r.glass,s);o.LayoutOrder=i
   W.grad(b,T.gradEggCard);stroke(b,T.text,s,.8)
   local ped=frame(b,'Pedestal',{Size=UDim2.fromOffset(96,92),Position=UDim2.new(.5,-48,0,8)})
   for _,l in ipairs({{T.heroFrom,.4,88,20},{T.gold,.3,53,12}}) do
    W.new('ImageLabel',ped,{Name='Plinth',Size=UDim2.fromOffset(l[3],l[4]),Position=UDim2.fromOffset(48-l[3]/2,82-l[4]/2),BackgroundTransparency=1,Image=asset(T.images.radial),ImageColor3=l[1],ImageTransparency=l[2]})
   end
   local egg=frame(ped,'Egg',{Size=UDim2.fromOffset(62,78),Position=UDim2.fromOffset(17,6),ZIndex=2});egg:SetAttribute('Motion','egg.wobble')
   W.glow(egg,egg,T.glowRarity,rc,'egg');W.icon(egg,'Egg',UDim2.fromScale(1,1),UDim2.new()).ZIndex=0
   display(egg,'Q','?',T.t.eggQ,UDim2.fromScale(1,1),nil,T.outline,2,.3)
   local y=8+92+5
   display(b,'Name',v[2],T.t.eggName,UDim2.fromOffset(iw,nh),UDim2.fromOffset(8,y),T.lip,2)
   y+=nh+10
   local odds=corner(frame(b,'Odds',{Size=UDim2.fromOffset(iw-2,6),Position=UDim2.fromOffset(9,y+1)}),T.r[4]-1);stroke(odds,T.text,T.s.hair,.6)
   if p.odds then
    local bar=corner(W.new('CanvasGroup',odds,{Name='Bar',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0}),T.r[4]-1);local at=0
    for _,e in ipairs(p.entries) do frame(bar,'Segment',{Size=UDim2.fromScale(e.pct/100,1),Position=UDim2.fromScale(at/100,0),BackgroundTransparency=0,BackgroundColor3=T.rarityColor[e.key].rc});at+=e.pct end
   end
   y+=8+8
   local legend=frame(b,'Legend',{Size=UDim2.fromOffset(iw,p.rows*lh+2*(p.rows-1)),Position=UDim2.fromOffset(8,y)})
   local x0=if p.rows==1 then math.floor((iw-(p.entries[#p.entries].x+p.entries[#p.entries].w))/2) else 0
   for j,e in ipairs(p.entries) do
    local l=W.new('TextLabel',legend,{Name='Entry'..j,Size=UDim2.fromOffset(e.w,lh),Position=UDim2.fromOffset(x0+e.x,(e.row-1)*(lh+2)),BackgroundTransparency=1,Text=e.text,TextColor3=T.text,Font=T.fontBody,TextSize=T.size(T.t.small),TextXAlignment=Enum.TextXAlignment.Right})
    l:SetAttribute('BaseTextSize',T.t.small);W.textStroke(l)
    if e.key then corner(frame(l,'Swatch',{Size=UDim2.fromOffset(8,8),Position=UDim2.new(0,0,.5,-4),BackgroundTransparency=0,BackgroundColor3=T.rarityColor[e.key].rc}),T.r[2]) end
   end
   y+=p.rows*lh+2*(p.rows-1)+5
   local bx=if p.wrap then (iw-p.bw)/2 else (iw-p.bw-6-x3)/2
   if v[4] then coinBuy(screen,b,data,v[3],v[4],iw,UDim2.fromOffset(8+bx,y)) else robux(b,p.bw,UDim2.fromOffset(8+bx,y)) end
   local tx,ty=if p.wrap then (iw-x3)/2 else bx+p.bw+6,if p.wrap then y+32+6 else y
   W.ghostOff(b,'Buy3','×3',UDim2.fromOffset(x3,32),UDim2.fromOffset(8+tx,ty),T.t.buy3,9)
  end
  return g
 end
end
-- Bat skins (skin(), L296-305): grid min 112 gap 10. Card r16, padding 8/8/10, gap 4, stroke 3 rc, gradSkin, hollow glowRarity 'skin'.
-- Trail h54 + bat 38. Name FO 13, desc FO 10.5 T.15. Candy Swirl is real (coins); its owned/equipped state comes from ShopRules.cosmetics.
local function skins(cx)
 local screen,data=cx.screen,cx.data
 local items={{'blue','Comet','Blue streak'},{'violet','Candy Swirl','Pink swirl','candy_swirl'},{'gold','Ember','Gold sparks'},{'prism','Prism','Rainbow trail'}}
 local n,cell=columns(cx.cw,112,10);local s=T.s.bold;local iw=cell-16-2*s;local nh=lineH(T.fontBody,T.t.skinName)
 local cellH=0;for _,v in ipairs(items) do cellH=math.max(cellH,s+8+54+4+nh+4+paraH(v[3],T.t.micro,iw)+4+32+10+s) end
 return gridH(#items,n,10,cellH),function(parent)
  local g=grid(parent,'Skins',#items,n,cell,10,cellH)
  local cos=ShopRules.cosmetics(data)
  for i,v in ipairs(items) do
   local key,rc=v[1],T.rarityColor[v[1]].rc
   local o,b=card(g,'Skin_'..v[2]:gsub('[^%w]',''),T.r.btn,s);o.LayoutOrder=i
   W.glow(o,o,T.glowRarity,rc,'skin');W.grad(b,T.gradSkin);stroke(b,rc,s,0)
   trail(b,key,UDim2.new(1,-16,0,54),UDim2.fromOffset(8,8),38)
   local y=8+54+4
   txt(b,'Name',v[2],T.fontBody,T.t.skinName,T.text,UDim2.fromOffset(iw,nh),UDim2.fromOffset(8,y),center,true)
   y+=nh+4;local _,dh=para(b,'Desc',v[3],T.t.micro,iw,UDim2.fromOffset(8,y),T.textDimT[3])
   y+=dh+4
   local id=v[4]
   if not id then local bw=soon(nil,nil,iw);robux(b,bw,UDim2.new(.5,-bw/2,0,y))
   elseif not cos.skins[id] then local item=ShopRules.catalog[id];local bt,bw=coinBuy(screen,b,data,id,item.price,iw);bt.Position=UDim2.new(.5,-bw/2,0,y)
   elseif cos.batSkin==id then
    local bw=btnW('Unequip',T.t.buy3,12,T.s.glass,iw)
    W.ghost(b,'Unequip','Unequip',UDim2.fromOffset(bw,32),UDim2.new(.5,-bw/2,0,y),function() screen:send('Skin',{op='clear'}) end,{n=T.t.buy3,padX=12})
   else
    local bw=btnW('Equip',T.t.buy,12,T.s.bold,iw)
    W.cta(b,'Equip','Equip',UDim2.fromOffset(bw,32),UDim2.new(.5,-bw/2,0,y),function() screen:send('Skin',{op='equip',id=id}) end,{n=T.t.buy,padX=12})
   end
  end
  return g
 end
end
-- Bats (owner §17): the real equip/upgrade cards moved from the old Shop › Bats tab, behaviour unchanged (Bat equip/upgrade via
-- screen:action), sized to the scroll content width. The old banner is dropped (the wallet shows coins).
local function bats(cx)
 local screen,data=cx.screen,cx.data
 local list=(data.ui and data.ui.bats) or {}
 local compact=screen.compact
 local cardH=if compact then 160 else 214
 local n,cell=columns(cx.cw,200,10)
 if #list==0 then return 0,function() return nil end end
 return gridH(#list,n,10,cardH),function(parent)
  local g=grid(parent,'BatCards',#list,n,cell,10,cardH)
  for i,bat in ipairs(list) do
   local card_=W.card(g,'Bat_'..bat.id,nil,nil,if bat.equipped then T.cta.base elseif bat.owned then T.alt else T.off,bat.name);card_.LayoutOrder=i
   local a=if compact then 50 else 84
   local art=W.round(W.frame(card_,'Art',UDim2.fromOffset(a+12,a+12),UDim2.new(1,-a-22,0,34),T.navy),12);W.stroke(art,T.outline,2)
   W.icon(art,'Bat',UDim2.fromOffset(a,a),UDim2.fromOffset(6,6))
   local sideW=math.min(96,cell-a-40)
   if bat.owned then
    local lv=W.label(card_,'Lv '..bat.level,UDim2.fromOffset(sideW,24),UDim2.fromOffset(10,36),T.display,14,T.ink,center);lv.BackgroundTransparency=0;lv.BackgroundColor3=T.navy;W.round(lv,6);W.stroke(lv,T.outline,1.5)
    if compact then
     W.pill(card_,nil,'Power '..bat.knockback,sideW,20,UDim2.fromOffset(10,62))
     W.pill(card_,nil,'Reach '..bat.reach,sideW,20,UDim2.fromOffset(10,84))
    else
     if bat.equipped then W.chip(card_,'Equipped',T.ok.base,UDim2.fromOffset(sideW,22),UDim2.fromOffset(10,66)) end
     local pw=math.floor((cell-30)/2)
     W.pill(card_,nil,'Power '..bat.knockback,pw,22,UDim2.new(0,10,1,-80))
     W.pill(card_,nil,'Reach '..bat.reach,pw,22,UDim2.new(0,20+pw,1,-80))
    end
    local half=UDim2.new(.5,-14,0,44)
    screen:action(card_,'Equip_'..bat.id,if bat.equipped then 'Equipped' else 'Equip','Bat',{op='equip',id=bat.id},not bat.equipped,UDim2.new(0,10,1,-52),half,'blue')
    screen:action(card_,'Upgrade_'..bat.id,if bat.cost then bat.cost..' coins' else 'Max level','Bat',{op='upgrade',id=bat.id},bat.equipped and bat.cost~=nil and (data.coins or 0)>=bat.cost,UDim2.new(.5,4,1,-52),half,'gold')
   else
    W.icon(card_,'Padlock',UDim2.fromOffset(34,34),UDim2.fromOffset(10+math.floor((sideW-34)/2),34))
    W.chip(card_,'Locked',T.navy,UDim2.fromOffset(sideW,22),UDim2.fromOffset(10,72))
    local kingdom=C.kingdoms[bat.kingdom]
    local bar=W.progress(card_,if bat.total>0 then bat.have/bat.total else 0,UDim2.new(1,-24,0,18),UDim2.new(0,12,1,-62),T.bar.fill)
    W.label(bar.Parent,bat.have..' / '..bat.total,UDim2.fromScale(1,1),nil,T.display,12,T.ink,center).ZIndex=2
    W.label(card_,if kingdom then 'Complete the '..kingdom.name..' index set' else 'Complete an index set',UDim2.new(1,-16,0,30),UDim2.new(0,8,1,-38),nil,12,T.ink,center,true)
   end
  end
  -- S:pending ran before these deferred buttons existed: apply it now (busy / Waiting… state).
  screen:pending()
  return g
 end
end
-- Note (L306, L639): FO 11 T.15, margin-top 10, last; plus the two P2 promise lines (owner Q6 copy).
local noteText='Skins change looks only. Bat level, reach and knockback are earned with coins and never sold.\nTRUE ODDS · Odds shown are the odds used.\nFAIR PLAY · Robux creatures never battle or raid.'
local function note(cx)
 return 10+paraH(noteText,T.t.small,cx.cw),function(parent)
  local o=frame(parent,'Note',{Size=UDim2.fromScale(1,0),AutomaticSize=Enum.AutomaticSize.Y})
  W.new('UIPadding',o,{PaddingTop=UDim.new(0,10)})
  local l=W.text(o,noteText,UDim2.fromScale(1,0),nil,T.fontBody,T.t.small)
  l.Name='Note';l.AutomaticSize=Enum.AutomaticSize.Y;l.TextTransparency=T.textDimT[3]
  return o
 end
end
-- Board order (L632-639): header title, note, section keys (true = tab), builder.
local sections={
 {'Free gifts','one every 15 min · coming soon',{Featured=true,['Free gifts']=false},ladder}, -- Featured = top; 'Free gifts' = Daily dock target
 {'Daily deal','coming soon',{},ticket},
 {'Coins','bonus vs the smallest pack',{Coins=true},coinPacks},
 {'Passes','forever · tycoon only',{Passes=true},passes},
 {'Boosts','timed · tycoon only',{},boosts},
 {'Eggs','odds on every egg',{Eggs=true},eggs},
 {'Bat skins','looks only',{Skins=true},skins},
 {'Bats','earned with coins',{Bats=false},bats},
 {nil,nil,{},note},
}
-- Shop.render (Screens S:shop): panel dressing + hero, then the sections. Progressive build (plan §6, no frame > 33 ms on open): every
-- section is measured first; the first view (through Coins, and through the landing target or the restored scroll + one window) is
-- built now, the rest one section per frame. Render token = this body: a re-render or close stops the rest. screen.complete builds the
-- rest at once when a jump targets a section that has not arrived; screen.sectionsPending keeps tab sync off the partial canvas end.
function Shop.render(screen,data)
 local f=screen.shade.Hub;local body=screen.body
 local cx={screen=screen,data=data,cw=screen.rowW+8} -- scroll content width (rowW keeps 8 off for the stacked rows)
 panelRays(f);wallet(screen,f,data);hero(screen,f)
 -- Section tops in the canvas: scroll padding 3 + headers (W.sectionHeader: margin 14 / 7, first 2, one FO 11 line) + bodies.
 local lh=lineH(T.fontBody,T.t.small);local steps,top={},3
 for i,s in ipairs(sections) do
  local h,build=s[4](cx);local hh=if s[1] then (if i==1 then 2 else 14)+lh+7 else 0
  steps[i]={title=s[1],note=s[2],keys=s[3],build=build,top=top};top+=hh+h
 end
 local need=screen.bodyHeight -- one scroll window at most (the hero only shrinks it)
 local target=screen.landKey or (if screen.restoreY==nil and screen.tab~='Featured' then screen.tab else nil)
 if target then for _,st in ipairs(steps) do if st.keys[target]~=nil then need=math.max(need,st.top+screen.bodyHeight) end end end
 if screen.restoreY then need=math.max(need,screen.restoreY+screen.bodyHeight) end
 local built=0
 local function buildNext()
  built+=1;local st=steps[built]
  if st.title then
   local h=W.sectionHeader(body,st.title,st.note,built==1);h.LayoutOrder=2*built-1
   for k,isTab in pairs(st.keys) do screen:section(k,h,isTab) end
  end
  local o=st.build(body);if o then o.LayoutOrder=2*built end
 end
 while built<#steps and (built<3 or steps[built+1].top<need) do buildNext() end
 if built>=#steps then return end
 local function live() return screen.body==body and body.Parent~=nil end
 local function finish() if live() then screen.sectionsPending=nil;screen.complete=nil end end
 screen.sectionsPending=true
 screen.complete=function() if live() then while built<#steps do buildNext() end;finish() end end
 task.spawn(function()
  while built<#steps do
   RunService.Heartbeat:Wait()
   if not live() then return end
   if built<#steps then buildNext() end
  end
  finish()
  if live() then screen:syncTab() end -- the end-of-list rule applies again
 end)
end
return Shop
