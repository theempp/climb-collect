-- Isolated review QA only: navigates all implemented tabs and checks actual rendered bounds.
local pg=game.Players.LocalPlayer.PlayerGui
local gui=pg:WaitForChild('MountainHUD')
local root=gui.SafeRoot
local probe=gui:WaitForChild('UIProbe')
local report={view=tostring(root.AbsoluteSize),screens={},errors={}}
local function visible(o)
 local p=o
 while p and p~=gui do if p:IsA('GuiObject') and not p.Visible then return false end;p=p.Parent end
 return true
end
for _,hub in ipairs({'Creatures','Discovery','Sanctuary','Mountain','Social','Profile','Shop','Settings'}) do
 probe:Invoke('open',hub);task.wait(.05)
 local tabs={}
 for _,o in ipairs(root.HubShade.Hub.Tabs:GetChildren()) do if o:IsA('TextButton') then table.insert(tabs,o.Text) end end
 for _,tab in ipairs(tabs) do
  probe:Invoke('tab',tab);task.wait(.05)
  local n=0
  for _,o in ipairs(root.HubShade:GetDescendants()) do
   if visible(o) then
    if (o:IsA('TextLabel') or o:IsA('TextButton')) and o.Text~='' and not o.TextFits then
     table.insert(report.errors,hub..'/'..tab..' text: '..o.Name..' '..o.Text)
    end
    if o:IsA('GuiButton') then
     n+=1
     if o.AbsoluteSize.Y<44 or o.AbsoluteSize.X<44 then table.insert(report.errors,hub..'/'..tab..' touch target: '..o.Name) end
    end
   end
  end
  table.insert(report.screens,{hub=hub,tab=tab,controls=n,instances=#gui:GetDescendants()})
 end
end
probe:Invoke('close');task.wait(.3)
local touch=pg:FindFirstChild('TouchGui')
local obstacles={}
if touch then for _,name in ipairs({'DynamicThumbstickFrame','ThumbstickFrame','JumpButton'}) do local o=touch:FindFirstChild(name,true);if o and visible(o) then table.insert(obstacles,o) end end end
local function overlap(a,b)
 local ap,bp=a.AbsolutePosition,b.AbsolutePosition;local as,bs=a.AbsoluteSize,b.AbsoluteSize
 return ap.X<bp.X+bs.X and bp.X<ap.X+as.X and ap.Y<bp.Y+bs.Y and bp.Y<ap.Y+as.Y
end
for _,o in ipairs(root:GetDescendants()) do
 if o:IsA('GuiButton') and visible(o) then
  for _,native in ipairs(obstacles) do if overlap(o,native) then table.insert(report.errors,'Native control overlap: '..o.Name..' / '..native.Name) end end
 end
end
report.closedInstances=#gui:GetDescendants()
report.ready=probe:Invoke().ready
return game.HttpService:JSONEncode(report)
