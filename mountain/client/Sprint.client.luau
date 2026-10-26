-- Shift holds sprint; touch uses a toggle. Speed remains server-owned.
local Players=game:GetService('Players')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild('MountainRemotes'):WaitForChild('SprintRequest')
local gui=Instance.new('ScreenGui');gui.Name='MountainSprint';gui.ResetOnSpawn=false;gui.DisplayOrder=15;gui.Parent=player:WaitForChild('PlayerGui')
local button=Instance.new('TextButton');button.Name='SprintToggle';button.AnchorPoint=Vector2.new(1,1);button.Size=UDim2.fromOffset(100,50)
button.Position=UDim2.new(1,-22,1,-170);button.BackgroundColor3=Color3.fromRGB(34,67,60);button.TextColor3=Color3.fromRGB(248,244,216)
button.Font=Enum.Font.GothamBold;button.TextSize=15;button.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,14);corner.Parent=button
local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(160,205,169);stroke.Thickness=2;stroke.Parent=button
local wanted=false;local held={};local toggle=false;local character,humanoid,track,animation
local function label()
 button.Visible=Input.TouchEnabled
 button.Text=if wanted then 'SPRINT ON' else 'SPRINT'
 button.BackgroundColor3=if wanted then Color3.fromRGB(70,114,79) else Color3.fromRGB(34,67,60)
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
label()
