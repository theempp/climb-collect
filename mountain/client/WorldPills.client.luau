-- Owner-only decor price pills (home-base style S3 answer, s1-plan R2): the server builds coin markers without pills
-- (attribute Price); this client draws the pill on the nearest 4 in the player's own plot, so plot billboards stay <= 12.
local Players=game:GetService('Players')
local Pill=require(game.ReplicatedStorage:WaitForChild('MountainShared'):WaitForChild('WorldPill'))
local player=Players.LocalPlayer
local NEAREST,EVERY=4,.25
local shown={} -- marker -> BillboardGui
local function markers()
 local i=player:GetAttribute('SanctuaryPlot');local s=workspace:FindFirstChild('Sanctuary')
 local plot=i and s and s:FindFirstChild('SanctuaryPlots') and s.SanctuaryPlots:FindFirstChild(string.format('Plot_%02d',i))
 local stands=plot and plot:FindFirstChild('DecorStands',true);local list={}
 if stands then for _,m in stands:GetChildren() do if m.Name=='CoinMarker' and m:GetAttribute('Price') and m:FindFirstChild('Coin') then table.insert(list,m) end end end
 return list
end
while true do
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local keep={}
 if root then
  local list=markers()
  table.sort(list,function(a,b) return (a.Coin.Position-root.Position).Magnitude<(b.Coin.Position-root.Position).Magnitude end)
  for n=1,math.min(NEAREST,#list) do
   local m=list[n];keep[m]=true
   if not shown[m] then shown[m]=Pill(m.Coin,tostring(m:GetAttribute('Price'))..' coins','coinStroke',Vector3.new(0,2.4,0)) end
  end
 end
 for m,b in shown do if not keep[m] or not m.Parent then b:Destroy();shown[m]=nil end end
 task.wait(EVERY)
end
