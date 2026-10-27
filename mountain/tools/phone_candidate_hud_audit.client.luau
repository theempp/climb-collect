-- Phone-candidate QA only (needs ReplicatedStorage.StudioAids=true for the UIProbe; never save with it on).
-- All hubs/tabs: TextFits, >=44px touch targets, native thumbstick/jump overlap, one HUD root, no focus left.
task.wait(6)
local pg=game.Players.LocalPlayer.PlayerGui
local gui=pg:WaitForChild('MountainHUD')
local root=gui.SafeRoot
local probe=gui:WaitForChild('UIProbe',10)
if not probe then return 'NO PROBE' end
local errors,screens={},0
local function visible(o) local p=o while p and p~=gui do if p:IsA('GuiObject') and not p.Visible then return false end;p=p.Parent end return true end
for _,hub in ipairs({'Creatures','Discovery','Sanctuary','Mountain','Social','Profile','Shop','Settings'}) do
 probe:Invoke('open',hub);task.wait(.05)
 local tabs={}
 for _,o in ipairs(root.HubShade.Hub.Tabs:GetChildren()) do if o:IsA('TextButton') then table.insert(tabs,o.Text) end end
 for _,tab in ipairs(tabs) do
  probe:Invoke('tab',tab);task.wait(.05);screens+=1
  for _,o in ipairs(root.HubShade:GetDescendants()) do
   if visible(o) then
    if (o:IsA('TextLabel') or o:IsA('TextButton')) and o.Text~='' and not o.TextFits then table.insert(errors,hub..'/'..tab..' text: '..o.Name) end
    if o:IsA('GuiButton') and (o.AbsoluteSize.Y<44 or o.AbsoluteSize.X<44) then table.insert(errors,hub..'/'..tab..' touch target: '..o.Name) end
   end
  end
 end
end
probe:Invoke('close');task.wait(.3)
local touch=pg:FindFirstChild('TouchGui')
local obstacles={}
if touch then for _,name in ipairs({'DynamicThumbstickFrame','ThumbstickFrame','JumpButton'}) do local o=touch:FindFirstChild(name,true);if o and visible(o) then table.insert(obstacles,o) end end end
local function overlap(a,b) local ap,bp=a.AbsolutePosition,b.AbsolutePosition;local as,bs=a.AbsoluteSize,b.AbsoluteSize return ap.X<bp.X+bs.X and bp.X<ap.X+as.X and ap.Y<bp.Y+bs.Y and bp.Y<ap.Y+as.Y end
for _,o in ipairs(root:GetDescendants()) do
 -- Owner 2026-10-27: the centred team slots + context button may sit over the dynamic joystick's gesture zone only.
 local centred=o:IsDescendantOf(root:FindFirstChild('Team') or o) or o:IsDescendantOf(root:FindFirstChild('Actions') or o)
 if o:IsA('GuiButton') and visible(o) then for _,native in ipairs(obstacles) do if overlap(o,native) and not (centred and native.Name=='DynamicThumbstickFrame') then table.insert(errors,'native: '..o.Name..'/'..native.Name) end end end
end
local huds=0 for _,g in pg:GetChildren() do if g.Name=='MountainHUD' then huds+=1 end end
local sel=game:GetService('GuiService').SelectedObject
return game.HttpService:JSONEncode({view=tostring(root.AbsoluteSize),screens=screens,errors=errors,hudRoots=huds,focus=sel and sel.Name or 'nil',nativeControls=#obstacles,ready=probe:Invoke().ready})
