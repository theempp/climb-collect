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
 local stroke=W.new('UIStroke',o,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=color or T.line,Thickness=if T.prefs.highContrast then math.max(2,base) else base,Transparency=if T.prefs.highContrast then 0 else .15})
 stroke:SetAttribute('BaseThickness',base);return stroke
end
function W.frame(parent,name,size,pos,color)
 return W.new('Frame',parent,{Name=name,Size=size or UDim2.fromScale(1,1),Position=pos or UDim2.new(),BackgroundColor3=color or T.panel,BorderSizePixel=0})
end
function W.panel(parent,name,size,pos,color)
 local o=W.round(W.frame(parent,name,size,pos,color));W.stroke(o,nil,2)
 W.new('UIGradient',o,{Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(173,202,222)),Rotation=90})
 return o
end
function W.text(parent,content,size,pos,font,n,color)
 local label=W.new('TextLabel',parent,{Name='Text',Size=size or UDim2.new(1,0,0,26),Position=pos or UDim2.new(),BackgroundTransparency=1,Text=tostring(content),TextColor3=color or T.ink,Font=font or T.body,TextSize=T.size(n or 15),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,RichText=false})
 label:SetAttribute('BaseTextSize',n or 15);return label
end
function W.button(parent,name,label,size,pos,fn,variant,enabled)
 local isEnabled=enabled~=false
 local color=if variant=='gold' then T.gold elseif variant=='quiet' then T.card elseif variant=='danger' then T.coral else T.blue
 local b=W.round(W.new('TextButton',parent,{Name=name,Size=size or UDim2.new(1,0,0,44),Position=pos or UDim2.new(),BackgroundColor3=if isEnabled then color else T.panel,BorderSizePixel=0,Text=label,TextColor3=if not isEnabled then T.muted elseif variant=='gold' then T.navy else T.ink,TextSize=T.size(14),Font=T.bold,TextWrapped=true,AutoButtonColor=isEnabled,Active=isEnabled,Selectable=isEnabled}),10)
 W.stroke(b,if isEnabled then color:Lerp(T.ink,.45) else T.line,2)
 W.new('UIGradient',b,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(208,220,244)),Rotation=90})
 b:SetAttribute('ButtonColor',color);b:SetAttribute('ButtonInk',if variant=='gold' then T.navy else T.ink)
 b:SetAttribute('QAControl',true);b:SetAttribute('Enabled',isEnabled)
 b:SetAttribute('BaseTextSize',14)
 b.Activated:Connect(function() if b:GetAttribute('Enabled') and fn then fn() end end)
 return b
end
function W.enable(b,on,label)
 b:SetAttribute('Enabled',on);b.Active=on;b.Selectable=on;b.AutoButtonColor=on
 b.BackgroundColor3=if on then b:GetAttribute('ButtonColor') or T.blue else T.panel
 b.TextColor3=if on then b:GetAttribute('ButtonInk') or T.ink else T.muted
 b.TextTransparency=0;if label then b.Text=label end
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
function W.progress(parent,value,size,pos,color)
 local track=W.round(W.frame(parent,'Progress',size,pos,T.navy),5)
 local fill=W.round(W.frame(track,'Fill',UDim2.fromScale(math.clamp(value or 0,0,1),1),nil,color or T.sky),5)
 return fill
end
function W.tag(parent,label,pos,color)
 local f=W.round(W.frame(parent,'Tag',UDim2.fromOffset(100,24),pos,color or T.navy),7)
 local t=W.text(f,label,UDim2.fromScale(1,1),nil,T.bold,11);t.TextXAlignment=Enum.TextXAlignment.Center
 return f
end
-- Local vector artwork: no external asset permissions or network loading dependency.
function W.icon(parent,kind,size,pos)
 local f=W.frame(parent,'Icon'..kind,size,pos);f.BackgroundTransparency=1
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
function W.tile(parent,name,label,kind,size,pos,fn,color)
 local b=W.button(parent,name,'',size,pos,fn,'quiet');b.BackgroundColor3=T.navy
 b.UIStroke.Color=color or T.sky
 local icon=W.icon(b,kind,UDim2.fromOffset(42,42),UDim2.new(.5,-21,0,3))
 local caption=W.text(b,label,UDim2.new(1,-6,0,22),UDim2.new(0,3,1,-25),T.bold,12)
 caption.TextXAlignment=Enum.TextXAlignment.Center
 return b
end
function W.portrait(parent,species,size,pos)
 local C=require(game.ReplicatedStorage.MountainShared.Catalog)
 local accent=Color3.fromRGB(table.unpack(C.kingdoms[species.kingdom].accent))
 local color=if species.kingdom==1 and species.shape=='rabbit' then T.green elseif species.kingdom==1 and species.shape=='fox' then T.gold else accent
 local f=W.round(W.frame(parent,'Portrait',size,pos,T.navy),12)
 -- Species silhouette badge stays legible even before 3D world streaming completes.
 local halo=W.round(W.frame(f,'Medallion',UDim2.fromScale(.70,.70),UDim2.fromScale(.15,.15),color),100)
 halo.BackgroundTransparency=.55
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
