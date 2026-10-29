-- Input/presentation for the single server traversal machine. No local climbing physics.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local Run=game:GetService("RunService")
local HS=game:GetService("HttpService")
local plr=Players.LocalPlayer
local Net=require(RS:WaitForChild("CC_Core"):WaitForChild("Net"))
local K=require(RS.CC_Core:WaitForChild("TraversalConfig"))
local request=Net.get("CoreRequest")
local fx=Net.get("CoreFx")
local sections={}
local function V(a) return Vector3.new(a[1],a[2],a[3]) end
local folder=RS:WaitForChild("CC_TraversalDefs",30)
if folder then
 for _,sv in ipairs(folder:GetChildren()) do
  local ok,s=pcall(function() return HS:JSONDecode(sv.Value) end)
  if ok then s.entry,s.exit=V(s.entry),V(s.exit); for _,h in ipairs(s.holds) do h.pos=V(h.p); if h.alternative then h.alternative.pos=V(h.alternative.p) end end; sections[s.id]=s end
 end
end
local gui=Instance.new("ScreenGui")
gui.Name="CC_TraversalUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.DisplayOrder=15; gui.Parent=plr:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(0.5,1); panel.Position=UDim2.new(0.5,0,1,-18); panel.Size=UDim2.new(0.52,0,0,122)
panel.BackgroundColor3=Color3.fromRGB(35,44,51); panel.BackgroundTransparency=0.08; panel.BorderSizePixel=0; panel.Parent=gui
local limit=Instance.new("UISizeConstraint"); limit.MinSize=Vector2.new(310,122); limit.MaxSize=Vector2.new(580,140); limit.Parent=panel
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
local border=Instance.new("UIStroke"); border.Color=Color3.fromRGB(171,135,88); border.Thickness=1; border.Parent=panel
local label=Instance.new("TextLabel")
label.Position=UDim2.fromOffset(10,4); label.Size=UDim2.new(1,-20,0,44); label.BackgroundTransparency=1
label.Font=Enum.Font.GothamMedium; label.TextSize=16; label.TextColor3=Color3.fromRGB(244,232,210); label.TextWrapped=true; label.Parent=panel
local function button(name,x,w)
 local b=Instance.new("TextButton"); b.Name=name; b.Position=UDim2.new(x,4,0,52); b.Size=UDim2.new(w,-8,0,58)
 b.BackgroundColor3=Color3.fromRGB(62,75,84); b.BorderSizePixel=0; b.TextColor3=Color3.fromRGB(255,235,196)
 b.TextSize=17; b.Font=Enum.Font.GothamSemibold; b.TextWrapped=true; b.Selectable=true; b.Parent=panel
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
 return b
end
local left=button("Left",0,0.29)
local right=button("Right",0.29,0.29)
local choice=button("FootholdChoice",0.58,0.22)
local release=button("Release",0.80,0.20)
local context=button("Context",0,0.58)
local secondary=button("Secondary",0.58,0.42)
local device="keyboard"
local focused=true
local alternate=false
local jumpAt=-100
local lastSent={}
local contextAction,secondaryAction,mode="clip",nil,"ground"
local function blocked() return not focused or plr:GetAttribute("CC_MenuOpen")==true or UIS:GetFocusedTextBox()~=nil end
local function send(action,extra)
 if blocked() then return end
 local now=os.clock(); if now-(lastSent[action] or -10)<0.12 then return end; lastSent[action]=now
 local p=extra or {}; p.action=action; request:FireServer("traversal",p)
end
local function hand(side) send("step",{hand=side,choice=alternate and "stable" or "direct"}) end
left.Activated:Connect(function() hand("L") end)
right.Activated:Connect(function() hand("R") end)
release.Activated:Connect(function() send("release") end)
choice.Activated:Connect(function() alternate=not alternate end)
context.Activated:Connect(function() if contextAction then send(contextAction) end end)
secondary.Activated:Connect(function() if secondaryAction then send(secondaryAction) end end)
local function setDevice(t)
 device=t==Enum.UserInputType.Touch and "touch" or tostring(t):find("Gamepad") and "gamepad" or "keyboard"
 alternate=false; lastSent={}
	if mode=="flight" then request:FireServer("traversal",{action="steer",x=0,z=0}) end
end
setDevice(UIS:GetLastInputType())
UIS.LastInputTypeChanged:Connect(setDevice)
UIS.WindowFocusReleased:Connect(function() focused=false; alternate=false; lastSent={}; if mode=="flight" then request:FireServer("traversal",{action="steer",x=0,z=0}) end end)
UIS.WindowFocused:Connect(function() focused=true end)
plr:GetAttributeChangedSignal("CC_MenuOpen"):Connect(function() alternate=false; lastSent={}; if mode=="flight" then request:FireServer("traversal",{action="steer",x=0,z=0}) end end)
local function held() return mode=="climb" or mode=="rope" end
local function bind(name,callback,keys)
 CAS:BindActionAtPriority(name,function(_,state)
  if blocked() then return Enum.ContextActionResult.Pass end
  if state==Enum.UserInputState.Begin and callback() then return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end,false,2100,table.unpack(keys))
end
bind("CC_LeftHand",function() if held() then hand("L"); return true end end,{Enum.KeyCode.Q,Enum.KeyCode.ButtonL1})
bind("CC_RightHand",function() if held() then hand("R"); return true end end,{Enum.KeyCode.R,Enum.KeyCode.ButtonR1})
bind("CC_Release",function() if held() or mode=="hanging" then send("release"); return true end end,{Enum.KeyCode.X,Enum.KeyCode.ButtonB})
bind("CC_Choice",function() if held() then alternate=not alternate; return true end end,{Enum.KeyCode.Tab,Enum.KeyCode.DPadRight})
-- F / Y matches traversal anchors; global creature/station prompts retain E / X.
-- Bind the visible contextual action too, so an off-screen native prompt cannot make the HUD key inert.
bind("CC_TraversalContext",function() if contextAction then send(contextAction); return true end end,{Enum.KeyCode.F,Enum.KeyCode.ButtonY})
bind("CC_Descend",function() if mode=="ground" and secondaryAction=="descend" then send("descend"); return true end end,{Enum.KeyCode.C,Enum.KeyCode.DPadDown})
UIS.JumpRequest:Connect(function()
 local ch=plr.Character; local h=ch and ch:FindFirstChildOfClass("Humanoid")
 if not blocked() and mode=="ground" and h and h.FloorMaterial~=Enum.Material.Air and os.clock()-jumpAt>0.5 then jumpAt=os.clock(); send("jump") end
end)
local markers={}
for i=1,2 do
 local part=Instance.new("Part"); part.Name="NextFoothold"; part.Shape=Enum.PartType.Ball; part.Size=Vector3.new(0.55,0.55,0.55)
 part.Anchored,part.CanCollide,part.CanQuery,part.CanTouch,part.CastShadow=true,false,false,false,false
 part.Material=Enum.Material.Neon; part.Color=Color3.fromRGB(244,194,107); part.Transparency=1; part.Parent=workspace.CurrentCamera
 local tag=Instance.new("BillboardGui"); tag.Size=UDim2.fromOffset(104,34); tag.StudsOffset=Vector3.new(0,1.1,0); tag.AlwaysOnTop=true; tag.MaxDistance=55; tag.Enabled=false; tag.Parent=part
 local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundColor3=Color3.fromRGB(32,42,49); text.BackgroundTransparency=0.1; text.TextColor3=Color3.fromRGB(255,236,199); text.TextSize=14; text.Font=Enum.Font.GothamBold; text.Parent=tag
 Instance.new("UICorner",text).CornerRadius=UDim.new(0,6)
 markers[i]={part=part,tag=tag,text=text}
end
local cueUntil,cueText=0,nil
fx.OnClientEvent:Connect(function(p)
 if type(p)=="table" and p.kind=="traversalCue" then cueText=tostring(p.text); cueUntil=os.clock()+1.3 end
end)
local function nearest(pos,top)
 local best,dist
 for _,s in pairs(sections) do
  local d=(pos-(top and s.exit or s.entry)).Magnitude
  if d<(top and K.topRange or K.entryRange)+1 and (not dist or d<dist) then best,dist=s,d end
 end
 return best
end
local function campNear(pos)
 local world=workspace:FindFirstChild("World"); local cps=world and world:FindFirstChild("Checkpoints")
 for _,p in ipairs(cps and cps:GetChildren() or {}) do
  if p:GetAttribute("Camp") and tostring(p:GetAttribute("Checkpoint")):match("^Camp[1-4]$") and (pos-p.Position).Magnitude<K.flightLaunchRadius then return true end
 end
 return false
end
local acc,steerAt,grabAt=0,0,0
local animationCharacter,climbTrack
local function animate(ch,h)
	if animationCharacter ~= ch then
		if climbTrack then climbTrack:Stop(0); climbTrack:Destroy() end
		animationCharacter,climbTrack=ch,nil
	end
	local active=held() or mode=="hanging"
	if active and not climbTrack then
		local stock=ch:FindFirstChild("Animate")
		local folder=stock and stock:FindFirstChild("climb")
		local asset=folder and folder:FindFirstChildOfClass("Animation")
		local animator=h:FindFirstChildOfClass("Animator")
		if asset and animator then
			local ok,track=pcall(function() return animator:LoadAnimation(asset) end)
			if ok then climbTrack=track; track.Priority=Enum.AnimationPriority.Action; track.Looped=true end
		end
	end
	if climbTrack then
		if active then
			if not climbTrack.IsPlaying then climbTrack:Play(0.15) end
			climbTrack:AdjustSpeed(held() and workspace:GetServerTimeNow()<(ch:GetAttribute("CC_RhythmAt") or 0) and 0.8 or 0)
		elseif climbTrack.IsPlaying then climbTrack:Stop(0.15) end
	end
end
Run.Heartbeat:Connect(function(dt)
 acc+=dt; if acc<0.1 then return end; acc=0
 local ch=plr.Character; local h=ch and ch:FindFirstChildOfClass("Humanoid"); local r=ch and ch:FindFirstChild("HumanoidRootPart")
 if not r or not h then panel.Visible=false; return end
 local nextMode=ch:GetAttribute("CC_TraversalState") or "ground"
 if nextMode~=mode then mode=nextMode; alternate=false; lastSent={} end
	animate(ch,h)
	if mode=="ground" and ch:GetAttribute("CC_CramponsActive") and h.MoveDirection.Magnitude<0.1 then
		local v=r.AssemblyLinearVelocity; r.AssemblyLinearVelocity=Vector3.new(v.X*0.3,v.Y,v.Z*0.3)
	end
 for _,m in ipairs(markers) do m.part.Transparency=1; m.tag.Enabled=false end
 local active=held()
 left.Visible=active; right.Visible=active; choice.Visible=active; release.Visible=active or mode=="hanging"
 context.Visible=not active; secondary.Visible=not active and mode~="hanging"
 contextAction,secondaryAction=nil,nil
 panel.Visible=not blocked()
 local scale=math.clamp(tonumber(plr:GetAttribute("CC_TextScale")) or 1,0.9,1.35)
 label.TextSize=16*scale
	left.TextSize=17*scale; right.TextSize=17*scale
	choice.TextSize=14*scale; release.TextSize=14*scale
	context.TextSize=16*scale; secondary.TextSize=16*scale
	for _,m in ipairs(markers) do m.text.TextSize=14*scale end
 local lh=device=="gamepad" and "L1" or device=="keyboard" and "Q" or "Left"
	local rh=device=="gamepad" and "R1" or device=="keyboard" and "R" or "Right"
 local use=device=="gamepad" and "Y" or device=="keyboard" and "F" or "Tap"
 local stop=device=="gamepad" and "B" or device=="keyboard" and "X" or "Release"
 release.Text=stop.."\nLet go"
 if active then
  local nextHand=ch:GetAttribute("CC_NextHand") or "L"
  local ready=workspace:GetServerTimeNow()>=(ch:GetAttribute("CC_RhythmAt") or 0)
  label.Text=(mode=="rope" and "SHARED ROPE  •  " or "CLIPPED  •  ")..(ready and ("Next: "..(nextHand=="L" and "LEFT" or "RIGHT").."  •  No hurry") or "Moving to your foothold…")
  left.Text=device=="touch" and "LEFT" or lh.."  LEFT"; right.Text=device=="touch" and "RIGHT" or rh.."  RIGHT"
  left.BackgroundColor3=nextHand=="L" and Color3.fromRGB(120,91,54) or Color3.fromRGB(62,75,84)
  right.BackgroundColor3=nextHand=="R" and Color3.fromRGB(120,91,54) or Color3.fromRGB(62,75,84)
  local sec=sections[ch:GetAttribute("CC_SectionId")]
  local index=(ch:GetAttribute("CC_HoldIndex") or 1)+(ch:GetAttribute("CC_ClimbDirection") or 1)
  local nextHold=sec and sec.holds[index]
  choice.Visible=nextHold~=nil and nextHold.alternative~=nil
  choice.Text=alternate and "2\nSTABLE" or "1\nCHOICE"
  if nextHold then
   for i,hold in ipairs({nextHold,nextHold.alternative}) do
    local m=markers[i]; m.part.Position=hold.pos; m.part.Transparency=0.15; m.tag.Enabled=true
    m.text.Text=(i==1 and "1 • " or "2 • ")..(hold.stable and "STABLE" or (nextHand=="L" and "LEFT" or "RIGHT"))
   end
  else label.Text="One more rhythm input to step onto the landing." end
 elseif mode=="hanging" then
  contextAction="recover"; context.Size=UDim2.new(0.8,-8,0,58)
  local can=ch:GetAttribute("CC_CanRecover")
  context.Text=can and (use.."  Regain hold") or "Resting • grip recovering"
  label.Text="Harness caught you • finds safe"
 elseif mode=="flight" then
  context.Text="Steer with movement controls"; context.Size=UDim2.new(1,-8,0,58); secondary.Visible=false
  label.Text="PARACHUTE  •  Land at a camp below or the Foothold"
  if os.clock()-steerAt>0.42 and not blocked() then steerAt=os.clock(); send("steer",{x=h.MoveDirection.X,z=h.MoveDirection.Z}) end
 else
  context.Size=UDim2.new(0.58,-8,0,58)
  local near=nearest(r.Position,false); local top=nearest(r.Position,true)
  if os.clock()-jumpAt<K.jumpWindow and h.FloorMaterial==Enum.Material.Air and campNear(r.Position) then
   contextAction="parachute"; context.Text=use.."  Open parachute"; secondary.Visible=false; label.Text="Intentional camp jump • safe parachute practice"
  elseif near then
   contextAction="clip"; context.Text=use.."  Clip & climb"; secondary.Visible=false
   label.Text=near.tutorial and "First protected climb • clip once at the marked anchor" or "Marked anchor • harness protects this climb"
   if os.clock()-grabAt>0.7 and h.MoveDirection:Dot(V(near.into))>0.5 then grabAt=os.clock(); send("grab") end
  elseif top then
   contextAction="rope"; secondaryAction="descend"; context.Text=use.."  Shared rope"
   secondary.Text=(device=="gamepad" and "↓" or device=="keyboard" and "C" or "Tap").."  Climb down"
   label.Text="Top anchor • share this existing route with other climbers"
  elseif campNear(r.Position) then
   context.Text="Jump, then "..use.." to deploy"; secondary.Visible=false
   label.Text="Parachute practice • return areas only; cargo stays carried"
  else panel.Visible=false end
 end
 if cueText and os.clock()<cueUntil then label.Text=cueText end
 -- Native truss climbing is retired even though its tutorial art is preserved.
 h:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
end)
plr.CharacterAdded:Connect(function(ch)
 mode="ground"; alternate=false; jumpAt=-100; lastSent={}
 task.spawn(function()
  local root=ch:WaitForChild("HumanoidRootPart",10); local p=root and root:WaitForChild("RescuePrompt",10)
  if p then p.Enabled=false; p:GetPropertyChangedSignal("Enabled"):Connect(function() if p.Enabled then p.Enabled=false end end) end
 end)
end)
