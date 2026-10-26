-- Local, cosmetic altitude response; never changes weather, physics or game state.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local Input=game:GetService('UserInputService')
local P=require(game:GetService('ReplicatedStorage'):WaitForChild('MountainShared'):WaitForChild('AlpineProfile'))
local player=Players.LocalPlayer
local fx=Instance.new('Folder');fx.Name='LocalAltitudeAtmosphere';fx.Parent=workspace
local anchor=Instance.new('Part');anchor.Name='AirVolume';anchor.Size=Vector3.new(54,14,46)
anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false;anchor.Parent=fx
local tint=Instance.new('ColorCorrectionEffect');tint.Name='MountainAltitudeTint';tint.Enabled=false;tint.Parent=Lighting
local function emitter(name,texture,size,life,speed,color)
 local e=Instance.new('ParticleEmitter');e.Name=name;e.Texture=texture;e.Rate=0;e.Enabled=false
 e.Size=NumberSequence.new(size);e.Lifetime=NumberRange.new(life*.7,life);e.Speed=NumberRange.new(speed*.7,speed)
 e.SpreadAngle=Vector2.new(45,30);e.EmissionDirection=Enum.NormalId.Right;e.Acceleration=Vector3.new(2,-.7,0)
 e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-12,12);e.Color=ColorSequence.new(color)
 e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.42),NumberSequenceKeypoint.new(.75,.62),NumberSequenceKeypoint.new(1,1)})
 e.LightEmission=.18;e.LightInfluence=.75;e.Parent=anchor;return e
end
local snow=emitter('Spindrift','rbxasset://textures/particles/sparkles_main.dds',.15,2.4,9,Color3.fromRGB(217,235,245))
local motes=emitter('AlpineMotes','rbxasset://textures/particles/sparkles_main.dds',.27,3.5,2,Color3.fromRGB(158,204,236))
local wisps=emitter('WindVeil','rbxasset://textures/particles/smoke_main.dds',3.5,2,7,Color3.fromRGB(185,207,223))
wisps.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.4,.94),NumberSequenceKeypoint.new(1,1)})
local intensity,elapsed,average=0,0,1/60
local function quality()
 local factor=if Input.TouchEnabled then .55 else 1
 local ok,level=pcall(function() return UserSettings():GetService('UserGameSettings').SavedQualityLevel.Value end)
 if ok and level>0 and level<=3 then factor=math.min(factor,.4) end
 if average>1/35 then factor=math.min(factor,.35) end
 return factor
end
local connection
connection=Run.Heartbeat:Connect(function(dt)
 average+=(math.min(dt,.25)-average)*math.min(dt*2,1);elapsed+=dt
 if elapsed<.1 then return end
 local step=elapsed;elapsed=0
 local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 local target=0
 if root and humanoid and humanoid.Health>0 then local p=root.Position;target=P.intensity(p.X,p.Y,p.Z) end
 intensity+=(target-intensity)*(1-math.exp(-step*2.5))
 local active=target>0 or intensity>.003
 tint.Enabled=active;tint.TintColor=Color3.new(1,1,1):Lerp(Color3.fromRGB(219,233,255),intensity*.28)
 tint.Contrast=intensity*.035;tint.Saturation=-intensity*.045
 local scale=quality();snow.Rate=28*intensity^2*scale;motes.Rate=8*intensity*scale;wisps.Rate=2.5*intensity^2*scale
 for _,e in {snow,motes,wisps} do e.Enabled=target>0;if target==0 then e:Clear() end end
 if root then anchor.CFrame=CFrame.new(root.Position+Vector3.new(-16,12,0)) end
 fx:SetAttribute('Intensity',intensity);fx:SetAttribute('QualityScale',scale);fx:SetAttribute('Target',target)
end)
script.Destroying:Connect(function() connection:Disconnect();fx:Destroy();tint:Destroy() end)
