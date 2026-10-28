-- Isolated Studio fixture: no network actions, no grants, no saved changes.
local UI=game.Players.LocalPlayer.PlayerScripts.MountainClient.UI
local Screens=require(UI.Screens)
local R=require(game.ReplicatedStorage.MountainShared.Rules)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local p=R.newProfile(os.time());T.ensure(p,os.time());p.ui={atHome=true,atRefuge=true,settings={}}
local fixture=Instance.new('ScreenGui');fixture.Name='HUDRefreshFixture';fixture.Parent=game.Players.LocalPlayer.PlayerGui
local root=Instance.new('Frame');root.Size=UDim2.fromScale(1,1);root.Parent=fixture
local sent=0
local s=Screens.new(root,{profile=p,pending={},request=function() sent+=1 end,now=os.time},{toast=function() end},function() end)
local ok,err=pcall(function()
 s:open('Sanctuary');s.tab='Habitats';s.tycoonRoster=1;s.tycoonPage=2;s:render(false)
 s:close();s:open('Sanctuary');s.tab='Habitats';s:render(false)
 assert(s.tycoonRoster==nil,'Reopening habitats must leave the old assignment picker')
 s.tab='Cosmetics';s:render(false);task.wait(.1)
 local tabs=s.shade.Hub.Tabs;tabs.CanvasPosition=Vector2.new(0,240);task.wait(.1)
 local before=tabs.CanvasPosition.Y;s.body.CanvasPosition=Vector2.new(0,80)
 s:render(true);task.wait(.1)
 assert(math.abs(s.shade.Hub.Tabs.CanvasPosition.Y-before)<2,'Refresh must preserve the side-tab scroll')
 s:open('Creatures');s.tab='Team';s.selected={'c2','c1'};s:render(true)
 assert(s.selected[1]=='c2' and s.selected[2]=='c1','Refresh must preserve unsaved team selection')
 assert(sent==0,'Refreshing must never send intents')
 p.coins=10000;s:open('Sanctuary');s.tab='Upgrades';s:render(false)
 s.touches.fixture=true;s:render(true)
 local upgrade=s.shade.Hub.Content:FindFirstChild('Upgrade_production',true)
 assert(upgrade and not upgrade:GetAttribute('Enabled'),'Unrendered state must keep spending actions locked')
 s.touches.fixture=nil;s:render(true)
 assert(s.shade.Hub.Content:FindFirstChild('Upgrade_production',true):GetAttribute('Enabled'),'Actions unlock after fresh state renders')
 local a=Instance.new('Frame');a.Name='Duplicate';a.Parent=s.shade
 local b=a:Clone();b.Parent=s.shade
 local button=Instance.new('TextButton');button.Name='Assign_second';button.Parent=b
 assert(s:focusTarget({'Duplicate','Assign_second'},'Assign_second')==button,'Duplicate row names must preserve the unique focused action')
end)
s:destroy();fixture:Destroy();assert(ok,err)
return 'PASS refresh fixture: picker reset, tab scroll, team selection, zero intents, stale action lock, duplicate focus'
