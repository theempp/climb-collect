local T=require(script.Parent.Theme)
local W={}
function W.new(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parent;return o
end
function W.round(o,r) W.new('UICorner',o,{CornerRadius=UDim.new(0,r or 14)});return o end
function W.stroke(o,color,thickness)
 local base=thickness or 1
 local stroke=W.new('UIStroke',o,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=color or T.outline,Thickness=if T.prefs.highContrast then math.max(2,base) else base,Transparency=0,LineJoinMode=Enum.LineJoinMode.Round})
 stroke:SetAttribute('BaseThickness',base);return stroke
end
function W.frame(parent,name,size,pos,color)
 return W.new('Frame',parent,{Name=name,Size=size or UDim2.fromScale(1,1),Position=pos or UDim2.new(),BackgroundColor3=color or T.panel,BorderSizePixel=0})
end
-- Panel (intel §4): panel.blue body, ink outline, soft top-light gradient. Purple is for reward moments.
function W.panel(parent,name,size,pos,color)
 local o=W.round(W.frame(parent,name,size,pos,color),14);W.stroke(o,T.outline,3)
 W.new('UIGradient',o,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(214,224,244)),Rotation=90})
 return o
end
-- Light text gets the ink text stroke (intel §3: about 13 % of the text size).
function W.textStroke(label,n,color)
 local c=label.TextColor3;if (c.R+c.G+c.B)/3<.55 then return end
 local s=W.new('UIStroke',label,{ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual,Color=color or T.outline,Thickness=math.max(1,math.floor((n or 15)*.13+.5)),LineJoinMode=Enum.LineJoinMode.Round})
 s:SetAttribute('BaseThickness',s.Thickness);return s
end
function W.text(parent,content,size,pos,font,n,color)
 local label=W.new('TextLabel',parent,{Name='Text',Size=size or UDim2.new(1,0,0,26),Position=pos or UDim2.new(),BackgroundTransparency=1,Text=tostring(content),TextColor3=color or T.ink,Font=font or T.body,TextSize=T.size(n or 15),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,RichText=false})
 label:SetAttribute('BaseTextSize',n or 15);W.textStroke(label,n)
 return label
end
-- Candy button (intel §2): ink outline, darker lip slab, gradient face, light rim, highlight band + gloss, slanted Bangers label.
-- The TextButton itself is the lip; its Text is mirrored into Label so callers keep setting b.Text / b.BackgroundColor3.
local black=Color3.new(0,0,0)
local function candyColors(base)
 if base==T.cta.base or base==T.gold then return T.cta.base,T.cta.shade,T.cta.lip,T.cta.ink end
 if base==T.ok.base then return base,base:Lerp(black,.12),T.ok.lip,T.outline end
 if base==T.no.base then return base,base:Lerp(black,.12),T.no.lip,T.outline end
 return base,base:Lerp(black,.16),base:Lerp(black,.42),T.outline
end
local function paint(b)
 local face,shade,lip,ink=candyColors(b:GetAttribute('FaceColor'))
 b:SetAttribute('Painting',true);b.BackgroundColor3=lip;b:SetAttribute('Painting',false)
 local f=b:FindFirstChild('Face');if f then f.UIGradient.Color=ColorSequence.new(face,shade);f.Rim.BackgroundColor3=face:Lerp(Color3.new(1,1,1),.35) end
 local stroke=b:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=ink end
 local label=b:FindFirstChild('Label');if label then label.UIStroke.Color=ink end
end
function W.candy(b,base)
 b.BackgroundTransparency=0;b.TextTransparency=1;b.AutoButtonColor=false;b:SetAttribute('FaceColor',base)
 local radius=b:FindFirstChildOfClass('UICorner').CornerRadius
 W.stroke(b,T.outline,2.5)
 local face=W.new('UICorner',W.frame(b,'Face',UDim2.new(1,0,1,-5),nil,Color3.new(1,1,1)),{CornerRadius=radius}).Parent;face.ZIndex=0
 W.new('UIGradient',face,{Rotation=90})
 local rim=W.round(W.frame(face,'Rim',UDim2.new(1,-12,0,2),UDim2.new(0,6,1,-3)),1);rim.BackgroundTransparency=.35;rim.ZIndex=0
 local shine=W.new('UICorner',W.frame(face,'Shine',UDim2.new(1,-8,.42,0),UDim2.fromOffset(4,3),Color3.new(1,1,1)),{CornerRadius=radius}).Parent;shine.ZIndex=0
 W.new('UIGradient',shine,{Rotation=90,Transparency=NumberSequence.new(.5,.92)})
 local gloss=W.round(W.frame(face,'Gloss',UDim2.fromOffset(8,5),UDim2.new(1,-17,0,5),Color3.new(1,1,1)),3);gloss.BackgroundTransparency=.2;gloss.ZIndex=0
 local label=W.new('TextLabel',b,{Name='Label',Size=UDim2.new(1,-10,1,-5),Position=UDim2.fromOffset(5,0),BackgroundTransparency=1,Text=b.Text,TextColor3=T.ink,Font=T.label,TextSize=b.TextSize+3,TextWrapped=true,TextScaled=true})
 -- Labels shrink (never spill) when a button is narrower than its text.
 local cap=W.new('UITextSizeConstraint',label,{MaxTextSize=b.TextSize+3,MinTextSize=9})
 W.new('UIStroke',label,{ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual,Color=T.outline,Thickness=2,LineJoinMode=Enum.LineJoinMode.Round}):SetAttribute('BaseThickness',2)
 local function fit()
  local h=b.AbsoluteSize.Y;if h<=0 then return end
  local lip=math.clamp(math.floor(h*.14+.5),3,8);local down=if b:GetAttribute('Pressed') then lip else 0
  face.Size=UDim2.new(1,0,1,-lip);face.Position=UDim2.fromOffset(0,down)
  label.Size=UDim2.new(1,-10,1,-lip);label.Position=UDim2.fromOffset(5,down)
 end
 b:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
 b:GetPropertyChangedSignal('Text'):Connect(function() label.Text=b.Text end)
 b:GetPropertyChangedSignal('TextSize'):Connect(function() label.TextSize=b.TextSize+3;cap.MaxTextSize=b.TextSize+3 end)
 b:GetPropertyChangedSignal('TextTransparency'):Connect(function() if b.TextTransparency~=1 then b.TextTransparency=1 end end)
 b:GetPropertyChangedSignal('BackgroundColor3'):Connect(function() if not b:GetAttribute('Painting') then b:SetAttribute('FaceColor',b.BackgroundColor3);paint(b) end end)
 local function press(i,on) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then b:SetAttribute('Pressed',on and b:GetAttribute('Enabled')~=false);fit() end end
 b.InputBegan:Connect(function(i) press(i,true) end);b.InputEnded:Connect(function(i) press(i,false) end)
 b.MouseLeave:Connect(function() b:SetAttribute('Pressed',false);fit() end)
 paint(b);fit();return b
end
function W.button(parent,name,label,size,pos,fn,variant,enabled)
 local isEnabled=enabled~=false
 local color=if variant=='gold' then T.cta.base elseif variant=='quiet' then T.navy elseif variant=='danger' then T.no.base elseif variant=='ok' then T.ok.base elseif variant=='close' then T.close elseif variant=='tert' then T.tert else T.alt
 local b=W.round(W.new('TextButton',parent,{Name=name,Size=size or UDim2.new(1,0,0,44),Position=pos or UDim2.new(),BackgroundColor3=color,BorderSizePixel=0,Text=label,TextColor3=T.ink,TextSize=T.size(14),Font=T.label,TextWrapped=true,AutoButtonColor=false,Active=isEnabled,Selectable=isEnabled}),10)
 b:SetAttribute('ButtonColor',color);b:SetAttribute('ButtonInk',T.ink)
 b:SetAttribute('QAControl',true);b:SetAttribute('Enabled',isEnabled)
 b:SetAttribute('BaseTextSize',14)
 W.candy(b,color);if not isEnabled then W.enable(b,false) end
 b.Activated:Connect(function() if b:GetAttribute('Enabled') and fn then fn() end end)
 return b
end
-- Disabled = off.base face, no highlight (intel §2 states).
function W.enable(b,on,label)
 b:SetAttribute('Enabled',on);b.Active=on;b.Selectable=on;b.AutoButtonColor=false
 b.BackgroundColor3=if on then b:GetAttribute('ButtonColor') or T.alt else T.off
 local face=b:FindFirstChild('Face');if face then face.Shine.Visible=on;face.Gloss.Visible=on end
 if label then b.Text=label end
end
function W.padding(o,n) return W.new('UIPadding',o,{PaddingTop=UDim.new(0,n),PaddingBottom=UDim.new(0,n),PaddingLeft=UDim.new(0,n),PaddingRight=UDim.new(0,n)}) end
function W.list(parent,gap,horizontal)
 return W.new('UIListLayout',parent,{Padding=UDim.new(0,gap or 10),FillDirection=if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder})
end
function W.scroll(parent,name,size,pos)
 local s=W.new('ScrollingFrame',parent,{Name=name,Size=size,Position=pos or UDim2.new(),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=T.sky,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
 W.padding(s,4);W.list(s,10);return s
end
function W.row(parent,title,description,height,color)
 local f=W.panel(parent,(title:gsub('[^%w]','')),UDim2.new(1,-8,0,height or 112),nil,color or T.card)
 W.text(f,title,UDim2.new(1,-28,0,28),UDim2.fromOffset(14,10),T.bold,16).Name='Title'
 local desc=W.text(f,description,UDim2.new(1,-28,0,(height or 112)-52),UDim2.fromOffset(14,42),nil,14,T.muted);desc.Name='Description';desc.TextYAlignment=Enum.TextYAlignment.Top
 local accent=W.round(W.frame(f,'Accent',UDim2.new(0,4,1,-28),UDim2.fromOffset(0,14),T.sky),3)
 return f
end
-- Bar (intel §1/§4): navy track with ink outline, bar.fill / bar.ready / bar.max fills.
function W.progress(parent,value,size,pos,color)
 local track=W.frame(parent,'Progress',size,pos,T.navy);W.new('UICorner',track,{CornerRadius=UDim.new(.5,0)});W.stroke(track,T.outline,1.5)
 local fill=W.frame(track,'Fill',UDim2.fromScale(math.clamp(value or 0,0,1),1),nil,color or T.bar.fill);W.new('UICorner',fill,{CornerRadius=UDim.new(.5,0)})
 W.new('UIGradient',fill,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(205,215,230)),Rotation=90})
 return fill
end
-- Notification dot (intel §4): 18 px circle over the top-right corner; alert red or ready green.
function W.dot(parent,count,ready)
 local d=parent:FindFirstChild('Dot') or W.frame(parent,'Dot',UDim2.fromOffset(18,18),UDim2.new(1,-12,0,-6))
 d.ZIndex=4;d.BackgroundColor3=if ready then T.readyDot else T.alertDot
 if not d:FindFirstChildOfClass('UICorner') then W.new('UICorner',d,{CornerRadius=UDim.new(.5,0)});W.stroke(d,Color3.new(1,1,1),2);local t=W.text(d,'',UDim2.fromScale(1,1),nil,T.display,11);t.Name='Count';t.ZIndex=5;t.TextXAlignment=Enum.TextXAlignment.Center end
 d.Count.Text=if count and count>0 then tostring(count) else '';d.Visible=count~=nil and count~=0
 return d
end
function W.tag(parent,label,pos,color)
 local f=W.frame(parent,'Tag',UDim2.fromOffset(100,24),pos,color or T.navy);W.new('UICorner',f,{CornerRadius=UDim.new(.5,0)});W.stroke(f,T.outline,1.5)
 local t=W.text(f,label,UDim2.fromScale(1,1),nil,T.bold,11);t.TextXAlignment=Enum.TextXAlignment.Center
 return f
end
-- Approved illustrated icons (Theme.icons ids); vector art below is the fallback while an id is 0.
local iconFor={Creatures='creature',Discovery='egg',Mountain='map',Sanctuary='heart',Shop='chest',Profile='scroll',Social='bat',Settings='gear',Coin='coin',Gem='gem',Interact='climb',Bat='bat',Sprint='sprint',Jump='jump',Egg='egg',EggCracked='egg-cracked',Gift='gift',Calendar='calendar',Padlock='padlock',Chest='chest',Map='map',Scroll='scroll',Heart='heart',Gear='gear',Creature='creature',Climb='climb'}
function W.icon(parent,kind,size,pos)
 local f=W.frame(parent,'Icon'..kind,size,pos);f.BackgroundTransparency=1
 local id=T.icons[iconFor[kind] or '']
 if id and id~=0 then W.new('ImageLabel',f,{Name='Image',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=if type(id)=='string' then id else 'rbxassetid://'..id,ScaleType=Enum.ScaleType.Fit});return f end
 local function shape(name,x,y,w,h,color,round,rotation)
  local p=W.round(W.frame(f,name,UDim2.fromScale(w,h),UDim2.fromScale(x,y),color),round or 4)
  p.Rotation=rotation or 0;return p
 end
 local gold=T.gold;local white=T.ink;local blue=T.sky
 if kind=='Creatures' then
  shape('EarL',.16,.12,.25,.42,blue,7,-24);shape('EarR',.59,.12,.25,.42,blue,7,24)
  local face=shape('Face',.16,.30,.68,.58,blue,18);W.stroke(face,T.navy,2)
  for _,x in ipairs({.31,.59}) do shape('Eye',x,.48,.12,.20,T.navy,20);shape('EyeLight',x+.02,.49,.04,.06,white,20) end
  shape('Muzzle',.40,.70,.20,.09,white,10)
 elseif kind=='Discovery' then
  local egg=shape('Egg',.24,.08,.53,.80,white,100);W.stroke(egg,T.navy,2)
  shape('Spot',.31,.31,.14,.18,T.purple,20,-25);shape('Spot',.58,.48,.13,.19,blue,20,20);shape('Spot',.37,.67,.15,.12,T.green,20)
 elseif kind=='Mountain' then
  shape('Peak',.20,.30,.48,.48,white,3,45);shape('Peak',.50,.45,.34,.34,blue,3,45)
  shape('MountainBase',.10,.65,.80,.24,T.line,4)
 elseif kind=='Sanctuary' then
  shape('Roof',.25,.12,.50,.50,T.green,4,45);shape('House',.21,.43,.60,.44,gold,6);shape('Door',.43,.59,.18,.29,T.navy,4)
 elseif kind=='Shop' then
  shape('Handle',.35,.12,.30,.31,gold,10);shape('Inner',.42,.19,.16,.25,T.navy,5)
  local bag=shape('Bag',.17,.34,.66,.53,Color3.fromRGB(255,162,42),8);W.stroke(bag,T.navy,2)
  shape('Belt',.18,.56,.64,.12,gold,2);shape('Buckle',.44,.51,.14,.24,white,3)
 elseif kind=='Profile' then
  shape('Medal',.25,.22,.50,.50,gold,100);shape('Ribbon',.26,.63,.19,.28,T.blue,3,18);shape('Ribbon',.55,.63,.19,.28,T.blue,3,-18)
  local star=W.text(f,'★',UDim2.fromScale(.5,.5),UDim2.fromScale(.25,.20),T.bold,24,T.navy);star.TextScaled=true;star.TextXAlignment=Enum.TextXAlignment.Center
 elseif kind=='Social' then
  for _,x in ipairs({.12,.56}) do shape('Head',x+.04,.17,.24,.27,blue,100);shape('Body',x,.49,.33,.34,T.purple,10) end
 elseif kind=='Settings' then
  for i=0,7 do shape('Cog',.39,.06,.22,.88,T.line,3,i*45) end
  shape('Gear',.20,.20,.60,.60,white,100);shape('Center',.37,.37,.26,.26,T.navy,100)
 elseif kind=='Menu' then
  for i=0,2 do shape('Bar',.18,.23+i*.23,.64,.10,white,4) end
 elseif kind=='Coin' then
  local coin=shape('Coin',.13,.13,.74,.74,gold,100);W.stroke(coin,Color3.fromRGB(255,239,160),2)
  shape('Shine',.30,.28,.12,.33,white,4,20);shape('Stamp',.52,.33,.12,.34,Color3.fromRGB(213,126,21),4)
 elseif kind=='Interact' then
  shape('Palm',.27,.39,.48,.45,white,10)
  for i=0,3 do shape('Finger',.27+i*.12,.10+math.abs(i-1.5)*.06,.10,.47,white,6) end
  shape('Thumb',.12,.43,.17,.32,white,6,-35)
 end
 return f
end
-- Icon tile (intel §4): candy face in the hub colour, illustrated icon, caption inside the tile.
function W.tile(parent,name,label,kind,size,pos,fn,color)
 local b=W.button(parent,name,'',size,pos,fn,'quiet');b:SetAttribute('ButtonColor',color or T.alt);b.BackgroundColor3=color or T.alt
 local icon=W.icon(b,kind,UDim2.fromOffset(42,42),UDim2.new(.5,-21,0,3))
 local caption=W.text(b,string.upper(label),UDim2.new(1,-6,0,22),UDim2.new(0,3,1,-25),T.label,14)
 caption.TextScaled=true;W.new('UITextSizeConstraint',caption,{MaxTextSize=14,MinTextSize=8})
 caption.TextXAlignment=Enum.TextXAlignment.Center
 return b
end
function W.portrait(parent,species,size,pos)
 local C=require(game.ReplicatedStorage.MountainShared.Catalog)
 local accent=Color3.fromRGB(table.unpack(C.kingdoms[species.kingdom].accent))
 local color=if species.kingdom==1 and species.shape=='rabbit' then T.green elseif species.kingdom==1 and species.shape=='fox' then T.gold else accent
 -- Rarity card fill (owner decision: creature cards coloured by rarity); prismatic tiers get the rainbow rim gradient.
 local f=W.round(W.frame(parent,'Portrait',size,pos,T.rarity[species.rarity] or T.alt),12);W.stroke(f,T.outline,2)
 if T.prismatic[species.rarity] then W.new('UIGradient',f,{Rotation=45,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,95,160)),ColorSequenceKeypoint.new(.35,Color3.fromRGB(255,201,60)),ColorSequenceKeypoint.new(.7,Color3.fromRGB(79,216,240)),ColorSequenceKeypoint.new(1,Color3.fromRGB(154,92,240))})}) end
 -- Species silhouette badge stays legible even before 3D world streaming completes.
 local halo=W.round(W.frame(f,'Medallion',UDim2.fromScale(.70,.70),UDim2.fromScale(.15,.15),Color3.new(1,1,1)),100)
 halo.BackgroundTransparency=.7
 local shape=species.shape
 local tall=shape=='rabbit';local wing=shape=='moth' or shape=='bird'
 if shape=='deer' then
  for _,x in ipairs({.25,.67}) do
   local antler=W.round(W.frame(f,'Antler',UDim2.fromScale(.09,.34),UDim2.fromScale(x,.06),T.gold),3);antler.Rotation=if x<.5 then -18 else 18
   local branch=W.round(W.frame(f,'AntlerBranch',UDim2.fromScale(.20,.07),UDim2.fromScale(x-.05,.15),T.gold),3);branch.Rotation=if x<.5 then 32 else -32
  end
 end
 for _,x in ipairs({.24,.59}) do
  local ear=W.round(W.frame(f,'Silhouette',UDim2.fromScale(if wing then .28 else .19,if tall then .38 else .25),UDim2.fromScale(x,if tall then .08 else .16),color),8)
  ear.Rotation=if x<.4 then -20 else 20
  local inner=W.round(W.frame(ear,'InnerEar',UDim2.fromScale(.45,.7),UDim2.fromScale(.28,.12),color:Lerp(T.ink,.55)),5)
 end
 local face=W.round(W.frame(f,'Face',UDim2.fromScale(.64,.52),UDim2.fromScale(.18,.31),color),18);W.stroke(face,color:Lerp(T.ink,.5),1)
 W.new('UIGradient',face,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(150,186,212)),Rotation=90})
 for _,x in ipairs({.22,.62}) do
  local eye=W.round(W.frame(face,'Eye',UDim2.fromScale(.17,.33),UDim2.fromScale(x,.26),T.navy),20)
  W.round(W.frame(eye,'Glint',UDim2.fromScale(.38,.36),UDim2.fromScale(.17,.12),T.ink),20)
 end
 W.round(W.frame(face,'Muzzle',UDim2.fromScale(.30,.18),UDim2.fromScale(.35,.66),color:Lerp(T.ink,.75)),20)
 local nose=W.round(W.frame(face,'Nose',UDim2.fromScale(.11,.10),UDim2.fromScale(.45,.59),T.navy),5)
 local rarity=W.round(W.frame(f,'Rarity',UDim2.fromScale(.10,.10),UDim2.fromScale(.82,.08),T.rarity[species.rarity]),3);rarity.Rotation=45
 return f
end
function W.mountain(parent)
 local f=W.frame(parent,'MountainMark',UDim2.fromScale(1,1));f.BackgroundTransparency=1;f.ClipsDescendants=true
 for i,v in ipairs({{.24,.57,.34,T.panel},{.51,.54,.45,T.card},{.70,.68,.26,T.blue}}) do
  local p=W.frame(f,'Peak'..i,UDim2.fromScale(v[3],v[3]*1.5),UDim2.fromScale(v[1],v[2]),v[4]);p.AnchorPoint=Vector2.new(.5,.5);p.Rotation=45
 end
 local star=W.text(f,'✦',UDim2.fromOffset(42,42),UDim2.fromScale(.49,.16),T.display,34,T.gold);star.AnchorPoint=Vector2.new(.5,.5)
 return f
end
-- Hub kit (Review03). Values trace to design/hud-v2-intel.md §1–§4 and the cited pins.
local center=Enum.TextXAlignment.Center
-- Text that shrinks to its box instead of spilling (single line unless wrap).
function W.fit(label,max,min,wrap)
 label.TextScaled=true;label.TextWrapped=wrap==true
 W.new('UITextSizeConstraint',label,{MaxTextSize=T.size(max),MinTextSize=min or 8});return label
end
function W.label(parent,content,size,pos,font,n,color,align,wrap)
 local t=W.fit(W.text(parent,content,size,pos,font,n,color),n or 15,8,wrap);t.TextXAlignment=align or Enum.TextXAlignment.Left;return t
end
-- Offer/feature card (robloxf1-v2/07 boxes, finale-f1/01 shop tiles, cc/05 upgrade tiles): colour face, ink outline,
-- top-light gradient (as the creature cards), panel.navy header strip with a Bangers title.
function W.card(parent,name,size,pos,color,title)
 local f=W.round(W.frame(parent,name,size,pos,color or T.alt),12);W.stroke(f,T.outline,3)
 W.new('UIGradient',f,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(190,200,225)),Rotation=90})
 if title then
  local band=W.round(W.frame(f,'Header',UDim2.new(1,-10,0,24),UDim2.fromOffset(5,5),T.navy),8)
  local t=W.label(band,string.upper(title),UDim2.new(1,-10,1,-2),UDim2.fromOffset(5,1),T.label,18,T.ink,center);t.Name='Title'
 end
 return f
end
-- Tag ribbon (robloxf1-v2/07 GUARANTEED / HIGH CHANCE strips).
function W.chip(parent,label,color,size,pos)
 local c=color or T.cta.base
 local f=W.round(W.frame(parent,'Chip',size or UDim2.fromOffset(96,20),pos,c),6);W.stroke(f,T.outline,1.5)
 local t=W.label(f,string.upper(label),UDim2.new(1,-8,1,0),UDim2.fromOffset(4,0),T.label,15,T.ink,center);t.Name='Label'
 if c==T.cta.base then t.UIStroke.Color=T.cta.ink end
 return f
end
-- Value pill (intel §4 currency pill): panel.navy pill, illustrated icon ~1.25x the pill height over the left end, white number.
function W.pill(parent,kind,value,w,h,pos)
 local f=W.frame(parent,'Pill',UDim2.fromOffset(w,h),pos,T.navy);W.new('UICorner',f,{CornerRadius=UDim.new(.5,0)});W.stroke(f,T.outline,1.5)
 local x=8
 if kind then local a=math.floor(h*1.25);local i=W.icon(f,kind,UDim2.fromOffset(a,a),UDim2.fromOffset(-2,math.floor((h-a)/2)));i:SetAttribute('Overhang',true);x=a end
 local t=W.label(f,tostring(value),UDim2.new(1,-x-8,1,-2),UDim2.fromOffset(x,1),T.display,h-6,T.ink,center);t.Name='Value'
 return f
end
-- Stat cell (cc/03, robloxf1-v2/19 stat rows): light panel.row cell, icon, small caps name over a dark value.
function W.stat(parent,kind,name,value,w,h,pos)
 local f=W.round(W.frame(parent,'Stat_'..name:gsub('[^%w]',''),UDim2.fromOffset(w,h),pos,T.row),8);W.stroke(f,T.outline,1.5)
 local x=8;if kind then local a=math.min(h-10,40,math.floor(w*.28));W.icon(f,kind,UDim2.fromOffset(a,a),UDim2.fromOffset(5,math.floor((h-a)/2)));x=a+10 end
 W.label(f,string.upper(name),UDim2.new(1,-x-6,.4,-2),UDim2.fromOffset(x,3),T.display,12,T.alt).Name='Name'
 W.label(f,tostring(value),UDim2.new(1,-x-6,.6,-4),UDim2.new(0,x,.4,1),T.display,20,T.textDark).Name='Value'
 return f
end
-- Spotlight banner (finale-f1/01 SPECIAL OFFER, robloxf1-v2/02 rays, cc/05 hero header): big illustrated icon on a ray
-- burst, LuckiestGuy title, short line. Purple = reward/rare moments; alt blue elsewhere. `reserve` keeps the right side for a CTA.
function W.spotlight(parent,name,height,kind,title,subtitle,color,reserve)
 local f=W.round(W.frame(parent,name,UDim2.new(1,-8,0,height),nil,color or T.alt),14);W.stroke(f,T.outline,3);f.ClipsDescendants=true
 W.new('UIGradient',f,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(190,200,225)),Rotation=90})
 local art=height-14
 local burst=W.frame(f,'Burst',UDim2.fromOffset(art*2.4,art*2.4),UDim2.fromOffset(7+art/2,height/2));burst.AnchorPoint=Vector2.new(.5,.5);burst.BackgroundTransparency=1;burst:SetAttribute('Decor',true)
 for i=0,5 do local ray=W.frame(burst,'Ray',UDim2.new(0,math.floor(art*.3),1,0),UDim2.fromScale(.5,.5),Color3.new(1,1,1));ray.AnchorPoint=Vector2.new(.5,.5);ray.Rotation=i*30;ray.BackgroundTransparency=.88 end
 local glow=W.round(W.frame(f,'Glow',UDim2.fromOffset(art,art),UDim2.fromOffset(7,7),Color3.new(1,1,1)),100);glow.BackgroundTransparency=.82
 W.icon(f,kind,UDim2.fromOffset(art-6,art-6),UDim2.fromOffset(10,10))
 local x=art+20;local r=(reserve or 0)+12
 W.label(f,string.upper(title),UDim2.new(1,-x-r,0,math.floor(height*.40)),UDim2.fromOffset(x,6),T.title,32,T.ink).Name='Title'
 if subtitle then local d=W.label(f,subtitle,UDim2.new(1,-x-r,1,-math.floor(height*.40)-12),UDim2.fromOffset(x,math.floor(height*.40)+6),T.body,14,T.ink,nil,true);d.Name='Subtitle';d.TextYAlignment=Enum.TextYAlignment.Top end
 return f,x
end
-- Hero column (short phones): the same spotlight stood upright beside the content at full height, so the cards next to
-- it keep their full height. Art + rays on top, LuckiestGuy title, short line; `slotH` px at the bottom for the CTA.
function W.spotlightColumn(parent,name,w,h,kind,title,subtitle,color,slotH)
 local f=W.round(W.frame(parent,name,UDim2.fromOffset(w,h),nil,color or T.alt),14);W.stroke(f,T.outline,3);f.ClipsDescendants=true
 W.new('UIGradient',f,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(190,200,225)),Rotation=90})
 local art=math.min(56,math.floor(h*.3))
 local burst=W.frame(f,'Burst',UDim2.fromOffset(art*2.4,art*2.4),UDim2.fromOffset(w/2,8+art/2));burst.AnchorPoint=Vector2.new(.5,.5);burst.BackgroundTransparency=1;burst:SetAttribute('Decor',true)
 for i=0,5 do local ray=W.frame(burst,'Ray',UDim2.new(0,math.floor(art*.3),1,0),UDim2.fromScale(.5,.5),Color3.new(1,1,1));ray.AnchorPoint=Vector2.new(.5,.5);ray.Rotation=i*30;ray.BackgroundTransparency=.88 end
 local glow=W.round(W.frame(f,'Glow',UDim2.fromOffset(art,art),UDim2.fromOffset(w/2-art/2,8),Color3.new(1,1,1)),100);glow.BackgroundTransparency=.82
 W.icon(f,kind,UDim2.fromOffset(art-6,art-6),UDim2.fromOffset(w/2-art/2+3,11))
 local y=art+12;local free=h-y-(slotH or 0)-14
 W.label(f,string.upper(title),UDim2.new(1,-16,0,math.min(40,free)),UDim2.fromOffset(8,y),T.title,22,T.ink,center,true).Name='Title'
 if subtitle and free-44>=26 then local d=W.label(f,subtitle,UDim2.new(1,-16,0,free-44),UDim2.fromOffset(8,y+44),T.body,12,T.ink,center,true);d.Name='Subtitle';d.TextYAlignment=Enum.TextYAlignment.Top end
 return f
end
-- Milestone track (robloxf1-v2/16 check nodes, cc2/05 node bar): nodes sit at cell centres so captions never leave the track.
function W.track(parent,labels,done,size,pos,color)
 local f=W.frame(parent,'Track',size,pos);f.BackgroundTransparency=1
 local n=#labels;local last=0;for i=1,n do if done[i] then last=i end end
 local bar=W.frame(f,'Bar',UDim2.new(1-1/n,0,0,8),UDim2.new(.5/n,0,0,11),T.navy);W.new('UICorner',bar,{CornerRadius=UDim.new(.5,0)});W.stroke(bar,T.outline,1.5)
 local fill=W.frame(bar,'Fill',UDim2.fromScale(if n>1 then math.max(0,last-1)/(n-1) else 1,1),nil,color or T.bar.ready);W.new('UICorner',fill,{CornerRadius=UDim.new(.5,0)})
 for i,l in ipairs(labels) do
  local x=(i-.5)/n
  local node=W.frame(f,'Node'..i,UDim2.fromOffset(28,28),UDim2.new(x,-14,0,1),if done[i] then T.readyDot else T.navy);W.new('UICorner',node,{CornerRadius=UDim.new(.5,0)});W.stroke(node,if done[i] then Color3.new(1,1,1) else T.outline,2)
  W.label(node,if done[i] then '✓' else tostring(i),UDim2.fromScale(1,1),nil,T.display,16,T.ink,center)
  W.label(f,l,UDim2.new(1/n,-4,1,-32),UDim2.new((i-1)/n,2,0,32),T.display,13,T.ink,center,true).Name='Caption'..i
 end
 return f
end
-- Rounded portrait slot for team/defense strips (layout E slot): rarity portrait, or an empty navy slot with a "+".
function W.slot(parent,species,size,pos)
 if species then return W.portrait(parent,species,size,pos) end
 local f=W.round(W.frame(parent,'EmptySlot',size,pos,T.navy),12);W.stroke(f,T.outline,2)
 W.label(f,'+',UDim2.fromScale(1,1),nil,T.display,30,T.row,center)
 return f
end
-- Glassbloom kit (P3). Tokens: Theme (intel §1); recipes: climb&collect/design/hud-glassbloom-intel.md §2; touch §3.
-- L### = board lines cited by the intel. No tweens: animated pieces carry attribute Motion=<§6 token>.
-- Root layering (ZIndexBehavior Sibling): Glow -2, Lip -1, Body 0, labels/caller content >=1, Hit 20. CSS borders sit inside
-- the box (Conversions), so each Body is inset by its stroke and the root keeps the border-box size. Do not clip a root.
-- Every stroke stores BaseThickness + BaseTransparency (Controller.applyPreferences must honour the latter).
local Players=game:GetService('Players')
local MarketplaceService=game:GetService('MarketplaceService')
local TextService=game:GetService('TextService')
local handlers=setmetatable({},{__mode='k'});local states=setmetatable({},{__mode='k'})
local function asset(id) return 'rbxassetid://'..id end
local function udim(r:any) return if type(r)=='number' then UDim.new(0,math.max(0,r)) else r end
local function corner(o,r) W.new('UICorner',o,{CornerRadius=udim(r)});return o end
local function less(r,n) return if type(r)=='number' then r-n else r end
local function gstroke(o,color,th,t,ctx)
 local s=W.new('UIStroke',o,{ApplyStrokeMode=if ctx then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border,Color=color,Thickness=if T.prefs.highContrast then math.max(2,th) else th,Transparency=t or 0,LineJoinMode=Enum.LineJoinMode.Round})
 s:SetAttribute('BaseThickness',th);s:SetAttribute('BaseTransparency',t or 0);return s
end
-- T.grad* table -> UIGradient (stop = {pos, colour, T?}); `color` fills colour-less stops (gradStreak = rc).
function W.grad(o,g,color,rot)
 local c,n,alpha={},{},false
 for _,k in ipairs(g.stops) do table.insert(c,ColorSequenceKeypoint.new(k[1],k[2] or color));table.insert(n,NumberSequenceKeypoint.new(k[1],k[3] or 0));alpha=alpha or k[3]~=nil end
 local u=W.new('UIGradient',o,{Color=ColorSequence.new(c),Rotation=rot or g.rot or 0})
 if alpha then u.Transparency=NumberSequence.new(n) end
 return u
end
local tierKey={Common='blue',Uncommon='blue',Rare='gold',Epic='violet',Mythic='prism',Legendary='prism'} -- 1b (H L9)
local function rcg(o,key)
 local r=T.rarityColor[key]
 if r.stops then local k={};for i,c in ipairs(r.stops) do k[i]=ColorSequenceKeypoint.new((i-1)/(#r.stops-1),c) end;return W.new('UIGradient',o,{Color=ColorSequence.new(k),Rotation=r.rot}) end
 return W.new('UIGradient',o,{Color=ColorSequence.new(r.from,r.to),Rotation=r.rot})
end
local function gtext(parent,name,content,font,n,color,align)
 local l=W.new('TextLabel',parent,{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=tostring(content),TextColor3=color or T.text,Font=font,TextSize=T.size(n),TextXAlignment=align or Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center})
 l:SetAttribute('BaseTextSize',n);return l
end
-- W.text recipe (L48, P§2): body text gets a 1 px ink T.2 outline; display text gets a drop label instead.
local function inked(l) gstroke(l,T.outline,T.s.hair,.2,true);return l end
local function root(class,parent,name,size,pos,r)
 local o=W.new(class,parent,{Name=name,Size=size or UDim2.fromScale(1,1),Position=pos or UDim2.new(),BackgroundTransparency=1,BorderSizePixel=0})
 if class=='TextButton' then o.Text='';o.TextTransparency=1;o.AutoButtonColor=false end
 o:SetAttribute('CornerRadius',udim(r));return o
end
local function body(o,r,s,color,t)
 return corner(W.new('Frame',o,{Name='Body',Size=UDim2.new(1,-2*s,1,-2*s),Position=UDim2.fromOffset(s,s),BackgroundColor3=color or T.text,BackgroundTransparency=t or 0,BorderSizePixel=0,ZIndex=0}),less(r,s))
end
-- Lip = box-shadow 0 Y 0 (Conversions). Opaque body: same-shape Frame at +Y behind. Translucent body: inside a
-- ClipsDescendants strip spanning y H..H+Y so it never shows through. Decor: shadows are outside the board's boxes.
local function lip(o,r,y,color,t,clipped)
 local host=o
 if clipped then host=W.new('Frame',o,{Name='LipClip',Size=UDim2.new(1,0,0,y),Position=UDim2.fromScale(0,1),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=-1});host:SetAttribute('Decor',true) end
 local l=corner(W.new('Frame',host,{Name='Lip',Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(0,y),BackgroundColor3=color,BackgroundTransparency=t or 0,BorderSizePixel=0,ZIndex=-1}),r)
 if clipped then
  local function fit() local h=if o.AbsoluteSize.Y>0 then o.AbsoluteSize.Y else o.Size.Y.Offset;l.Size=UDim2.new(1,0,0,h);l.Position=UDim2.fromOffset(0,y-h) end
  fit();o:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
 end
 l:SetAttribute('Decor',true);return l
end
local function fire(c) if c:GetAttribute('Enabled')~=false and handlers[c] then handlers[c]() end end
-- Handler registry: the Hit area and gamepad Activated on the control both reach fn. Use fn/W.bind, not control.Activated
-- (the Hit child sits on top and receives mouse/touch).
function W.bind(c,fn)
 if not fn then return c end
 if handlers[c]==nil and c:IsA('GuiButton') then c.Activated:Connect(function() fire(c) end) end
 handlers[c]=fn;return c
end
function W.setOn(c,on) local f=states[c];if f then f(on==true) end;c:SetAttribute('On',on==true);return c end
-- Touch target (§3, STOP 1 G1): invisible TextButton 'Hit' >= minSize (44) centred on the control; drawn size unchanged.
-- maxSize (number or Vector2) trims at the neighbour midpoint (side tabs 39, wrapped chips 33). Re-call to change.
function W.hit(control,minSize,maxSize)
 local h=control:FindFirstChild('Hit')
 if not h then
  h=W.new('TextButton',control,{Name='Hit',Text='',BackgroundTransparency=1,BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),AutoButtonColor=false,Selectable=false,ZIndex=20})
  h:SetAttribute('HitArea',true);W.new('UISizeConstraint',h,{})
  h.Activated:Connect(function() fire(control) end)
 end
 local m=minSize or 44;local mx=if type(maxSize)=='number' then Vector2.new(maxSize,maxSize) else maxSize or Vector2.new(math.huge,math.huge)
 local c=h:FindFirstChildOfClass('UISizeConstraint');c.MinSize=Vector2.zero;c.MaxSize=mx;c.MinSize=Vector2.new(math.min(m,mx.X),math.min(m,mx.Y))
 return h
end
-- Focus ring (L35, s.focus): 2 px white stroke on a Frame 2 px outside the control, used as SelectionImageObject.
function W.focus(button)
 local r=button:GetAttribute('CornerRadius') or UDim.new()
 local f=W.new('Frame',nil,{Name='Focus',Size=UDim2.new(1,4,1,4),Position=UDim2.fromOffset(-2,-2),BackgroundTransparency=1,BorderSizePixel=0})
 corner(f,if r.Scale>0 then r else UDim.new(0,r.Offset+2));gstroke(f,T.text,T.s.focus,0)
 button.SelectionImageObject=f;return f
end
-- Hollow U1 glow (Conversions: box-shadow 0 0 B S C): size element+2(B+S), SliceScale B/32, tint C, T. Pass the widget
-- root as both parent and target (layout-safe, inside the root at Z -2); otherwise a sibling one Z below target.
-- color: tint for colour-less tokens (glowRarity = rc); use: key into a per-use blur table (glowRarity.b). S>0 adds a stroke S.
function W.glow(parent,target,g,color,use)
 local b=if type(g.b)=='table' then g.b[use] else g.b;local sp=g.s or 0;local c=g.color or color
 local function place(o,e)
  if target==parent then o.Size=UDim2.new(1,2*e,1,2*e);o.Position=UDim2.fromOffset(-e,-e);o.ZIndex=-2;return end
  local a=target.AnchorPoint;o.AnchorPoint=a;o.Size=target.Size+UDim2.fromOffset(2*e,2*e)
  o.Position=target.Position+UDim2.fromOffset((2*a.X-1)*e,(2*a.Y-1)*e);o.ZIndex=target.ZIndex-1
 end
 local o=W.new('ImageLabel',parent,{Name='Glow',BackgroundTransparency=1,Image=asset(T.images.glow),ImageColor3=c,ImageTransparency=g.t,ScaleType=Enum.ScaleType.Slice,SliceCenter=T.slice.glow,SliceScale=b/32})
 place(o,b+sp);o:SetAttribute('Decor',true)
 if sp>0 then
  local f=W.new('Frame',parent,{Name='GlowSpread',BackgroundTransparency=1,BorderSizePixel=0});place(f,0);f:SetAttribute('Decor',true)
  local cr=target:GetAttribute('CornerRadius') or (target:FindFirstChildOfClass('UICorner') and target:FindFirstChildOfClass('UICorner').CornerRadius) or UDim.new()
  corner(f,cr);gstroke(f,c,sp,g.t)
 end
 return o
end
-- W.glass (§2, L47): gradGlass body, rim 2, 2 px top highlight (x r..W-r), clipped night lip 5 T.4, optional hollow glow.
-- No blur; the inset bottom shade is not ported. ~9 instances (+1 glow). opts: radius (px or T.r.circle; default r.glass),
-- variant 'shop'|'banner'|'edge', rim, rimT, glow (token, false = none), lip (default true).
local glassVariant={shop={rim=T.gold,rimT=.2,glow=T.glowShop},banner={rim=T.text},edge={rim=T.go}} -- L210, L144, L129
function W.glass(parent,name,size,pos,opts)
 opts=opts or {};local v=glassVariant[opts.variant] or {}
 local r=opts.radius or T.r.glass;local s=T.s.glass
 local o=root('Frame',parent,name,size,pos,r)
 local b=body(o,r,s);W.grad(b,T.gradGlass)
 -- GAP: banner/edge rim transparency is not stated (§2 variants name only the colour); glass.rimT kept.
 gstroke(b,opts.rim or v.rim or T.glassRim,s,opts.rimT or v.rimT or T.glassRimT)
 if type(r)=='number' then W.new('Frame',b,{Name='Highlight',Size=UDim2.new(1,2*(s-r),0,2),Position=UDim2.fromOffset(r-s,2-s),BackgroundColor3=T.text,BackgroundTransparency=T.glassHiT,BorderSizePixel=0}) end
 if opts.lip~=false then lip(o,r,5,T.night,T.glassLipT,true) end
 local g=if opts.glow~=nil then opts.glow else v.glow
 if g then W.glow(o,o,g) end
 return o
end
-- W.ring (§2, L112/L126/L283; verified in Studio, evidence/hud_glassbloom_2026-10-27/p3/ring_spike_01.png). The ring is
-- the outer t px inside d. Returns {Frame=, set=function(self,p)} (p 0..1, static; Motion drives :set). Full circle at p>=1.
function W.ring(parent,d,t,fillColor,trackT,innerColor)
 local f=W.new('Frame',parent,{Name='Ring',Size=UDim2.fromOffset(d,d),BackgroundTransparency=1,BorderSizePixel=0})
 local function circle(host,name,x,color,z)
  return corner(W.new('Frame',host,{Name=name,Size=UDim2.fromOffset(d-2*t,d-2*t),Position=UDim2.fromOffset(x,t),BackgroundColor3=color or T.text,BackgroundTransparency=if color then 0 else 1,BorderSizePixel=0,ZIndex=z}),T.r.circle)
 end
 if innerColor then circle(f,'Inner',t,innerColor,1) end
 gstroke(circle(f,'Track',t,nil,1),T.text,t,trackT)
 local step=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.501,1),NumberSequenceKeypoint.new(1,1)})
 local halves={}
 for i,h in ipairs({{'HalfR',d/2,-d/2+t},{'HalfL',0,t}}) do
  local clip=W.new('Frame',f,{Name=h[1],Size=UDim2.fromOffset(d/2,d),Position=UDim2.fromOffset(h[2],0),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=2})
  halves[i]={clip=clip,grad=W.new('UIGradient',gstroke(circle(clip,'Arc',h[3],nil,2),fillColor,t,0),{Transparency=step})}
 end
 local full=circle(f,'Full',t,nil,2);gstroke(full,fillColor,t,0)
 local ring={Frame=f}
 function ring.set(_,p)
  p=math.clamp(p or 0,0,1);local done=p>=1
  halves[1].grad.Rotation=math.min(p,.5)*360;halves[2].grad.Rotation=180+math.max(p-.5,0)*360
  halves[1].clip.Visible=p>0 and not done;halves[2].clip.Visible=p>.5 and not done;full.Visible=done
 end
 ring:set(0);return ring
end
-- W.orb (§2, L55): circle body (gradient or flat fill), stroke 3 white, lip, hollow glow, U8 gloss, icon. TextButton root.
-- opts: preset 'sprint'|'bat', gradient, fill, fillT, flat (no gloss, clipped lip), glow, lipColor, lipY, glossT, icon,
-- iconSize, pos, fn. Plain orb defaults: gradCta, glowOrb, lip `lip`, gloss T.4 (U8).
local orbPreset={
 sprint={gradient=T.gradMint,glow=T.glowSprint,lipColor=T.goLip,lipY=5,glossT=.4,icon='Sprint',iconSize=32}, -- L123, U8
 bat={flat=true,fill=T.batFill,fillT=.22,glow=T.glowBat,lipColor=T.batLip,lipY=4,icon='Bat',iconSize=30}, -- L124
}
function W.orb(parent,name,d,opts)
 opts=opts or {};local p=orbPreset[opts.preset] or {}
 local function get(k) local v=opts[k];if v==nil then v=p[k] end;return v end
 local r=T.r.circle;local s=T.s.bold;local flat=get('flat')
 local o=root('TextButton',parent,name,UDim2.fromOffset(d,d),opts.pos,r);o:SetAttribute('QAControl',true)
 local g=get('glow');if g==nil and not opts.preset then g=T.glowOrb end
 if g then W.glow(o,o,g) end
 -- GAP: the plain cta orb (L55; the jump orb is not built, D5) has no lip height in the intel; pass opts.lipY.
 local ly=get('lipY');if ly then lip(o,r,ly,get('lipColor') or T.lip,0,flat) end
 local b=body(o,r,s,if flat then get('fill') else T.text,if flat then get('fillT') else 0)
 if not flat then W.grad(b,get('gradient') or T.gradCta) end
 gstroke(b,T.text,s,0)
 if not flat then W.new('ImageLabel',b,{Name='Gloss',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset(T.images.glossOrb),ImageTransparency=get('glossT') or .4}) end
 -- GAP: the plain orb's icon size is not in the intel; the icon is drawn only when iconSize is given (presets have it).
 local k,a=get('icon'),get('iconSize');if k and a then W.icon(o,k,UDim2.fromOffset(a,a),UDim2.fromOffset((d-a)/2,(d-a)/2)) end
 W.bind(o,opts.fn);W.hit(o);W.focus(o);return o
end
-- Shared button body for cta / ghost / buy. k: stroke, strokeT, grad, fill, fillT, gloss, shine, glow, lipY, lipColor,
-- lipT, clipped, drop (colour), ink, n, padX.
local function ctaCore(parent,name,label,size,pos,k)
 local r=T.r.btn;local s=k.stroke;local pad=k.padX or 0
 local o=root('TextButton',parent,name,size,pos,r);o.Text=label;o.Font=T.fontDisplay;o.TextSize=T.size(k.n)
 o:SetAttribute('QAControl',true);o:SetAttribute('Enabled',true)
 if k.glow then W.glow(o,o,k.glow) end
 lip(o,r,k.lipY,k.lipColor,k.lipT,k.clipped)
 local b=body(o,r,s,k.fill or T.text,k.fillT);b.ClipsDescendants=k.shine==true
 if k.grad then W.grad(b,k.grad) end
 gstroke(b,T.text,s,k.strokeT)
 if k.gloss then W.grad(corner(W.new('Frame',b,{Name='Gloss',Size=UDim2.fromScale(1,1),BackgroundColor3=T.text,BorderSizePixel=0}),less(r,s)),T.gradGloss) end
 if k.shine then
  -- Rest pose = buy.shine start (x -40 %, rect-clipped by the body); Motion sweeps it to 130 %.
  local sh=W.new('Frame',b,{Name='Shine',Size=UDim2.fromScale(.28,1.2),Position=UDim2.fromScale(-.4,-.1),Rotation=20,BackgroundColor3=T.text,BorderSizePixel=0})
  W.grad(sh,T.gradShine);sh:SetAttribute('Motion','buy.shine');sh:SetAttribute('Decor',true)
 end
 local function label_(name_,color,y,z)
  local l=W.fit(gtext(o,name_,label,T.fontDisplay,k.n,color),k.n,8);l.Size=UDim2.new(1,-2*pad,1,0);l.Position=UDim2.fromOffset(pad,y);l.ZIndex=z;return l
 end
 local drop=if k.drop then label_('Drop',k.drop,2,1) else nil
 local l=label_('Label',k.ink or T.text,0,2)
 o:GetPropertyChangedSignal('Text'):Connect(function() l.Text=o.Text;if drop then drop.Text=o.Text end end)
 W.hit(o);W.focus(o);return o
end
-- W.cta (§2, L56): gradCta, gloss overlay, stroke 3 white, lip `lip` 6, glowCta, LuckiestGuy label + `lip` drop +2.
-- Returns the TextButton (Text = label; the Label child draws it). opts: n (text px, default t.btn 20), padX (default 0).
function W.cta(parent,name,label,size,pos,fn,opts)
 opts=opts or {}
 return W.bind(ctaCore(parent,name,label,size,pos,{stroke=T.s.bold,grad=T.gradCta,gloss=true,glow=T.glowCta,lipY=6,lipColor=T.lip,drop=T.lip,n=opts.n or T.t.btn,padX=opts.padX}),fn)
end
-- W.ghost (§2, L57/L246/L307): night2 T.3, stroke 2 white T.6, clipped lip night T.3 5, LuckiestGuy (both ghosts: 15).
-- Radius = the .btn r16 (ghost is a .btn variant, L57); the board ghosts are h 30-32, so it renders as a pill. opts: n, padX.
local function ghostSpec(n,pad) return {stroke=T.s.glass,fill=T.night2,fillT=T.ghostT.fill,strokeT=T.ghostT.rim,lipY=5,lipColor=T.night,lipT=T.ghostT.lip,clipped=true,n=n,padX=pad} end
function W.ghost(parent,name,label,size,pos,fn,opts)
 opts=opts or {}
 return W.bind(ctaCore(parent,name,label,size,pos,ghostSpec(opts.n or T.t.pbtn,opts.padX)),fn)
end
-- buy() (§2, L242-246, L614): W.cta shape, stroke 2, LG 16, gloss + shine. Signature: (parent,name,price,currency,size,pos,fn,opts)
-- with opts {productId, short, onShort, n, padX}; `price` is the caller's formatted label (G22). Robux: id 0/nil -> disabled ghost
-- "Coming soon" (G15); else tap -> PromptProductPurchase (Roblox handles the top-up), then fn(). Coins: tap 1 -> "CONFIRM" 3 s,
-- tap 2 -> fn(); attribute Short (opts.short, settable later) -> label "Need <price>", taps call onShort.
function W.buy(parent,name,price,currency,size,pos,fn,opts)
 opts=opts or {};local n=opts.n or T.t.buy;local pad=opts.padX or 12;local robux=currency=='robux';price=tostring(price)
 if robux and (opts.productId or 0)==0 then
  local o=ctaCore(parent,name,'Coming soon',size,pos,ghostSpec(n,pad))
  o:SetAttribute('Enabled',false);o:SetAttribute('Currency',currency);o.Active=false;o.Selectable=false;return o
 end
 -- GAP: the coin lip height (L245) is not quoted in the intel (§2 names only gold.lip); the Robux lip 4 (L242) is used.
 local lipC=if robux then T.goLip else T.goldLip
 local o=ctaCore(parent,name,price,size,pos,{stroke=T.s.glass,grad=if robux then T.gradMint else T.gradCoinBuy,gloss=true,shine=true,glow=if robux then T.glowBuyRobux else T.glowBuyCoin,lipY=4,lipColor=lipC,drop=lipC,n=n,padX=pad})
 o:SetAttribute('Currency',currency)
 if robux then return W.bind(o,function() MarketplaceService:PromptProductPurchase(Players.LocalPlayer,opts.productId);if fn then fn() end end) end
 local armed,serial=false,0
 local function idle() armed=false;o.Text=if o:GetAttribute('Short') then 'Need '..price else price end
 o:SetAttribute('Short',opts.short==true);idle()
 o:GetAttributeChangedSignal('Short'):Connect(idle)
 return W.bind(o,function()
  if o:GetAttribute('Short') then if opts.onShort then opts.onShort() end;return end
  if armed then idle();if fn then fn() end;return end
  armed=true;serial+=1;local mine=serial;o.Text='CONFIRM'
  task.delay(3,function() if armed and serial==mine then idle() end end)
 end)
end
-- tabs() Tab (§2, L182-186): h 34 r11, padX 9, icon 22, gap 7, FO 13; off night T.5 + stroke 1.5 white T.82; on gradCta
-- Rot 0 + stroke white + glowTabOn. Fills the column width. Toggle with W.setOn(tab,on); fn optional (or W.bind).
function W.tab(parent,name,label,iconKind,on,fn)
 local r=T.r[11];local s=T.s.thin;local x=s+9
 local o=root('TextButton',parent,name,UDim2.new(1,0,0,34),nil,r);o.Text=label;o:SetAttribute('QAControl',true)
 local glow=W.glow(o,o,T.glowTabOn)
 local b=body(o,r,s,T.night,T.wellT.tab);local g=W.grad(b,T.gradCta,nil,0);local st=gstroke(b,T.text,s,.82)
 if iconKind then W.icon(o,iconKind,UDim2.fromOffset(22,22),UDim2.fromOffset(x,6));x+=22+7 end
 local l=W.fit(inked(gtext(o,'Label',label,T.fontBody,T.t.tab,T.text,Enum.TextXAlignment.Left)),T.t.tab,8);l.Size=UDim2.new(1,-x-s-9,1,0);l.Position=UDim2.fromOffset(x,0)
 states[o]=function(v)
  b.BackgroundColor3=if v then T.text else T.night;b.BackgroundTransparency=if v then 0 else T.wellT.tab;g.Enabled=v;glow.Visible=v
  st.Transparency=if v then 0 else .82;st:SetAttribute('BaseTransparency',st.Transparency)
 end
 W.setOn(o,on);W.bind(o,fn);W.hit(o);W.focus(o);return o
end
-- Scroll-area section header (§2, L193-195): FO 11 pinkText uppercase, margin 14 top / 7 bottom (first: 2 top), right note
-- FO 11 lavText. Height follows the text (AutomaticSize Y; the board line-height is not stated).
function W.sectionHeader(parent,text,note,first)
 local f=W.new('Frame',parent,{Name='SectionHeader',Size=UDim2.fromScale(1,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0})
 W.new('UIPadding',f,{PaddingTop=UDim.new(0,if first then 2 else 14),PaddingBottom=UDim.new(0,7)})
 local function line(name,s,color,align) local l=inked(gtext(f,name,s,T.fontBody,T.t.small,color,align));l.Size=UDim2.fromScale(1,0);l.AutomaticSize=Enum.AutomaticSize.Y;return l end
 line('Title',string.upper(text),T.pinkText,Enum.TextXAlignment.Left)
 if note then line('Note',note,T.lavText,Enum.TextXAlignment.Right) end
 return f
end
-- Scroll area (§2, L188-195, P§2): ScrollingFrame Y, UIPadding 3/10/14/3, bar 6 solid pk over a night T.45 r4 track, block-flow
-- list (gap 0), 36 px bottom fade (Decor) hidden at the end. Returns scroll, holder (holder = the positioned box named `name`).
function W.scrollArea(parent,name,size,pos)
 local h=W.new('Frame',parent,{Name=name,Size=size or UDim2.fromScale(1,1),Position=pos or UDim2.new(),BackgroundTransparency=1,BorderSizePixel=0});local bar=6
 corner(W.new('Frame',h,{Name='ScrollTrack',Size=UDim2.new(0,bar,1,0),Position=UDim2.new(1,-bar,0,0),BackgroundColor3=T.night,BackgroundTransparency=T.wellT.track,BorderSizePixel=0,ZIndex=0}),T.r[4])
 local s=W.new('ScrollingFrame',h,{Name='Scroll',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=bar,ScrollBarImageColor3=T.pk,ScrollBarImageTransparency=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=1})
 W.new('UIPadding',s,{PaddingTop=UDim.new(0,3),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,14),PaddingLeft=UDim.new(0,3)});W.list(s,0)
 -- GAP: "gradient to the panel tint" has no value in the intel; the glass panel's bottom stop (glassTo T.38) is used.
 local last=T.gradGlass.stops[#T.gradGlass.stops]
 local fade=W.new('Frame',h,{Name='BottomFade',Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,1,-36),BackgroundColor3=last[2],BorderSizePixel=0,Active=false,ZIndex=2})
 W.new('UIGradient',fade,{Rotation=90,Transparency=NumberSequence.new(1,last[3])});fade:SetAttribute('Decor',true)
 local function sync() fade.Visible=s.CanvasPosition.Y<s.AbsoluteCanvasSize.Y-s.AbsoluteWindowSize.Y-1 end
 for _,p in ipairs({'CanvasPosition','AbsoluteCanvasSize','AbsoluteWindowSize'}) do s:GetPropertyChangedSignal(p):Connect(sync) end
 sync();return s,h
end
-- Glassbloom chip (§2 chips, L196-198): h 27, padX 10, r12, FO 12; off night T.5 + stroke 1.5 white T.78; on pk T.65 + stroke
-- white, no glow. Width = text + padding unless size is given. W.setOn(chip,on); fn optional (or W.bind).
function W.glassChip(parent,label,on,size,pos,fn)
 local r=T.r[12];local s=T.s.thin;local n=T.t.chip;local pad=s+10
 if not size then size=UDim2.fromOffset(math.ceil(TextService:GetTextSize(label,T.size(n),T.fontBody,Vector2.new(1e4,1e4)).X)+2*pad,27) end
 local o=root('TextButton',parent,'Chip'..(label:gsub('[^%w]','')),size,pos,r);o.Text=label;o:SetAttribute('QAControl',true)
 local b=body(o,r,s,T.night,T.wellT.chip);local st=gstroke(b,T.text,s,.78)
 local l=W.fit(inked(gtext(o,'Label',label,T.fontBody,n)),n,8);l.Size=UDim2.new(1,-2*pad,1,0);l.Position=UDim2.fromOffset(pad,0)
 states[o]=function(v)
  b.BackgroundColor3=if v then T.pk else T.night;b.BackgroundTransparency=if v then .65 else T.wellT.chip
  st.Transparency=if v then 0 else .78;st:SetAttribute('BaseTransparency',st.Transparency)
 end
 W.setOn(o,on);W.bind(o,fn);W.hit(o);W.focus(o);return o
end
-- card() (§2, L199-206, L610-612): rcg fill, stroke 3 ink, outer ring 2 white T.7 (violet/prism: T.4 + glowCardRare), art h 62
-- with U11 highlight + icon 52, ink T.38 name band (padding 3/7/6, gap 3, FO 12, XP h 7), level badge 28 at (5,5) deep FO 13.
-- rarityKey: tier name or rarityColor key (default species.rarity). species nil = unknown ("???", "?" FO 30).
-- opts: level, xp (0..1), locked (padlock 38), icon (W.icon kind, default 'Creature').
function W.rarityCard(parent,name,species,rarityKey,size,pos,opts)
 opts=opts or {}
 local key=if T.rarityColor[rarityKey] then rarityKey else tierKey[rarityKey or (species and species.rarity) or '']
 local r=T.r.card;local s=T.s.bold;local rare=key=='violet' or key=='prism';local known=species~=nil and key~=nil and not opts.locked
 local o=root('Frame',parent,name,size,pos,r)
 if rare and known then W.glow(o,o,T.glowCardRare) end
 gstroke(corner(W.new('Frame',o,{Name='Ring',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=-1}),r),T.text,T.s.glass,if rare and known then .4 else .7)
 local b=body(o,r,s,if known then T.text else T.cardFallback);gstroke(b,T.outline,s,0)
 if known then rcg(b,key) end
 local art=W.new('Frame',b,{Name='Art',Size=UDim2.new(1,0,0,62),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true})
 if known then
  -- GAP: the highlight extent is not stated; sized to the farthest art corner from (50 %, 42 %) (the CSS radial default).
  local hi=W.new('ImageLabel',art,{Name='Highlight',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.42),BackgroundTransparency=1,Image=asset(T.images.radial),ImageColor3=T.text,ImageTransparency=.4})
  hi:SetAttribute('Decor',true)
  local function fit() local w=if art.AbsoluteSize.X>0 then art.AbsoluteSize.X elseif size then size.X.Offset-2*s else 0;local e=2*math.sqrt((w/2)^2+(62*.58)^2);hi.Size=UDim2.fromOffset(e,e) end
  fit();art:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
  W.icon(art,opts.icon or 'Creature',UDim2.fromOffset(52,52),UDim2.new(.5,-26,.5,-26))
 elseif opts.locked then W.icon(art,'Padlock',UDim2.fromOffset(38,38),UDim2.new(.5,-19,.5,-19))
 else gtext(art,'Unknown','?',T.fontBody,T.t.cardArt) end
 local band=W.new('Frame',b,{Name='Band',AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.fromScale(1,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=T.outline,BackgroundTransparency=.38,BorderSizePixel=0})
 W.new('UIPadding',band,{PaddingTop=UDim.new(0,3),PaddingRight=UDim.new(0,7),PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,7)});W.list(band,3)
 local nm=inked(gtext(band,'Name',if species then species.name else '???',T.fontBody,T.t.cardName));nm.Size=UDim2.fromScale(1,0);nm.AutomaticSize=Enum.AutomaticSize.Y;nm.TextWrapped=true;nm.LayoutOrder=1
 if known then
  -- GAP: the card XP track fill is not stated; well.T xp (night T.3, L51) used. Fill = gradAction, full = gradCardXpFull.
  local xp=math.clamp(opts.xp or 0,0,1)
  local tr=corner(W.new('Frame',band,{Name='XP',Size=UDim2.new(1,0,0,7),BackgroundColor3=T.night,BackgroundTransparency=T.wellT.xp,BorderSizePixel=0,LayoutOrder=2}),T.r.circle)
  W.grad(corner(W.new('Frame',tr,{Name='Fill',Size=UDim2.fromScale(xp,1),BackgroundColor3=T.text,BorderSizePixel=0}),T.r.circle),if xp>=1 then T.gradCardXpFull else T.gradAction)
 end
 if opts.level then
  -- GAP G12: the level hexagon has no primitive or upload; drawn as a circle.
  local lv=corner(W.new('Frame',b,{Name='Level',Size=UDim2.fromOffset(28,28),Position=UDim2.fromOffset(5,5),BackgroundColor3=T.deep,BorderSizePixel=0,ZIndex=2}),T.r.circle)
  inked(gtext(lv,'Value',opts.level,T.fontBody,T.t.lvh))
 end
 return o
end
-- cpk Burst (§2, L269-271): 3 gold squares rotated 0/30/60 (12 points), label FO 11 goldInk rotated -12, at top 4 / right 4
-- (the caller moves it to top 24 under a ribbon). size default 40. Motion owns the wobble.
function W.burst(parent,size,label)
 size=size or 40
 local f=W.new('Frame',parent,{Name='Burst',Size=UDim2.fromOffset(size,size),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,4),BackgroundTransparency=1,BorderSizePixel=0})
 for _,a in ipairs({0,30,60}) do W.new('Frame',f,{Name='Point',Size=UDim2.fromScale(1,1),Rotation=a,BackgroundColor3=T.gold,BorderSizePixel=0}) end
 local l=gtext(f,'Label',label,T.fontBody,T.t.small,T.goldInk);l.Rotation=-12;l.ZIndex=2
 f:SetAttribute('Motion','burst.wob');return f
end
return W
