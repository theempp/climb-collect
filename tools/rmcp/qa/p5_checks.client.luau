-- P5 QA (StudioAids on): every hub/tab — enabled buttons are gamepad-selectable, every Robux buy is disabled (product id 0),
-- and the menu is destroyed on close (HUD descendants return to the rest count).
local gui=game.Players.LocalPlayer.PlayerGui:WaitForChild('MountainHUD');local probe=gui:WaitForChild('UIProbe',10);local root=gui.SafeRoot
probe:Invoke('close');task.wait(.3);local rest=#gui:GetDescendants()
local HUBS={'Creatures','Discovery','Sanctuary','Mountain','Social','Profile','Shop','Settings'}
local unselectable,robux,robuxLive,buttons,screens={},0,{},0,0
local function visible(o) local p=o while p and p~=gui do if p:IsA('GuiObject') and not p.Visible then return false end;p=p.Parent end return true end
for _,hub in ipairs(HUBS) do
 probe:Invoke('open',hub);task.wait(.05)
 local tabs={};for _,o in ipairs(root.HubShade.Hub.Tabs:GetChildren()) do if o:IsA('TextButton') and o.Name:sub(1,3)=='Tab' then table.insert(tabs,o.Name:sub(4)) end end
 for _,tab in ipairs(tabs) do
  probe:Invoke('tab',tab);task.wait(.05);screens+=1
  for _,o in ipairs(root.HubShade:GetDescendants()) do
   if o:GetAttribute('Currency')=='robux' then robux+=1;if o:GetAttribute('Enabled')~=false or o.Active or o.Selectable then table.insert(robuxLive,hub..'/'..tab..' '..o.Name) end end
   if o:IsA('GuiButton') and visible(o) and not o:GetAttribute('HitArea') and o:GetAttribute('Enabled')~=false and o.Active~=false then
    buttons+=1;if not o.Selectable and #unselectable<60 then table.insert(unselectable,hub..'/'..tab..' '..o.Name) end
   end
  end
 end
end
probe:Invoke('close');task.wait(.3);local after=#gui:GetDescendants()
return game:GetService('HttpService'):JSONEncode({screens=screens,buttons=buttons,unselectable=unselectable,robuxButtons=robux,robuxLive=robuxLive,restBefore=rest,restAfterClose=after})
