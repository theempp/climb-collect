local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local CAS=game:GetService('ContextActionService')
local Run=game:GetService('RunService')
local C=require(script.Parent.Parent.MovementConfig)
local Theme=require(script.Parent.Parent.ExpeditionUITheme)
local M={}
function M.mount(deps)
 local p=Players.LocalPlayer
 local connections={};local characterConnections={}
 local ch,h,track,assetKey,attemptAt,failedKey
 local focused=true;local desired=false;local seq=0;local generation
 local blockedBefore=false;local leaseAt=0;local suppressionUntil=0;local dead=false
 local scanAt=0;local trackPending=false
 local function connect(signal,fn,list) local c=signal:Connect(fn);table.insert(list or connections,c);return c end
 local function send(action,enabled)
  if not ch or not generation then return end
  seq+=1;deps.request('movement',{action=action,enabled=enabled,generation=generation,seq=seq})
 end
 local function stopTrack(destroy)
  if track then track:Stop(C.blendSeconds);if destroy then track:Destroy();track=nil end end
 end
 -- Only tell the server when sprint is actually on; repeated jump/blocked events must not eat the request cap.
 local function clear()
  if desired or (ch and ch:GetAttribute('CC_SprintRequested')) then send('sprint',false) end
  desired=false;stopTrack(false)
 end
 local function blocked()
  return not focused or UIS:GetFocusedTextBox()~=nil or deps.blocked() or os.clock()<suppressionUntil
 end
 local function toggle()
  if dead or blocked() or not ch or not ch:GetAttribute('CC_SprintAvailable') then return end
  desired=not desired;send('sprint',desired)
 end
 local button=Theme.button(deps.parent,'SPRINT OFF',toggle,Theme.teal)
 button.Name='SprintToggle';button.AnchorPoint=Vector2.new(1,1);button.Size=UDim2.fromOffset(144,56);button.ZIndex=30;button.Visible=false
 local function releaseCharacter()
  for _,c in ipairs(characterConnections) do c:Disconnect() end;table.clear(characterConnections)
  stopTrack(true);ch=nil;h=nil;generation=nil;assetKey=nil;failedKey=nil;trackPending=false;desired=false;suppressionUntil=0
 end
 local function bindCharacter(character)
  releaseCharacter();ch=character;seq=0;scanAt=0
  generation=ch:GetAttribute('CC_MovementGeneration')
  connect(ch:GetAttributeChangedSignal('CC_MovementGeneration'),function() generation=ch:GetAttribute('CC_MovementGeneration');seq=0;desired=false end,characterConnections)
  connect(ch:GetAttributeChangedSignal('CC_SprintRequested'),function() desired=ch:GetAttribute('CC_SprintRequested')==true end,characterConnections)
  connect(ch:GetAttributeChangedSignal('CC_MovementZone'),function() clear() end,characterConnections)
 end
 local function discover(now)
  if not ch or now<scanAt then return end;scanAt=now+0.5
  h=ch:FindFirstChildOfClass('Humanoid')
  if not h or (h.RigType~=Enum.HumanoidRigType.R6 and h.RigType~=Enum.HumanoidRigType.R15) then return end
  local animate=ch:FindFirstChild('Animate');local animator=h:FindFirstChildOfClass('Animator')
  local run=animate and animate:FindFirstChild('run');local walk=animate and animate:FindFirstChild('walk')
  local asset=run and run:FindFirstChildWhichIsA('Animation') or walk and walk:FindFirstChildWhichIsA('Animation')
  if not asset or asset.AnimationId=='' or not animator then return end
  local key=tostring(h.RigType)..':'..asset.AnimationId
  if key==assetKey or key==failedKey then return end
  stopTrack(true);assetKey=key
  local ok,result=pcall(function() return animator:LoadAnimation(asset) end)
  if not ok then failedKey=key;return end
  track=result;track.Name='CC_GroundRun';track.Looped=true;track.Priority=Enum.AnimationPriority.Movement
  attemptAt=now;trackPending=true
 end
 CAS:BindActionAtPriority('CC_SprintToggle',function(_,state)
  if state==Enum.UserInputState.Begin then toggle() end
  return Enum.ContextActionResult.Sink
 end,false,1900,Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3)
 connect(UIS.WindowFocusReleased,function() focused=false;clear();send('suppress',true) end)
 connect(UIS.WindowFocused,function() focused=true end)
 connect(UIS.TextBoxFocused,function() clear();send('suppress',true) end)
 connect(UIS.JumpRequest,clear)
 connect(p.CharacterAdded,bindCharacter)
 connect(p.CharacterRemoving,function(character) if character==ch then clear();releaseCharacter() end end)
 if p.Character then bindCharacter(p.Character) end
 local function sink() return Enum.ContextActionResult.Sink end
 connect(Run.RenderStepped,function()
  if dead then return end
  local now=os.clock();discover(now)
  local isBlocked=blocked()
  if isBlocked~=blockedBefore then
   clear();send('suppress',isBlocked);leaseAt=now
   if isBlocked then
    CAS:BindActionAtPriority('CC_MovementModal',sink,false,3000,Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump,Enum.KeyCode.Thumbstick1)
   else CAS:UnbindAction('CC_MovementModal') end
   blockedBefore=isBlocked
  elseif isBlocked and now-leaseAt>=0.5 then leaseAt=now;send('suppress',true) end
  local mode=ch and ch:GetAttribute('CC_TraversalState')
  local zone=ch and ch:GetAttribute('CC_MovementZone')
  local grounded=h and h.FloorMaterial~=Enum.Material.Air and h:GetState()~=Enum.HumanoidStateType.Jumping
  -- Brief air on bumpy ground is judged by the server; jumps clear through JumpRequest.
  if desired and ((mode~='ground' and mode~='fall') or isBlocked) then clear() end
  button.Visible=ch~=nil and zone=='mountain' and not isBlocked and h~=nil and h.Health>0
  button.Active=button.Visible and ch:GetAttribute('CC_SprintAvailable')==true
  button.Text=ch and ch:GetAttribute('CC_SprintExhausted') and 'RECOVERING' or ch and ch:GetAttribute('CC_SprintRequested') and 'SPRINT ON' or 'SPRINT OFF'
  button.BackgroundColor3=ch and ch:GetAttribute('CC_SprintRequested') and Theme.gold or Theme.teal
  button.Position=UDim2.new(1,-20,1,(mode=='climb' or mode=='rope' or mode=='hanging' or mode=='flight') and -238 or -166)
  if track and trackPending then
   if track.Length>0 then trackPending=false
   elseif now-attemptAt>2 then failedKey=assetKey;stopTrack(true);trackPending=false end
  end
  local r=ch and ch:FindFirstChild('HumanoidRootPart')
  local speed=r and (r.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
  local running=grounded and mode=='ground' and not isBlocked and h.Health>0 and not r.Anchored and not h.PlatformStand and not ch:GetAttribute('CC_MovementLocked') and (zone=='lobby' or ch:GetAttribute('CC_Sprinting')) and speed>C.motionThreshold
  if track and not trackPending then
   if running then if not track.IsPlaying then track:Play(C.blendSeconds) end;track:AdjustSpeed(math.clamp(speed/16,0.5,1.8))
   elseif track.IsPlaying then stopTrack(false) end
  end
 end)
 local self={}
 function self.suppress(seconds) suppressionUntil=math.max(suppressionUntil,os.clock()+(seconds or 0));clear();send('suppress',true) end
 function self.destroy()
  if dead then return end
  clear();send('suppress',false);dead=true
  for _,c in ipairs(connections) do c:Disconnect() end
  releaseCharacter();CAS:UnbindAction('CC_SprintToggle');CAS:UnbindAction('CC_MovementModal');button:Destroy()
 end
 return self
end
return M
