-- Isolated Studio memory backend. This does not contact Roblox DataStore.
local P=require(game.ServerScriptService.MountainServer.Profiles)
local Store=require(game.ServerScriptService.MountainServer.Store)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local backend=Store.memory()
local first=P.newForTests(backend,'tycoon-first')
local nextSession=P.newForTests(backend,'tycoon-rejoin')
local checks=0
local function check(v,m) assert(v,m);checks+=1 end
for i=1,8 do
 local player={UserId=92000000+i}
 local p=first.load(player);check(p~=nil,'load fixture')
 check(T.assign(p,1,'c1',os.time()),'assign starter')
 p.tycoon.habitats[1].eggs=9;p.tycoon.habitats[1].value=10
 p.tycoon.bag.eggs=3;p.tycoon.bag.value=4;p.coins=i*10
 check(first.save(player,true),'save and release fixture')
 backend:update('u'..player.UserId,function(old) old.profile.tycoon.lastAt=os.time()-86400;return old end)
 local q=nextSession.load(player);check(q~=nil,'rejoin fixture')
 check(q.coins==i*10 and q.tycoon.bag.eggs==3 and q.tycoon.bag.value==4,'saved coins and bag preserved')
 check(q.tycoon.habitats[1].eggs==30,'offline fills to capacity')
 local storedValue=q.tycoon.habitats[1].value
 check(not first.load(player),'contended fixture denied')
 check(nextSession.save(player,true),'release rejoined fixture')
 local again=first.load(player);check(again.tycoon.habitats[1].eggs==30 and again.tycoon.habitats[1].value==storedValue,'repeated rejoin cannot duplicate full stored eggs')
 check(first.save(player,true),'final release')
end
return {checks=checks,profiles=8,scope='sequential isolated memory save/rejoin/offline fixtures; no hosted DataStore, networking or real clients'}
