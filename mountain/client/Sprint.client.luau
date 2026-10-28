-- Shift holds sprint; touch uses the Glassbloom sprint orb (intel §2: W.orb preset sprint, 54 at (1,-96, 1,-20)). Pref sprintMode
-- (UIProtocol): 0 = HOLD (press and hold the orb), 1 = TOGGLE (tap). Speed remains server-owned.
local Players=game:GetService('Players')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild('MountainRemotes'):WaitForChild('SprintRequest')
local P=require(game.ReplicatedStorage.MountainShared.UIPresentation)
local function bx(o) return {x=o.AbsolutePosition.X,y=o.AbsolutePosition.Y,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y} end
local W=require(script.Parent.UI.Widgets)
local T=require(script.Parent.UI.Theme)
local gui=Instance.new('ScreenGui');gui.Name='MountainSprint';gui.ResetOnSpawn=false;gui.DisplayOrder=15;gui.Parent=player:WaitForChild('PlayerGui')
gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ClipToDeviceSafeArea=true
local root=W.frame(gui,'SafeRoot',UDim2.fromScale(1,1));root.BackgroundTransparency=1
-- Same virtual space as the HUD root (G2): one UIScale on this gui's HUD layer.
local layer=W.new('Frame',root,{Name='Hud',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0})
local uiScale=W.new('UIScale',layer,{Scale=1})
local wanted=false;local held={};local toggle=false;local pressing=false;local character,humanoid,track,animation
local function holdMode() return T.prefs.sprintMode==0 end
local set
local button=W.orb(layer,'SprintToggle',54,{preset='sprint',fn=function()
 if holdMode() then return end
 toggle=not toggle;set(toggle or next(held)~=nil)
end})
button:SetAttribute('HudClass','permanent');button:SetAttribute('HudPiece','sprint');button.Text='Sprint'
local function label()
 -- GAP: the board draws no sprint on-state; the state is the On attribute + Text (audits read 'Sprint ON').
 button.Text=if wanted then 'Sprint ON' else 'Sprint';button:SetAttribute('On',wanted)
end
function set(value)
 if wanted~=value then wanted=value;remote:FireServer(value) end
 label()
end
local function reset() held={};toggle=false;pressing=false;set(false) end
-- HOLD: press on the orb's hit area sprints until release.
local hit=button:FindFirstChild('Hit')
local function pointer(i) return i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 end
hit.InputBegan:Connect(function(i) if holdMode() and pointer(i) then pressing=true;set(true) end end)
hit.InputEnded:Connect(function(i) if pressing and pointer(i) then pressing=false;set(toggle or next(held)~=nil) end end)
hit.MouseLeave:Connect(function() if pressing then pressing=false;set(toggle or next(held)~=nil) end end)
Input.InputBegan:Connect(function(input,processed)
 if processed or Input:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then held[input.KeyCode]=true;set(true) end
end)
Input.InputEnded:Connect(function(input)
 if held[input.KeyCode] then held[input.KeyCode]=nil;set(toggle or pressing or next(held)~=nil) end
end)
Input.WindowFocusReleased:Connect(reset)
Input.TextBoxFocused:Connect(reset)
local mode=nil
local function bind(c)
 reset();if track then track:Stop(0);track:Destroy();track=nil end;if animation then animation:Destroy() end
 character=c;humanoid=c:WaitForChild('Humanoid')
 local animator=humanoid:WaitForChild('Animator')
 -- Roblox's standard run, already used by the default R15 Animate controller.
 -- R6 uses its standard locomotion clip at sprint cadence.
 animation=Instance.new('Animation');animation.AnimationId=if humanoid.RigType==Enum.HumanoidRigType.R15 then 'rbxassetid://507767714' else 'rbxassetid://180426354'
 track=animator:LoadAnimation(animation);track.Looped=true;track.Priority=Enum.AnimationPriority.Movement
 humanoid.Died:Connect(reset)
end
player.CharacterAdded:Connect(bind)
if player.Character then task.spawn(bind,player.Character) end
Run.PreAnimation:Connect(function()
 if not humanoid or not track or not character then return end
 local state=humanoid:GetState()
 local running=character:GetAttribute('Sprinting')==true and humanoid.MoveDirection.Magnitude>.1 and humanoid.Health>0
  and humanoid.FloorMaterial~=Enum.Material.Air and not humanoid.Sit and not humanoid.PlatformStand
  and state~=Enum.HumanoidStateType.Jumping and state~=Enum.HumanoidStateType.Freefall and state~=Enum.HumanoidStateType.Climbing and state~=Enum.HumanoidStateType.Swimming
 if running then
  if not track.IsPlaying then track:Play(.15) end
  track:AdjustSpeed(humanoid.WalkSpeed/(if humanoid.RigType==Enum.HumanoidRigType.R15 then 20 else 16))
 elseif track.IsPlaying then track:Stop(.15) end
end)
local age=0;local scale=1
Run.Heartbeat:Connect(function(dt)
 age+=dt;if age<.2 then return end;age=0
 -- Switching hold/toggle drops a latched toggle.
 local m=T.prefs.sprintMode;if m~=mode then mode=m;if toggle then toggle=false;set(pressing or next(held)~=nil) end end
 local hud=player.PlayerGui:FindFirstChild('MountainHUD');local safe=hud and hud:FindFirstChild('SafeRoot')
 -- Touch devices only; QA fixtures (HudFixture, StudioAids) show it for audits on desktop.
 button.Visible=(Input.TouchEnabled or (hud~=nil and hud:GetAttribute('HudFixture')~=nil)) and safe~=nil and not safe:FindFirstChild('HubShade') and not safe:FindFirstChild('Confirmation') and not safe:FindFirstChild('HatchReveal') and not safe.Loading.Visible
 if not button.Visible then return end
 local v=root.AbsoluteSize;local s=P.hudScale(T.prefs.hudScale,v.X)
 if s~=scale then scale=s;uiScale.Scale=s;layer.Size=UDim2.fromScale(1/s,1/s);W.hit(button,44/s) end
 local obstacles={};local touch=player.PlayerGui:FindFirstChild('TouchGui')
 for name,kind in pairs({JumpButton='jump',ThumbstickFrame='stick'}) do
  local o=touch and touch:FindFirstChild(name,true)
  if o and o.Visible then local r=P.nativeRect(bx(o),bx(root:FindFirstAncestorWhichIsA('LayerCollector')),bx(root),kind=='jump');r.kind=kind;table.insert(obstacles,r) end
 end
 local r=P.hudLayout(v.X,v.Y,obstacles,Input.TouchEnabled,nil,{scale=s}).sprint
 button.Position=UDim2.fromOffset(r.x,r.y)
end)
label()
require(script.Parent.UI.Controller)
