local T=require(script.Parent.Theme)
local W={}
function W.new(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parent;return o
end
function W.round(o,r) W.new('UICorner',o,{CornerRadius=UDim.new(0,r or 12)});return o end
function W.stroke(o,color,thickness) return W.new('UIStroke',o,{Color=color or T.line,Thickness=thickness or (if T.prefs.highContrast then 2 else 1),Transparency=if T.prefs.highContrast then 0 else .15}) end
function W.frame(parent,name,size,pos,color)
 return W.new('Frame',parent,{Name=name,Size=size or UDim2.fromScale(1,1),Position=pos or UDim2.new(),BackgroundColor3=color or T.panel,BorderSizePixel=0})
end
function W.panel(parent,name,size,pos,color)
 local o=W.round(W.frame(parent,name,size,pos,color));W.stroke(o);return o
end
function W.text(parent,content,size,pos,font,n,color)
 local label=W.new('TextLabel',parent,{Name='Text',Size=size or UDim2.new(1,0,0,26),Position=pos or UDim2.new(),BackgroundTransparency=1,Text=tostring(content),TextColor3=color or T.ink,Font=font or T.body,TextSize=T.size(n or 15),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,RichText=false})
 label:SetAttribute('BaseTextSize',n or 15);return label
end
function W.button(parent,name,label,size,pos,fn,variant,enabled)
 local isEnabled=enabled~=false
 local color=if variant=='gold' then T.gold elseif variant=='quiet' then T.card elseif variant=='danger' then T.coral else T.blue
 local b=W.round(W.new('TextButton',parent,{Name=name,Size=size or UDim2.new(1,0,0,44),Position=pos or UDim2.new(),BackgroundColor3=if isEnabled then color else T.panel,BorderSizePixel=0,Text=label,TextColor3=if not isEnabled then T.muted elseif variant=='gold' then T.navy else T.ink,TextSize=T.size(14),Font=T.bold,TextWrapped=true,AutoButtonColor=isEnabled,Active=isEnabled,Selectable=isEnabled}),10)
 W.stroke(b,if isEnabled then color:Lerp(T.ink,.2) else T.line)
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
function W.portrait(parent,species,size,pos)
 local C=require(game.ReplicatedStorage.MountainShared.Catalog)
 local color=Color3.fromRGB(table.unpack(C.kingdoms[species.kingdom].accent))
 local f=W.round(W.frame(parent,'Portrait',size,pos,T.navy),14)
 -- Species silhouette badge stays legible even before 3D world streaming completes.
 local halo=W.round(W.frame(f,'Medallion',UDim2.fromScale(.70,.70),UDim2.fromScale(.15,.15),color),100)
 halo.BackgroundTransparency=.83
 local face=W.round(W.frame(f,'Face',UDim2.fromScale(.52,.42),UDim2.fromScale(.24,.35),color),18)
 for _,x in ipairs({.28,.66}) do
  W.round(W.frame(face,'Eye',UDim2.fromScale(.10,.16),UDim2.fromScale(x,.36),T.navy),20)
 end
 local shape=species.shape
 local tall=shape=='rabbit' or shape=='deer';local wing=shape=='moth' or shape=='bird'
 for _,x in ipairs({.24,.59}) do
  local ear=W.round(W.frame(f,'Silhouette',UDim2.fromScale(if wing then .28 else .16,if tall then .38 else .22),UDim2.fromScale(x,if tall then .1 else .23),color),8)
  ear.Rotation=if x<.4 then -20 else 20
 end
 local tier=({Common=1,Uncommon=2,Rare=3,Epic=4,Mythic=5,Legendary=6})[species.rarity] or 1
 W.text(f,string.rep('◆',tier),UDim2.new(1,0,0,18),UDim2.new(0,0,1,-20),T.bold,10,T.rarity[species.rarity]).TextXAlignment=Enum.TextXAlignment.Center
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
