-- Glassbloom HUD states (P4): rest / carry (+ regrab pop-up) / chase / sanctuary / battle. Values: Theme (intel §1) and
-- climb&collect/design/hud-glassbloom-intel.md §2 HUD builders (L### = board lines), plan §15 G2/G6-G9/G19. Geometry comes from
-- UIPresentation.hudLayout in the HUD root's virtual space (the root carries the one UIScale, G2).
-- Animated pieces carry Motion=<intel §6 token> and are built in their static end state; state transitions go through Motion
-- (P6: Motion.to / show / value / play, no tweens here). Every piece is tagged
-- HudClass = permanent | transient (audits, §3) and HudPiece = its layout key. Distance/edge update at 10 Hz while carrying.
local Players=game:GetService('Players')
local TextService=game:GetService('TextService')
local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local M=require(script.Parent.Motion)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local P=require(game.ReplicatedStorage.MountainShared.UIPresentation)
local Hud={};Hud.__index=Hud
local center=Enum.TextXAlignment.Center;local left=Enum.TextXAlignment.Left
local NODE_GLOW={color=T.pk,t=0,b=10,s=0} -- rail node on: pk + glow 10 (L105; opaque hex, so T 0)
local function tag(o,class,piece) o:SetAttribute('HudClass',class);o:SetAttribute('HudPiece',piece);return o end
local function place(o,r) o.Position=UDim2.fromOffset(r.x,r.y);o.Size=UDim2.fromOffset(r.w,r.h) end
local function textW(text,font,n) return math.ceil(TextService:GetTextSize(text,T.size(n),font,Vector2.new(1e4,1e4)).X) end
Hud.textW=textW
local function frame(parent,name,props)
 local f=W.new('Frame',parent,{Name=name,BackgroundTransparency=1,BorderSizePixel=0})
 for k,v in pairs(props or {}) do f[k]=v end
 return f
end
local function strokeOf(o,color,th,t)
 local s=W.stroke(o,color,th);s.Transparency=t or 0;s:SetAttribute('BaseTransparency',t or 0);return s
end
local function label(parent,name,text,font,n,color,align)
 local l=W.new('TextLabel',parent,{Name=name,BackgroundTransparency=1,Text=text,Font=font,TextSize=T.size(n),TextColor3=color or T.text,TextXAlignment=align or center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=2})
 l:SetAttribute('BaseTextSize',n);return l
end
Hud.label=label
-- Border-box circle (CSS border inside the box): fill inset by the stroke, UIStroke outside, so the outer edge is d.
local function disc(parent,name,d,th,color,t,rim,rimT)
 local f=W.new('Frame',parent,{Name=name,Size=UDim2.fromOffset(d-2*th,d-2*th),Position=UDim2.fromOffset(th,th),BackgroundColor3=color,BackgroundTransparency=t or 0,BorderSizePixel=0})
 W.new('UICorner',f,{CornerRadius=T.r.circle});if th>0 then strokeOf(f,rim,th,rimT) end
 return f
end
Hud.disc=disc
-- Pill (W.pill recipe, §2): border-box body + stroke, label padded padX; width follows the text unless minW is larger.
local function pill(parent,name,h,padX,fill,fillT,th,rim,radius,font,n,color,text,minW)
 local f=frame(parent,name,{Size=UDim2.fromOffset(0,h)})
 local b=W.new('Frame',f,{Name='Body',Size=UDim2.new(1,-2*th,1,-2*th),Position=UDim2.fromOffset(th,th),BackgroundColor3=fill,BackgroundTransparency=fillT,BorderSizePixel=0})
 W.new('UICorner',b,{CornerRadius=UDim.new(0,math.max(0,radius-th))});if th>0 then strokeOf(b,rim,th,0) end
 local l=label(f,'Label',text,font,n,color);l.Size=UDim2.new(1,-2*(padX+th),1,0);l.Position=UDim2.fromOffset(padX+th,0)
 local function fit() f.Size=UDim2.fromOffset(math.max(minW or 0,textW(l.Text,font,n)+2*(padX+th)),h) end
 fit();l:GetPropertyChangedSignal('Text'):Connect(fit);l:GetPropertyChangedSignal('TextSize'):Connect(fit)
 return f,l
end
Hud.pill=pill
-- Level badge (L114): pill h16 (13+3), pk, stroke 1.5 white, FO 10, r7, bottom -5 centred.
-- GAP: the badge's padX is not stated; width = max(16, text + border), a circle for 1-2 digits.
local function lvBadge(parent,text)
 local f,l=pill(parent,'Level',16,0,T.pk,0,T.s.thin,T.text,T.r[7],T.fontBody,T.t.lv,T.text,text,16)
 f.AnchorPoint=Vector2.new(.5,1);f.Position=UDim2.new(.5,0,1,5);f.ZIndex=4;return f,l
end
-- Rarity gradient table for a species id (1b), nil when unknown.
local function rarityOf(species)
 local s=type(species)=='string' and C.byId[species] or nil
 local key=s and W.rarityKey(s.rarity);return key,W.rarityGrad(key),s
end
Hud.rarityOf=rarityOf
-- Dock button (L111): 42 circle white T.9 + stroke 1.5 white T.7, icon 28. TextButton root (gamepad-selectable), Hit >= 44.
local function dockButton(self,parent,name,kind,fn,order)
 local b=W.new('TextButton',parent,{Name=name,Size=UDim2.fromOffset(42,42),BackgroundTransparency=1,BorderSizePixel=0,Text=name,TextTransparency=1,AutoButtonColor=false,LayoutOrder=order or 0})
 b:SetAttribute('QAControl',true);b:SetAttribute('Enabled',true);b:SetAttribute('CornerRadius',T.r.circle)
 disc(b,'Body',42,T.s.thin,T.text,T.dbtnT.fill,T.text,T.dbtnT.rim)
 W.icon(b,kind,UDim2.fromOffset(28,28),UDim2.fromOffset(7,7)).ZIndex=3
 local pitch=Vector2.new(48,math.huge) -- pitch 48 caps the hit width (G1)
 W.hit(b,44/self.scale,pitch);W.bind(b,function() if self:_dockTap(b) then return end;fn() end);W.focus(b);table.insert(self.hits,{b,pitch})
 b.SelectionGained:Connect(function() self:_dockTap(b,true) end)
 return b
end
-- Glass with the board's .g glow (L47).
local function glass(parent,name,size,radius,variant)
 return W.glass(parent,name,size,nil,{radius=radius,variant=variant,glow=T.glowGlass})
end
-- cb: open(hub,tab), card(), swing(), pickup(), dodge(), special(slot), ability(), sound().
function Hud.new(root,cb)
 local self=setmetatable({root=root,cb=cb,hits={},e={},restored=false,cardOpen=false,bandBusy=false,blocked=false,scale=1,alive=true,railSerial=0,xpSerial=0,tapSerial=0},Hud)
 local e=self.e
 local layer=frame(root,'Hud',{Size=UDim2.fromScale(1,1),ZIndex=30});self.layer=layer
 self.uiScale=W.new('UIScale',layer,{Scale=1})
 local function go(hub,tab) return function() cb.sound();cb.open(hub,tab) end end
 -- Chase vignette (§2, P7 R4 owner: board strength): 4 edge frames, vignette colour, depth 14.6 % of W / H, T `vignette.T` .45
 -- at the screen edge -> 1 inside (1c, L139 corner α .55). Corner cap: Left/Right are CanvasGroups whose group gradient fades
 -- them out toward the top/bottom (w = v/(.45+.55v) over the corner depth), so Top/Bottom over them stays ≤ α .55. Decor.
 local vig=frame(layer,'Vignette',{Visible=false,ZIndex=0});vig:SetAttribute('Decor',true);vig:SetAttribute('Motion','vignette.pulse');e.vignette=vig
 local vt,d=T.vignetteT,.146;local cap={1,.5745,.3103,.1304,0} -- group T at v 0,¼,½,¾,1 of the corner depth (1 - w)
 local ks={};for i=1,5 do table.insert(ks,NumberSequenceKeypoint.new(d*(i-1)/4,cap[i])) end;for i=5,1,-1 do table.insert(ks,NumberSequenceKeypoint.new(1-d*(i-1)/4,cap[i])) end
 for _,v in ipairs({{'Left',UDim2.new(d,0,1,0),UDim2.new(),0,{vt,1}},{'Right',UDim2.new(d,0,1,0),UDim2.fromScale(1-d,0),0,{1,vt}},
  {'Top',UDim2.new(1,0,d,0),UDim2.new(),90,{vt,1}},{'Bottom',UDim2.new(1,0,d,0),UDim2.fromScale(0,1-d),90,{1,vt}}}) do
  local host=vig;if v[4]==0 then host=W.new('CanvasGroup',vig,{Name=v[1],Size=v[2],Position=v[3],BackgroundTransparency=1,BorderSizePixel=0});W.new('UIGradient',host,{Rotation=90,Transparency=NumberSequence.new(ks)}) end
  local f=W.new('Frame',host,{Name=if host==vig then v[1] else 'Fill',Size=if host==vig then v[2] else UDim2.fromScale(1,1),Position=if host==vig then v[3] else UDim2.new(),BackgroundColor3=T.vignette,BorderSizePixel=0})
  W.new('UIGradient',f,{Rotation=v[4],Transparency=NumberSequence.new(v[5][1],v[5][2])})
 end
 -- B.tr (L97-100): coin pill (glass h34 r18, padding L38 R14, FO 15, coin icon 40 at x -2) + gear (glass circle 44, icon 26), gap 8.
 local tr=tag(frame(layer,'TopRight',{AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(155,44),ZIndex=2}),'permanent','tr');e.tr=tr
 W.new('UIListLayout',tr,{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
 local coin=glass(tr,'Coins',UDim2.fromOffset(103,34),T.r.glass);coin.LayoutOrder=1;e.coin=coin
 local ci=W.icon(coin,'Coin',UDim2.fromOffset(40,40),UDim2.fromOffset(-2,-3));ci.ZIndex=2;ci:SetAttribute('Overhang',true)
 local cv=W.textStroke(label(coin,'Value','—',T.fontBody,T.t.coin,T.text,left),nil).Parent;cv.Position=UDim2.fromOffset(38,0);e.coinValue=cv
 -- Coin pill opens the Shop (HUD v2 AddCoins behaviour kept; the board draws no tap target).
 W.hit(coin,44);W.bind(coin,go('Shop'));table.insert(self.hits,{coin})
 local gear=glass(tr,'Gear',UDim2.fromOffset(44,44),T.r.circle);gear.LayoutOrder=2;e.gear=gear
 W.icon(gear,'Gear',UDim2.fromOffset(26,26),UDim2.fromOffset(9,9)).ZIndex=2
 W.hit(gear,44);W.bind(gear,go('Settings'));table.insert(self.hits,{gear})
 local function fitCoin() local w=38+textW(cv.Text,T.fontBody,T.t.coin)+14;cv.Size=UDim2.new(0,w-52,1,0);coin.Size=UDim2.fromOffset(w,34);tr.Size=UDim2.fromOffset(w+8+44,44) end
 cv:GetPropertyChangedSignal('Text'):Connect(fitCoin);cv:GetPropertyChangedSignal('TextSize'):Connect(fitCoin);fitCoin()
 -- B.rail (L101-106): CanvasGroup at group T .7 idle (rail.idle); line x9 w4 r3 railLine, inset 4; nodes deep + stroke 2 white,
 -- on = pk + glow 10, summit gold. The canvas has a 10 px margin so node glows aren't clipped; the tagged box is the inner Rail.
 local canvas=W.new('CanvasGroup',layer,{Name='AltitudeRail',BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=T.railIdleT,ZIndex=1})
 canvas:SetAttribute('Motion','rail.bright');e.railCanvas=canvas
 local rail=tag(frame(canvas,'Rail',{Position=UDim2.fromOffset(10,10)}),'permanent','rail');e.rail=rail
 local line=W.new('Frame',rail,{Name='Line',Position=UDim2.fromOffset(9,4),BackgroundColor3=T.text,BorderSizePixel=0});W.new('UICorner',line,{CornerRadius=UDim.new(0,T.r[3])});W.grad(line,T.gradRailLine);e.railLine=line
 e.nodes={}
 for k=1,7 do
  local h=frame(rail,'Node'..(if k==7 then 'Summit' else k),{ZIndex=2})
  local glow=if k<7 then W.glow(h,h,NODE_GLOW) else nil;if glow then glow.Visible=false end
  e.nodes[k]={holder=h,glow=glow}
 end
 -- Rail label (L108, transient): pill h25, padX 9, night2 T.15, stroke 1.5 pk, r11, FO 11.5.
 local rl=pill(layer,'RailLabel',25,9,T.night2,T.pillT.rail,T.s.thin,T.pk,T.r[11],T.fontBody,T.t.railLabel,T.text,'')
 rl.Visible=false;rl.ZIndex=3;rl:SetAttribute('Motion','rail.label');tag(rl,'transient','railLabel');e.railLabel=rl
 -- P7 E cap after the pill's own width fit (connected after it, so it runs second under deferred signals too).
 for _,k in ipairs({'Text','TextSize'}) do rl.Label:GetPropertyChangedSignal(k):Connect(function() self:_fitRailLabel() end) end
 -- B.dock (L110-115) in a CanvasGroup (group T for the chase fade, dock.chaseFade); 18 px canvas margin keeps the glass glow.
 local dc=W.new('CanvasGroup',layer,{Name='DockFade',BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=0,ZIndex=2})
 dc:SetAttribute('Motion','dock.chaseFade');e.dockCanvas=dc
 local dock=tag(glass(dc,'Dock',UDim2.fromOffset(250,58),T.r.pill30),'permanent','dock');dock.Position=UDim2.fromOffset(18,18);e.dock=dock
 local row=frame(dock,'Buttons',{Size=UDim2.fromScale(1,1),ZIndex=1});W.padding(row,8)
 e.dockList=W.new('UIListLayout',row,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center})
 -- Creatures (D2): W.ring(42,3,pk,.84,deep) + lv badge; the ring tap opens the player card launcher.
 local cr=W.new('TextButton',row,{Name='Creatures',Size=UDim2.fromOffset(42,42),BackgroundTransparency=1,BorderSizePixel=0,Text='Creatures',TextTransparency=1,AutoButtonColor=false,LayoutOrder=1})
 cr:SetAttribute('QAControl',true);cr:SetAttribute('Enabled',true);cr:SetAttribute('CornerRadius',T.r.circle)
 e.xpRing=W.ring(cr,42,T.s.ring3,T.pk,T.ringTrackT.xp,T.deep)
 W.icon(cr,'Creature',UDim2.fromOffset(28,28),UDim2.fromOffset(7,7)).ZIndex=3
 local _,lv=lvBadge(cr,'1');e.level=lv
 W.hit(cr,44,Vector2.new(48,math.huge));W.bind(cr,function() if self:_dockTap(cr) then return end;cb.sound();cb.card() end);W.focus(cr);table.insert(self.hits,{cr,Vector2.new(48,math.huge)})
 cr.SelectionGained:Connect(function() self:_dockTap(cr,true) end)
 e.dockButtons={Creatures=cr,Map=dockButton(self,row,'Map','Map',go('Mountain','Map'),2),Shop=dockButton(self,row,'Shop','Chest',go('Shop'),3),
  -- Daily -> Shop › Free gifts (D2; D6 placeholder): Shop.luau registers the 'Free gifts' section key, so Screens lands there.
  Daily=dockButton(self,row,'Daily','Calendar',go('Shop','Free gifts'),4),Quests=dockButton(self,row,'Quests','Scroll',go('Mountain','Quests'),5)}
 -- Daily dot (L115): 13 circle danger + stroke 2 white at top -2 / right -2. D6 placeholder: shown as drawn.
 local dot=frame(e.dockButtons.Daily,'Dot',{Size=UDim2.fromOffset(13,13),Position=UDim2.fromOffset(42+2-13,-2),ZIndex=4});disc(dot,'Fill',13,T.s.glass,T.danger,0,T.text,0);e.dailyDot=dot
 -- XP line (L116-117, transient): 236x6, track r4 night T.3, fill gradAction.
 local xl=tag(W.new('Frame',layer,{Name='XpLine',BackgroundColor3=T.night,BackgroundTransparency=T.wellT.xp,BorderSizePixel=0,Visible=false,ZIndex=3}),'transient','xpLine')
 W.new('UICorner',xl,{CornerRadius=UDim.new(0,T.r[4])});xl:SetAttribute('Motion','xpLine');e.xpLine=xl
 local xf=W.new('Frame',xl,{Name='Fill',Size=UDim2.fromScale(0,1),BackgroundColor3=T.text,BorderSizePixel=0});W.new('UICorner',xf,{CornerRadius=UDim.new(0,T.r[4])});W.grad(xf,T.gradAction);e.xpFill=xf
 -- Bat orb (L124): flat bat recipe 52; hidden in the sanctuary and in battle. Name kept: Swing.
 e.bat=tag(W.orb(layer,'Swing',52,{preset='bat',fn=function() cb.swing() end}),'permanent','bat');e.bat.Text='Bat'
 e.bat:SetAttribute('Tooltip','Whack a climber carrying an unsecured creature to knock it loose, then grab it.')
 -- G8 pick-up orb = bat recipe 52, 10 px above the bat orb. D4: the only context action on the mountain. Name kept: Context.
 -- GAP: the pick-up icon is not specified; the kit's Interact (climb) icon is used.
 e.pickup=tag(W.orb(layer,'Context',52,{preset='bat',icon='Interact',fn=function() cb.pickup() end}),'permanent','pickup');e.pickup.Text='Pick up creature'
 -- G6 battle: Dodge = bat recipe 52 in the bat slot. P7 R7 owner: no icon (the Jump arrow read as a 2nd jump); the word
 -- "DODGE" in LG `t.claim` 13 (1i), word-fit to one line inside the 3 px stroke + 1. Name/input/cooldown unchanged.
 e.dodge=tag(W.orb(layer,'Dodge',52,{preset='bat',icon=false,fn=function() cb.dodge() end}),'permanent','dodge');e.dodge.Text='Dodge [Q]'
 local dw=W.fit(label(e.dodge,'Word','DODGE',T.fontDisplay,T.t.claim,T.text),T.t.claim,8,false,true);dw.Size=UDim2.new(1,-2*(T.s.bold+1),1,0);dw.Position=UDim2.fromOffset(T.s.bold+1,0);dw.ZIndex=3
 e.dodge:SetAttribute('Tooltip','Dodge the highlighted danger. A successful clean dodge advances Trial mastery.')
 -- G6: 3 special orbs (sprint recipe 54) in a dock glass r30 (padding 6, gap 6). Name kept: Team/Slot1-3. The badge reuses the
 -- lv badge recipe for the key / cooldown (GAP: no special-orb cooldown look on the board).
 local team=tag(glass(layer,'Team',UDim2.fromOffset(190,70),T.r.pill30),'permanent','team');team.ZIndex=2;e.team=team
 local trow=frame(team,'Buttons',{Size=UDim2.fromScale(1,1),ZIndex=1});W.padding(trow,8)
 W.new('UIListLayout',trow,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
 e.slots={}
 for i=1,3 do
  local o=W.orb(trow,'Slot'..i,54,{preset='sprint',icon='Creature',fn=function() cb.special(i) end});o.LayoutOrder=i;o.Text='['..i..']'
  o:SetAttribute('Tooltip','Activate this companion’s special during combat.')
  local _,b=lvBadge(o,tostring(i));e.slots[i]={button=o,badge=b}
 end
 -- G6: Ability = glass chip h27 above the dock. Name kept: Ability.
 local ab=W.glassChip(layer,'Ability 1',false,nil,nil,function() cb.ability() end);ab.Name='Ability';ab.ZIndex=2;tag(ab,'permanent','ability');e.ability=ab
 ab:SetAttribute('Tooltip','Choose a captured Guardian’s special. Regular companions use their role special.');table.insert(self.hits,{ab})
 -- G6: boss bar = banner glass r24 in the tier-2 slot with a 10 px gradAction bar. Banner text recipe (L144-146).
 -- GAP: the bar track is not stated; the kit's W.progress track (night T.3, stroke 1.5 white T.5) is used.
 local boss=tag(glass(layer,'Battle',UDim2.fromOffset(260,76),T.r.banner,'banner'),'transient','boss');boss.AnchorPoint=Vector2.new(.5,0);boss.ZIndex=3;e.boss=boss
 -- P7 E (owner): top band, one factor (P.bandSlot); no Motion scale on the boss bar, so its own UIScale is the only one.
 e.bossScale=W.new('UIScale',boss,{Name='BandScale'})
 local bk=W.textStroke(label(boss,'Kicker','',T.fontBody,T.t.smallHud,T.pinkText),nil).Parent;bk.Position=UDim2.fromOffset(30,8);bk.Size=UDim2.new(1,-60,0,12);W.fit(bk,T.t.smallHud,8);e.bossKicker=bk
 local bdrop=label(boss,'Drop','',T.fontDisplay,T.t.bannerTitle,T.lip);bdrop.Position=UDim2.fromOffset(30,23);bdrop.Size=UDim2.new(1,-60,0,29);bdrop.ZIndex=1;bdrop:SetAttribute('Decor',true);W.fit(bdrop,T.t.bannerTitle,10)
 local bt=label(boss,'Title','',T.fontDisplay,T.t.bannerTitle,T.text);bt.Position=UDim2.fromOffset(30,20);bt.Size=UDim2.new(1,-60,0,29);W.fit(bt,T.t.bannerTitle,10);e.bossTitle=bt;e.bossDrop=bdrop
 e.bossFill=W.progress(boss,1,UDim2.new(1,-60,0,10),UDim2.fromOffset(30,53));e.bossFill.Parent.ZIndex=2
 -- B.cp carry portrait (L125-128): W.ring(52,4,go,.8) + glowPortrait; inner disc rcg + stroke 2 white, icon 34; distance pill h19.
 local cp=tag(frame(layer,'CarryPortrait',{Size=UDim2.fromOffset(52,62),ZIndex=2}),'permanent','portrait');e.portrait=cp
 local rh=frame(cp,'RingHost',{Size=UDim2.fromOffset(52,52),ZIndex=1});W.glow(cp,rh,T.glowPortrait)
 local cd=disc(rh,'Disc',44,T.s.glass,T.text,0,T.text,0);cd.Position=UDim2.fromOffset(4+T.s.glass,4+T.s.glass);cd.ZIndex=0;cd.BackgroundColor3=T.cardFallback;e.portraitDisc=cd;self.portraitKey=false
 e.distanceRing=W.ring(rh,52,T.s.ring4,T.go,T.ringTrackT.distance,nil)
 W.icon(rh,'Creature',UDim2.fromOffset(34,34),UDim2.fromOffset(9,9)).ZIndex=3
 local dp,dl=pill(cp,'Distance',19,7,T.night2,T.pillT.distance,T.s.thin,T.go,T.r[8],T.fontBody,T.t.smallHud,T.text,'— m')
 dp.AnchorPoint=Vector2.new(.5,1);dp.Position=UDim2.new(.5,0,1,0);dp.ZIndex=4;e.distance=dl
 -- B.edge (L129, L589; G19 only while the gate is off screen): glass r18 rim go, padding L6 R11, gap 3, chevron 18, FO 13 go.text.
 local ea=tag(glass(layer,'EdgeArrow',UDim2.fromOffset(100,36),T.r.glass,'edge'),'permanent','edge');ea.AnchorPoint=Vector2.new(1,0);ea.ZIndex=2;ea:SetAttribute('Motion','edge.nudge');e.edge=ea
 -- Chevron = SVG M6 3l6 6-6 6 (L589) as two 3 px round-cap strokes. Colour: go.text (the SVG's currentColor, assumed).
 local chev=frame(ea,'Chevron',{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(2+6,9),ZIndex=2})
 for _,v in ipairs({{9,6,45},{9,12,-45}}) do
  local seg=W.new('Frame',chev,{Name='Stroke',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(v[1],v[2]),Size=UDim2.fromOffset(math.sqrt(72)+3,3),Rotation=v[3],BackgroundColor3=T.goText,BorderSizePixel=0})
  W.new('UICorner',seg,{CornerRadius=T.r.circle})
 end
 local et=label(ea,'Label','Safe — m',T.fontBody,T.t.edge,T.goText,left);et.Position=UDim2.fromOffset(2+6+18+3,0);et.Size=UDim2.new(1,-(2+6+18+3+11+2),1,0);W.textStroke(et);e.edgeText=et
 local function fitEdge() ea.Size=UDim2.fromOffset(2+6+18+3+textW(et.Text,T.fontBody,T.t.edge)+11+2,36) end
 et:GetPropertyChangedSignal('Text'):Connect(fitEdge);et:GetPropertyChangedSignal('TextSize'):Connect(fitEdge);fitEdge()
 -- B.pcard player card / launcher (L170-174, G7): glass r18, padding 10/12, ring 48 (t3, conic) icon 32, meta FO 14, XP bar h10
 -- (margin 4/3), sub FO 11 T.15, then one row of 5 dock buttons (Creatures, Profile, Social, Discovery, Sanctuary; D2).
 local card=tag(glass(layer,'PlayerCard',UDim2.fromOffset(262,124),T.r.glass),'transient','card');card.Visible=false;card.ZIndex=4;card:SetAttribute('Motion','pcard.open');e.card=card
 -- GAP: the card ring's track T and inner disc are not stated; the dock XP ring's (.84, deep) are used. Its icon (kind not
 -- stated) repeats the dock ring's creature icon.
 local pr=W.ring(card,48,T.s.ring3,T.pk,T.ringTrackT.xp,T.deep);pr.Frame.Position=UDim2.fromOffset(14,12);e.cardRing=pr
 for _,o in ipairs(pr.Frame:GetDescendants()) do
  if o:IsA('UIStroke') and o.Parent.Name~='Track' then
   local g=o:FindFirstChildOfClass('UIGradient') or W.new('UIGradient',o,{})
   local k={};for i,st in ipairs(T.gradRingConic.stops) do k[i]=ColorSequenceKeypoint.new(st[1],st[2]) end;g.Color=ColorSequence.new(k)
  end
 end
 W.icon(card,'Creature',UDim2.fromOffset(32,32),UDim2.fromOffset(22,20)).ZIndex=3
 local meta=W.textStroke(label(card,'Meta','Player · Lv 1',T.fontBody,T.t.pcardMeta,T.text,left),nil).Parent;meta.Position=UDim2.fromOffset(72,12);meta.Size=UDim2.fromOffset(176,17);W.fit(meta,T.t.pcardMeta,8);e.cardMeta=meta
 e.cardXp=W.progress(card,0,UDim2.fromOffset(176,10),UDim2.fromOffset(72,12+17+4));e.cardXp.Parent.ZIndex=2
 local sub=W.textStroke(label(card,'Sub','',T.fontBody,T.t.smallHud,T.text,left),nil).Parent;sub.Position=UDim2.fromOffset(72,12+17+4+10+3);sub.Size=UDim2.fromOffset(176,13);sub.TextTransparency=T.textDimT[3];W.fit(sub,T.t.smallHud,8);e.cardSub=sub
 local lrow=frame(card,'Launcher',{Position=UDim2.fromOffset(14,70),Size=UDim2.fromOffset(234,42),ZIndex=2});e.launcher=lrow
 e.launchList=W.new('UIListLayout',lrow,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
 for i,name in ipairs({'Creatures','Profile','Social','Discovery','Sanctuary'}) do
  dockButton(self,lrow,'Launch'..name,name,function() self.cardOpen=false;cb.sound();cb.open(name);self:render(self.view) end,i)
 end
 -- B.beacon (L131-133): BillboardGui (AlwaysOnTop) on the nearest SanctuaryExit; pillar x56 y26 w12 r6 + glowBeacon, label pill h23.
 -- GAP G19: no distance scaling on the board; drawn at the board's 124x150 px.
 self.anchor=W.new('Attachment',workspace.Terrain,{Name='MountainSafeGate'})
 local bb=W.new('BillboardGui',Players.LocalPlayer:WaitForChild('PlayerGui'),{Name='MountainSafeBeacon',Adornee=self.anchor,AlwaysOnTop=true,Size=UDim2.fromOffset(124,150),SizeOffset=Vector2.new(0,.5),LightInfluence=0,ResetOnSpawn=false,Enabled=false})
 bb:SetAttribute('HudClass','world');e.beacon=bb
 local pillar=W.new('Frame',bb,{Name='Pillar',Position=UDim2.fromOffset(56,26),Size=UDim2.fromOffset(12,124),BackgroundColor3=T.text,BorderSizePixel=0,ZIndex=2})
 W.new('UICorner',pillar,{CornerRadius=UDim.new(0,T.r[6])});W.grad(pillar,T.gradBeaconPillar);W.glow(bb,pillar,T.glowBeacon)
 local bp,bl=pill(bb,'Label',23,10,T.goInk,T.pillT.beacon,T.s.thin,T.go,T.r[10],T.fontBody,T.t.beacon,T.text,'SAFE GATE')
 bp.AnchorPoint=Vector2.new(.5,0);bp.Position=UDim2.fromScale(.5,0);bp.ZIndex=3;e.beaconText=bl
 for _,k in ipairs({'tr','railCanvas','dockCanvas','bat','pickup','dodge','team','ability','boss','portrait','edge'}) do e[k].Visible=false end
 -- Motion.value setters (rings / XP fill are drawn by :set or Size, not one property).
 self.setXpRing=function(p) e.xpRing:set(p) end;self.setCardRing=function(p) e.cardRing:set(p) end
 self.setXpFill=function(p) e.xpFill.Size=UDim2.fromScale(math.clamp(p,0,1),1) end
 return self
end
-- G2: one UIScale on the HUD root; hit areas stay >= 44 real px (min 44/scale, capped at the neighbour pitch).
function Hud:setScale(s)
 if s==self.scale then return end
 self.scale=s;self.uiScale.Scale=s;self.layer.Size=UDim2.fromScale(1/s,1/s)
 for _,h in ipairs(self.hits) do W.hit(h[1],44/s,h[2]) end
end
-- Text-fitted widths (virtual px) for the layout.
function Hud:measure()
 local e=self.e
 return {coinW=e.coin.Size.X.Offset,edgeW=e.edge.Size.X.Offset,abilityW=e.ability.Size.X.Offset}
end
function Hud:apply(l)
 self.l=l;local e=self.e
 e.tr.Position=UDim2.fromOffset(l.gear.x+44,l.tr.y)
 place(e.railCanvas,{x=l.rail.x-10,y=l.rail.y-10,w=l.rail.w+20,h=l.rail.h+20});e.rail.Size=UDim2.fromOffset(l.rail.w,l.rail.h)
 e.railLine.Size=UDim2.fromOffset(4,math.max(0,l.rail.h-8))
 for k=1,7 do
  local nd=e.nodes[k];local r=l.railNodes[k];place(nd.holder,r)
  if nd.size~=r.w then
   nd.size=r.w;if nd.disc then nd.disc:Destroy() end
   nd.disc=disc(nd.holder,'Disc',r.w,T.s.glass,if k==7 then T.gold else T.deep,0,T.text,0);nd.disc.ZIndex=1
  end
 end
 e.railLabel.Position=UDim2.fromOffset(l.railLabel.x,l.railLabel.y)
 place(e.xpLine,l.xpLine)
 place(e.bat,l.bat);place(e.pickup,l.pickup);place(e.dodge,l.dodge);place(e.team,l.team)
 e.ability.Position=UDim2.fromOffset(l.ability.x,l.ability.y)
 self:_seatBoss();self:_fitRailLabel()
 place(e.portrait,l.portrait);e.edge.Position=UDim2.fromOffset(l.edge.x+l.edge.w,l.edge.y);M.rebase(e.edge) -- edge.nudge restarts from the new spot
 place(e.card,l.card);local gap=UDim.new(0,l.dockGap or 6);e.dockList.Padding=gap;e.launchList.Padding=gap;e.launcher.Size=UDim2.fromOffset(l.card.w-28,42);place(e.vignette,l.screen)
 if self.view then self:render(self.view) end
end
-- Chase dock (L134): 3 buttons at group T .75; restored = all 5 at T 0. Motion owns the tap/focus restore timing (3 s).
function Hud:setChaseRestored(on) self.restored=on==true;if self.view then self:render(self.view) end end
-- dock.tapRestore (L414/L670): while the dock is slim, the first tap (or gamepad focus) on a dock button restores all 5 for 3 s
-- and is swallowed (true = don't run the action); a tap while restored acts and restarts the 3 s. Leaving chase ends it.
function Hud:_dockTap(b,focus)
 if self.lastState~='chase' or not b:IsDescendantOf(self.e.dock) then return false end
 local slim=not self.restored;if focus and not slim then return false end
 self.tapSerial+=1;local mine=self.tapSerial
 M.after(M.tokens['dock.tapRestore'].hold,function() if self.tapSerial==mine and self.alive and self.lastState=='chase' then self:setChaseRestored(false) end end)
 if slim then self:setChaseRestored(true) end
 return slim
end
function Hud:toggleCard(open) if open==nil then open=not self.cardOpen end;self.cardOpen=open;if self.view then self:render(self.view) end end
-- Boss bar seat (P7 E): the top band at its fitted width, one UIScale factor.
function Hud:_seatBoss()
 local l=self.l;if not l then return end;local e=self.e
 local r=P.bandSlot(l,e.boss.Size.X.Offset,76,nil,T.glowGlass.b+(T.glowGlass.s or 0)) -- drawn extent: the glass glow
 e.boss.Position=UDim2.fromOffset(l.band.cx,r.y);e.bossScale.Scale=r.f
end
-- Rail label (P7 E): never wider than l.railLabelMax (6 px short of M); a longer label shrinks to fit on one line (line mode:
-- the whole text is the word, never wraps; P7 R1 follow-up).
function Hud:_fitRailLabel()
 local l=self.l;if not l then return end;local rl=self.e.railLabel
 if rl.Size.X.Offset>l.railLabelMax then rl.Size=UDim2.fromOffset(l.railLabelMax,25);if not self.railFit then self.railFit=true;W.fit(rl.Label,T.t.railLabel,8,false,true) end end
end
-- Feedback hooks: tier-2 band in use (hides the boss bar), sanctuary moment waiting for Collect (hides dock + card).
function Hud:setBandBusy(on) self.bandBusy=on;if self.view then self:render(self.view) end end
function Hud:setBlocked(on) self.blocked=on;if self.view then self:render(self.view) end end
-- Hatch reveal (P7 R1): the HUD hides as under an open hub (board reveal has no coin pill / gear); back after Collect.
function Hud:setRevealing(on) self.revealing=on;if self.view then self:render(self.view) end end
-- Checkpoint (H.tiers.checkpoint, rail slot): rail bright (group T 0) + label "Checkpoint n/18 · h m" for the duration (3 s),
-- then idle (T .7). Motion owns the ramp/fade (rail.bright, rail.label).
function Hud:checkpoint(m,hold)
 local e=self.e;local d=m and m.data or {};local h=self.view and self.view.height or 0
 e.railLabel.Label.Text=(if d.order then 'Checkpoint '..d.order..'/18' else 'Checkpoint')..' · '..h..' m';self:_fitRailLabel()
 self.railSerial+=1;local mine=self.railSerial;self.railBright=true
 if self.view then self:render(self.view) end
 if not hold then task.delay(m and m.duration or 3,function() if self.railSerial==mine and self.alive then self.railBright=false;if self.view then self:render(self.view) end end end) end
end
-- XP line (H.tiers.xpLine): flashes the explorer XP above the dock for the duration (1.5 s). Motion 'xpLine' fades it (in by
-- .18 s, out from 1.125 s); 'xpLine.fill' runs the fill from the value before this gain (HudState.explorerDiff into - amount; a
-- level-up starts from 0) to the new one over .225-.9 s.
function Hud:xpLine(m,hold)
 local d=m and m.data or {};local p=if type(d.need)=='number' and d.need>0 then (d.into or 0)/d.need elseif self.view then self.view.xp or 0 else 0
 local from=if type(d.need)=='number' and d.need>0 and type(d.amount)=='number' then (if d.levelUp then 0 else math.clamp(((d.into or 0)-d.amount)/d.need,0,1)) else nil
 M.value(self.e.xpFill,math.clamp(p,0,1),'xpLine.fill',self.setXpFill,{from=from})
 self.xpSerial+=1;local mine=self.xpSerial;self.xpShown=true
 if self.view then self:render(self.view) end
 M.play(self.e.xpLine,'xpLine',{hold=hold})
 if not hold then task.delay(m and m.duration or 1.5,function() if self.xpSerial==mine and self.alive then self.xpShown=false;if self.view then self:render(self.view) end end end) end
end
function Hud:clearTransients()
 self.railSerial+=1;self.xpSerial+=1;self.tapSerial+=1;self.railBright=false;self.xpShown=false;self.cardOpen=false
 M.stop(self.e.xpLine);M.show(self.e.railLabel,false,nil,{instant=true}) -- QA resets land at once
end
local function nearestExit(exits,pos)
 local best,bd=nil,math.huge
 for _,x in ipairs(if type(exits)=='table' then exits else {}) do
  if typeof(x)=='table' and typeof(x.cframe)=='CFrame' and typeof(x.size)=='Vector3' then
   local q=x.cframe:PointToObjectSpace(pos);local h=x.size/2
   local c=x.cframe:PointToWorldSpace(Vector3.new(math.clamp(q.X,-h.X,h.X),math.clamp(q.Y,-h.Y,h.Y),math.clamp(q.Z,-h.Z,h.Z)))
   local d=(c-pos).Magnitude;if d<bd then bd=d;best=x end
  end
 end
 return best,bd
end
-- 10 Hz carry tick: distance to the nearest exit, ring progress (distance covered since the carry started), edge arrow when the
-- gate is off screen (G19), beacon on the gate.
function Hud:_carryTick()
 local v=self.view;local c=v and v.carry;local e=self.e
 if not c then return end
 local d,off,gate
 if c.fixed then d=c.fixed.distance;off=c.fixed.offscreen
  local x=nearestExit(c.exits,workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero);if x then gate=x.cframe*CFrame.new(0,-x.size.Y/2,0) end
 else
  local char=Players.LocalPlayer.Character;local rr=char and char:FindFirstChild('HumanoidRootPart')
  if not rr then return end
  local x,dist=nearestExit(c.exits,rr.Position);if not x then return end
  d=dist;gate=x.cframe*CFrame.new(0,-x.size.Y/2,0)
  local cam=workspace.CurrentCamera;local vp,on=cam:WorldToViewportPoint(x.cframe.Position);off=not on or vp.Z<0
 end
 local m=math.max(0,math.floor(d))
 if c.runId~=self.carryRun then self.carryRun=c.runId;self.carryStart=math.max(d,1) end
 self.carryStart=math.max(self.carryStart or 1,d)
 e.distance.Text=m..' m';e.edgeText.Text='Safe '..m..' m';e.beaconText.Text='SAFE GATE · '..m..' m'
 e.distanceRing:set(if c.fixed and c.fixed.progress then c.fixed.progress else 1-d/self.carryStart)
 self.offscreen=off==true
 if gate then self.anchor.WorldPosition=gate.Position end
 local showEdge=e.portrait.Visible and self.offscreen;if e.edge.Visible~=showEdge then e.edge.Visible=showEdge end
 e.beacon.Enabled=e.portrait.Visible and gate~=nil
end
function Hud:_track(on)
 if on and not self.tracking then
  self.tracking=true
  task.spawn(function() while self.tracking and self.alive do self:_carryTick();task.wait(.1) end end)
 elseif not on then self.tracking=false;self.carryRun=nil;self.offscreen=false;self.e.beacon.Enabled=false end
end
-- v: {ready, hubOpen, state, coins, level, xp (0..1), name, creatures, summit, section, height, rail (pref), daily, sanctuary,
-- bat={enabled,text}, pickup, carry={species,runId,exits,fixed?}, battle={name,kicker,hp,max,slots={{text,enabled}},
-- dodge={enabled,text}, ability}}.
function Hud:render(v)
 self.view=v;local e=self.e;local l=self.l
 local show=v.ready==true and not v.hubOpen and not self.revealing;local st=v.state
 local battle=st=='battle';local sanctuary=st=='sanctuary';local chase=st=='chase'
 if st~=self.lastState then
  if sanctuary then self.cardOpen=true elseif self.lastState=='sanctuary' then self.cardOpen=false end -- board L628: card shown in the sanctuary
  if chase then self.restored=false end
  self.lastState=st
 end
 e.coinValue.Text=tostring(v.coins or '—')
 e.tr.Visible=show
 e.railCanvas.Visible=show and not sanctuary and v.rail~=false
 -- rail.bright (L107): group T .7 → 0 in .49 s, back in .56 s (ease-in-out); the 3 s hold stays in Hud:checkpoint.
 M.to(e.railCanvas,{GroupTransparency=if self.railBright then 0 else T.railIdleT},'rail.bright',{out=not self.railBright})
 -- rail.label (L109): x -6 → 0 + fade in .49 s; fade out .56 s, then hidden. Hidden at once with the rail.
 M.show(e.railLabel,e.railCanvas.Visible and self.railBright==true,'rail.label',{instant=not e.railCanvas.Visible})
 for k=1,6 do
  local on=type(v.section)=='number' and k<=v.section;local nd=e.nodes[k]
  if nd.disc then nd.disc.BackgroundColor3=if on then T.pk else T.deep end;nd.glow.Visible=on
 end
 -- Dock: rest/carry/sanctuary 5 buttons; chase 3 at group T .75 unless restored; hidden in battle and while a Collect moment waits.
 local slim=chase and not self.restored
 e.dockCanvas.Visible=show and not battle and not self.blocked
 M.to(e.dockCanvas,{GroupTransparency=if slim then T.dockChaseT else 0},'dock.chaseFade') -- L134 .2 s; Motion acts on a change only
 e.dockButtons.Daily.Visible=not slim;e.dockButtons.Quests.Visible=not slim
 if l then local r=if slim then l.dockChase else l.dock;place(e.dockCanvas,{x=r.x-18,y=r.y-18,w=r.w+36,h=r.h+36});e.dock.Size=UDim2.fromOffset(r.w,r.h) end
 -- XP ring: last → new over the xpLine fill window (xpRing, derived); a level-up refills from 0.
 local lv=v.level or 1;local up=self.ringLevel~=nil and lv>self.ringLevel;self.ringLevel=lv
 M.value(e.xpRing,v.xp or 0,'xpRing',self.setXpRing,{from=if up then 0 else nil})
 e.level.Text=tostring(lv);e.dailyDot.Visible=v.daily==true
 e.xpLine.Visible=show and self.xpShown==true and not self.blocked -- P7 E: rides with the dock; a Collect moment's CTA may sit there
 -- Orbs: bat on the mountain only (not sanctuary/battle); pick-up while a creature is revealed (D4/G8).
 local bat=v.bat or {}
 e.bat.Visible=show and not sanctuary and not battle;e.bat:SetAttribute('Enabled',bat.enabled~=false);e.bat.Text=bat.text or 'Bat'
 e.pickup.Visible=show and v.pickup==true and not sanctuary and not battle
 -- Carry: portrait (+ edge arrow off screen, beacon) on the mountain while carrying, in carry/chase/battle.
 local carrying=v.carry~=nil and not sanctuary
 e.portrait.Visible=show and carrying
 if carrying then
  local key,grad=rarityOf(v.carry.species)
  if key~=self.portraitKey then
   self.portraitKey=key;local g=e.portraitDisc:FindFirstChildOfClass('UIGradient');if g then g:Destroy() end
   if grad then W.grad(e.portraitDisc,grad);e.portraitDisc.BackgroundColor3=T.text else e.portraitDisc.BackgroundColor3=T.cardFallback end
  end
 end
 e.edge.Visible=e.portrait.Visible and self.offscreen==true
 self:_track(carrying);if not carrying then e.beacon.Enabled=false end
 e.vignette.Visible=show and chase
 -- Battle (G6).
 local b=v.battle
 e.team.Visible=show and battle;e.dodge.Visible=show and battle;e.ability.Visible=show and battle
 e.boss.Visible=show and battle and not self.bandBusy
 if battle and b then
  for i,s in ipairs(e.slots) do local d=b.slots and b.slots[i] or {};s.badge.Text=d.text or tostring(i);s.button:SetAttribute('Enabled',d.enabled~=false);s.button.Text=d.label or ('['..i..']') end
  local dd=b.dodge or {};e.dodge:SetAttribute('Enabled',dd.enabled~=false);e.dodge.Text=dd.text or 'Dodge [Q]'
  e.ability.Text=b.ability or 'Ability 1';e.ability.Label.Text=e.ability.Text
  e.ability.Size=UDim2.fromOffset(textW(e.ability.Text,T.fontBody,T.t.chip)+2*(T.s.thin+10),27)
  e.bossKicker.Text=b.kicker or '';e.bossTitle.Text=b.name or '';e.bossDrop.Text=e.bossTitle.Text
  e.bossFill.Size=UDim2.fromScale(math.clamp((b.hp or 0)/math.max(1,b.max or 1),0,1),1)
  local w=math.max(textW(e.bossKicker.Text,T.fontBody,T.t.smallHud),textW(e.bossTitle.Text,T.fontDisplay,T.t.bannerTitle))+2*(2+28)
  e.boss.Size=UDim2.fromOffset(math.min(if l then l.bandMax else w,w),76);self:_seatBoss()
 end
 -- Player card (D2 launcher): opened by the ring; open by default in the sanctuary (L628); not in chase or battle.
 -- pcard.open (§19 as rendered): from (-115, +40) α 0 in .2 s ease-out; hide instant. Its ring tweens like the dock ring while
 -- shown and lands at once when the card opens.
 local cardOn=show and self.cardOpen and not battle and not chase and not self.blocked
 local opened=cardOn and not e.card.Visible
 M.show(e.card,cardOn,'pcard.open')
 if e.card.Visible then
  e.cardMeta.Text=(v.name or 'Player')..' · Lv '..tostring(v.level or 1);e.cardXp.Size=UDim2.fromScale(math.clamp(v.xp or 0,0,1),1)
  M.value(e.cardRing,v.xp or 0,'xpRing',self.setCardRing,{instant=opened,from=if up and not opened then 0 else nil})
  -- GAP: no summit counter exists in the profile (board "3 summits"); a reached summit is shown instead.
  e.cardSub.Text=tostring(v.creatures or 0)..' creatures'..(if v.summit then ' · summit reached' else '')
 end
end
function Hud:destroy()
 self.alive=false;self.tracking=false
 if self.e.beacon then self.e.beacon:Destroy() end;if self.anchor then self.anchor:Destroy() end;self.layer:Destroy()
end
return Hud
