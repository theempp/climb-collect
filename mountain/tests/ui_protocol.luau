local Protocol=require('../shared/UIProtocol')
local Requests=require('../server/UIRequests')
local Rules=require('../shared/Rules')
local count=0
local function check(value,message) assert(value,message);count+=1 end
local function intent(id,action,payload) return Protocol.validate(id,action,payload) end
check(intent('test:1','State',nil),'valid correlated request')
for _,id in ipairs({'',string.rep('x',65),'no-sequence','token:0','token:NaN'}) do check(not intent(id,'State',nil),'malformed IDs denied') end
for _,payload in ipairs({{slot=0/0},{slot=math.huge},{slot=1,ability=0/0},{slot=1,ability=5},{slot=1,extra=true}}) do check(not intent('test:1','Special',payload),'malformed specials denied') end
check(not intent('test:1','ChallengeDefense',0) and not intent('test:1','RegisterDefense',nil),'removed defense actions denied')
check(not intent('test:1','Anything',nil),'unknown action denied')
check(not intent('test:1','Train',{}),'wrong payload denied')
check(not intent('test:1','Equip',{'c1','c1'}),'duplicate slots denied')
local settings=Protocol.settings(nil)
check(settings.musicVolume==.7 and settings.sfxVolume==.8 and settings.hints==true and settings.largeText==false,'legacy preference defaults')
check(Protocol.settings({largeText=true},settings).largeText,'partial UI-only preferences merge')
for _,patch in ipairs({{coins=900},{hints=1},{musicVolume=0/0},{sfxVolume=math.huge},{musicVolume=-.1},{sfxVolume=1.1}}) do check(not Protocol.settings(patch,settings),'invalid preferences denied') end
-- C1: saved tables from a newer build may carry unknown keys; known keys stay strict, the patch path stays strict.
local saved=Protocol.savedSettings({largeText=true,futurePref=3,[1]='x'})
check(saved and saved.largeText and saved.futurePref==nil and saved.musicVolume==.7,'saved unknown key ignored, known kept')
check(not Protocol.settings({futurePref=3},settings),'patch with unknown key denied')
for _,bad in ipairs({{hints=1},{sfxVolume=math.huge},{musicVolume=-.1},'junk'}) do check(not Protocol.savedSettings(bad),'saved known key still validated') end
check(Protocol.settings(nil,{futurePref=3,largeText=true}).largeText,'saved merge ignores unknown key')
-- Stored form: no defaults written (a pre-T0 build still loads untouched prefs); a newer build's string keys survive; known keys snap.
check(Protocol.storedSettings(nil)==nil and next(Protocol.storedSettings({}))==nil,'stored settings never add defaults')
local kept=Protocol.storedSettings({futurePref={a=1},largeText=true,hudScale=.9,[1]='x'},{sprintMode=0})
check(kept.futurePref.a==1 and kept.largeText and kept.hudScale==1 and kept.sprintMode==0 and kept[1]==nil and kept.cameraShake==nil,'stored settings keep unknown string keys, snap known, add only the patch')
check(Protocol.storedSettings(nil,{hints=false}).hints==false and Protocol.storedSettings(nil,{hints=false}).musicVolume==nil,'first patch stores only its own key')
-- C2: new preferences; enums strict per key on the patch path, volumes keep the 0-1 rule, saved values snap.
check(settings.cameraShake==true and settings.altitudeRail==true and settings.hudScale==.5 and settings.effectsTier==1 and settings.sprintMode==1,'new preference defaults (sprint TOGGLE)')
for _,key in ipairs({'hudScale','effectsTier'}) do
 for _,v in ipairs({0,.5,1}) do check(Protocol.settings({[key]=v},settings)[key]==v,key..' step accepted') end
 check(not Protocol.settings({[key]=.25},settings),key..' off-step denied')
end
for _,v in ipairs({0,1}) do check(Protocol.settings({sprintMode=v},settings).sprintMode==v,'sprintMode HOLD/TOGGLE accepted') end
check(not Protocol.settings({sprintMode=.5},settings),'sprintMode off-step denied')
for _,key in ipairs({'cameraShake','altitudeRail'}) do check(Protocol.settings({[key]=false},settings)[key]==false and not Protocol.settings({[key]=0},settings),key..' boolean only') end
for _,v in ipairs({.25,.7,.75,.8,.95,1}) do check(Protocol.settings({musicVolume=v,sfxVolume=v},settings).sfxVolume==v,'volume keeps 0-1 rule') end
local snapped=Protocol.savedSettings({hudScale=.25,effectsTier=.25,sprintMode=.5})
check(snapped.hudScale==.5 and snapped.effectsTier==0 and snapped.sprintMode==1 and Protocol.settings(nil,{hudScale=.9}).hudScale==1,'saved off-step values snap on load')
local now=10;local profile=Rules.newProfile(100);profile.coins=100;local healthy=true;local busy=false;local calls=0
local requests=Requests.new({clock=function() return now end,available=function() return healthy end,busy=function() return busy end,handle=function(_,action,payload)
 calls+=1
 if action=='Train' then
  local creature=Rules.find(profile.creatures,payload)
  if not creature or profile.coins<15 then return false,'Training rejected.' end
  profile.coins-=15;Rules.addXP(creature,80);return true,'Trained.',{level=creature.level}
 elseif action=='Hatch' then return false,'Not ready.'
 elseif action=='Dodge' then error('fixture service failure') end
 return true,'Ready.'
end,maxCached=3,maxTokens=2,minInterval=.12})
local player={}
local first=requests.process(player,'test:1','Train','c1')
check(first.ok and first.id=='test:1' and first.action=='Train' and first.data.level==2 and profile.coins==85,'real rules train response')
local replay=requests.process(player,'test:1','Hatch','other')
check(replay==first and profile.coins==85 and calls==1,'duplicate intent replays original outcome without mutation even payload collision')
check(not requests.process(player,'test:2','Train','c1').ok and profile.coins==85,'rate limited requests never charge')
now+=1;healthy=false
check(not requests.process(player,'test:3','Train','c1').ok and profile.coins==85,'save unhealthy blocks paid mutation')
now+=1;healthy=true;busy=true
check(not requests.process(player,'test:4','Train','c1').ok and profile.coins==85,'legacy busy blocks correlated mutation')
now+=1;busy=false
check(not requests.process(player,'test:5','Hatch','e1').ok,'service rejection remains failure')
now+=1
check(not requests.process(player,'test:6','Dodge',nil).ok,'service error remains failure')
now+=1
check(not requests.process(player,'test:1','Train','c1').ok and profile.coins==85,'evicted duplicate never executes paid action')
now+=1;check(requests.process(player,'second:1','State',nil).ok,'second client generation accepted')
now+=1;check(not requests.process(player,'third:1','State',nil).ok,'token memory bounded without discarding replay protection')
requests.remove(player);now+=1;check(requests.process(player,'test:1','State',nil).ok,'player removal releases session state')
-- Yielding services remain at most once while the first intent is in flight.
local paid=0;local sharedBusy=false
local concurrent=Requests.new({clock=function() return 100 end,available=function() return true end,setBusy=function(_,value) sharedBusy=value end,handle=function() paid+=1;coroutine.yield();return true,'Done.' end})
local thread=coroutine.create(function() return concurrent.process(player,'inflight:1','State',nil) end)
check(coroutine.resume(thread),'first request yields inside service')
check(sharedBusy,'correlated yielding request locks legacy prompt and request paths')
check(concurrent.process(player,'inflight:1','State',nil)==nil and paid==1,'in-flight duplicate waits for original outcome without false terminal failure')
local ok,done=coroutine.resume(thread)
check(not sharedBusy,'correlated completion releases shared busy lock')
check(ok and done.ok and concurrent.process(player,'inflight:1','State',nil)==done,'completed in-flight replay returns final result')
-- C21: Buy{item,receipt} and Skin{op,id}; receipts are 8-64 of [%w-]; the legacy remote never reaches either.
check(intent('shop:1','Buy',{item='meadow_egg',receipt='a1b2-c3d4'}),'buy accepted')
check(intent('shop:1','Buy',{item='meadow_egg',receipt=string.rep('f',64)}),'buy 64-char receipt accepted')
check(not intent('shop:1','Buy',nil),'buy without payload denied')
for _,payload in ipairs({'meadow_egg',{item='meadow_egg'},{receipt='a1b2-c3d4'},{item='meadow_egg',receipt='short'},{item='meadow_egg',receipt=string.rep('f',65)},
 {item='meadow_egg',receipt='has space1'},{item='meadow_egg',receipt='colon:1234'},{item='meadow_egg',receipt=12345678},{item='',receipt='a1b2-c3d4'},{item='meadow_egg',receipt='a1b2-c3d4',count=3}}) do
 check(not intent('shop:1','Buy',payload),'malformed buy denied')
end
check(intent('shop:1','Skin',{op='equip',id='candy_swirl'}) and intent('shop:1','Skin',{op='clear'}),'skin equip and clear accepted')
check(intent('shop:1','Buy',{item='candy_swirl',receipt='a1b2-c3d5'}),'candy swirl buy accepted')
for _,payload in ipairs({{op='equip'},{op='clear',id='candy_swirl'},{op='buy',id='candy_swirl'},{op='equip',id='candy_swirl',extra=1},'candy_swirl'}) do check(not intent('shop:1','Skin',payload),'malformed skin denied') end
check(not intent('legacy:1','Buy',{item='meadow_egg',receipt='a1b2-c3d4'}) and not intent('legacy:1','Skin',{op='clear'}),'legacy remote refuses shop actions')
check(intent('legacy:1','Train','c1'),'legacy remote keeps other actions')
check(intent('raid:1','Strike','1:egg1'),'strike server egg ID')
check(intent('raid:2','Pickup','run-1'),'pickup server run ID')
check(not intent('raid:3','Pickup',{species='floravelle'}),'cannot supply reward species')
-- Home-base P2: Home{op=tier|place|clear} and Inspect{plot,kind,index}; never a tier, price or XP from the client.
check(intent('home:1','Home',{op='tier'}),'home tier accepted')
check(intent('home:1','Home',{op='place',slot=1,kind='creature',id='c1'}) and intent('home:1','Home',{op='place',slot=14,kind='prop',id='bed'}),'home place accepted')
check(intent('home:1','Home',{op='clear',slot=7}),'home clear accepted')
for i,payload in ipairs({'tier',{op='tier',tier=4},{op='tier',coins=0},{op='raise'},{op='place',slot=0,kind='prop',id='bed'},{op='place',slot=15,kind='prop',id='bed'},{op='place',slot=1.5,kind='prop',id='bed'},
 {op='place',slot=0/0,kind='prop',id='bed'},{op='place',slot=1,kind='egg',id='x'},{op='place',slot=1,kind='prop'},{op='place',slot=1,kind='prop',id=''},{op='place',slot=1,kind='prop',id=string.rep('a',81)},
 {op='place',slot=1,kind='prop',id='bed',price=0},{op='clear'},{op='clear',slot=1,id='bed'},{op='clear',slot='1'}}) do check(not intent('home:1','Home',payload),'malformed home denied '..i) end
check(not intent('home:1','Home',nil),'home without payload denied')
check(intent('look:1','Inspect',{plot=8,kind='habitat',index=6}) and intent('look:1','Inspect',{plot=1,kind='decor',index=14}),'inspect accepted')
for i,payload in ipairs({{plot=0,kind='habitat',index=1},{plot=9,kind='decor',index=1},{plot=1,kind='habitat',index=7},{plot=1,kind='decor',index=15},{plot=1,kind='bag',index=1},
 {plot=1,kind='decor',index=1,owner=1},{plot=1.5,kind='decor',index=1},{plot=1,kind='decor'},'1'}) do check(not intent('look:1','Inspect',payload),'malformed inspect denied '..i) end
check(not intent('look:1','Inspect',nil),'inspect without payload denied')
print('PASS '..count..' UI protocol/request checks')
