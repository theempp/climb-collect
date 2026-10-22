-- Authored parts-only expedition court. Never touches terrain or mountain routes.
local F={}
local gold=Color3.fromRGB(255,184,57)
local orange=Color3.fromRGB(238,112,42)
local teal=Color3.fromRGB(22,177,175)
local purple=Color3.fromRGB(135,78,205)
local ink=Color3.fromRGB(35,49,67)
local cream=Color3.fromRGB(255,239,196)
function F.build(_,placement)
 local w=workspace.World
 assert(not w:FindFirstChild('Fairground'),'Fairground already exists; preserve reviewed composition')
 local origin=placement and placement.origin or CFrame.new(0,48,2040)
 local root=Instance.new('Model');root.Name='Fairground'
 local anchors=Instance.new('Folder');anchors.Name='Anchors';anchors.Parent=root
 local function model(name) local m=Instance.new('Model');m.Name=name;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=root;return m end
 local function part(parent,name,size,cf,color,solid,shape)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=origin*cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=solid==true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;if shape then p.Shape=shape end;p.Parent=parent;return p
 end
 local function label(parent,text,at,width,height,color)
  local p=part(parent,'Sign',Vector3.new(width,height,0.6),at,color or ink,false)
  for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
   local s=Instance.new('SurfaceGui');s.Face=face;s.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;s.PixelsPerStud=35;s.Parent=p
   local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(0.94,0.9);t.Position=UDim2.fromScale(0.03,0.05);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=cream;t.TextScaled=true;t.Font=Enum.Font.FredokaOne;t.Parent=s
  end
  return p
 end
 local function anchor(id,x,z)
  local p=part(anchors,id,Vector3.new(3,3,3),CFrame.new(x,2,z),cream,false);p.Transparency=1;p:SetAttribute('ServiceId',id);return p
 end
 local ground=model('Court')
 part(ground,'Foundation',Vector3.new(188,1,184),CFrame.new(0,0.2,5),Color3.fromRGB(206,165,109),true)
 part(ground,'CourtInlay',Vector3.new(110,0.18,120),CFrame.new(0,0.8,5),cream,true)
 for _,x in {-57,57} do part(ground,'TurquoiseBorder',Vector3.new(2,0.2,122),CFrame.new(x,0.83,5),teal,false) end
 -- An open twenty-stud approach joins the original gates; no route entry is moved.
 part(ground,'MountainApproach',Vector3.new(22,0.5,134),CFrame.new(0,0.1,-139),Color3.fromRGB(206,165,109),true)
 anchor('Spawn',0,57);anchor('Bank',49,20);anchor('Return',34,28);anchor('HomeDoor',-26,65):SetAttribute('CabinSlot',1)
 anchor('Collection',-49,18);anchor('RouteBoard',0,-33);anchor('PracticeStart',-70,-20)
 for i,id in {'Bundle','Flag','Trail'} do anchor('Exchange_'..id,45+(i-1)*12,-35) end
 anchor('Exchange_Next',40,8);anchor('Exchange_Coins',60,8)
 local bounds=part(root,'SafeBounds',Vector3.new(202,90,208),CFrame.new(0,35,0),cream,false);bounds.Transparency=1
 local function pavilion(name,x,z,color,title,subtitle,width)
  local m=model(name);width=width or 34
  part(m,'Deck',Vector3.new(width+5,0.5,24),CFrame.new(x,0.9,z),ink,true)
  for _,dx in {-width/2,width/2} do for _,dz in {-10,10} do
   part(m,'TimberPost',Vector3.new(1.3,15,1.3),CFrame.new(x+dx,8,z+dz),orange,true)
   part(m,'BrassFoot',Vector3.new(2,1.5,2),CFrame.new(x+dx,1.6,z+dz),gold,false)
  end end
  for i=1,8 do
   part(m,'StripedCanopy',Vector3.new(width/8+0.1,0.65,26),CFrame.new(x-width/2+(i-0.5)*width/8,16,z)*CFrame.Angles(0,0,0),i%2==0 and cream or color,false)
  end
  part(m,'CanopyCrown',Vector3.new(width+2,1.3,1.3),CFrame.new(x,17.4,z),gold,false)
  label(m,title,CFrame.new(x,13,z+12.7),width-3,4,color)
  label(m,subtitle,CFrame.new(x,4,z-9),width-4,3,ink)
  return m
 end
 local bank=pavilion('BankPavilion',54,30,gold,'BANK YOUR FINDS','MAKE YOUR DISCOVERIES PERMANENT',30)
 -- Oversized expedition strongbox with brass lock, unmistakable bank silhouette.
 part(bank,'Strongbox',Vector3.new(15,9,8),CFrame.new(54,6,34),teal,true)
 for _,dx in {-5.7,5.7} do part(bank,'BrassBand',Vector3.new(1.3,10,8.4),CFrame.new(54+dx,6,34),gold,false) end
 part(bank,'Lock',Vector3.new(3,4,1),CFrame.new(54,6,38.5),gold,false)
 label(bank,'C&C',CFrame.new(54,9,38.7),8,2,teal)
 pavilion('Exchange',58,-47,purple,'THE EXCHANGE','EXPEDITION GEAR • COSMETIC PREVIEWS',42)
 local home=pavilion('HomeEntrance',-30,76,orange,'YOUR HOME','COLLECTIONS • COMPANIONS • VISITS',28)
 part(home,'DoorArch',Vector3.new(14,13,2),CFrame.new(-30,7,81),teal,true)
 label(home,'HOME',CFrame.new(-30,8,82.2),10,4,teal)
 local collection=pavilion('CollectionShowcase',-56,27,purple,'FIELD COLLECTION','YOUR FINDS. YOUR STORY.',30)
 for i=1,3 do
  part(collection,'ShowcaseBase',Vector3.new(7,2,7),CFrame.new(-68+i*6,2.4,25),gold,true)
  local crystal=part(collection,'IllustratedCrystal',Vector3.new(3,6+i,3),CFrame.new(-68+i*6,7,25)*CFrame.Angles(0,0,math.rad(20)),i==2 and teal or purple,false);crystal.Material=Enum.Material.Glass
 end
 local routes=model('RouteInformation')
 label(routes,'THE SUMMIT IS CALLING',CFrame.new(0,12,-53),38,5,teal)
 label(routes,'SHEPHERD →   WATERFALL →\nLEDGE & SPIRE • COMING SOON',CFrame.new(0,6,-53),36,5,ink)
 for _,x in {-20,20} do part(routes,'BoardPost',Vector3.new(1.6,15,1.6),CFrame.new(x,7,-53),orange,true) end
 -- Oversized carabiner framing the practice frontage.
 local practice=model('PracticeLandmark')
 for i=0,17 do local a=i*math.pi*2/18
  part(practice,'Carabiner',Vector3.new(1.8,3.2,1.8),CFrame.new(-77+8*math.cos(a),19+11*math.sin(a),-38)*CFrame.Angles(0,0,a),gold,false)
 end
 label(practice,'PRACTICE CRAG',CFrame.new(-70,10,-22),30,4,teal)
 label(practice,'FREE DAILY CHALLENGE',CFrame.new(-70,6,-22),27,3,ink)
 -- Low pennant strings frame the sides, leaving the summit axis clear.
 for _,side in {-1,1} do
  local decor=model(side<0 and 'WestPennants' or 'EastPennants')
  for _,z in {-77,70} do part(decor,'Mast',Vector3.new(1,23,1),CFrame.new(side*91,11,z),ink,false) end
  for i=0,15 do
   local z=-77+i*9.8;local y=22-3*math.sin(i/15*math.pi)
   part(decor,'Cable',Vector3.new(0.15,0.15,10),CFrame.new(side*91,y,z),ink,false)
   local flag=part(decor,'Pennant',Vector3.new(0.18,2.6,3.6),CFrame.new(side*91,y-1.4,z),({gold,teal,purple,orange})[i%4+1],false);flag:SetAttribute('FairgroundMotion','pennant')
  end
 end
 local attraction=model('ExpeditionGlobe')
 part(attraction,'Pedestal',Vector3.new(9,2,9),CFrame.new(78,2,67),ink,true)
 local globe=part(attraction,'Globe',Vector3.new(9,9,9),CFrame.new(78,9,67),teal,false,Enum.PartType.Ball);globe:SetAttribute('FairgroundMotion','globe')
 for i=1,3 do part(attraction,'Mountain',Vector3.new(2.3,4+i,2),CFrame.new(74+i*2,10,70)*CFrame.Angles(0,0,math.rad(20)),cream,false) end
 label(attraction,'GO FIND YOUR NEXT FAVOURITE',CFrame.new(78,17,67),22,3,orange)
 root.Parent=w
 -- Only the inventoried authored Foothold structures are archived. Mountain, gates and cabins survive.
 local archive=Instance.new('Folder');archive.Name='BeforeFairgroundStructures';archive.Parent=game.ServerStorage
 local old=w.Regions.Foothold
 for _,v in old.Core:GetChildren() do if v.Name~='Gates' then v.Parent=archive end end
 for _,v in old.Districts:GetChildren() do if v.Name~='Cabins' then v.Parent=archive end end
 local displays=w:FindFirstChild('CommerceDisplays');if displays then displays.Parent=archive end
 local sp=workspace:FindFirstChildOfClass('SpawnLocation');assert(sp,'existing spawn missing')
 sp.CFrame=origin*CFrame.new(0,1.2,57);sp.Size=Vector3.new(8,1,8);sp.Transparency=1;sp.CanCollide=false
 return {root=root,anchors=anchors}
end
return F
