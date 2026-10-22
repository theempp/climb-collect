-- Original expedition palette and chunky illustrated primitives, shared across presentation.
local T={ink=Color3.fromRGB(29,46,64),cream=Color3.fromRGB(255,244,207),teal=Color3.fromRGB(22,174,173),orange=Color3.fromRGB(246,138,48),purple=Color3.fromRGB(133,83,207),gold=Color3.fromRGB(255,207,73)}
function T.make(class,parent,props)
 local x=Instance.new(class);for k,v in props or {} do x[k]=v end;x.Parent=parent;return x
end
function T.panel(parent,name,color)
 local f=T.make('Frame',parent,{Name=name,BackgroundColor3=color or T.cream,BorderSizePixel=0})
 if parent:IsA('ScrollingFrame') then f.LayoutOrder=#parent:GetChildren() end
 T.make('UICorner',f,{CornerRadius=UDim.new(0,16)});T.make('UIStroke',f,{Color=T.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border});return f
end
function T.text(parent,text,size)
 return T.make('TextLabel',parent,{BackgroundTransparency=1,Text=text,TextColor3=T.ink,Font=Enum.Font.FredokaOne,TextSize=size or 20,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,36)})
end
function T.button(parent,text,fn,color)
 local b=T.make('TextButton',parent,{Text=text,Font=Enum.Font.FredokaOne,TextSize=18,TextWrapped=true,TextColor3=T.ink,BackgroundColor3=color or T.gold,Size=UDim2.new(1,0,0,52),BorderSizePixel=0,Selectable=true})
 if parent:IsA('ScrollingFrame') then b.LayoutOrder=#parent:GetChildren() end
 T.make('UICorner',b,{CornerRadius=UDim.new(0,12)});T.make('UIStroke',b,{Color=T.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border});if fn then b.Activated:Connect(fn) end;return b
end
function T.mountain(parent)
 local v=T.make('ViewportFrame',parent,{Name='OriginalMountainArtwork',BackgroundTransparency=1,Ambient=Color3.new(.8,.8,.8),LightColor=Color3.new(1,1,1),Size=UDim2.fromOffset(100,70)})
 for i=1,3 do
  local x=(i-2)*5;local h=i==2 and 11 or 7;local z=i==2 and -1 or 0
  for _,side in {-1,1} do
   T.make('WedgePart',v,{Anchored=true,Size=Vector3.new(.6,h,5),Color=i==2 and T.teal or T.ink,CFrame=CFrame.new(x+side*2.5,h/2,z)*CFrame.Angles(0,side*math.pi/2,0),Material=Enum.Material.SmoothPlastic})
   T.make('WedgePart',v,{Anchored=true,Size=Vector3.new(.7,h*.3,1.5),Color=T.cream,CFrame=CFrame.new(x+side*.75,h*.85,z+.2)*CFrame.Angles(0,side*math.pi/2,0),Material=Enum.Material.SmoothPlastic})
  end
 end
 local c=T.make('Camera',v,{FieldOfView=35,CFrame=CFrame.lookAt(Vector3.new(0,6,36),Vector3.new(0,5,0))});v.CurrentCamera=c;return v
end
return T
