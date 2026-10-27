-- Shift holds sprint; touch uses a toggle. Speed remains server-owned.
local Players=game:GetService('Players')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild('MountainRemotes'):WaitForChild('SprintRequest')
local P=require(game.ReplicatedStorage.MountainShared.UIPresentation)
local W=require(script.Parent.UI.Widgets)
local T=require(script.Parent.UI.Theme)
local gui=Instance.new('ScreenGui');gui.Name='MountainSprint';gui.ResetOnSpawn=false;gui.DisplayOrder=15;gui.Parent=player:WaitForChild('PlayerGui')
gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ClipToDeviceSafeArea=true
local root=W.frame(gui,'SafeRoot',UDim2.fromScale(1,1));root.BackgroundTransparency=1
-- HUD v2 (mock 1/2): round green candy with the sprint icon and an ON badge; Text stays for audits, the label is hidden.
local button=W.button(root,'SprintToggle','Sprint',UDim2.fromOffset(64,64),nil,nil,'ok')
button.Position=UDim2.new(1,-22,1,-170);button.Label.Visible=false
for _,o in ipairs({button,button.Face,button.Face.Shine}) do o:FindFirstChildOfClass('UICorner').CornerRadius=UDim.new(.5,0) end
W.icon(button,'Sprint',UDim2.fromOffset(44,44),UDim2.new(.5,-22,0,6))
local badge=W.tag(button,'ON',UDim2.new(1,-30,0,-8),T.ok.base);badge.Size=UDim2.fromOffset(36,20);badge.ZIndex=3;badge.Text.ZIndex=4;badge.Visible=false
local wanted=false;local held={};local toggle=false;local character,humanoid,track,animation
local function label()
 button.Visible=Input.TouchEnabled
 button.Text=if wanted then 'Sprint ON' else 'Sprint'
 badge.Visible=wanted
end
local function set(value)
 if wanted~=value then wanted=value;remote:FireServer(value) end
 label()
end
local function reset() held={};toggle=false;set(false) end
button.Activated:Connect(function() toggle=not toggle;set(toggle) end)
Input.InputBegan:Connect(function(input,processed)
 if processed or Input:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then held[input.KeyCode]=true;set(true) end
end)
Input.InputEnded:Connect(function(input)
 if held[input.KeyCode] then held[input.KeyCode]=nil;set(toggle or next(held)~=nil) end
end)
Input.WindowFocusReleased:Connect(reset)
Input.TextBoxFocused:Connect(reset)
Input:GetPropertyChangedSignal('TouchEnabled'):Connect(label)
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
local age=0
Run.Heartbeat:Connect(function(dt)
 age+=dt;if age<.2 then return end;age=0
 local hud=player.PlayerGui:FindFirstChild('MountainHUD');local safe=hud and hud:FindFirstChild('SafeRoot')
 button.Visible=Input.TouchEnabled and safe~=nil and not safe:FindFirstChild('HubShade') and not safe:FindFirstChild('Confirmation') and not safe.Loading.Visible
 if not button.Visible then return end
 local obstacles={};local touch=player.PlayerGui:FindFirstChild('TouchGui')
 for _,name in ipairs({'DynamicThumbstickFrame','ThumbstickFrame','JumpButton'}) do
  local o=touch and touch:FindFirstChild(name,true)
  if o and o.Visible then table.insert(obstacles,{x=o.AbsolutePosition.X-root.AbsolutePosition.X,y=o.AbsolutePosition.Y-root.AbsolutePosition.Y,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y}) end
 end
 local r=P.hudLayout(root.AbsoluteSize.X,root.AbsoluteSize.Y,obstacles).sprint
 button.Position=UDim2.fromOffset(r.x+r.w-64,r.y+r.h-64)
end)
label()
