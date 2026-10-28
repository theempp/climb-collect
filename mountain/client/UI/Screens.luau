local Players=game:GetService('Players')
local GuiService=game:GetService('GuiService')
local UIS=game:GetService('UserInputService')
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local R=require(game.ReplicatedStorage.MountainShared.Rules)
local P=require(game.ReplicatedStorage.MountainShared.UIPresentation)
local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local TycoonHub=require(script.Parent.TycoonHub)
local S={};S.__index=S
local tabs={Creatures={'Collection','Team','Training','Evolution'},Discovery={'Eggs','Field guide'},Sanctuary={'Overview','Habitats','Upgrades','Automation','Cosmetics','Facilities'},Mountain={'Map','Quests','Trials'},Social={'Party','Challenges','Defense'},Profile={'Overview','Achievements','Recognition'},Shop={'Bats','Cosmetics','Convenience'},Settings={'Accessibility','Audio','Quick'}}
local aliases={Collection='Creatures',Training='Creatures',Incubator='Discovery',Eggs='Discovery',Travel='Mountain',Journal='Mountain',Competition='Social'}
local aliasTabs={Training='Training',Incubator='Eggs',Eggs='Eggs',Travel='Map',Journal='Quests',Competition='Challenges'}
-- Side-tab icons only where the board draws them (Collection All/Team/Index/Evolve, L630); every other tab has none.
local tabIcons={Creatures={Collection='Creature',Team='Heart',Training='Scroll',Evolution='EggCracked'}}
-- Section-jump hubs (intel §2 per-menu): their tabs are sections of one scroll. Shop (task D) and Settings (task E) join here.
local sectionHubs={}
function S.new(root,store,feedback,onClose)
 local self=setmetatable({root=root,store=store,feedback=feedback,onClose=onClose,selected={},query='',rarity='All',sort='Name',page=1,tickers={},actionButtons={},touches={},sections={},tabButtons={}},S)
 self.touchBegin=UIS.TouchStarted:Connect(function(input) self.touches[input]=true end)
 self.touchEnd=UIS.TouchEnded:Connect(function(input) self.touches[input]=nil end)
 return self
end
-- `tab` (optional): a tab name, or a section key the content registers with S:section (e.g. Shop 'Free gifts').
function S:open(name,tab)
 local hub=aliases[name] or name
 if not tabs[hub] then return end
 self.tycoonRoster=nil;self.tycoonPage=1
 self.hub=hub;self.tab=aliasTabs[name] or tabs[hub][1];self.detail=nil;self.page=1;self.landKey=nil
 if tab then if table.find(tabs[hub],tab) then self.tab=tab else self.landKey=tab end end
 if self.store.profile then self.selected=table.clone(self.store.profile.team) end
 self:render(false)
end
function S:close()
 if self.shade then self.shade:Destroy();self.shade=nil end
 self.hub=nil;self.detail=nil;self.tickers={};self.actionButtons={};self.sections={};self.tabButtons={};self.landing=nil;self.landKey=nil;GuiService.SelectedObject=nil
 if self.onClose then self.onClose() end
end
function S:destroy()
 self:close();self.touchBegin:Disconnect();self.touchEnd:Disconnect();table.clear(self.touches)
end
function S:back() if self.detail then self.detail=nil;self:render(false) else self:close() end end
function S:send(action,payload)
 local id=self.store:request(action,payload)
 if not id then self.feedback:toast('That action is already waiting for a response. Check the status below.') end
end
function S:action(parent,name,label,action,payload,enabled,pos,size,variant)
 local b=W.button(parent,name,label,size or UDim2.new(1,-28,0,44),pos or UDim2.new(0,14,1,-56),function() self:send(action,if type(payload)=='function' then payload() else payload) end,variant or 'blue',enabled)
 table.insert(self.actionButtons,{button=b,action=action,enabled=enabled~=false,label=label});return b
end
-- Info strip: navy inset with an illustrated icon, title and one short line; `reserve` keeps room on the right for a button.
function S:info(kind,title,description,height,reserve)
 local h=height or 72
 local f=W.panel(self.body,(title:gsub('[^%w]','')),UDim2.new(1,-8,0,h),nil,T.navy)
 local a=math.min(h-16,52);local x=14
 if kind then W.icon(f,kind,UDim2.fromOffset(a,a),UDim2.new(0,10,.5,-a/2));x=a+22 end
 local r=(reserve or 0)+12
 W.label(f,title,UDim2.new(1,-x-r,0,22),UDim2.fromOffset(x,8),T.bold,17).Name='Title'
 local d=W.label(f,description,UDim2.new(1,-x-r,1,-38),UDim2.fromOffset(x,31),nil,13,T.muted,nil,true);d.Name='Description';d.TextYAlignment=Enum.TextYAlignment.Top
 return f
end
function S:blocked(title,description,actionLabel,kind)
 local w=if self.rowW<520 then 130 else 170
 local f=self:info(kind or 'Padlock',title,description,72,w)
 W.button(f,'Unavailable',actionLabel or 'Not available in this build',UDim2.fromOffset(w,44),UDim2.new(1,-w-12,.5,-24),nil,'quiet',false)
 return f
end
function S:note(title,description,height) return self:info(nil,title,description,math.min(height or 72,96)) end
-- Card grid: equal cells sized from a minimum card width so cards always fit the panel; few cards stay centred.
function S:grid(name,count,minW,cellH)
 local cols=math.max(1,math.floor((self.rowW+10)/(minW+10)))
 local cw=(self.rowW-10*(cols-1))/cols
 local g=W.frame(self.body,name,UDim2.new(1,-8,0,math.ceil(math.max(count,1)/cols)*(cellH+10)-10));g.BackgroundTransparency=1
 local layout=W.new('UIGridLayout',g,{CellPadding=UDim2.fromOffset(10,10),SortOrder=Enum.SortOrder.LayoutOrder})
 if count<cols then cw=math.min(cw,minW*1.5);layout.CellSize=UDim2.fromOffset(cw,cellH);layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
 else layout.CellSize=UDim2.new(1/cols,-10*(cols-1)/cols-1,0,cellH) end
 return g,math.floor(cw)
end
-- Spotlight banner. `slot` {w,h} reserves room for a CTA/pills: the returned Slot frame sits at the banner's right
-- (wide) or at the foot of the hero column (short phones, where the banner stands beside the content).
function S:banner(kind,title,subtitle,color,slot,height)
 local sw,sh=if slot then slot.w else 0,if slot then slot.h else 0
 if self.compact and not height then
  -- The column takes the left of the scroll holder; the scroll, its rows and the bottom fade move right of it.
  local cw=184;local inset=cw+8;local body=self.body;local holder=body.Parent
  body.Position=UDim2.fromOffset(inset,0);body.Size=UDim2.new(1,-inset,1,0);self.rowW-=inset
  local fade=holder:FindFirstChild('BottomFade')
  if fade then fade.Position=UDim2.new(0,inset,fade.Position.Y.Scale,fade.Position.Y.Offset);fade.Size=UDim2.new(1,-inset,0,fade.Size.Y.Offset) end
  local f=W.spotlightColumn(holder,'Spotlight',cw,self.bodyHeight,kind,title,subtitle,color,sh);f.Size=UDim2.new(0,cw,1,0)
  sw=math.min(sw,cw-16)
  local s=W.frame(f,'Slot',UDim2.fromOffset(sw,sh),UDim2.new(.5,-sw/2,1,-sh-10));s.BackgroundTransparency=1
  return f,s,sw
 end
 local f,x=W.spotlight(self.body,'Spotlight',height or (if self.compact then 72 else 112),kind,title,subtitle,color,if slot then sw+4 else nil)
 local s=W.frame(f,'Slot',UDim2.fromOffset(sw,sh),UDim2.new(1,-sw-14,.5,-sh/2));s.BackgroundTransparency=1
 return f,s,sw,x
end
function S:pending()
 for _,v in ipairs(self.actionButtons) do
  local busy=false
  for _,p in pairs(self.store.pending) do if p.action==v.action then busy=true;break end end
  W.enable(v.button,v.enabled and not busy and not self.deferredRender,if busy then 'Waiting…' else v.label)
 end
 if self.status and self.shade then
  -- Status strip (no board line; results toast): shown only while a request waits, timed out or a refresh is deferred.
  local message,retryId=nil,nil
  for id,p in pairs(self.store.pending) do
   if p.status=='timeout' then message='No reply yet. Retry safely with the same request.';retryId=id;break
   else message='Waiting for '..p.action..'…' end
  end
  if self.deferredRender then message='Release your touch or finish editing to refresh actions.' end
  local h=if retryId then 48 elseif message then 20 else 0
  self.status.Text=message or '';self.retry.Visible=retryId~=nil;self.retryId=retryId
  self.status.Size=UDim2.new(1,if retryId then -(88+12) else 0,1,0)
  self.statusStrip.Visible=h>0;self.statusStrip.Size=UDim2.fromOffset(self.scrollW,h);self.statusStrip.Position=UDim2.fromOffset(self.scrollX,26+self.bodyHeight-h)
  self.holder.Size=UDim2.fromOffset(self.scrollW,self.bodyHeight-h)
 end
end
-- Section-jump mode (intel §2 per-menu "Tab sync" / "Jump"; the hero is not in the scroll, P§2, so offsets 10 / 4). Content calls
-- S:section(key, frame) for the frame that starts a section; keys that are not tabs (Shop 'Free gifts', 'Coins') are jump targets only.
function S:section(key,frame,isTab)
 if isTab==nil then isTab=table.find(tabs[self.hub] or {},key)~=nil end
 self.sections[key]={frame=frame,tab=isTab==true};return frame
end
function S:sectionOffset(key)
 local s=self.sections[key];local body=self.body
 if not s or not body or not s.frame:IsDescendantOf(body) then return nil end
 return s.frame.AbsolutePosition.Y-body.AbsolutePosition.Y+body.CanvasPosition.Y
end
function S:highlight(name) for n,b in pairs(self.tabButtons) do W.setOn(b,n==name) end end
-- Landing (a section key or a restored y) is re-applied while the layout settles and dropped once the player scrolls. No tween (Motion, P6).
function S:land()
 local p,body=self.landing,self.body
 if not p or not body or not body.Parent then return end
 local y=if p.key then self:sectionOffset(p.key) else p.y
 if y then body.CanvasPosition=Vector2.new(0,math.max(0,if p.key then y-4 else y)) end
end
function S:jumpToSection(key)
 if not self.sections[key] then return false end
 self.landing={key=key};self:land();task.defer(function() self:land() end);return true
end
function S:jumpTo(name)
 if not table.find(tabs[self.hub] or {},name) then return end
 if not self.sectionMode then self.tab=name;self.detail=nil;self.page=1;self:render(false);return end
 self.tab=name;self:highlight(name);self:jumpToSection(name)
end
-- Tab sync: a tab is active once its section's offset − 10 ≤ scroll; the last tab is active at the end of the canvas.
function S:syncTab()
 local body=self.body
 if not self.sectionMode or not body or not body.Parent then return end
 local names=tabs[self.hub];local y=body.CanvasPosition.Y;local first,last,active
 for _,n in ipairs(names) do
  local s=self.sections[n]
  if s and s.tab then first=first or n;last=n;local o=self:sectionOffset(n);if o and o-10<=y then active=n end end
 end
 local canvas,window=body.AbsoluteCanvasSize.Y,body.AbsoluteWindowSize.Y
 if last and canvas>window+1 and y>=canvas-window-1 then active=last end
 active=active or first
 if active and active~=self.tab then self.tab=active;self:highlight(active) end
end
-- Side footer CTA (board .side .btn, L186: h 36, LG 16) pinned under the tabs, outside the Tabs scroll (which gives up 36 + gap 5).
function S:sideFooter(label,fn)
 local f=self.shade and self.shade:FindFirstChild('Hub')
 if not f or self.footer then return self.footer end
 local b=W.cta(f,'SideFooter',label,UDim2.fromOffset(self.sideW,36),UDim2.new(0,12,1,-12-36),fn,{n=T.t.btnSide});b.ZIndex=2
 self.tabScroll.Size-=UDim2.fromOffset(0,36+5);self.footer=b;return b
end
-- Title plate (board .ttl, L180): W.cta look h 42, padX 20, LG 23, centred on the panel's top edge (top −21). Text only.
-- Hook: the Shop hub restyles its plate in task D by replacing this call for self.hub=='Shop'.
function S:titlePlate(f,text)
 local p=W.ctaPlate(f,'TitleRibbon',text,UDim2.fromOffset(W.plateWidth(text,T.t.menuTitle,20),42),UDim2.new(.5,0,0,-21),T.t.menuTitle,20)
 p.AnchorPoint=Vector2.new(.5,0);p.ZIndex=2;p:SetAttribute('Overhang',true);return p
end
function S:tick()
 if self.deferredRender then self:render(true) end
 for _,fn in ipairs(self.tickers) do fn() end
end
function S:focusTarget(path,name)
 local target=self.shade
 for _,part in ipairs(path) do target=target and target:FindFirstChild(part) end
 return target or (name and self.shade:FindFirstChild(name,true))
end
function S:render(preserve)
 if not self.hub or not self.store.profile then return end
 local focused=UIS:GetFocusedTextBox()
 if preserve and self.shade and ((focused and focused:IsDescendantOf(self.shade)) or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or next(self.touches)~=nil) then self.deferredRender=true;self:pending();return end
 self.deferredRender=false
 local selected=GuiService.SelectedObject;local selectedName=if selected then selected.Name else nil;local selectedPath={}
 if preserve and selected and self.shade and selected:IsDescendantOf(self.shade) then
  local cursor=selected;while cursor and cursor~=self.shade do table.insert(selectedPath,1,cursor.Name);cursor=cursor.Parent end
 end
 local tabScrollPosition=if preserve and self.shade then self.shade.Hub.Tabs.CanvasPosition else Vector2.zero
 local scroll=if preserve and self.body then self.body.CanvasPosition else Vector2.zero
 if self.shade then self.shade:Destroy() end
 self.tickers={};self.actionButtons={};self.sections={};self.tabButtons={};self.landing=nil;self.footer=nil
 local data=self.store.profile;local view=self.root.AbsoluteSize
 -- Glassbloom (intel §2 panel(), L177-181): mtint backdrop (no blur; the world shows through), glass panel r22 (shop: gold glass).
 self.shade=W.frame(self.root,'HubShade',UDim2.fromScale(1,1));W.tint(self.shade,T.gradMtint);self.shade.ZIndex=20;self.shade.Active=true
 -- G14 (plan §17): board insets 24 sides / 66 top / 10 bottom up to 850×660, then that size, centred in the inset region.
 local width=math.min(850,view.X-48);local height=math.min(660,view.Y-76)
 local px=math.floor((view.X-width)/2);local py=66+math.floor((view.Y-76-height)/2)
 local shop=self.hub=='Shop'
 local f=W.glass(self.shade,'Hub',UDim2.fromOffset(width,height),UDim2.fromOffset(px,py),{radius=T.r.panel,variant=if shop then 'shop' else nil,glow=if shop then nil else T.glowGlass});f.ZIndex=21
 local title=if self.detail then 'Creature details' else self.hub
 if self.hub=='Creatures' and not self.detail then local owned={};for _,c in ipairs(data.creatures) do owned[c.species]=true end;local n=0;for _ in pairs(owned) do n+=1 end;title='Creatures '..n..'/'..#C.species end
 self:titlePlate(f,string.upper(title))
 -- X (L181): 36 circle at top −13 / right −10; the 44 hit button is centred on it. Back leaves a creature detail first.
 local back=W.closeX(f,'Back',UDim2.new(1,10-36-4,0,-13-4),function() self:back() end);back.ZIndex=3;back:SetAttribute('Overhang',true)
 local short=view.Y<390;self.compact=short
 self.sectionMode=sectionHubs[self.hub]==true and not self.detail
 -- Columns (L177-179): padding 26 top / 12 sides+bottom, side column 128, gap 12, scroll area = the rest.
 local side=128;local sx=12+side+12;local sw=width-sx-12;local sh=height-26-12
 self.sideW=side;self.scrollX=sx;self.scrollW=sw;self.bodyHeight=sh
 -- tabs() (L182-186): vertical list gap 5 in a Y scroll (a hub may hold more tabs than fit). The frame keeps a glowTabOn-blur (12)
 -- margin on every side so the on-tab glow stays inside it; its right margin ends where the scroll area starts.
 local m=T.glowTabOn.b
 local tabScroll=W.new('ScrollingFrame',f,{Name='Tabs',Size=UDim2.fromOffset(side+2*m,sh+2*m),Position=UDim2.fromOffset(12-m,26-m),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=0})
 W.padding(tabScroll,m);W.list(tabScroll,5);self.tabScroll=tabScroll
 local icons=tabIcons[self.hub] or {}
 for i,name in ipairs(tabs[self.hub]) do
  local t=W.tab(tabScroll,'Tab'..name,name,icons[name],name==self.tab,function()
   if self.sectionMode then self:jumpTo(name) else self.tab=name;self.detail=nil;self.page=1;self:render(false) end
  end)
  -- STOP 1 G1: side-tab hit areas trimmed to the 39 px pitch (full column width).
  t.LayoutOrder=i;W.hit(t,44,Vector2.new(math.huge,39));self.tabButtons[name]=t
 end
 -- Scroll area (L188-195, P§2). Normal hubs keep the 10 px gap their stacked rows rely on; section hubs use sectionHeader margins.
 local body,holder=W.scrollArea(f,'Content',UDim2.fromOffset(sw,sh),UDim2.fromOffset(sx,26))
 local layout=body:FindFirstChildOfClass('UIListLayout');if layout then layout.Padding=UDim.new(0,if self.sectionMode then 0 else 10) end
 self.body=body;self.holder=holder
 self.rowW=sw-3-10-8
 local strip=W.frame(f,'Status',UDim2.fromOffset(sw,0),UDim2.fromOffset(sx,26+sh));strip.BackgroundTransparency=1;strip.Visible=false;self.statusStrip=strip
 self.status=W.label(strip,'',UDim2.fromScale(1,1),nil,T.fontBody,T.t.small,T.lavText);self.status.Name='StatusText'
 self.retry=W.button(strip,'Retry','Retry',UDim2.fromOffset(88,44),UDim2.new(1,-88,.5,-22),function() if self.retryId then self.store:retry(self.retryId) end end,'gold');self.retry.Visible=false
 if self.hub=='Creatures' then self:creatures(data,width)
 elseif self.hub=='Discovery' then self:discovery(data)
 elseif self.hub=='Sanctuary' then self:sanctuary(data)
 elseif self.hub=='Mountain' then self:mountain(data)
 elseif self.hub=='Social' then self:social(data)
 elseif self.hub=='Profile' then self:profile(data)
 elseif self.hub=='Shop' then self:shop(data)
 elseif self.hub=='Settings' then self:settings(data) end
 if self.body~=body then return end -- content re-rendered (e.g. a missing creature detail); that render finished the frame
 -- Landing: a refresh restores the scroll; an open/probe lands on its section key or (section hubs) the current tab.
 if preserve then self.landing={y=scroll.Y}
 elseif self.landKey and self.sections[self.landKey] then self.landing={key=self.landKey}
 elseif self.sectionMode and self.tab~=tabs[self.hub][1] and self.sections[self.tab] then self.landing={key=self.tab} end
 self.landKey=nil
 local function settle() self:land();self:syncTab() end
 body:GetPropertyChangedSignal('AbsoluteCanvasSize'):Connect(settle);body:GetPropertyChangedSignal('CanvasPosition'):Connect(function() self:syncTab() end)
 local function scrolled() self.landing=nil end
 body.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then scrolled() end end)
 body.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseWheel then scrolled() end end)
 body.SelectionChanged:Connect(scrolled)
 self:land();task.defer(settle)
 tabScroll.CanvasPosition=tabScrollPosition;self:pending();self:tick()
 if UIS.GamepadEnabled and UIS:GetLastInputType()==Enum.UserInputType.Gamepad1 then
  local target=nil
  if preserve and #selectedPath>0 then target=self:focusTarget(selectedPath,selectedName) end
  GuiService.SelectedObject=if target and target:IsA('GuiButton') and target.Selectable then target else f.Back
 end
end
local black=Color3.new(0,0,0)
local center=Enum.TextXAlignment.Center
local function inset(self,name,height) return W.panel(self.body,name,UDim2.new(1,-8,0,height),nil,T.navy) end
function S:creatures(data,width)
 if self.detail then
  local c=R.find(data.creatures,self.detail);if not c then self.detail=nil;self:render(false);return end
  local info=P.creature(c);local species=C.byId[c.species]
  -- Hero (cc/03 Knight card): big rarity portrait + level badge, LuckiestGuy name, tag chips, stat cells.
  local h=if self.compact then 150 else 186
  local hero=inset(self,'Hero',h)
  local art=h-24
  W.portrait(hero,species,UDim2.fromOffset(art,art),UDim2.fromOffset(12,12))
  local badge=W.label(hero,'Lv '..c.level,UDim2.fromOffset(52,24),UDim2.fromOffset(16,16),T.display,15,T.ink,center);badge.Name='Level';badge.BackgroundTransparency=0;badge.BackgroundColor3=T.navy;W.round(badge,7);W.stroke(badge,T.outline,2)
  local statsW=math.min(300,math.floor(self.rowW*.40));local infoX=art+26;local infoW=self.rowW-infoX-statsW-24
  W.label(hero,string.upper(info.name),UDim2.fromOffset(infoW,36),UDim2.fromOffset(infoX,10),T.title,30,T.ink).Name='Name'
  local chipW=math.floor((infoW-12)/3)
  W.chip(hero,species.rarity,T.rarity[species.rarity],UDim2.fromOffset(chipW,22),UDim2.fromOffset(infoX,52))
  W.chip(hero,species.element,T.alt,UDim2.fromOffset(chipW,22),UDim2.fromOffset(infoX+chipW+6,52))
  W.chip(hero,species.role,T.tert,UDim2.fromOffset(chipW,22),UDim2.fromOffset(infoX+2*(chipW+6),52))
  local feature=W.label(hero,species.feature,UDim2.fromOffset(infoW,h-92),UDim2.fromOffset(infoX,82),nil,13,T.muted,nil,true);feature.TextYAlignment=Enum.TextYAlignment.Top
  local cellW=math.floor((statsW-8)/2);local cellH=math.floor((h-32)/2)
  local sx=self.rowW-statsW-12
  W.stat(hero,'Bat','Attack',math.floor(info.attack),cellW,cellH,UDim2.fromOffset(sx,12))
  W.stat(hero,'Heart','Health',math.floor(info.health),cellW,cellH,UDim2.fromOffset(sx+cellW+8,12))
  W.stat(hero,'Scroll','XP',if info.xpRequired>0 then c.xp..'/'..info.xpRequired else 'MAX',cellW,cellH,UDim2.fromOffset(sx,20+cellH))
  W.stat(hero,'EggCracked','Stage',R.stage(c.level)..' / 3',cellW,cellH,UDim2.fromOffset(sx+cellW+8,20+cellH))
  -- Evolution journey (robloxf1-v2/16 node track).
  local evo=inset(self,'Evolution',88)
  W.label(evo,'EVOLUTION',UDim2.new(.26,-14,0,24),UDim2.fromOffset(14,10),T.label,20,T.ink).Name='Title'
  W.label(evo,'Evolves automatically at each level.',UDim2.new(.26,-14,1,-44),UDim2.fromOffset(14,36),nil,12,T.muted,nil,true)
  W.track(evo,{'Stage I · Lv 1','Stage II · Lv 15','Focus · Lv 25','Stage III · Lv 35'},{c.level>=1,c.level>=15,c.level>=25,c.level>=35},UDim2.new(.74,-12,0,72),UDim2.new(.26,0,0,8),T.panelPurple)
  -- Specials + training side by side (cc/05 ability slots, robloxf1-v2/14 UPGRADE).
  local g,cw=self:grid('SpecialsTraining',2,260,132)
  local abilities=info.abilityNames or {species.role..' special'}
  local sp=W.card(g,'Specials',nil,nil,T.tert,'Manual specials');sp.LayoutOrder=1
  local chipW2=math.floor((cw-30)/2)
  for i,a in ipairs(abilities) do if i<=4 then W.chip(sp,a,T.navy,UDim2.fromOffset(chipW2,26),UDim2.fromOffset(10+((i-1)%2)*(chipW2+10),38+math.floor((i-1)/2)*32)) end end
  W.label(sp,'Basic attacks run automatically.',UDim2.new(1,-20,0,18),UDim2.new(0,10,1,-26),nil,12,T.ink)
  local at=data.ui and data.ui.atRefuge
  local train=W.card(g,'Training',nil,nil,T.alt,'Training session');train.LayoutOrder=2
  local pw=math.floor((cw-36)/2)
  W.pill(train,'Coin','15',pw,26,UDim2.fromOffset(14,40))
  W.pill(train,'Scroll','+80 XP',pw,26,UDim2.fromOffset(cw-14-pw,40))
  if at then self:action(train,'Train','Train · 15 coins','Train',c.id,data.coins>=15 and c.level<50,UDim2.new(0,12,1,-54),UDim2.new(1,-24,0,44),'gold')
  else
   self:action(train,'Train','Train · 15 coins','Train',c.id,false,UDim2.new(0,12,1,-54),UDim2.new(.5,-18,0,44),'gold')
   W.label(train,'Visit the training station on your plot or the refuge.',UDim2.new(.5,-18,0,44),UDim2.new(.5,6,1,-54),nil,12,T.ink,nil,true)
  end
  if c.specialization then self:info('Gem','Specialization · '..c.specialization,c.specialization..' is your permanent focus.',64)
  elseif c.level>=25 then
   local fg=self:grid('Focus',3,180,132)
   for i,v in ipairs({{'Power','Bat','Attack +20%'},{'Guard','Padlock','15% defense'},{'Vitality','Heart','Health +25%'}}) do
    local card=W.card(fg,'Focus_'..v[1],nil,nil,T.cta.base,v[1]);card.LayoutOrder=i
    W.icon(card,v[2],UDim2.fromOffset(36,36),UDim2.fromOffset(12,34))
    W.label(card,v[3],UDim2.new(1,-66,0,30),UDim2.fromOffset(54,37),T.display,17,T.ink)
    W.button(card,'Focus'..v[1],'Choose '..v[1],UDim2.new(1,-20,0,44),UDim2.new(0,10,1,-54),function()
     self.feedback:confirm('Choose '..v[1]..'?',species.name..' will keep this specialization permanently.',function() self:send('Specialize',{id=c.id,choice=v[1]}) end)
    end,'gold')
   end
  else self:info('Padlock','Specialization unlocks at Lv 25','Choose Power, Guard or Vitality when this creature reaches level 25.',64) end
  return
 end
 local compact=self.compact
 if self.tab=='Team' then
  -- Team strip (layout E slots): three portrait slots + save.
  local h=if compact then 80 else 112
  local team=inset(self,'TeamStrip',h)
  local art=h-20;local saveW=170
  for i=1,3 do local id=self.selected[i];local c=id and R.find(data.creatures,id);W.slot(team,c and C.byId[c.species],UDim2.fromOffset(art,art),UDim2.fromOffset(10+(i-1)*(art+10),10)).Name='TeamSlot'..i end
  local tx=10+3*(art+10)+6
  W.label(team,'YOUR EXPEDITION TEAM',UDim2.new(1,-tx-saveW-24,0,26),UDim2.fromOffset(tx,10),T.label,20,T.ink).Name='Title'
  W.label(team,'Tap Select on up to three cards, then save. '..#self.selected..' / 3 selected.',UDim2.new(1,-tx-saveW-24,1,-46),UDim2.fromOffset(tx,38),nil,13,T.muted,nil,true)
  self:action(team,'Equip','Save team ('..#self.selected..'/3)','Equip',function() return table.clone(self.selected) end,#self.selected>0,UDim2.new(1,-saveW-12,.5,-24),UDim2.fromOffset(saveW,44),'gold')
 elseif self.tab=='Training' then
  local _,slot,sw=self:banner('Creature','Grow your team','Train on your plot or at the refuge. Open a creature for its stats.',T.alt,{w=138,h=72})
  W.pill(slot,'Coin','15 coins',sw-4,28,UDim2.fromOffset(4,4));W.pill(slot,'Scroll','+80 XP',sw-4,28,UDim2.fromOffset(4,40))
 elseif self.tab=='Evolution' then
  if compact then self:banner('EggCracked','A journey, not a purchase','Stage II at Lv 15, focus at Lv 25, Stage III at Lv 35. Open a creature for its timeline.',T.panelPurple)
  else
   local b,_,_,x=self:banner('EggCracked','A journey, not a purchase',nil,T.panelPurple,nil,112)
   W.track(b,{'Lv 1','Lv 15','Focus 25','Lv 35'},{true,false,false,false},UDim2.new(1,-x-12,0,56),UDim2.new(0,x,1,-60),T.bar.max)
  end
 end
 local filters=W.panel(self.body,'Filters',UDim2.new(1,-8,0,56),nil,T.navy)
 local box=W.round(W.new('TextBox',filters,{Name='Search',Size=UDim2.new(.45,-12,0,44),Position=UDim2.fromOffset(6,6),Text=self.query,PlaceholderText='Search your creatures',ClearTextOnFocus=false,TextColor3=T.ink,PlaceholderColor3=T.muted,BackgroundColor3=T.outline,Font=T.body,TextSize=T.size(15),TextTruncate=Enum.TextTruncate.AtEnd,BorderSizePixel=0}),8)
 box.FocusLost:Connect(function() self.query=box.Text;self.page=1;self:render(false) end)
 local rarities={'All','Common','Uncommon','Rare','Epic','Mythic','Legendary'}
 W.button(filters,'Rarity','Rarity: '..self.rarity,UDim2.new(.3,-6,0,44),UDim2.new(.45,0,0,6),function() self.rarity=rarities[(table.find(rarities,self.rarity) or 1)%#rarities+1];self.page=1;self:render(false) end,'quiet')
 W.button(filters,'Sort','Sort: '..self.sort,UDim2.new(.25,-12,0,44),UDim2.new(.75,0,0,6),function() self.sort=if self.sort=='Name' then 'Level' elseif self.sort=='Level' then 'Rarity' else 'Name';self:render(true) end,'quiet')
 local list=P.filterCreatures(data,self.query,self.rarity,self.sort)
 if #list==0 then self:info('Egg','No matching companions','Try another filter, or discover eggs on your next climb. Your collection stays safe.',72);return end
 local cardHeight=if compact then 156 else 210
 local shown=math.min(12,#list-(self.page-1)*12)
 local grid=self:grid('CreatureGrid',shown,150,cardHeight)
 for index=(self.page-1)*12+1,math.min(#list,self.page*12) do
  local c=list[index];local s=C.byId[c.species];local card=W.panel(grid,'Creature_'..c.id,nil,nil,T.rarity[s.rarity]);card.LayoutOrder=index
  -- Mock 3 card: level badge top-left, portrait, XP bar with n/max, darker name band (colour = rarity).
  card.UIGradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(190,200,225))
  local art=if compact then 52 else 84
  W.portrait(card,s,UDim2.fromOffset(art,art),UDim2.new(.5,-art/2,0,6))
  local badge=W.label(card,tostring(c.level),UDim2.fromOffset(26,26),UDim2.fromOffset(6,6),T.display,14,T.ink,center);badge.Name='Level';badge.BackgroundColor3=T.navy;badge.BackgroundTransparency=0
  W.new('UICorner',badge,{CornerRadius=UDim.new(0,7)});W.stroke(badge,T.outline,2)
  local info=P.creature(c);local barY=art+10
  local maxed=info.xpRequired<=0
  local bar=W.progress(card,if maxed then 1 else c.xp/info.xpRequired,UDim2.new(1,-24,0,14),UDim2.fromOffset(12,barY),if maxed then T.bar.max else T.bar.fill)
  local xp=W.label(bar.Parent,if maxed then 'MAX' else c.xp..'/'..info.xpRequired,UDim2.fromScale(1,1),nil,T.display,11,T.ink,center);xp.ZIndex=2
  local band=W.frame(card,'NameBand',UDim2.new(1,-6,0,if compact then 22 else 26),UDim2.fromOffset(3,barY+18),T.rarity[s.rarity]:Lerp(black,.3))
  W.label(band,string.upper(s.name),UDim2.new(1,-8,1,0),UDim2.fromOffset(4,0),T.label,if compact then 16 else 19,T.ink,center).Name='Name'
  if not compact then W.label(card,s.rarity,UDim2.new(1,-16,0,16),UDim2.fromOffset(8,barY+48),T.display,12,T.ink,center).Name='Tier' end
  local selected=table.find(self.selected,c.id)
  local label=if self.tab=='Team' then (if selected then 'Selected '..selected else 'Select') else 'Details'
  W.button(card,'Details_'..c.id,label,UDim2.new(1,-20,0,44),UDim2.new(0,10,1,-52),function()
   if self.tab=='Team' then
    local n=table.find(self.selected,c.id)
    if n then table.remove(self.selected,n) elseif #self.selected<3 then table.insert(self.selected,c.id) else self.feedback:toast('Your team has three slots. Deselect one first.') end
   else self.detail=c.id end
   self:render(self.tab=='Team')
  end,if selected and self.tab=='Team' then 'gold' else 'blue')
 end
 if #list>12 then
  local pages=W.frame(self.body,'Pages',UDim2.new(1,-8,0,50));pages.BackgroundTransparency=1
  W.button(pages,'Previous','Previous',UDim2.new(.5,-8,0,44),nil,function() self.page=math.max(1,self.page-1);self:render(false) end,'quiet',self.page>1)
  W.button(pages,'Next','Next',UDim2.new(.5,-8,0,44),UDim2.new(.5,8,0,0),function() self.page+=1;self:render(false) end,'quiet',self.page*12<#list)
 end
end
function S:discovery(data)
 local compact=self.compact
 if self.tab=='Field guide' then
  local owned={};for _,c in ipairs(data.creatures) do owned[c.species]=true end
  local total=0;for _ in pairs(owned) do total+=1 end
  self:banner('Creature','Field guide',total..' / '..#C.species..' species discovered. Look for nests, wild encounters, puzzles and exploration branches.',T.panelPurple)
  local g=self:grid('Kingdoms',#C.kingdoms,170,if compact then 150 else 176)
  for k,kingdom in ipairs(C.kingdoms) do
   local found=0;for _,s in ipairs(C.species) do if s.kingdom==k and owned[s.id] then found+=1 end end
   -- Collection card (finale-f1/03 n/max bar): gold when the kingdom set is complete.
   local card=W.card(g,'Kingdom_'..k,nil,nil,if found>=6 then T.cta.base else T.alt,kingdom.name);card.LayoutOrder=k
   local a=if compact then 54 else 74
   W.icon(card,if found>0 then 'Creature' else 'Egg',UDim2.fromOffset(a,a),UDim2.new(.5,-a/2,0,32))
   local bar=W.progress(card,found/6,UDim2.new(1,-24,0,16),UDim2.new(0,12,1,-46),if found>=6 then T.bar.max else T.bar.fill)
   W.label(bar.Parent,found..' / 6',UDim2.fromScale(1,1),nil,T.display,12,T.ink,Enum.TextXAlignment.Center).ZIndex=2
   W.label(card,kingdom.element..' · '..kingdom.resource,UDim2.new(1,-16,0,18),UDim2.new(0,8,1,-26),T.display,12,T.ink,Enum.TextXAlignment.Center)
  end;return
 end
 local active=0;for _,e in ipairs(data.eggs) do if e.readyAt then active+=1 end end
 -- Incubator banner (robloxf1-v2/18 streak strip): three incubator slots light up when in use.
 local slotW=if compact then 46 else 58
 local _,b=self:banner('Egg','Eggs & incubation',#data.eggs..' secured · '..active..' / 3 incubating. Incubation and hatching are free at home.',T.panelPurple,{w=3*slotW+12,h=slotW})
 for i=1,3 do
  local slot=W.round(W.frame(b,'Incubator'..i,UDim2.fromOffset(slotW,slotW),UDim2.fromOffset((i-1)*(slotW+6),0),if i<=active then T.cta.base else T.navy),10);W.stroke(slot,T.outline,2)
  W.icon(slot,if i<=active then 'EggCracked' else 'Egg',UDim2.new(1,-10,1,-10),UDim2.fromOffset(5,5))
  if i>active then slot.IconEgg.BackgroundTransparency=1;for _,o in ipairs(slot.IconEgg:GetDescendants()) do if o:IsA('ImageLabel') then o.ImageTransparency=.6 end end end
 end
 if #data.cargo+#data.eggs==0 then self:info('Map','Your next companion is out there','Climb into any section. Break a visible egg, pick up the creature and escape through the sanctuary exit.',72);return end
 local n=#data.cargo+#data.eggs
 local g=self:grid('Eggs',n,160,if compact then 176 else 200)
 local order=0
 for _,e in ipairs(data.cargo) do
  order+=1;local species=C.byId[e.species]
  local card=W.card(g,'Cargo_'..e.id,nil,nil,T.rarity[species.rarity],species.name..' egg');card.LayoutOrder=order
  W.icon(card,'Egg',UDim2.fromOffset(56,56),UDim2.new(.5,-28,0,34))
  W.chip(card,'Unsecured',T.no.base,UDim2.new(1,-24,0,22),UDim2.new(0,12,0,94))
  W.label(card,'Carry to a checkpoint. A fall drops a recoverable pack for 3 minutes.',UDim2.new(1,-20,1,-126),UDim2.fromOffset(10,120),nil,12,T.ink,Enum.TextXAlignment.Center,true)
 end
 for _,e in ipairs(data.eggs) do
  order+=1;local species=C.byId[e.species]
  local card=W.card(g,'Egg_'..e.id..'_Card',nil,nil,T.rarity[species.rarity],species.name..' egg');card.LayoutOrder=order
  local a=if compact then 50 else 66
  W.icon(card,if e.readyAt then 'EggCracked' else 'Egg',UDim2.fromOffset(a,a),UDim2.new(.5,-a/2,0,32))
  W.chip(card,species.rarity,T.navy,UDim2.new(1,-40,0,20),UDim2.new(0,20,0,34+a))
  local timer=W.label(card,'',UDim2.new(1,-16,0,18),UDim2.new(0,8,1,-72),T.display,13,T.ink,Enum.TextXAlignment.Center)
  local at=data.ui and data.ui.atRefuge
  local btn=self:action(card,'Egg_'..e.id,if e.readyAt then 'Hatch free' else 'Incubate free',if e.readyAt then 'Hatch' else 'Incubate',e.id,at and (if e.readyAt then e.readyAt<=self.store:now() else active<3),UDim2.new(0,10,1,-52),UDim2.new(1,-20,0,44),if e.readyAt then 'ok' else 'gold')
  table.insert(self.tickers,function()
   local remain=if e.readyAt then P.remaining(e.readyAt,self.store:now()) else nil
   timer.Text=if remain then (if remain==0 then 'Ready to hatch' else P.formatTime(remain)..' left') else P.formatTime(C.incubation[species.rarity])..' incubation'
   if not at then timer.Text..=' · at your plot' end
   for _,v in ipairs(self.actionButtons) do if v.button==btn then v.enabled=at and (if remain then remain==0 else active<3) end end
  end)
 end
end
function S:sanctuary(data) TycoonHub.render(self,data) end
function S:mountain(data)
 local compact=self.compact
 if self.tab=='Quests' then
  -- Objective card (layout quest card + robloxf1-v2/16 weekly track).
  local q=P.quest(data)
  local card=self:info('Scroll',q.title,q.detail,if compact then 84 else 92)
  local bar=W.progress(card,q.progress/math.max(q.total,1),UDim2.new(1,-90,0,14),UDim2.new(0,76,1,-20),T.bar.ready)
  W.label(bar.Parent,q.progress..' / '..q.total,UDim2.fromScale(1,1),nil,T.display,11,T.ink,Enum.TextXAlignment.Center).ZIndex=2
  card.Description.Size=UDim2.new(1,-90,1,-62)
  local track=W.panel(self.body,'GuardianTrack',UDim2.new(1,-8,0,96),nil,T.navy)
  W.label(track,'KINGDOM GUARDIANS',UDim2.new(1,-24,0,22),UDim2.fromOffset(14,6),T.label,19,T.ink).Name='Title'
  local labels,done={},{};for k,kingdom in ipairs(C.kingdoms) do labels[k]=kingdom.name:match('^%S+');done[k]=data.wins[tostring(k)]==true end
  W.track(track,labels,done,UDim2.new(1,-24,0,62),UDim2.fromOffset(12,30))
  self:blocked('Daily missions','Daily objectives and claimable rewards are not connected yet.','Daily rewards unavailable','Calendar')
 elseif self.tab=='Trials' then
  -- Guardian cards (robloxf1-v2/06 tier frames): gold = captured, purple = trial ready, grey = locked.
  local g=self:grid('Trials',#C.guardians,170,if compact then 176 else 212)
  for k,gd in ipairs(C.guardians) do
   local owned=data.captures[gd.id];local won=data.wins[tostring(k)]
   local card=W.card(g,'Guardian_'..k,nil,nil,if owned then T.cta.base elseif won then T.panelPurple else T.off,gd.name);card.LayoutOrder=k
   local a=if compact then 56 else 78
   W.portrait(card,{kingdom=k,shape=gd.shape,rarity='Legendary'},UDim2.fromOffset(a,a),UDim2.new(.5,-a/2,0,34))
   W.chip(card,if owned then 'Captured' elseif won then 'Trial ready' else 'Locked',if owned then T.ok.base elseif won then T.cta.base else T.navy,UDim2.new(1,-30,0,22),UDim2.new(0,15,0,40+a))
   local req='3 clean dodges + 4 patterns'..(if k==5 then ' + golden heart' elseif k==6 then ' + three star stones' else '')
   W.label(card,if owned then gd.title elseif won then 'At the kingdom altar · '..req else 'Defeat the normal Guardian first',UDim2.new(1,-16,1,-(72+a)),UDim2.fromOffset(8,66+a),nil,12,T.ink,Enum.TextXAlignment.Center,true)
  end
 else
  local _,slot,sw=self:banner('Map','Six open sections','Walk into any section. Fast travel uses discovered rest points.',T.alt,{w=184,h=44})
  self:action(slot,'ReturnRefuge','Return to sanctuary','Travel','refuge',data.ui and (data.ui.atRefuge or data.ui.nearCheckpoint),UDim2.new(),UDim2.fromOffset(sw,44),'gold')
  -- Route rows: number badge, name, status chip + resource pill, three travel stops.
  local h=if compact then 66 else 76
  for k,kingdom in ipairs(C.kingdoms) do
   local unlocked=R.canEnter(data,k);local won=data.wins[tostring(k)]
   local row=W.card(self.body,'Kingdom_'..k,UDim2.new(1,-8,0,h),nil,if won then T.cta.base else T.alt);row.LayoutOrder=k+1
   local num=W.round(W.frame(row,'Number',UDim2.fromOffset(36,36),UDim2.new(0,10,.5,-18),T.navy),18);W.stroke(num,T.outline,2)
   W.label(num,tostring(k),UDim2.fromScale(1,1),nil,T.display,20,T.ink,Enum.TextXAlignment.Center)
   local leftW=math.floor(self.rowW*.46)-56
   W.label(row,string.upper(kingdom.name),UDim2.fromOffset(leftW,24),UDim2.fromOffset(56,7),T.label,20,T.ink).Name='Name'
   local half=math.floor((leftW-8)/2)
   W.chip(row,if won then 'Guardian defeated' else 'Open',if won then T.ok.base else T.navy,UDim2.fromOffset(half,22),UDim2.new(0,56,1,-30))
   W.pill(row,'Gem',(data.resources[tostring(k)] or 0)..(if half>=110 then ' '..kingdom.resource:match('%S+$') else ''),half,22,UDim2.new(0,56+half+10,1,-30))
   local bx=math.floor(self.rowW*.46);local bw=math.floor((self.rowW-bx-12-16)/3)
   for i,point in ipairs({'entrance','recovery','guardian'}) do
    local id=k..':'..point;local found=data.discoveries[id]==true
    self:action(row,'Travel_'..k..'_'..point,if found then point:gsub('^%l',string.upper) else 'Undiscovered','Travel',id,unlocked and found and data.ui and (data.ui.atRefuge or data.ui.nearCheckpoint),UDim2.new(0,bx+(i-1)*(bw+8),.5,-24),UDim2.fromOffset(bw,44))
   end
  end
 end
end
function S:social(data)
 local compact=self.compact
 if self.tab=='Party' then
  local battle=self.store.battle
  self:banner('Social','Climb together','Friends can join the same Guardian at its altar while the encounter is open. Teammates attack automatically.',T.alt)
  if battle and battle.members then
   local g=self:grid('Members',#battle.members,170,if compact then 120 else 140)
   for i,m in ipairs(battle.members) do
    local card=W.card(g,'Member_'..i,nil,nil,T.alt,m.name or tostring(m.userId));card.LayoutOrder=i
    if m.userId then local a=if compact then 48 else 64;local img=W.new('ImageLabel',card,{Name='Avatar',Size=UDim2.fromOffset(a,a),Position=UDim2.new(.5,-a/2,0,34),BackgroundColor3=T.navy,Image='rbxthumb://type=AvatarHeadShot&id='..m.userId..'&w=150&h=150'});W.round(img,a/2);W.stroke(img,T.outline,2) end
    W.label(card,'In your Guardian encounter',UDim2.new(1,-16,0,18),UDim2.new(0,8,1,-24),nil,12,T.ink,Enum.TextXAlignment.Center)
   end
  else self:info('Map','No active co-op encounter','Meet other climbers at a Guardian altar to battle together.',64) end
  self:blocked('Party finder & invitations','Persistent parties and invitations are not connected. No invitations are sent from here.','Invitations unavailable')
 elseif self.tab=='Defense' then
  -- Defense strip: your equipped team as three slots + register (layout E slots).
  local h=if compact then 96 else 116
  local strip=W.panel(self.body,'DefenseTeam',UDim2.new(1,-8,0,h),nil,T.navy)
  local art=h-30;local regW=180
  for i=1,3 do
   local id=data.team[i];local c=id and R.find(data.creatures,id)
   W.slot(strip,c and C.byId[c.species],UDim2.fromOffset(art,art),UDim2.fromOffset(10+(i-1)*(art+10),8)).Name='DefenseSlot'..i
   W.label(strip,if c then 'Lv '..c.level else 'Empty',UDim2.fromOffset(art,16),UDim2.fromOffset(10+(i-1)*(art+10),h-20),T.display,12,T.ink,Enum.TextXAlignment.Center)
  end
  local tx=10+3*(art+10)+6
  W.label(strip,'YOUR TEAM IS YOUR DEFENSE',UDim2.new(1,-tx-regW-24,0,26),UDim2.fromOffset(tx,10),T.label,20,T.ink).Name='Title'
  W.label(strip,'Register a snapshot for asynchronous challenges. Creatures and eggs cannot be stolen. UserId '..Players.LocalPlayer.UserId,UDim2.new(1,-tx-regW-24,1,-46),UDim2.fromOffset(tx,38),nil,12,T.muted,nil,true)
  self:action(strip,'RegisterDefense','Register defense','RegisterDefense',nil,data.ui and data.ui.atRefuge,UDim2.new(1,-regW-12,.5,-24),UDim2.fromOffset(regW,44),'gold')
  self:blocked('Sanctuary defense layout','Raid defense buildings are not available yet. Team registration is above.')
 else
  local _,slot,sw=self:banner('Bat','Sanctuary challenges','Challenge a saved defense. Opponents can be offline; practice is separate.',T.panelPurple,{w=138,h=30})
  W.pill(slot,nil,data.trophies..' trophies',sw,30,UDim2.new())
  local f=W.panel(self.body,'ChallengeDefense',UDim2.new(1,-8,0,if compact then 92 else 100),nil,T.navy)
  W.label(f,'CHALLENGE A DEFENSE',UDim2.new(.4,-14,0,24),UDim2.fromOffset(14,8),T.label,20,T.ink).Name='Title'
  W.label(f,'Enter a numeric UserId. 0 = practice defense.',UDim2.new(.4,-14,0,30),UDim2.fromOffset(14,34),nil,12,T.muted,nil,true)
  local timer=W.label(f,'',UDim2.new(.4,-14,0,18),UDim2.new(0,14,1,-24),T.display,13,T.gold)
  local box=W.round(W.new('TextBox',f,{Name='OpponentId',Size=UDim2.new(.36,-10,0,44),Position=UDim2.new(.4,0,.5,-22),Text=self.opponent or '',PlaceholderText='Player UserId (0 = practice)',ClearTextOnFocus=false,TextColor3=T.ink,PlaceholderColor3=T.muted,BackgroundColor3=T.outline,Font=T.body,TextSize=T.size(15),TextTruncate=Enum.TextTruncate.AtEnd,BorderSizePixel=0}),8)
  box.FocusLost:Connect(function() self.opponent=box.Text;if self.deferredRender then task.defer(function() self:render(true) end) end end)
  self:action(f,'ChallengeDefense','Challenge','ChallengeDefense',function() self.opponent=box.Text;return tonumber(box.Text) end,data.ui and data.ui.atRefuge,UDim2.new(.76,0,.5,-24),UDim2.new(.24,-12,0,44),'gold')
  table.insert(self.tickers,function() local n=P.remaining(data.competitionAt,self.store:now());timer.Text=if n>0 then 'Next challenge in '..P.formatTime(n) else 'Ready at refuge' end)
  self:blocked('Raids & friend challenges','Live raids and friend matchmaking are not connected. Saved defense challenges use the server rules.','Live raids unavailable')
 end
end
function S:profile(data)
 local compact=self.compact
 local captures,wins=0,0;for _ in pairs(data.captures) do captures+=1 end;for _ in pairs(data.wins) do wins+=1 end
 if self.tab=='Overview' then
  -- Player card (robloxf1-v2/22): avatar card + big stat cells.
  local h=if compact then 150 else 190
  local card=W.panel(self.body,'PlayerCard',UDim2.new(1,-8,0,h),nil,T.navy)
  local a=h-20
  local frame=W.card(card,'Avatar',UDim2.fromOffset(a,a),UDim2.fromOffset(10,10),T.alt)
  W.new('ImageLabel',frame,{Name='Headshot',Size=UDim2.new(1,-12,1,-36),Position=UDim2.fromOffset(6,6),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Image='rbxthumb://type=AvatarHeadShot&id='..Players.LocalPlayer.UserId..'&w=150&h=150'})
  local band=W.round(W.frame(frame,'NameBand',UDim2.new(1,-8,0,24),UDim2.new(0,4,1,-28),T.navy),8)
  W.label(band,'@'..Players.LocalPlayer.Name,UDim2.new(1,-8,1,0),UDim2.fromOffset(4,0),T.display,13,T.ink,Enum.TextXAlignment.Center)
  local x=a+22;local w=self.rowW-x-10
  W.label(card,string.upper(Players.LocalPlayer.DisplayName),UDim2.fromOffset(w,34),UDim2.fromOffset(x,8),T.title,30,T.ink).Name='Name'
  local cw=math.floor((w-24)/4);local ch=h-60
  for i,v in ipairs({{'Creature','Creatures',#data.creatures},{'Bat','Guardians',wins..' / 6'},{'Gem','Captures',captures..' / 6'},{'Gift','Trophies',data.trophies}}) do
   W.stat(card,v[1],v[2],v[3],cw,math.min(ch,64),UDim2.fromOffset(x+(i-1)*(cw+8),48))
  end
  local track=W.panel(self.body,'ExpeditionTrack',UDim2.new(1,-8,0,96),nil,T.navy)
  W.label(track,'EXPEDITION RECORD',UDim2.new(.6,-14,0,22),UDim2.fromOffset(14,6),T.label,19,T.ink).Name='Title'
  W.chip(track,if data.discoveries.summit then 'Sovereign Explorer' else 'Summit in progress',if data.discoveries.summit then T.cta.base else T.alt,UDim2.fromOffset(170,22),UDim2.new(1,-184,0,6))
  local labels,done={},{};for k,kingdom in ipairs(C.kingdoms) do labels[k]=kingdom.name:match('^%S+');done[k]=data.wins[tostring(k)]==true end
  table.insert(labels,'Summit');table.insert(done,data.discoveries.summit==true)
  W.track(track,labels,done,UDim2.new(1,-24,0,62),UDim2.fromOffset(12,30),T.bar.max)
 elseif self.tab=='Achievements' then
  -- Medal cards (robloxf1-v2/05 badge tiers): gold = both earned, blue = one, grey = none.
  local g=self:grid('Medals',#C.guardians+1,150,if compact then 168 else 196)
  for k,gd in ipairs(C.guardians) do
   local won=data.wins[tostring(k)]==true;local cap=data.captures[gd.id]~=nil
   local card=W.card(g,'Medal_'..k,nil,nil,if won and cap then T.cta.base elseif won or cap then T.alt else T.off,gd.name);card.LayoutOrder=k
   local a=if compact then 52 else 72
   W.portrait(card,{kingdom=k,shape=gd.shape,rarity='Legendary'},UDim2.fromOffset(a,a),UDim2.new(.5,-a/2,0,32))
   W.chip(card,(if won then '✓ ' else '')..'Victory',if won then T.ok.base else T.navy,UDim2.new(.5,-12,0,22),UDim2.new(0,8,0,38+a))
   W.chip(card,(if cap then '✓ ' else '')..'Capture',if cap then T.ok.base else T.navy,UDim2.new(.5,-12,0,22),UDim2.new(.5,4,0,38+a))
   W.label(card,gd.title,UDim2.new(1,-16,1,-(74+a)),UDim2.fromOffset(8,66+a),nil,12,T.ink,Enum.TextXAlignment.Center,true)
  end
  local summit=data.discoveries.summit==true
  local card=W.card(g,'Medal_Summit',nil,nil,if summit then T.cta.base else T.off,'Sovereign Explorer');card.LayoutOrder=99
  local a=if compact then 52 else 72
  W.icon(card,'Map',UDim2.fromOffset(a,a),UDim2.new(.5,-a/2,0,32))
  W.chip(card,if summit then '✓ Summit reached' else 'Summit',if summit then T.ok.base else T.navy,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,38+a))
  W.label(card,if summit then 'The crown is yours' else 'Defeat Caeloryn and reach the summit',UDim2.new(1,-16,1,-(74+a)),UDim2.fromOffset(8,66+a),nil,12,T.ink,Enum.TextXAlignment.Center,true)
 else
  self:banner('Gift',data.trophies..' trophies','Earned in the mountain and challenge systems. Captures and summit achievements appear in your profile.',T.panelPurple)
  self:blocked('Leaderboards & rankings','A ranking service is not connected. No sample players or invented ranks are shown.','Rankings unavailable')
  self:blocked('Badges & equipped titles','Badge awards and title selection need platform services. Milestones stay in Achievements.','Titles unavailable')
 end
end
function S:shop(data)
 local compact=self.compact
 if self.tab=='Bats' then
  -- Featured offer banner (finale-f1/01 SPECIAL OFFER, purple) with the coin pill (intel §4).
  local _,slot,sw=self:banner('Bat','Bats','Knock a carried creature loose for 3 s. No hits in the sanctuary or at rest points.',T.panelPurple,{w=138,h=40})
  W.pill(slot,'Coin',tostring(data.coins or 0),sw-4,30,UDim2.fromOffset(4,5))
  local bats=(data.ui and data.ui.bats) or {}
  -- Offer cards (robloxf1-v2/07): equipped = gold "VIP" card, owned = blue, locked = grey with padlock.
  local cardH=if compact then 160 else 214
  local g,cw=self:grid('BatCards',#bats,200,cardH)
  for i,bat in ipairs(bats) do
   local card=W.card(g,'Bat_'..bat.id,nil,nil,if bat.equipped then T.cta.base elseif bat.owned then T.alt else T.off,bat.name);card.LayoutOrder=i
   local a=if compact then 50 else 84
   local art=W.round(W.frame(card,'Art',UDim2.fromOffset(a+12,a+12),UDim2.new(1,-a-22,0,34),T.navy),12);W.stroke(art,T.outline,2)
   W.icon(art,'Bat',UDim2.fromOffset(a,a),UDim2.fromOffset(6,6))
   local sideW=math.min(96,cw-a-40)
   if bat.owned then
    local lv=W.label(card,'Lv '..bat.level,UDim2.fromOffset(sideW,24),UDim2.fromOffset(10,36),T.display,14,T.ink,Enum.TextXAlignment.Center);lv.BackgroundTransparency=0;lv.BackgroundColor3=T.navy;W.round(lv,6);W.stroke(lv,T.outline,1.5)
    if compact then
     W.pill(card,nil,'Power '..bat.knockback,sideW,20,UDim2.fromOffset(10,62))
     W.pill(card,nil,'Reach '..bat.reach,sideW,20,UDim2.fromOffset(10,84))
    else
     if bat.equipped then W.chip(card,'Equipped',T.ok.base,UDim2.fromOffset(sideW,22),UDim2.fromOffset(10,66)) end
     local pw=math.floor((cw-30)/2)
     W.pill(card,nil,'Power '..bat.knockback,pw,22,UDim2.new(0,10,1,-80))
     W.pill(card,nil,'Reach '..bat.reach,pw,22,UDim2.new(0,20+pw,1,-80))
    end
    local half=UDim2.new(.5,-14,0,44)
    self:action(card,'Equip_'..bat.id,if bat.equipped then 'Equipped' else 'Equip','Bat',{op='equip',id=bat.id},not bat.equipped,UDim2.new(0,10,1,-52),half,'blue')
    self:action(card,'Upgrade_'..bat.id,if bat.cost then bat.cost..' coins' else 'Max level','Bat',{op='upgrade',id=bat.id},bat.equipped and bat.cost~=nil and (data.coins or 0)>=bat.cost,UDim2.new(.5,4,1,-52),half,'gold')
   else
    W.icon(card,'Padlock',UDim2.fromOffset(34,34),UDim2.fromOffset(10+math.floor((sideW-34)/2),34))
    W.chip(card,'Locked',T.navy,UDim2.fromOffset(sideW,22),UDim2.fromOffset(10,72))
    local kingdom=C.kingdoms[bat.kingdom]
    local bar=W.progress(card,if bat.total>0 then bat.have/bat.total else 0,UDim2.new(1,-24,0,18),UDim2.new(0,12,1,-62),T.bar.fill)
    W.label(bar.Parent,bat.have..' / '..bat.total,UDim2.fromScale(1,1),nil,T.display,12,T.ink,Enum.TextXAlignment.Center).ZIndex=2
    W.label(card,if kingdom then 'Complete the '..kingdom.name..' index set' else 'Complete an index set',UDim2.new(1,-16,0,30),UDim2.new(0,8,1,-38),nil,12,T.ink,Enum.TextXAlignment.Center,true)
   end
  end
 elseif self.tab=='Cosmetics' then
  local _,slot,sw=self:banner('Gift','Free palettes','Your unlocked kingdom palettes are free. Personalize habitat trim and machines at your plot.',T.panelPurple,{w=168,h=70})
  W.chip(slot,'Free',T.ok.base,UDim2.fromOffset(80,22),UDim2.new(.5,-40,0,0))
  W.button(slot,'FreePalettes','Open palettes',UDim2.fromOffset(sw,44),UDim2.fromOffset(0,26),function() self:open('Sanctuary');self.tab='Cosmetics';self:render(false) end,'gold')
  self:info('Chest','Make the mountain yours','Appearances, decorations and visual effects. Your combat strength always comes from play.',64)
  self:blocked('Cosmetic collection','No approved product catalog is connected. Items and prices appear when available.','Checkout unavailable')
 else
  self:banner('Chest','Fair conveniences','Only noncompetitive convenience belongs here.',T.alt)
  -- Promise tiles (cc/05 perk tiles).
  local g=self:grid('Promises',3,180,if compact then 92 else 108)
  for i,v in ipairs({{'Egg','True odds','Odds shown are the odds used'},{'Bat','No power','Strength comes from play'},{'Creature','Fair play','Robux creatures never battle or raid'}}) do
   local card=W.card(g,'Promise'..i,nil,nil,T.navy);card.LayoutOrder=i
   local a=if compact then 48 else 60
   W.icon(card,v[1],UDim2.fromOffset(a,a),UDim2.new(0,10,.5,-a/2))
   W.label(card,string.upper(v[2]),UDim2.new(1,-a-28,0,24),UDim2.new(0,a+18,.5,-24),T.label,19,T.ink).Name='Title'
   W.label(card,v[3],UDim2.new(1,-a-28,.5,-6),UDim2.new(0,a+18,.5,2),nil,12,T.muted,nil,true).TextYAlignment=Enum.TextYAlignment.Top
  end
  self:blocked('Convenience catalog','No approved convenience products or receipt validation are connected.','Checkout unavailable')
 end
end
function S:settings(data)
 local prefs=(data.ui and data.ui.settings) or {}
 local compact=self.compact
 -- Settings tiles: icon, name + one line, ON/OFF candy (cc2/05 ON/OFF pill; finale-f1/01 YES green).
 local icons={largeText='Scroll',highContrast='Gem',reducedMotion='Sprint',simplifiedVFX='Gift',hints='Map',musicVolume='Heart',sfxVolume='Bat'}
 local function grid(n) return self:grid('SettingsGrid',n,300,if compact then 70 else 78) end
 local function tile(g,i,key,title,description)
  local card=W.card(g,'Tile_'..key,nil,nil,T.navy);card.LayoutOrder=i
  W.icon(card,icons[key],UDim2.fromOffset(40,40),UDim2.new(0,10,.5,-20))
  W.label(card,title,UDim2.new(1,-180,0,22),UDim2.fromOffset(58,8),T.bold,16).Name='Title'
  local d=W.label(card,description,UDim2.new(1,-180,1,-36),UDim2.fromOffset(58,31),nil,12,T.muted,nil,true);d.TextYAlignment=Enum.TextYAlignment.Top
  return card
 end
 local function toggles(list)
  local g=grid(#list)
  for i,v in ipairs(list) do
   local card=tile(g,i,v[1],v[2],v[3]);local on=prefs[v[1]]==true
   self:action(card,'Setting_'..v[1],if on then 'On' else 'Off','Settings',function() return {[v[1]]=not prefs[v[1]]} end,true,UDim2.new(1,-112,.5,-24),UDim2.fromOffset(100,44),if on then 'ok' else 'quiet')
  end
 end
 if self.tab=='Audio' then
  local g=grid(2)
  for i,v in ipairs({{'musicVolume','Music & ambience'},{'sfxVolume','Sound effects'}}) do
   local key,title=v[1],v[2];local value=prefs[key] or 0
   local card=tile(g,i,key,title,'')
   -- Slider (cc2/05 gauge): bar.fill on a navy track.
   local bar=W.progress(card,value,UDim2.new(1,-190,0,14),UDim2.new(0,58,1,-26),T.bar.fill)
   W.label(bar.Parent,math.floor(value*100)..'%',UDim2.fromScale(1,1),nil,T.display,11,T.ink,Enum.TextXAlignment.Center).ZIndex=2
   self:action(card,'Volume_'..key,'Adjust','Settings',function() return {[key]=if value>=1 then 0 else math.min(1,value+.25)} end,true,UDim2.new(1,-112,.5,-24),UDim2.fromOffset(100,44))
  end
 elseif self.tab=='Quick' then
  toggles({{'reducedMotion','Reduced motion','Keep feedback still; no cinematic movement.'},{'hints','Contextual hints','Short guidance, never a mandatory slideshow.'},{'simplifiedVFX','Simplified effects','Fewer decorative particles; encounter cues stay.'}})
 else
  toggles({{'largeText','Larger text','Larger menu labels and descriptions.'},{'highContrast','High contrast','Opaque panels and brighter outlines.'},{'reducedMotion','Reduced motion','Less UI animation and camera feedback.'},{'simplifiedVFX','Simplified effects','Fewer decorative effects; danger stays visible.'},{'hints','Contextual hints','Short, nonblocking expedition guidance.'}})
 end
 self:info('Gear','Preference storage',data.saveMode or 'Preferences follow your profile save status.',60)
end
return S
