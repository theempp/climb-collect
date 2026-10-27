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
 local label=W.new('TextLabel',b,{Name='Label',Size=UDim2.new(1,-10,1,-5),Position=UDim2.fromOffset(5,0),BackgroundTransparency=1,Text=b.Text,TextColor3=T.ink,Font=T.label,TextSize=b.TextSize+3,TextWrapped=true})
 W.new('UIStroke',label,{ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual,Color=T.outline,Thickness=2,LineJoinMode=Enum.LineJoinMode.Round}):SetAttribute('BaseThickness',2)
 local function fit()
  local h=b.AbsoluteSize.Y;if h<=0 then return end
  local lip=math.clamp(math.floor(h*.14+.5),3,8);local down=if b:GetAttribute('Pressed') then lip else 0
  face.Size=UDim2.new(1,0,1,-lip);face.Position=UDim2.fromOffset(0,down)
  label.Size=UDim2.new(1,-10,1,-lip);label.Position=UDim2.fromOffset(5,down)
 end
 b:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
 b:GetPropertyChangedSignal('Text'):Connect(function() label.Text=b.Text end)
 b:GetPropertyChangedSignal('TextSize'):Connect(function() label.TextSize=b.TextSize+3 end)
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
local iconFor={Creatures='creature',Discovery='egg',Mountain='map',Sanctuary='heart',Shop='chest',Profile='scroll',Social='bat',Settings='gear',Coin='coin',Gem='gem',Interact='climb',Bat='bat',Sprint='sprint',Jump='jump',Egg='egg',EggCracked='egg-cracked',Gift='gift',Calendar='calendar',Padlock='padlock',Chest='chest',Map='map',Scroll='scroll',Heart='heart'}
function W.icon(parent,kind,size,pos)
 local f=W.frame(parent,'Icon'..kind,size,pos);f.BackgroundTransparency=1
 local id=T.icons[iconFor[kind] or '']
 if id and id~=0 then W.new('ImageLabel',f,{Name='Image',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image='rbxassetid://'..id,ScaleType=Enum.ScaleType.Fit});return f end
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
return W
