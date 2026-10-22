local Run=game:GetService('RunService');local CAS=game:GetService('ContextActionService');local Players=game:GetService('Players')
local T=require(script.Parent.Parent.ExpeditionUITheme);local Art=require(script.Parent.Parent.SummitArt);local C=require(script.Parent.Parent.SummitConfig)
local M={};local current
function M.play(result,settings,deps)
 if current then current.destroy() end
 local self={};current=self;local dead=false;local elapsed=0;local connections={};local hidden={};local char=Players.LocalPlayer.Character
 local cam=workspace.CurrentCamera;local saved={kind=cam.CameraType,subject=cam.CameraSubject,cf=cam.CFrame,fov=cam.FieldOfView,focus=cam.Focus,selection=game.GuiService.SelectedObject}
 local atmosphere=game.Lighting:FindFirstChildOfClass('Atmosphere');local atmosphereSaved=atmosphere and {density=atmosphere.Density,haze=atmosphere.Haze}
 local folder=Instance.new('Folder');folder.Name='PersonalSummitScene';folder.Parent=workspace
 local gui=T.make('ScreenGui',Players.LocalPlayer.PlayerGui,{Name='SummitPresentation',DisplayOrder=90,ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
 local subtitle=T.text(gui,'SUMMIT REACHED',28);subtitle.TextColor3=T.cream;subtitle.TextStrokeTransparency=.2;subtitle.TextXAlignment=Enum.TextXAlignment.Center;subtitle.Position=UDim2.new(.15,0,0,20);subtitle.Size=UDim2.new(.7,0,0,70)
 local function cleanup(show)
  if dead then return end;dead=true
  for _,c in connections do c:Disconnect() end
  CAS:UnbindAction('CC_SummitSkip');CAS:UnbindAction('CC_SummitInput')
  for part,value in hidden do if part.Parent then part.LocalTransparencyModifier=value end end
  if atmosphere and atmosphere.Parent then atmosphere.Density=atmosphereSaved.density;atmosphere.Haze=atmosphereSaved.haze end
  if workspace.CurrentCamera==cam then cam.CameraType=saved.kind;cam.FieldOfView=saved.fov;cam.CFrame=saved.cf;cam.Focus=saved.focus;cam.CameraSubject=saved.subject and saved.subject.Parent and saved.subject or (Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid')) end
  game.GuiService.SelectedObject=saved.selection and saved.selection.Parent and saved.selection or nil
  folder:Destroy();gui:Destroy();if current==self then current=nil end
  if show then deps.finished() end
 end
 function self.skip() cleanup(true) end
 function self.destroy() cleanup(false) end
 local skip=T.button(gui,'SKIP • B / SPACE',self.skip,T.gold);skip.AnchorPoint=Vector2.new(1,1);skip.Position=UDim2.new(1,-18,1,-18);skip.Size=UDim2.fromOffset(210,56);game.GuiService.SelectedObject=skip
 CAS:BindActionAtPriority('CC_SummitSkip',function(_,state) if state==Enum.UserInputState.Begin then self.skip() end;return Enum.ContextActionResult.Sink end,false,6000,Enum.KeyCode.ButtonB,Enum.KeyCode.Space,Enum.KeyCode.Escape)
 CAS:BindActionAtPriority('CC_SummitInput',function() return Enum.ContextActionResult.Sink end,false,5000,Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
 table.insert(connections,Players.LocalPlayer.CharacterAdded:Connect(self.skip))
 local hum=char and char:FindFirstChildOfClass('Humanoid');if hum then table.insert(connections,hum.Died:Connect(self.skip)) end
 task.delay(24,function() if not dead then self.skip() end end)
 -- Bounded loading: Skip exists before streaming/loading starts, and timeout uses the same immutable result.
 task.spawn(function()
  local ok,err=pcall(function()
   local stage=workspace.World:FindFirstChild('SummitStage');local anchor=stage and stage:FindFirstChild('Celebration')
   if not anchor or not char then self.skip();return end
   local origin=anchor.Position
   local heli=Art.helicopter(folder);local rotor=heli.Rotor;local tail=heli.TailRotor
   local was=char.Archivable;char.Archivable=true;local avatar=char:Clone();char.Archivable=was
   avatar.Name='YourSummitDouble'
   for _,v in avatar:GetDescendants() do
    if v:IsA('BaseScript') or v:IsA('Animator') or v:IsA('Sound') then v:Destroy()
    elseif v:IsA('BasePart') then v.Anchored=v.Name=='HumanoidRootPart';v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
    elseif v:IsA('Humanoid') then v.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
   end
   avatar.Parent=folder;avatar:PivotTo(CFrame.new(origin)*CFrame.Angles(0,math.pi,0))
   for _,v in char:GetDescendants() do if v:IsA('BasePart') then hidden[v]=v.LocalTransparencyModifier;v.LocalTransparencyModifier=1 end end
   local sounds={}
   for kind,id in {fanfare=C.fanfare,rotor=C.rotor} do local s=Instance.new('Sound');s.Name=kind;s.SoundId=id;s.Volume=kind=='rotor' and .22 or .35;s.Looped=kind=='rotor';s.Parent=folder;sounds[kind]=s end
   local loaded=false;task.spawn(function() pcall(function() game.ContentProvider:PreloadAsync({sounds.fanfare,sounds.rotor}) end);loaded=true end)
   local start=os.clock();while not loaded and os.clock()-start<5 and not dead do task.wait(.05) end
   if dead then return end
   if not loaded then self.skip();return end
   cam.CameraType=Enum.CameraType.Scriptable;cam.FieldOfView=55
   if atmosphere then atmosphere.Density=.08;atmosphere.Haze=.3 end
   local cable=Instance.new('Part');cable.Name='WinchCable';cable.Anchored=true;cable.CanCollide=false;cable.CanQuery=false;cable.CanTouch=false;cable.Color=T.ink;cable.Size=Vector3.new(.12,1,.12);cable.Parent=folder
   local armJoints={};for _,v in avatar:GetDescendants() do if v:IsA('Motor6D') and v.Name:lower():find('shoulder') then table.insert(armJoints,{joint=v,cf=v.C0}) end end
   local started=false
   table.insert(connections,Run.RenderStepped:Connect(function(dt)
    local frameOK=pcall(function()
     elapsed+=dt;if elapsed>=C.duration then self.skip();return end
     local t=elapsed;local reduced=settings and settings.reducedMotion
     if t>=4 and not started then started=true;sounds.fanfare:Play();sounds.rotor:Play() end
     local pickup=origin+Vector3.new(-7,17,-2);local helicopterPosition
     if t<8 then helicopterPosition=(origin+Vector3.new(-180,65,110)):Lerp(pickup,math.clamp((t-4)/4,0,1))
     elseif t<13 then helicopterPosition=pickup
     else local a=(t-13)/5;helicopterPosition=pickup+Vector3.new(-210*a*a,75*a*a,-240*a*a) end
     local hc=CFrame.new(helicopterPosition)*CFrame.Angles(0,t>13 and -.25 or 0,0);heli:PivotTo(hc)
     rotor:PivotTo(hc*CFrame.new(0,6.3,0)*CFrame.Angles(0,t*38,0));tail:PivotTo(hc*CFrame.new(1.6,4,17)*CFrame.Angles(t*52,0,0))
     local characterPos=origin
     if t>=8 and t<13 then characterPos=origin:Lerp(pickup+Vector3.new(7,-2,2),math.clamp((t-8)/4.5,0,1))
     elseif t>=13 then characterPos=helicopterPosition+Vector3.new(0,-.5,1)
     elseif t>=4 and not reduced then characterPos+=Vector3.new(0,math.abs(math.sin((t-4)*math.pi*2))*.65,0) end
     avatar:PivotTo(CFrame.new(characterPos)*CFrame.Angles(0,math.pi,0))
     for i,v in armJoints do v.joint.C0=v.cf*CFrame.Angles(0,0,(i%2==0 and 1 or -1)*(t>=4 and t<8 and 1.8 or .15)) end
     local a=helicopterPosition+Vector3.new(7,2,2);local b=characterPos+Vector3.new(0,2,0);cable.Size=Vector3.new(.12,.12,math.max(.1,(a-b).Magnitude));cable.CFrame=CFrame.lookAt((a+b)/2,b);cable.Transparency=t>=8 and t<13 and 0 or 1
     local eye,look
     if t<4 then eye=origin+Vector3.new(100-(reduced and 0 or t*7),48,110);look=origin+Vector3.new(0,-10,0);subtitle.Text='YOU REACHED THE TRUE PEAK'
     elseif t<8 then eye=origin+Vector3.new(18,8,25);look=origin+Vector3.new(0,2,0);subtitle.Text='EXPEDITION COMPLETE\nYour prizes are saved'
     elseif t<13 then eye=origin+Vector3.new(35,22,38);look=origin+Vector3.new(0,9,0);subtitle.Text='A RIDE WELL EARNED'
     else eye=origin+Vector3.new(80,35,95);look=reduced and (origin+Vector3.new(-90,40,-90)) or helicopterPosition;subtitle.Text='THE NEXT ADVENTURE AWAITS' end
     cam.CFrame=CFrame.lookAt(eye,look)
    end)
    if not frameOK then self.skip() end
   end))
  end)
  if not ok then warn('[CC] summit presentation fallback: '..tostring(err));self.skip() end
 end)
 return self
end
return M
