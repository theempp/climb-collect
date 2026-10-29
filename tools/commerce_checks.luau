-- Run only in an unpublished local Studio playtest:
-- require(game.ServerStorage.CC_DevTools.CommerceChecks).run()
local M={}
function M.run()
 assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0,"Disposable Studio review only")
 local modules=game.ServerScriptService.CC_CoreServer
 local a,ap,af=require(modules.Tests).runA1()
 local e,ep,ef=require(modules.ExpeditionTests).run()
 local c=require(modules.CommerceTests).run()
 local t=require(modules.TraversalTests).run()
 local P=require(modules.Profile);local data=P.default();local H=game:GetService("HttpService")
 local baseline=#H:JSONEncode(data)
 for i=1,1000 do data.commerce.processedPurchases[string.format("00000000-0000-0000-0000-%012d",i)]=true end
 local growth=#H:JSONEncode(data)-baseline
 local displays=workspace.World.CommerceDisplays
 local count=0;for _,v in ipairs(displays:GetDescendants()) do if v:IsA("BasePart") then assert(not v.CanCollide,"Merchandise blocks traversal");count+=1 end end
 assert(#displays:GetChildren()==5,"Expected three market and two bank displays")
 assert(#game.ServerStorage.CC_Creatures:GetDescendants()==179,"Protected creature library changed")
 assert(#workspace.CC_CreatureStage1:GetDescendants()==186,"Protected creature stage changed")
 assert(#game.ServerStorage.CC_Checkpoints:GetChildren()==2,"Development checkpoint limit changed")
 assert(#workspace.World.Checkpoints:GetChildren()==24,"Gameplay checkpoint count changed")
 assert(not H.HttpEnabled,"Sync left HTTP on")
 return {commerce=c,a1={pass=ap,fail=af,log=a},expedition={pass=ep,fail=ef,log=e},traversal=t,
  invariants={displays=5,noncollidingParts=count,creatureLibrary=179,creatureStage=186,developmentCheckpoints=2,routeCheckpoints=24,http=false},
  paidLedger={sampleIds=1000,additionalBytes=growth,bytesPerId=growth/1000,profileBudget=require(game.ReplicatedStorage.CC_Core.CoreConfig).PERSIST.maxBytes,
   note="Paid IDs are never evicted. Pending reveals and other profile data consume additional space; model actual usage before launch and require tested atomic archival before approaching the budget."},
  platform="Fake Store and Marketplace adapters; no real purchases or persistent networking verified"}
end
return M
