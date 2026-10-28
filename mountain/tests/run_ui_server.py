from service_harness import *

body += r'''
local backend=Store.memory()
local migration=Profiles.newForTests(backend,'migration')
local migrant={UserId=888}
local legacy=Rules.newProfile(os.time());legacy.coins=91
backend.backend.u888={profile=legacy}
local migrated=migration.load(migrant)
check(migrated.tycoon and migrated.coins==91,'migration initializes production without destroying coins')
Tycoon.assign(migrated,1,'c1',os.time());
migrated.tycoon.lastAt=os.time()-10
local settledAt=migrated.tycoon.lastAt
check(migration.save(migrant,false) and migrated.tycoon.lastAt==settledAt,'saving does not silently settle production outside tick notifications')
migrated.tycoon.habitats[1].eggs=10;migrated.tycoon.habitats[1].value=13
check(migration.save(migrant,true),'production state releases')
local rejoined=migration.load(migrant)
check(rejoined.tycoon.habitats[1].eggs==10 and rejoined.tycoon.habitats[1].value==13,'stored eggs survive rejoin')
backend.failAfterCommit=1
check(migration.save(migrant,true),'uncertain release outcome safely acknowledged')

local first=Profiles.newForTests(backend,'first')
local second=Profiles.newForTests(backend,'second')
local player={UserId=123,DisplayName='Fixture'}
local p=first.load(player)
check(p.settings.musicVolume==.7 and p.settings.hints,'legacy/default profile preferences')
check(p.settings.sprintMode==1 and p.settings.hudScale==.5 and p.settings.effectsTier==1 and p.settings.cameraShake and p.settings.altitudeRail,'legacy profile gets new preference defaults')
check(not first.setSettings(player,{coins=1000}) and p.coins==0,'settings cannot award currency')
check(not first.setSettings(player,{musicVolume=0/0}),'settings cannot persist NaN')
local ok,settings=first.setSettings(player,{largeText=true,musicVolume=.2})
check(ok and settings.largeText and settings.musicVolume==.2,'valid preferences acknowledged after save')
check(first.save(player,true),'profile releases normally')
local q=second.load(player)
check(q.settings.largeText and q.settings.musicVolume==.2 and q.settings.sfxVolume==.8,'preferences survive release and reload')
backend.failAll=true
check(not second.setSettings(player,{hints=false}) and not second.get(player),'failed settings persistence freezes profile and rejects result')
backend.failAll=false
check(second.save(player,false) and second.get(player)==q,'existing retry restores profile health')
check(second.save(player,true),'second profile releases')
check(first.load(player).settings.hints==false,'save retry persists the validated desired settings')
local leased=Profiles.newForTests(backend,'leased');local leasePlayer={UserId=777};leased.load(leasePlayer)
backend.backend.u777.lock.expires=os.time()-1
local savedCoins=backend.backend.u777.profile.coins
leased.sessions[leasePlayer].p.coins=900
check(not leased.save(leasePlayer,false) and backend.backend.u777.profile.coins==savedCoins,'expired lease cannot overwrite saved balance')
local takeover=Profiles.newForTests(backend,'takeover');local winner=takeover.load(leasePlayer)
check(winner~=nil and not leased.save(leasePlayer,false),'new owner rejects stale writes')
local bad=Rules.newProfile(os.time());Tycoon.ensure(bad,os.time());bad.tycoon.bag.eggs=-1
backend.backend.u999={profile=bad};local rejected=takeover.load({UserId=999})
check(not rejected and backend.backend.u999.profile.tycoon.bag.eggs==-1,'malformed production fails closed without overwriting')
local malformed=Rules.newProfile(1);malformed.settings={sfxVolume=math.huge}
check(not Profiles.valid(malformed),'malformed saved preferences rejected')
malformed.settings=nil;check(Profiles.valid(malformed),'legacy saved profile without settings accepted')
local legacyPrefs=Rules.newProfile(os.time());legacyPrefs.settings={largeText=true,musicVolume=.7,sfxVolume=.8};backend.backend.u321={profile=legacyPrefs}
local prefsService=Profiles.newForTests(backend,'prefs');local prefsPlayer={UserId=321}
local lp=prefsService.load(prefsPlayer)
check(lp and lp.settings.largeText and lp.settings.sprintMode==1 and lp.settings.hudScale==.5,'legacy settings without new keys load with defaults')
for _,v in ipairs({.7,.8,.95}) do
 check(prefsService.setSettings(prefsPlayer,{musicVolume=v,sfxVolume=v,sprintMode=0}) and prefsService.save(prefsPlayer,true),'volume saved')
 lp=prefsService.load(prefsPlayer);check(lp.settings.musicVolume==v and lp.settings.sfxVolume==v and lp.settings.sprintMode==0,'volume round-trips')
end
local preXp=Rules.newProfile(os.time());preXp.explorer=nil;preXp.wins['1']=true;table.insert(preXp.creatures,{id='c9',species='bloomlet',level=1,xp=0});backend.backend.u432={profile=preXp}
local xpService=Profiles.newForTests(backend,'xp');local xpPlayer={UserId=432};local xpp=xpService.load(xpPlayer)
check(xpp and xpp.explorer.won['1'] and xpp.explorer.species.bloomlet and ExplorerRules.summary(xpp).xp==150 and backend.backend.u432.profile.explorer.species.bloomlet,'legacy profile explorer seeded and persisted')
check(xpService.save(xpPlayer,true) and xpService.load(xpPlayer).explorer.species.bloomlet,'seeded explorer survives release and reload')
local junkXp=Rules.newProfile(os.time());junkXp.explorer='junk';backend.backend.u433={profile=junkXp}
check(type(xpService.load({UserId=433}).explorer)=='table','explorer junk loads without a kick')
-- T10 (C16): legacy profiles without cosmetics load; Candy Swirl ownership and equip are durable; unknown skin ids leave on load.
do
 local legacyFan=Rules.newProfile(os.time());legacyFan.coins=6000;backend.backend.u434={profile=legacyFan}
 local fans=Profiles.newForTests(backend,'skins');local fan={UserId=434};local fp=fans.load(fan)
 check(fp and fp.cosmetics==nil and backend.backend.u434.profile.cosmetics==nil,'legacy profile without cosmetics loads')
 local tick=0
 local skins=UIRequests.actions({profiles=fans,rules=Rules,safe=function() return true end,shop=ShopRules,monotonic=function() return tick end,
  rollOdds=function() error('skins never roll') end,inSanctuary=function() return true end,inBattle=function() return false end})
 local durable=function() return backend.backend.u434.profile end
 local writes=backend.calls.update
 local ok,message,data=skins(fan,'Buy',{item='candy_swirl',receipt='skin-durable1'})
 check(ok and data.skin=='candy_swirl' and backend.calls.update==writes+1 and durable().coins==1000 and durable().cosmetics.skins.candy_swirl and ShopRules.has(durable(),'skin-durable1'),'skin purchase commits debit, ownership and receipt in one write')
 tick+=2;writes=backend.calls.update;ok,message=skins(fan,'Buy',{item='candy_swirl',receipt='skin-durable2'})
 check(not ok and message=='You already own this skin.' and fans.get(fan).coins==1000 and backend.calls.update==writes and durable().coins==1000,'owned skin refused with no debit or write')
 check(skins(fan,'Skin',{op='equip',id='candy_swirl'}) and fans.save(fan,true) and durable().cosmetics.batSkin=='candy_swirl','equipped skin saved on release')
 local again=fans.load(fan)
 check(again.cosmetics.skins.candy_swirl and again.cosmetics.batSkin=='candy_swirl' and again.coins==1000 and ShopRules.batLook(again)==ShopRules.catalog.candy_swirl.look,'skin ownership and equip survive release and reload')
 check(fans.save(fan,true),'skin owner releases')
 local odd=Rules.newProfile(os.time());odd.cosmetics={skins={candy_swirl=true,pink_swirl=true},batSkin='pink_swirl'};backend.backend.u435={profile=odd}
 local op=fans.load({UserId=435});local saved=backend.backend.u435.profile.cosmetics
 check(op and op.cosmetics.skins.candy_swirl and op.cosmetics.skins.pink_swirl==nil and op.cosmetics.batSkin==nil and saved.skins.pink_swirl==nil and saved.skins.candy_swirl,'load drops unknown skin ids in the load write')
 local junk=Rules.newProfile(os.time());junk.cosmetics='junk';backend.backend.u436={profile=junk}
 local jp=fans.load({UserId=436});check(jp and jp.cosmetics==nil,'cosmetics junk loads without a kick')
 local typed=Rules.newProfile(1);typed.cosmetics=7;check(not Profiles.valid(typed),'non-table cosmetics fail the save type check')
 typed.cosmetics={skins='x',batSkin=5};check(Profiles.valid(typed),'valid checks the cosmetics type only')
end
local events={}
Combat.init(first,function(_,kind,data) table.insert(events,{kind=kind,data=data}) end,function() end)
local now=os.clock();Combat.specialAt['123:c1:1']=now+12;Combat.specialAt['124:c2:1']=now+24
Combat.dodgeUntil[player]=now+.65
local cooldowns,dodge=Combat.cooldowns(player,1000)
check(cooldowns['c1:1']>1011.9 and cooldowns['c1:1']<=1012 and not cooldowns['c2:1'],'only owned cooldowns converted to server clock domain')
check(dodge>1003.6 and dodge<=1003.65,'dodge cooldown includes active dodge window and existing recovery')
Combat.remove(player)
check(Combat.specialAt['123:c1:1']~=nil,'death keeps existing special cooldown gameplay')
Combat.remove(player,true)
check(Combat.specialAt['123:c1:1']==nil and Combat.specialAt['124:c2:1']~=nil,'disconnect only cleans owned cooldown records')
Combat.wild[player]={part={Parent=true}}
Combat.tick()
check(Combat.wild[player]==nil and events[#events-1].kind=='battle' and events[#events-1].data==false,'wild cancellation explicitly clears battle UI')
'''
# T9 (C12/C13): a real pending buy refuses Buy, and Main's movement correction still runs on the session.
main = (ROOT/'mountain/server/Main.server.luau').read_text(encoding='utf-8')
guard = main[main.index('  -- C13: movement correction'):main.index('  if p and rr and h and h.Health>0 then')]
body += r'''
do
 local pendingBackend=Store.memory();local PS=Profiles.newForTests(pendingBackend,'pending');local mover={UserId=140}
 local mp=PS.load(mover);mp.coins=6000
 local tick=0
 local shop=UIRequests.actions({profiles=PS,rules=Rules,safe=function() return true end,shop=ShopRules,monotonic=function() return tick end,
  rollOdds=function() return 10 end,inSanctuary=function() return true end,inBattle=function() return false end})
 pendingBackend.failAll=true
 local ok,message=shop(mover,'Buy',{item='meadow_egg',receipt='pending-0001'})
 check(not ok and PS.pending(mover)=='buy:pending-0001' and not PS.get(mover),'buy commit fails and stays pending')
 tick+=5;ok,message=shop(mover,'Buy',{item='meadow_egg',receipt='pending-0002'})
 check(not ok and message=='Profile or saving unavailable.' and PS.pending(mover)=='buy:pending-0001','pending transaction refuses another buy')
 local vector={}
 local function v(x,y,z) return setmetatable({X=x,Y=y,Z=z},vector) end
 vector.__sub=function(a,b) return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
 vector.__index=function(a,key) if key=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end end
 local Enum={Material={Air='Air'}};local RS={MountainShared={RaidConfig=RaidConfig}}
 local rr={Position=v(0,10,0)};local h={Health=100,FloorMaterial='Grass'}
 local motion={};local teleports={};local toasts={};local areas={};local lost=0;local exits=0
 local function teleport(player,pos) rr.Position=pos;table.insert(teleports,pos);motion[player]={pos=pos,time=0,blockedUntil=0,fallTop=pos.Y};return true end
 local function send(_,kind,data) if kind=='toast' then table.insert(toasts,data) end end
 local raids={protected=function() return false end,exit=function() exits+=1 end}
 local function loseCargo() lost+=1 end
 local home={inSanctuary=function() return true end,spawn=function() return v(0,10,0) end}
 local function checkpoint() error('checkpoint needs a profile') end
 local world={GetAttribute=function() return nil end}
 local P=PS
 local function tickMotion(player,p,now)
''' + guard + r'''
 end
 motion[mover]={pos=v(0,10,0),time=0,blockedUntil=0,fallTop=10}
 rr.Position=v(5,10,0);tickMotion(mover,PS.get(mover),.2)
 check(#teleports==0 and motion[mover].pos.X==5,'pending session still tracks ordinary movement')
 rr.Position=v(400,10,0);tickMotion(mover,PS.get(mover),.4)
 check(#teleports==1 and teleports[1].X==5 and toasts[1]=='Movement corrected.' and rr.Position.X==5,'teleport during pending is corrected')
 h.FloorMaterial='Air';rr.Position=v(5,90,0);tickMotion(mover,PS.get(mover),2);h.FloorMaterial='Grass';rr.Position=v(5,10,0);tickMotion(mover,PS.get(mover),4)
 rr.Position=v(5,-40,0);motion[mover].pos=rr.Position;tickMotion(mover,PS.get(mover),5.2)
 check(lost==0 and exits==0 and #teleports==1,'fall, void and exit checks wait for the profile')
 pendingBackend.failAll=false;check(PS.save(mover,false) and PS.get(mover) and PS.get(mover).coins==3500 and #PS.get(mover).eggs==1 and ShopRules.has(PS.get(mover),'pending-0001'),'autosave commits the pending buy once')
 tickMotion(mover,PS.get(mover),5.4)
 check(lost==1 and #teleports==2 and rr.Position.Y==10,'void check resumes once the profile is back')
 local gone={UserId=141};motion[gone]={pos=v(0,10,0),time=0,blockedUntil=0,fallTop=10};rr.Position=v(900,10,0);tickMotion(gone,nil,6)
 check(#teleports==2,'no session, no correction')
end
print('PASS '..checks..' profile/combat adapter checks (service fixtures, no live DataStore)')
'''
with tempfile.TemporaryDirectory(prefix='hud-server-tests-') as directory:
    target = Path(directory) / 'server_tests.luau'
    target.write_text(body, encoding='utf-8')
    subprocess.run([str(CLI), str(target)], check=True)
