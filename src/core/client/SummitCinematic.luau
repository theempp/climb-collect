local Run=game:GetService('RunService');local CAS=game:GetService('ContextActionService');local Players=game:GetService('Players')
local T=require(script.Parent.Parent.ExpeditionUITheme);local Art=require(script.Parent.Parent.SummitArt);local C=require(script.Parent.Parent.SummitConfig)
local Flight=require(script.Parent.Parent.SummitFlight)
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
   local heli=Art.helicopter(folder);local rotor=heli.Rotor;local tail=heli.TailRotor;local door=heli.Door
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
   local loaded=false;local loadFailed=false;task.spawn(function() local ok=pcall(function() game.ContentProvider:PreloadAsync({sounds.fanfare,sounds.rotor}) end);loaded=ok and sounds.fanfare.IsLoaded and sounds.rotor.IsLoaded;loadFailed=not loaded end)
   local start=os.clock();while not loaded and not loadFailed and os.clock()-start<5 and not dead do task.wait(.05) end
   if dead then return end
   if not loaded then self.skip();return end
   cam.CameraType=Enum.CameraType.Scriptable;cam.FieldOfView=55
   if atmosphere then atmosphere.Density=.08;atmosphere.Haze=.3 end
   local cable=Instance.new('Part');cable.Name='WinchCable';cable.Anchored=true;cable.CanCollide=false;cable.CanQuery=false;cable.CanTouch=false;cable.Color=T.ink;cable.Size=Vector3.new(.12,1,.12);cable.Parent=folder
   local hook=Instance.new('Part');hook.Name='RescueSling';hook.Shape=Enum.PartType.Ball;hook.Size=Vector3.new(.65,.8,.65);hook.Color=T.gold;hook.Anchored=true;hook.CanCollide=false;hook.CanQuery=false;hook.CanTouch=false;hook.Parent=folder
   local armJoints={};for _,v in avatar:GetDescendants() do if v:IsA('Motor6D') and v.Name:lower():find('shoulder') then table.insert(armJoints,{joint=v,cf=v.C0}) end end
   local started=false
   table.insert(connections,Run.RenderStepped:Connect(function(dt)
    local frameOK=pcall(function()
     elapsed+=dt;if elapsed>=C.duration then self.skip();return end
     local t=elapsed;local reduced=settings and settings.reducedMotion
     if t>=4 and not started then started=true;sounds.fanfare:Play();sounds.rotor:Play() end
     local f=Flight.sample(t)
     local helicopterPosition=origin+Vector3.new(f.x,f.y,f.z)
     local hc=CFrame.new(helicopterPosition)*CFrame.Angles(f.pitch,f.yaw,f.roll);heli:PivotTo(hc)
     rotor:PivotTo(hc*CFrame.new(0,6.3,0)*CFrame.Angles(0,t*38,0))
     tail:PivotTo(hc*CFrame.new(1,4.4,18.2)*CFrame.Angles(t*52,0,0))
     door:PivotTo(hc*CFrame.new(0,0,5*f.door))
     local characterPos=origin+Vector3.new(f.riderX,f.riderY,f.riderZ)
     local riderFrame=CFrame.new(characterPos)*CFrame.Angles(0,math.pi,0)
     if t>=13 then riderFrame=hc*CFrame.new(1,-1,2)*CFrame.Angles(0,math.pi,0)
     elseif t>=4 and t<7.5 and not reduced then riderFrame*=CFrame.Angles(0,math.sin((t-4)*2)*.12,0) end
     avatar:PivotTo(riderFrame)
     for i,v in armJoints do
      local celebrate=t>=4 and t<7.5
      local hang=t>=9 and t<11.8
      local angle=celebrate and (1.8+math.sin(t*5)*.12) or (hang and 2.5 or .15)
      v.joint.C0=v.cf*CFrame.Angles(0,0,(i%2==0 and 1 or -1)*angle)
     end
     local a=hc:PointToWorldSpace(Vector3.new(7,2,2))
     local b=t<9 and a:Lerp(origin+Vector3.new(0,2,0),f.lower) or characterPos+Vector3.new(0,2,0)
     cable.Size=Vector3.new(.1,.1,math.max(.05,(a-b).Magnitude));cable.CFrame=CFrame.lookAt((a+b)/2,b)
     local cableVisible=t>=8 and t<12.7
     cable.Transparency=cableVisible and 0 or 1;hook.Transparency=cable.Transparency;hook.CFrame=CFrame.new(b)
     sounds.rotor.Volume=.04+.22*math.clamp((t-4)/4,0,1)*(1-f.depart*.8)
     local eye,look
     if t<4 then
      eye=origin+Vector3.new(62-(reduced and 0 or t*4),30,66);look=origin+Vector3.new(-4,-7,0);subtitle.Text='YOU REACHED THE TRUE PEAK'
     elseif t<8 then
      eye=origin+Vector3.new(20,8,25);look=origin+Vector3.new(-3,5,0);subtitle.Text='EXPEDITION COMPLETE\nYour prizes are saved'
     elseif t<13 then
      eye=origin+Vector3.new(26,18,-30);look=origin+Vector3.new(-3,10,0);subtitle.Text='A RIDE WELL EARNED'
     else
      eye=origin+Vector3.new(48,27,54);look=reduced and (origin+Vector3.new(-80,42,-100)) or helicopterPosition;subtitle.Text='THE NEXT ADVENTURE AWAITS'
     end
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
