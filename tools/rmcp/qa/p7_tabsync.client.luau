-- P7 R2: open the Shop on each tab (UIProbe tab, Daily dock path = Featured, wallet + = Coins glide) and report the lit tab after the build settles.
local pg=game.Players.LocalPlayer.PlayerGui;local gui=pg.MountainHUD;local pr=gui.UIProbe;local root=gui.SafeRoot
local function lit() local t=root.HubShade.Hub.Tabs;local r={};for _,b in ipairs(t:GetChildren()) do if b:IsA('GuiButton') and b:GetAttribute('On') then table.insert(r,b.Name:sub(4)) end end;return table.concat(r,',') end
local out={}
for _,tab in ipairs({'Featured','Coins','Passes','Eggs','Skins'}) do
 pr:Invoke('close');task.wait(.2);pr:Invoke('open','Shop');pr:Invoke('tab',tab);task.wait(1.2)
 out[tab]=lit()
end
pr:Invoke('close');task.wait(.2);pr:Invoke('open','Shop');task.wait(1)
local plus=root.HubShade.Hub:FindFirstChild('Plus',true)
out.plusFound=plus~=nil
pr:Invoke('close')
return out
