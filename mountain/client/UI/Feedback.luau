-- Glassbloom message host (P4; intel §4 tier map, §2 B.toast/B.bnr/B.cpop/B.run/B.moment, plan §15 G5). Name and public API
-- kept: toast(text, priority), confirm, reveal, close, destroy, .modal, .tooltip. New: layout(l), show(m) for HudState messages.
-- Tier 1 = toast under the coin pill (queue). Tier 2 = top band (banner / carry pop-up / RUN!; the newest replaces). Tier 3 =
-- centre moment (queue; in the sanctuary it waits for Collect). Messages never take input on the mountain.
-- No tweens: each message is built in its static end state with Motion=<intel §6 token>; lifetimes come from HudState.
-- Motion (P6) plays each tagged piece on creation; MotionHold = a held message plays only its in part and stays.
local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local Hud=require(script.Parent.Hud)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local H=require(game.ReplicatedStorage.MountainShared.HudState)
local EggOdds=require(game.ReplicatedStorage.MountainShared.EggOdds)
local GuiService=game:GetService('GuiService')
local UIS=game:GetService('UserInputService')
local F={};F.__index=F
local label,pill,textW,disc=Hud.label,Hud.pill,Hud.textW,Hud.disc
local left=Enum.TextXAlignment.Left
local function speciesName(id) local s=type(id)=='string' and C.byId[id] or nil;return if s then s.name else 'Creature' end
local function place(o,r) o.Position=UDim2.fromOffset(r.x,r.y);o.Size=UDim2.fromOffset(r.w,r.h) end
local function tag(o,piece,motion) o:SetAttribute('HudClass','transient');o:SetAttribute('HudPiece',piece);o:SetAttribute('Motion',motion);o.Active=false;return o end
-- Held (QA fixtures, Collect moments, the reward modal): every Motion piece in o plays its in part only (Motion reads it on scan).
local function held(o)
 if o:GetAttribute('Motion') then o:SetAttribute('MotionHold',true) end
 for _,x in ipairs(o:GetDescendants()) do if x:GetAttribute('Motion') then x:SetAttribute('MotionHold',true) end end
 return o
end
-- Display text with a drop label (W.text recipe: drops on display text only).
local function display(parent,name,text,n,color,drop,dropY,dropT)
 local d=label(parent,name..'Drop',text,T.fontDisplay,n,drop);d.ZIndex=1;d.TextTransparency=dropT or 0;d:SetAttribute('Decor',true)
 local l=label(parent,name,text,T.fontDisplay,n,color);l.ZIndex=2
 l:GetPropertyChangedSignal('Position'):Connect(function() d.Position=l.Position+UDim2.fromOffset(0,dropY) end)
 l:GetPropertyChangedSignal('Size'):Connect(function() d.Size=l.Size end)
 return l,d
end
function F.new(root,layer)
 local self=setmetatable({root=root,layer=layer or root,queue={},moments={},serial=0,alive=true,hooks={},inSanctuary=false},F)
 self.tooltip=W.panel(root,'Tooltip',UDim2.fromOffset(280,64),UDim2.new(.5,-140,0,124),T.navy);self.tooltip.ZIndex=80;self.tooltip.Visible=false
 self.tooltipText=W.text(self.tooltip,'',UDim2.new(1,-24,1,-12),UDim2.fromOffset(12,6),nil,14);self.tooltipText.ZIndex=81
 local function attach(o)
  if not o:IsA('GuiButton') then return end
  local function show() local text=o:GetAttribute('Tooltip');if text and self.alive and not self.current then self.tooltipText.Text=text;self.tooltip.Visible=true;self.tooltipOwner=o end end
  local function hide() if self.tooltipOwner==o then self.tooltip.Visible=false;self.tooltipOwner=nil end end
  o.MouseEnter:Connect(show);o.MouseLeave:Connect(hide);o.SelectionGained:Connect(show);o.SelectionLost:Connect(hide);o.Destroying:Connect(hide)
 end
 self.added=root.DescendantAdded:Connect(attach)
 self.focus=GuiService:GetPropertyChangedSignal('SelectedObject'):Connect(function()
  local selected=GuiService.SelectedObject
  if self.modal and selected and not selected:IsDescendantOf(self.modal) then GuiService.SelectedObject=self.modal.Dialog.Confirm
  -- A hatch reveal keeps gamepad focus on its Collect (the hub stays open underneath; closing it clears the selection).
  elseif not self.modal and self.moment and self.moment.trap and UIS.GamepadEnabled and not (selected and selected:IsDescendantOf(self.moment.frame)) then GuiService.SelectedObject=self.moment.trap end
 end)
 return self
end
function F:layout(l)
 self.l=l
 for _,slot in ipairs({'current','band','moment'}) do local m=self[slot];if m and m.place then m.place() end end
end
-- Legacy free text (server toasts, request results): HudState classifies it; text whose typed hud event drives the moment is
-- skipped here (G5, P2).
function F:toast(message,priority)
 local m=H.classify(message,self.inSanctuary);if not m or m.typed then return end
 if priority then m.priority=true end
 self:show(m)
end
function F:show(m,hold)
 if not self.alive or type(m)~='table' then return end
 local slot=m.slot
 if slot=='toast' then self:_queueToast(m,hold)
 elseif slot=='xpLine' or slot=='rail' then local fn=self.hooks[slot];if fn then fn(m,hold) end
 elseif slot=='banner' or slot=='carryPop' or slot=='run' then self:_band(m,hold)
 elseif slot=='moment' or slot=='reveal' then table.insert(self.moments,{m=m,hold=hold});if not self.moment then self:_nextMoment() end end
end
-- Tier 1 (B.toast, L141, L601): glass r16 pill h30, padding L6 R12, gap 6, coin icon 24 (coin gain only), FO 13. Queue of 4.
local function toastText(m)
 local d=m.data or {}
 if m.kind=='knocked' then return 'Knocked loose!' end -- G5
 if m.kind=='xp' then return '+'..tostring(d.amount)..' XP' end
 if m.kind=='creatureXp' then return '+'..tostring(d.amount)..' creature XP' end
 return m.text or d.text or ''
end
function F:_queueToast(m,hold)
 self.tooltip.Visible=false;self.tooltipOwner=nil
 local text=toastText(m);if text=='' then return end
 if self.current and self.current.text==text then return end
 for _,q in ipairs(self.queue) do if q.text==text then return end end
 if m.priority then table.clear(self.queue);self:_dropToast() end
 if #self.queue>=4 then table.remove(self.queue,1) end
 table.insert(self.queue,{m=m,text=text,hold=hold})
 if not self.current then self:_nextToast() end
end
function F:_dropToast() if self.current then self.current.frame:Destroy();self.current=nil end end
function F:_nextToast()
 self:_dropToast()
 local q=table.remove(self.queue,1);if not q or not self.alive then return end
 local coin=q.m.kind=='coin'
 -- GAP: the board toast always carries its coin icon; text-only toasts use the right padding (12) on the left too.
 local padL=if coin then 6+24+6 else 12
 local g=tag(W.glass(self.layer,'Toast',UDim2.fromOffset(100,30),nil,{radius=T.r.btn,glow=T.glowGlass}),'toast','toast');g.AnchorPoint=Vector2.new(1,0);g.ZIndex=12
 if coin then W.icon(g,'Coin',UDim2.fromOffset(24,24),UDim2.fromOffset(2+6,3)).ZIndex=2 end
 local t=W.textStroke(label(g,'Text',q.text,T.fontBody,T.t.toast,T.text,left),nil).Parent;W.fit(t,T.t.toast,8)
 if q.hold then held(g) end
 local rec={frame=g,text=q.text}
 rec.place=function()
  local l=self.l;if not l then return end
  local w=math.min(l.toastMax,2+padL+textW(q.text,T.fontBody,T.t.toast)+12+2)
  g.Size=UDim2.fromOffset(w,30);g.Position=UDim2.fromOffset(l.toast.x,l.toast.y)
  t.Position=UDim2.fromOffset(2+padL,0);t.Size=UDim2.new(1,-(2+padL+12+2),1,0)
 end
 rec.place();self.current=rec
 if not q.hold then task.delay(q.m.duration or 1.5,function() if self.current==rec then self:_nextToast() end end) end
end
-- Tier 2 builders. Banner (B.bnr L144-146): glass r24 rim white, padding 6/28/8, kicker FO 11 pinkText, title LG 28 + drop 3 lip.
local function bannerCopy(m)
 local d=m.data or {}
 if m.kind=='section' then return 'SECTION '..tostring(d.section),d.name or '' end
 if m.kind=='safe' then return 'SECURED',speciesName(d.species) end -- G5
 if m.kind=='lost' then return 'LOST IT',speciesName(d.species)..' went home' end -- G5
 return '',m.text or ''
end
function F:_banner(m)
 local kicker,title=bannerCopy(m)
 local g=tag(W.glass(self.layer,'Banner',UDim2.fromOffset(200,59),nil,{radius=T.r.banner,variant='banner',glow=T.glowGlass}),'banner','banner');g.AnchorPoint=Vector2.new(.5,0);g.ZIndex=12
 local k=W.textStroke(label(g,'Kicker',kicker,T.fontBody,T.t.smallHud,T.pinkText),nil).Parent;k.Position=UDim2.fromOffset(30,8);W.fit(k,T.t.smallHud,8)
 local t=display(g,'Title',title,T.t.bannerTitle,T.text,T.lip,3);W.fit(t,T.t.bannerTitle,10)
 local d=g:FindFirstChild('TitleDrop');W.fit(d,T.t.bannerTitle,10)
 return g,function(l)
  local w=math.min(l.bandMax,math.max(textW(kicker,T.fontBody,T.t.smallHud),textW(title,T.fontDisplay,T.t.bannerTitle))+2*(2+28))
  g.Size=UDim2.fromOffset(w,59);g.Position=UDim2.fromOffset(l.banner.x,l.banner.y)
  k.Size=UDim2.new(1,-60,0,12);t.Position=UDim2.fromOffset(30,20);t.Size=UDim2.new(1,-60,0,29)
 end
end
-- Carry pop-up (B.cpop L155-160): pill r30, padding 7/24/7/7, gap 12, rcg + cpopOverlay, stroke 3 white, glowRarity 26, lip night
-- T.4 5. Portrait 58 rcg + gloss U8 T.2, stroke 3 white, glow 14, icon 42. Kicker FO 11 (+ drop 1 ink T.2), name LG 30 (+ drop 3
-- ink T.15), hint FO 11.5 T.05. Static frames: CARRYING and GOT IT BACK (regrab).
function F:_carryPop(m)
 local d=m.data or {}
 local key,grad=Hud.rarityOf(d.species);local rc=if key then T.rarityColor[key].rc else T.cardFallback
 local regrab=m.kind=='regrab'
 local kicker=if regrab then 'GOT IT BACK' else 'CARRYING'
 local name=string.upper(speciesName(d.species))
 local hint=if regrab then 'Run it to the safe gate' else 'Get it to the safe gate'
 local o=tag(W.new('Frame',self.layer,{Name='CarryPop',BackgroundTransparency=1,BorderSizePixel=0,AnchorPoint=Vector2.new(.5,0),ZIndex=12}),'carryPop','carry.pop')
 W.glow(o,o,T.glowRarity,rc,'cpop')
 local lipF=W.new('Frame',o,{Name='Lip',Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(0,5),BackgroundColor3=T.night,BackgroundTransparency=T.glassLipT,BorderSizePixel=0,ZIndex=-1})
 W.new('UICorner',lipF,{CornerRadius=UDim.new(0,T.r.pill30)});lipF:SetAttribute('Decor',true)
 local s=T.s.bold
 local body=W.new('Frame',o,{Name='Body',Size=UDim2.new(1,-2*s,1,-2*s),Position=UDim2.fromOffset(s,s),BackgroundColor3=if grad then T.text else T.cardFallback,BorderSizePixel=0,ZIndex=0})
 W.new('UICorner',body,{CornerRadius=UDim.new(0,T.r.pill30-s)});if grad then W.grad(body,grad) end
 local bs=W.new('UIStroke',body,{Color=T.text,Thickness=s});bs:SetAttribute('BaseThickness',s);bs:SetAttribute('BaseTransparency',0)
 local ov=W.new('Frame',body,{Name='Overlay',Size=UDim2.fromScale(1,1),BackgroundColor3=T.text,BorderSizePixel=0});W.new('UICorner',ov,{CornerRadius=UDim.new(0,T.r.pill30-s)});W.grad(ov,T.gradCpopOverlay)
 local ph=W.new('Frame',o,{Name='Portrait',Size=UDim2.fromOffset(58,58),Position=UDim2.fromOffset(s+7,s+7),BackgroundTransparency=1,ZIndex=2})
 ph:SetAttribute('Motion','carry.iconTwist')
 W.glow(o,ph,T.glowRarity,rc,'cpic')
 local pd=disc(ph,'Disc',58,s,if grad then T.text else T.cardFallback,0,T.text,0);if grad then W.grad(pd,grad) end
 W.new('ImageLabel',pd,{Name='Gloss',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image='rbxassetid://'..T.images.glossOrb,ImageTransparency=.2,ZIndex=2})
 W.icon(ph,'Creature',UDim2.fromOffset(42,42),UDim2.fromOffset(8,8)).ZIndex=3
 local x=s+7+58+12
 local function line(nm,text,font,n,y,h,dropY,dropT,dimT)
  local dl=label(o,nm..'Drop',text,font,n,T.outline,left);dl.TextTransparency=dropT;dl.Position=UDim2.fromOffset(x,y+dropY);dl.Size=UDim2.fromOffset(0,h);dl.ZIndex=2;dl:SetAttribute('Decor',true)
  local l=label(o,nm,text,font,n,T.text,left);l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(0,h);l.ZIndex=3;l.TextTransparency=dimT or 0
  W.fit(dl,n,8);W.fit(l,n,8);return l,dl
 end
 local lines={}
 lines[1]={line('Kicker',kicker,T.fontBody,T.t.smallHud,s+7,13,1,.2)}
 lines[2]={line('Name',name,T.fontDisplay,T.t.carryName,s+7+13,30,3,.15)}
 local hl=label(o,'Hint',hint,T.fontBody,T.t.carryHint,T.text,left);hl.Position=UDim2.fromOffset(x,s+7+43);hl.Size=UDim2.fromOffset(0,15);hl.ZIndex=3;hl.TextTransparency=T.textDimT[1];W.textStroke(hl);W.fit(hl,T.t.carryHint,8)
 lines[3]={hl}
 return o,function(l)
  local tw=math.max(textW(kicker,T.fontBody,T.t.smallHud),textW(name,T.fontDisplay,T.t.carryName),textW(hint,T.fontBody,T.t.carryHint))
  local w=math.min(l.bandMax,x+tw+24+s);tw=w-x-24-s
  for _,pair in ipairs(lines) do for _,lb in ipairs(pair) do lb.Size=UDim2.fromOffset(tw,lb.Size.Y.Offset) end end
  o.Size=UDim2.fromOffset(w,78);o.Position=UDim2.fromOffset(l.carryPop.x,l.carryPop.y)
 end
end
-- RUN! (B.run L162-167): LG 104 + gradRun fill + UIStroke 4.5 runStroke + drop +8 runDrop; awake pill h27 padX 14 r12 runAwakeBg
-- T.15, stroke 1.5 dangerRim, FO 13, 6 below; shock ring 180 (UIStroke 6 runShock + glowShock) centred at top .22, Decor.
function F:_run(m)
 local d=m.data or {}
 local o=W.new('Frame',self.layer,{Name='Run',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=12}) -- holder; tagged boxes are its children
 local shock=W.new('Frame',o,{Name='Shock',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0});shock:SetAttribute('Decor',true);shock:SetAttribute('Motion','run.shock')
 local sd=W.new('Frame',shock,{Name='Ring',Size=UDim2.new(1,-12,1,-12),Position=UDim2.fromOffset(6,6),BackgroundTransparency=1,BorderSizePixel=0})
 W.new('UICorner',sd,{CornerRadius=T.r.circle});local ss=W.new('UIStroke',sd,{Color=T.runShock,Thickness=T.s.ring6});ss:SetAttribute('BaseThickness',T.s.ring6);ss:SetAttribute('BaseTransparency',0)
 W.glow(shock,shock,T.glowShock)
 local drop=label(o,'RunDrop','RUN!',T.fontDisplay,T.t.run,T.runDrop);drop.ZIndex=1;drop:SetAttribute('Decor',true)
 local word=label(o,'Word','RUN!',T.fontDisplay,T.t.run,T.text);word.ZIndex=2;W.grad(word,T.gradRun)
 local ws=W.new('UIStroke',word,{Color=T.runStroke,Thickness=T.s.text.run,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual,LineJoinMode=Enum.LineJoinMode.Round});ws:SetAttribute('BaseThickness',T.s.text.run);ws:SetAttribute('BaseTransparency',0)
 tag(word,'run','run.slam')
 local awake,al=pill(o,'Awake',27,14,T.runAwakeBg,T.pillT.awake,T.s.thin,T.dangerRim,T.r[12],T.fontBody,T.t.awake,T.text,string.upper(tostring(d.guardian or 'Guardian'))..' IS AWAKE')
 awake.AnchorPoint=Vector2.new(.5,0);awake.ZIndex=3;tag(awake,'awake','run.awake')
 local awakeFit=false
 return o,function(l)
  place(word,l.run);drop.Position=word.Position+UDim2.fromOffset(0,8);drop.Size=word.Size
  awake.Position=UDim2.fromOffset(l.awake.x,l.awake.y)
  if awake.Size.X.Offset>l.bandMax then awake.Size=UDim2.fromOffset(l.bandMax,27);if not awakeFit then awakeFit=true;W.fit(al,T.t.awake,8) end end
  local e=T.glowShock.b;shock.Size=UDim2.fromOffset(l.shock.w,l.shock.h);shock.Position=UDim2.fromOffset(l.shock.x,l.shock.y)
  local g=shock:FindFirstChild('Glow');if g then g.Size=UDim2.new(1,2*e,1,2*e);g.Position=UDim2.fromOffset(-e,-e) end
 end
end
-- The newest tier-2 message replaces the one showing (L532).
function F:_band(m,hold)
 if self.band then self.band.frame:Destroy();self.band=nil end
 local o,fit
 if m.slot=='carryPop' then o,fit=self:_carryPop(m) elseif m.slot=='run' then o,fit=self:_run(m) else o,fit=self:_banner(m) end
 if hold then held(o) end
 local rec={frame=o};rec.place=function() if self.l then fit(self.l) end end;rec.place();self.band=rec
 if self.hooks.band then self.hooks.band(true) end
 if not hold then task.delay(m.duration or 2.5,function() if self.band==rec then o:Destroy();self.band=nil;if self.hooks.band then self.hooks.band(false) end end end) end
end
-- Tier 3 (B.moment L149-151): LG 64 moment.text + UIStroke 3 lip + drop 5 lipDeep; sub pill padding 2/12 r10 night2 T.2 FO 13,
-- 8 below. In the sanctuary a Collect CTA (reveal Collect: W.cta 190x46, LG 24) ends it; on the mountain it lasts 2.5 s.
local function momentCopy(m)
 local d=m.data or {}
 if m.kind=='summit' then return 'SUMMIT!','Section 6 cleared' end
 -- GAP: level-up copy is not on the board (tier map names the moment only).
 if m.kind=='levelUp' then return 'LEVEL '..tostring(d.level),'Explorer level up' end
 return m.text or '',nil
end
function F:_nextMoment()
 if self.moment then local cur=self.moment;self.moment=nil;cur.frame:Destroy() end
 local q=table.remove(self.moments,1)
 if not q or not self.alive then if self.hooks.blocking then self.hooks.blocking(false) end;return end
 local m=q.m
 if m.slot=='reveal' then self:_reveal(m);return end
 local title,sub=momentCopy(m)
 local o=W.new('Frame',self.layer,{Name='Moment',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=13}) -- holder
 local t,td=display(o,'Title',title,T.t.moment,T.momentText,T.lipDeep,5)
 local ts=W.new('UIStroke',t,{Color=T.lip,Thickness=T.s.text.moment,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual,LineJoinMode=Enum.LineJoinMode.Round});ts:SetAttribute('BaseThickness',T.s.text.moment);ts:SetAttribute('BaseTransparency',0)
 tag(t,'moment','moment');W.fit(t,T.t.moment,16);W.fit(td,T.t.moment,16)
 local sp,sl
 if sub then sp,sl=pill(o,'Sub',20,12,T.night2,T.pillT.momentSub,0,T.night2,T.r[10],T.fontBody,T.t.momentSub,T.text,sub);sp.AnchorPoint=Vector2.new(.5,0);sp.ZIndex=3;tag(sp,'momentSub','moment') end
 local subFit=false
 local cta
 if m.collect then
  cta=W.cta(o,'Collect','COLLECT',UDim2.fromOffset(190,46),nil,function() self:_nextMoment() end,{n=T.t.revealCta});cta.ZIndex=4
  cta:SetAttribute('HudClass','transient');cta:SetAttribute('HudPiece','collect');cta:SetAttribute('Motion','moment')
  if self.hooks.blocking then self.hooks.blocking(true) end
 end
 if m.collect or q.hold then held(o) end -- a Collect moment waits: title / sub / Collect stay in
 local rec={frame=o}
 rec.place=function()
  local l=self.l;if not l then return end
  t.Position=UDim2.fromOffset(0,l.moment.y);t.Size=UDim2.fromOffset(l.moment.w,l.moment.h)
  if sp then sp.Position=UDim2.fromOffset(l.momentSub.x,l.momentSub.y);if sp.Size.X.Offset>l.bandMax then sp.Size=UDim2.fromOffset(l.bandMax,20);if not subFit then subFit=true;W.fit(sl,T.t.momentSub,8) end end end
  if cta then cta.Position=UDim2.fromOffset(l.collect.x,l.collect.y) end
 end
 rec.place();self.moment=rec
 if not m.collect and not q.hold then task.delay(m.duration or 2.5,function() if self.moment==rec then self:_nextMoment() end end) end
end
-- Sanctuary hatch reveal strip (P5 E; intel §2 `reveal strip`, board L326-356, L538-548, L731-738). Tier-3 moment kind 'hatch'
-- (HudState tiers.hatch: slot reveal, collect): Collect ends it. Static end state = landed + named + cta (the board's reduce-motion
-- frame with the landed title); every animated piece carries Motion (§6 reveal.*, rays.reveal, sparkle; MotionDelay = the board
-- delay). Scope R (1i): a SafeRoot child above the hub and HUD, never HUD-scaled.
-- Scale decision (the board has one size; §3 has no strip check): every positioned part sits in the board's 844x390 frame
-- ('Strip'), centred, with one UIScale = min(1, W/844, H/390), so 749x330 keeps Collect and the chance line on screen. The
-- backdrop (root fill + radial), sun and band are screen-wide outside it, placed at the scaled geometry.
-- reveal.dim (group opacity .12 = T.88, L345) is per child (intel Conversions): T = 1-(1-T0)*.12; Motion recovers
-- T0 = 1-(1-T)/(1-revealDimT).
local function dimT(t) return 1-(1-(t or 0))*(1-T.revealDimT) end
local TRACK='bbgbvbgbbgbvbgvbbgbb' -- L731 colours: b #6C8CF0, g #F7A21B, v #B06CF0 (rarityColor rc); index 14 = the hatch
local TRACK_KEY={b='blue',g='gold',v='violet'}
local CARD_FILL={rot=90,stops={{0,T.text,0},{1,T.text,.2}}} -- L732 c → c+'cc' (rarity fill → T.2), times BackgroundColor3 rc
local SPARKS={{250,260,34,T.glowSparkle},{590,250,28,T.glowSparkle2,.7},{540,60,22,T.glowSparkle,1.3}} -- L546 .tw/.d2/.d3, L41
local FADE=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})
local function stroke(o,color,th,t,ctx)
 local s=W.new('UIStroke',o,{Color=color,Thickness=if T.prefs.highContrast then math.max(2,th) else th,Transparency=t or 0,LineJoinMode=Enum.LineJoinMode.Round,ApplyStrokeMode=if ctx then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border})
 s:SetAttribute('BaseThickness',th);s:SetAttribute('BaseTransparency',t or 0);return s
end
local function box(parent,name,x,y,w,h,z) return W.new('Frame',parent,{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=z or 1}) end
local function round(o,r) W.new('UICorner',o,{CornerRadius=if type(r)=='number' then UDim.new(0,r) else r});return o end
-- Full-width display line in the 844 frame + drop label, grouped so Motion moves both. lh = the CSS line box; the label is at least
-- the text size tall (large text keeps TextFits).
local function revealText(parent,name,text,n,color,drop,dropY,y,lh,z,motion)
 local g=box(parent,name,0,y,844,lh,z);g:SetAttribute('Motion',motion)
 local th=math.max(lh,T.size(n))
 local function line(nm,c,dy,lz) local l=label(g,nm,text,T.fontDisplay,n,c);l.Size=UDim2.new(1,0,0,th);l.Position=UDim2.fromOffset(0,(lh-th)/2+dy);l.ZIndex=lz;return l end
 line('Drop',drop,dropY,1):SetAttribute('Decor',true)
 return g,line('Text',color,0,2)
end
-- species = Catalog entry or id; info.chance (percent) overrides the roll weight in the species' section table (EggOdds).
function F:hatchReveal(species,info)
 if type(species)=='string' then species=C.byId[species] end
 if type(species)~='table' or not C.byId[species.id] then return end
 local chance=type(info)=='table' and info.chance or nil
 if chance==nil then for _,e in ipairs(EggOdds.table(species.kingdom) or {}) do if e.id==species.id then chance=e.weight end end end
 self:show(H.message('hatch',{species=species.id,chance=chance},true))
end
function F:_reveal(m)
 local d=m.data or {};local sp=C.byId[d.species];if not sp then self:_nextMoment();return end
 local key=W.rarityKey(sp.rarity);local rc=if key then T.rarityColor[key].rc else T.cardFallback
 self.tooltip.Visible=false;self.tooltipOwner=nil
 -- Root = backdrop reveal.bgOut (L326), full screen; it sinks input so the hub underneath can't be tapped.
 local o=W.new('Frame',self.root,{Name='HatchReveal',Size=UDim2.fromScale(1,1),BackgroundColor3=T.revealBgOut,BorderSizePixel=0,Active=true,ClipsDescendants=true,ZIndex=60})
 o:SetAttribute('HudClass','transient');o:SetAttribute('HudPiece','reveal') -- full screen by design: §3 has no strip check
 -- U11 radial reveal.bgIn at 50 %/48 %, linear to bgOut at 75 % of the farthest-corner distance (≈702 at 844x390, est.).
 local radial=W.new('ImageLabel',o,{Name='Radial',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.48),BackgroundTransparency=1,Image='rbxassetid://'..T.images.radial,ImageColor3=T.revealBgIn,ZIndex=1})
 radial:SetAttribute('Decor',true)
 -- Sun: U2 rays.tint T.72, ≈1224 at 844 (§5). Centre = the frame centre: .rvsun is inset -60 % (L327), so it turns about 50 %/50 %
 -- (the 48 % is the backdrop radial's centre).
 local sun=W.new('ImageLabel',o,{Name='Sun',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundTransparency=1,Image='rbxassetid://'..T.images.rays,ImageColor3=T.raysTint,ImageTransparency=T.raysT.reveal,ZIndex=2})
 sun:SetAttribute('Decor',true);sun:SetAttribute('Motion','rays.reveal')
 -- Band y 92 h 130 night2 T.38, top/bottom lines 3 white T.45 inside the box (L329), dimmed.
 local band=W.new('Frame',o,{Name='Band',BackgroundColor3=T.night2,BackgroundTransparency=dimT(.38),BorderSizePixel=0,ZIndex=3});band:SetAttribute('Motion','reveal.dim')
 local lines={}
 for i=0,1 do lines[i+1]=W.new('Frame',band,{Name='Line',AnchorPoint=Vector2.new(0,i),Position=UDim2.fromScale(0,i),BackgroundColor3=T.text,BackgroundTransparency=dimT(.45),BorderSizePixel=0}) end
 local h=W.new('Frame',o,{Name='Strip',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(844,390),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=4})
 local scale=W.new('UIScale',h,{})
 -- Title LG 26 landed (30 before, instant switch at reveal.landed, L328/L356) goldText at top 20, drop 3 lip, glowRevealTitle as
 -- the optional U1 around the text (1g). Line box ≈1.2 x 26 (line-height normal, est.).
 -- Owner STOP 3: "RARE PULL!" (board L738) for Rare and up; Common/Uncommon read "NEW COMPANION!".
 local titleText=if sp.rarity=='Common' or sp.rarity=='Uncommon' then 'NEW COMPANION!' else 'RARE PULL!'
 local title=revealText(h,'Title',titleText,T.t.revealTitleLanded,T.goldText,T.lip,3,20,32,1,'reveal.landed')
 local tg,tb=T.glowRevealTitle,T.glowRevealTitle.b
 W.new('ImageLabel',title,{Name='Glow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(textW(titleText,T.fontDisplay,T.t.revealTitleLanded)+2*tb,T.size(T.t.revealTitleLanded)+2*tb),BackgroundTransparency=1,
  Image='rbxassetid://'..T.images.glow,ImageColor3=tg.color,ImageTransparency=tg.t,ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.glow,SliceScale=tb/32,ZIndex=0}):SetAttribute('Decor',true)
 -- Track y 104 (L331-332, L731-733): 20 cards 96x108 at pitch 108, landed with index 14 centred, x = 422 - (14*108 + 54).
 -- Track = the dim group; Reel = the spinning strip (overflows the frame by design: Decor).
 local track=box(h,'Track',0,104,844,108,3);track:SetAttribute('Motion','reveal.dim');track:SetAttribute('Decor',true)
 local reel=box(track,'Reel',422-(14*108+54),0,20*108,108);reel:SetAttribute('Motion','reveal.spin')
 -- Clipped lip 4 ink (translucent card body, intel Conversions): one clip strip under the reel at y 108..112.
 local lipClip=box(reel,'LipClip',0,108,20*108,4);lipClip.ClipsDescendants=true;lipClip:SetAttribute('Decor',true)
 for i=0,19 do
  local x=i*108;local c=if i==14 then rc else T.rarityColor[TRACK_KEY[TRACK:sub(i+1,i+1)]].rc
  -- r14, border 3 ink inside the box (body inset 3 + UIStroke 3), fill rc → rc T.2, inner ring 2 white T.65, icon 68
  -- (creature/egg alternating, L732).
  local b=round(W.new('Frame',reel,{Name='Card'..i,Position=UDim2.fromOffset(x+3,3),Size=UDim2.fromOffset(90,102),BackgroundColor3=c,BackgroundTransparency=dimT(0),BorderSizePixel=0,ZIndex=2}),T.r.card-T.s.bold)
  W.grad(b,CARD_FILL);stroke(b,T.outline,T.s.bold,dimT(0))
  stroke(round(box(b,'Ring',T.s.glass,T.s.glass,90-2*T.s.glass,102-2*T.s.glass),T.r.card-T.s.bold-T.s.glass),T.text,T.s.glass,dimT(.65))
  local img=W.icon(b,if i%2==0 then 'Creature' else 'Egg',UDim2.fromOffset(68,68),UDim2.fromOffset(11,17)):FindFirstChild('Image')
  if img then img.ImageTransparency=dimT(0) end
  local lp=round(box(lipClip,'Lip'..i,x,4-108,96,108),T.r.card);lp.BackgroundColor3=T.outline;lp.BackgroundTransparency=dimT(0)
 end
 -- Selector 120x150 at (362,82): stroke 5 gold r18, glowRevealSel (the inset glow is not ported), dimmed.
 local sel=box(h,'Selector',362,82,120,150,4);sel:SetAttribute('Motion','reveal.dim')
 W.glow(sel,sel,T.glowRevealSel).ImageTransparency=dimT(T.glowRevealSel.t)
 stroke(round(box(sel,'Ring',T.s.reveal,T.s.reveal,120-2*T.s.reveal,150-2*T.s.reveal),T.r.glass-T.s.reveal),T.gold,T.s.reveal,dimT(0))
 -- Halos 180x190 at (332,62): stroke 6 gold / stroke 3 pinkText, both glowHalo (.h2 overrides only the border, L335). The burst
 -- ends at α 0 (L337): built fully transparent at the CSS box; Motion scales .4 → 2.8.
 for i,v in ipairs({{T.gold,T.s.ring6},{T.pinkText,T.s.bold}}) do
  local hl=box(h,'Halo'..i,332,62,180,190,5);hl:SetAttribute('Motion','reveal.halo');hl:SetAttribute('Decor',true);if i==2 then hl:SetAttribute('MotionDelay',.12) end
  W.glow(hl,hl,T.glowHalo).ImageTransparency=1
  stroke(round(box(hl,'Ring',v[2],v[2],180-2*v[2],190-2*v[2]),T.r.circle),v[1],v[2],1)
 end
 -- GAP: G12 — the 5 shards (46x56 at (422,150), gradShard, reveal.shard, L338-341) have no primitive or upload; not built.
 -- Result card 140x170 at (352,70), rotation -3, stroke 5 white, rcg, glowRevealCard (B34 S8). Art: W.portrait 96 = the hatched
 -- species' art (P5 decision; the board draws the generic creature icon 96).
 local card=box(h,'Card',352,70,140,170,6);card.Rotation=-3;card:SetAttribute('Motion','reveal.cardIn');card:SetAttribute('CornerRadius',UDim.new(0,T.r.glass))
 W.glow(card,card,T.glowRevealCard)
 local cb=round(W.new('Frame',card,{Name='Body',Position=UDim2.fromOffset(T.s.reveal,T.s.reveal),Size=UDim2.fromOffset(140-2*T.s.reveal,170-2*T.s.reveal),BackgroundColor3=T.cardFallback,BorderSizePixel=0}),T.r.glass-T.s.reveal)
 if key then W.tint(cb,W.rarityGrad(key)) end;stroke(cb,T.text,T.s.reveal,0)
 W.portrait(cb,sp,UDim2.fromOffset(96,96),UDim2.fromOffset(70-T.s.reveal-48,85-T.s.reveal-48))
 -- Word = tier + "!" LG 62 momentText, UIStroke 3 lip (Contextual), drop 5 lipDeep, line box 62 (L346); named → y 226 (L355).
 local _,word=revealText(h,'Word',string.upper(sp.rarity)..'!',T.t.revealWord,T.momentText,T.lipDeep,5,226,62,7,'reveal.slam')
 stroke(word,T.lip,T.s.text.moment,0,true)
 -- Name LG 22 white + drop 2 lip at y 302 (L350); line box ≈1.2 x 22 (est.).
 revealText(h,'Species',string.upper(sp.name),T.t.revealName,T.text,T.lip,2,302,27,8,'reveal.name')
 -- Chance FO 14 pinkText at y 330 (L351): rarity pill (gradRevealPill, white, r10, padding 0/10) + " · N% chance", N = the roll
 -- weight. Line box ≈1.2 x 14 (est.). GAP: the board's "+250 XP" span (go) is omitted: a hatch grants no XP.
 local tier=string.upper(sp.rarity);local odds=if d.chance then ' · '..tostring(d.chance)..'% chance' else ''
 local pw=textW(tier,T.fontBody,T.t.revealChance)+2*10;local ow=if odds~='' then textW(odds,T.fontBody,T.t.revealChance) else 0
 local x0=math.floor(422-(pw+ow)/2)
 local row=box(h,'Chance',0,330,844,17,9);row:SetAttribute('Motion','reveal.name')
 local pill=round(W.new('Frame',row,{Name='Rarity',Position=UDim2.fromOffset(x0,0),Size=UDim2.fromOffset(pw,17),BackgroundColor3=T.text,BorderSizePixel=0}),T.r[10])
 W.grad(pill,T.gradRevealPill)
 local pl=label(pill,'Text',tier,T.fontBody,T.t.revealChance,T.text);pl.Size=UDim2.fromScale(1,1);W.textStroke(pl)
 if odds~='' then local ol=label(row,'Odds',odds,T.fontBody,T.t.revealChance,T.pinkText,left);ol.Position=UDim2.fromOffset(x0+pw,0);ol.Size=UDim2.fromOffset(ow+4,17);W.textStroke(ol) end
 -- Collect W.cta 190x46 LG 24 at (620,316): right inset 34 (L353).
 local cta=W.cta(h,'Collect','Collect!',UDim2.fromOffset(190,46),UDim2.fromOffset(844-34-190,316),function() self:_collect() end,{n=T.t.revealCta})
 cta.ZIndex=10;cta:SetAttribute('HudClass','transient');cta:SetAttribute('HudPiece','collect');cta:SetAttribute('Motion','reveal.cta')
 -- Sparkles (.fl, L40-42, L546): 2 crossed thin Frames with a centre-bright UIGradient (P§2) and a glow per arm (drop-shadow on the
 -- star, 1g). Static = the no-animation frame: full size, upright, α 1. GAP: arm thickness is not in the intel; .16 = the .fl
 -- clip-path waist (42 % → 58 %, L40).
 for i,v in ipairs(SPARKS) do
  local f=box(h,'Sparkle'..i,v[1],v[2],v[3],v[3],11);f:SetAttribute('Motion','sparkle');f:SetAttribute('Decor',true);if v[5] then f:SetAttribute('MotionDelay',v[5]) end
  for j,a in ipairs({{.16,1,.42,0,90},{1,.16,0,.42,0}}) do
   local arm=W.new('Frame',f,{Name='Arm'..j,Size=UDim2.fromScale(a[1],a[2]),Position=UDim2.fromScale(a[3],a[4]),BackgroundColor3=T.text,BorderSizePixel=0,ZIndex=2})
   W.new('UIGradient',arm,{Rotation=a[5],Transparency=FADE});W.glow(f,arm,v[4])
  end
 end
 local rec={frame=o,trap=cta}
 rec.place=function()
  local v=self.root.AbsoluteSize;if v.X<=0 or v.Y<=0 then return end
  local s=math.min(1,v.X/844,v.Y/390);scale.Scale=s
  local dia=1.5*math.sqrt((v.X/2)^2+(.52*v.Y)^2);radial.Size=UDim2.fromOffset(dia,dia)
  sun.Size=UDim2.fromOffset(1224*s,1224*s)
  band.Position=UDim2.fromOffset(0,(v.Y-390*s)/2+92*s);band.Size=UDim2.new(1,0,0,130*s)
  for _,l in ipairs(lines) do l.Size=UDim2.new(1,0,0,3*s) end
  W.hit(cta,44/s) -- 44 px on screen under the UIScale (§3)
 end
 rec.place();self.moment=rec
 if self.hooks.blocking then self.hooks.blocking(true) end
 if UIS.GamepadEnabled then rec.prev=GuiService.SelectedObject;GuiService.SelectedObject=cta end
end
function F:_collect()
 local prev=self.moment and self.moment.prev
 self:_nextMoment()
 if UIS.GamepadEnabled and not (self.moment and self.moment.trap) then GuiService.SelectedObject=if prev and prev:IsDescendantOf(self.root) then prev else nil end
end
-- Drop the moment queue and the moment showing (UIProbe close / reveal fixture); unblocks the HUD.
function F:clearMoments()
 table.clear(self.moments)
 if self.moment then local cur=self.moment;self.moment=nil;cur.frame:Destroy();if self.hooks.blocking then self.hooks.blocking(false) end end
end
-- QA fixtures and state resets: drop every message now.
function F:clear()
 table.clear(self.queue);self:_dropToast()
 if self.band then self.band.frame:Destroy();self.band=nil;if self.hooks.band then self.hooks.band(false) end end
 self:clearMoments()
end
function F:confirm(title,description,onConfirm)
 self:close();self.previousFocus=GuiService.SelectedObject
 local shade=W.frame(self.root,'Confirmation',UDim2.fromScale(1,1),nil,T.navy);shade.BackgroundTransparency=.15;shade.ZIndex=70;shade.Active=true;self.modal=shade
 local f=W.panel(shade,'Dialog',UDim2.new(.86,0,0,226),UDim2.fromScale(.5,.5));f.AnchorPoint=Vector2.new(.5,.5);f.ZIndex=71
 W.new('UISizeConstraint',f,{MaxSize=Vector2.new(480,226)})
 W.text(f,title,UDim2.new(1,-32,0,40),UDim2.fromOffset(16,14),T.display,22).ZIndex=72
 local descriptionLabel=W.text(f,description,UDim2.new(1,-32,0,86),UDim2.fromOffset(16,58),nil,15,T.muted);descriptionLabel.Name='Description';descriptionLabel.ZIndex=72
 W.button(f,'Cancel','Cancel',UDim2.new(.5,-24,0,48),UDim2.new(0,16,1,-64),function() self:close() end,'quiet').ZIndex=72
 local confirm=W.button(f,'Confirm','Confirm',UDim2.new(.5,-24,0,48),UDim2.new(.5,8,1,-64),function() self:close();onConfirm() end,'gold');confirm.ZIndex=72
 if game:GetService('UserInputService').GamepadEnabled then GuiService.SelectedObject=confirm end
end
function F:reveal(title,description,species)
 -- Called only by authoritative state transitions or acknowledged outcomes.
 self:confirm(title,description,function() end)
 local f=self.modal and self.modal:FindFirstChild('Dialog')
 if f then
  -- Reward moment (intel §4 + owner decision): purple panel, LuckiestGuy gold title, green confirm. Static end state; Motion
  -- owns the pop-in ('moment').
  f:SetAttribute('Motion','moment');f:SetAttribute('MotionHold',true) -- the modal waits for Continue: in part only
  f.BackgroundColor3=T.panelPurple;f.Text.Font=T.title;f.Text.TextColor3=T.gold;f.Text.TextXAlignment=Enum.TextXAlignment.Center;f.Text.TextSize=T.size(28);f.Text.UIStroke.Thickness=3
  f.Confirm:SetAttribute('ButtonColor',T.ok.base);f.Confirm.BackgroundColor3=T.ok.base
  f.Confirm.Text='Continue';f.Cancel.Visible=false;f.Confirm.Size=UDim2.new(1,-32,0,48);f.Confirm.Position=UDim2.new(0,16,1,-64)
  if species then
   f.Size=UDim2.new(.86,0,0,300);f.UISizeConstraint.MaxSize=Vector2.new(480,300)
   f.Description.Position=UDim2.fromOffset(16,158);f.Description.Size=UDim2.new(1,-32,0,64);f.Description.TextXAlignment=Enum.TextXAlignment.Center
   local portrait=W.portrait(f,species,UDim2.fromOffset(80,80),UDim2.new(.5,-40,0,70));portrait.ZIndex=72
   for _,o in ipairs(portrait:GetDescendants()) do if o:IsA('GuiObject') then o.ZIndex=73 end end
  end
 end
end
function F:close()
 if not self.modal then return false end
 local modal=self.modal;self.modal=nil;modal:Destroy()
 if self.previousFocus and self.previousFocus.Parent then GuiService.SelectedObject=self.previousFocus else GuiService.SelectedObject=nil end
 self.previousFocus=nil;return true
end
function F:destroy() self.alive=false;self:clear();self:close();self.added:Disconnect();self.focus:Disconnect();self.tooltip:Destroy() end
return F
