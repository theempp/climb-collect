-- Imported from offspring Collection-v004 carry review (2026-10-26), unchanged.
-- Cosmetic client adapter. Call once per carrier; Destroy on release/respawn.
-- Coordinates retain the authored scene-origin pivot (never mesh-bound center).
local Profiles=require(script.Parent.CarryProfiles)
local RunService=game:GetService('RunService')
local Fit={}
local function jointData(j)
 if j:IsA('Motor6D') then return j.Part0,j.Part1,j.C0,j.C1 end
 return j.Attachment0.Parent,j.Attachment1.Parent,j.Attachment0.CFrame,j.Attachment1.CFrame
end
local function basis(up,forward)
 local right=forward:Cross(up).Unit
 return CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up))
end
local function orient(a,b,localA,localB,forward)
 local rotation=basis((a-b).Unit,forward)*basis((localA-localB).Unit,Vector3.new(0,0,-1)):Inverse()
 return CFrame.new(a)*rotation*CFrame.new(-localA)
end
local function setJoint(j,parentCF,childCF)
 local _,_,c0,c1=jointData(j)
 j.Transform=(parentCF*c0):ToObjectSpace(childCF*c1)
end
function Fit.attach(model,character)
 local profile=assert(Profiles[model:GetAttribute('Species')],'Unknown carry species')
 local root=assert(character:FindFirstChild('HumanoidRootPart'),'No character root')
 local humanoid=assert(character:FindFirstChildOfClass('Humanoid'),'No humanoid')
 local torso=character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso')
 local arm=character:FindFirstChild('LeftUpperArm')
 assert(arm,'R15 articulated arms required')
 local ratio=math.clamp((arm.Size.Y+character.LeftLowerArm.Size.Y+character.LeftHand.Size.Y*.5)/1.938,.7,1.45)
 local offset=profile.offset*ratio-Vector3.new(0,.1*ratio,0)
 -- Keep the same front clearance on broad/deep torsos without changing the support pose.
 offset+=Vector3.new(0,0,-math.max(0,torso.Size.Z-.766)*.5)
 local state={model=model,arms={},ratio=ratio,offset=offset,profile=profile}
 local surface=require(script.Parent.CarrySurfaces[model:GetAttribute('Species')])
 for i,side in {'Left','Right'} do
  local hand=character[side..'Hand']
  local contact=profile.contacts[i]*ratio
  contact=Vector3.new((i==1 and -1 or 1)*math.max(math.abs(contact.X),hand.Size.X*.55),contact.Y,contact.Z)
  local bottom=math.huge
  for _,p in surface do
   if math.abs(p[1]*ratio-contact.X)<=hand.Size.X*.5+.045*ratio and math.abs(p[3]*ratio-contact.Z)<=hand.Size.Y*.5+.045*ratio then bottom=math.min(bottom,p[2]*ratio)end
  end
  assert(bottom<math.huge,'No measured support surface for '..side)
  contact=Vector3.new(contact.X,bottom-.008*ratio,contact.Z)
  local shoulder=assert(character:FindFirstChild(side..'Shoulder',true))
  local elbow=assert(character:FindFirstChild(side..'Elbow',true))
  local wrist=assert(character:FindFirstChild(side..'Wrist',true))
  local _,_,_,s1=jointData(shoulder);local _,_,e0,e1=jointData(elbow);local _,_,w0,w1=jointData(wrist)
  local palmFraction=hand.Size.Z/hand.Size.Y<1 and .41 or .49
  table.insert(state.arms,{hand=hand,contact=contact,palmOffset=Vector3.new(0,0,-hand.Size.Z*palmFraction),shoulder=shoulder,elbow=elbow,wrist=wrist,
   upperLength=(s1.Position-e0.Position).Magnitude,lowerLength=(e1.Position-w0.Position).Magnitude,side=i==1 and -1 or 1})
 end
 -- Raise the cradle into the measured arm workspace; never stretch the skeleton.
 local lift=0;local foundReach=false
 for attempt=1,80 do
  local reachable=true
  for _,a in state.arms do
   local parent,_,s0=jointData(a.shoulder);local _,_,_,w1=jointData(a.wrist)
   local target=torso.CFrame*CFrame.new(offset+a.contact+Vector3.new(0,lift,0))*CFrame.Angles(math.pi/2,0,0)
   local wrist=(target*CFrame.new(-a.palmOffset)*w1).Position
   if (wrist-(parent.CFrame*s0).Position).Magnitude>a.upperLength+a.lowerLength-.06*ratio then reachable=false end
  end
  if reachable then foundReach=true;break end
  lift+=.01*ratio
 end
 if not foundReach then
  error('Avatar arm reach cannot support this carry profile')
 end
 offset+=Vector3.new(0,lift,0);state.offset=offset;state.lift=lift
 model:ScaleTo(.01*profile.scale*ratio)
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end end
 for i,a in state.arms do
  a.target=Instance.new('Attachment');a.target.Name='OffspringCarryPalm'..i
  a.target.CFrame=CFrame.new(offset+a.contact)*CFrame.Angles(math.pi/2,0,0);a.target.Parent=torso
 end
 local function pose()
  for _,a in state.arms do
   local parent,_,s0,s1=jointData(a.shoulder)
   local _,_,e0,e1=jointData(a.elbow);local _,_,w0,w1=jointData(a.wrist)
   local handCF=a.target.WorldCFrame*CFrame.new(-a.palmOffset)
   local shoulder=(parent.CFrame*s0).Position
   local wrist=(handCF*w1).Position
   local delta=wrist-shoulder;local distance=delta.Magnitude
   a.reachError=math.max(0,distance-a.upperLength-a.lowerLength)
   local d=math.clamp(distance,math.abs(a.upperLength-a.lowerLength)+.001,a.upperLength+a.lowerLength-.001)
   local direction=delta.Unit
   local bend=torso.CFrame:VectorToWorldSpace(Vector3.new(a.side*.4,-2,.25))
   bend=(bend-direction*bend:Dot(direction)).Unit
   local along=(a.upperLength^2-a.lowerLength^2+d*d)/(2*d)
   local height=math.sqrt(math.max(0,a.upperLength^2-along^2))
   local elbow=shoulder+direction*along+bend*height
   local upperCF=orient(shoulder,elbow,s1.Position,e0.Position,torso.CFrame.LookVector)
   local lowerCF=orient(elbow,wrist,e1.Position,w0.Position,torso.CFrame.LookVector)
   setJoint(a.shoulder,parent.CFrame,upperCF);setJoint(a.elbow,upperCF,lowerCF);setJoint(a.wrist,lowerCF,handCF)
  end
 end
 local function update()
  if not model.Parent or not root.Parent then state:Destroy();return end
  model:PivotTo(torso.CFrame*CFrame.new(offset)*CFrame.Angles(profile.pitch,0,profile.roll)*CFrame.Angles(0,profile.yaw,0))
 end
 function state:Destroy()
  if self.connection then self.connection:Disconnect();self.connection=nil end
  if self.poseConnection then self.poseConnection:Disconnect();self.poseConnection=nil end
  for _,a in self.arms do a.target:Destroy();a.shoulder.Transform=CFrame.identity;a.elbow.Transform=CFrame.identity;a.wrist.Transform=CFrame.identity end
  table.clear(self.arms)
 end
 update();state.connection=RunService.PreRender:Connect(update);state.poseConnection=RunService.PreSimulation:Connect(pose)
 return state
end
return Fit
