-- P0 baseline (Edit): place descendants, Sanctuary subtree counts, per-plot subtree counts (plot folder + lodge + promenade parts within the plot rect).
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local s=workspace.Sanctuary
local function count(x) local n=0 for _ in x:GetDescendants() do n+=1 end return n end
local out={place=count(game),workspace=count(workspace),sanctuary=count(s),sanctuaryChildren={},plots={}}
for _,c in s:GetChildren() do out.sanctuaryChildren[c.Name]=count(c) end
for i,p in L.plots do
 local plot=s.SanctuaryPlots:FindFirstChild(string.format('Plot_%02d',i))
 local lodge=s.EnchantedAlpineLodges:FindFirstChild(string.format('Lodge_%02d',i))
 local inRect=0
 local cf=CFrame.new(p.x,L.groundY,p.z)*CFrame.Angles(0,p.yaw,0)
 for _,d in s:GetDescendants() do if d:IsA('BasePart') and not (plot and d:IsDescendantOf(plot)) and not (lodge and d:IsDescendantOf(lodge)) then
  local r=cf:PointToObjectSpace(d.Position) if math.abs(r.X)<=L.plotWidth/2 and math.abs(r.Z)<=L.plotDepth/2 then inRect+=1 end end end
 table.insert(out.plots,{plot=i,plotFolder=plot and count(plot) or -1,lodge=lodge and count(lodge) or -1,otherPartsInRect=inRect})
end
return game:GetService('HttpService'):JSONEncode(out)
