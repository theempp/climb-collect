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
print('PASS '..checks..' profile/combat adapter checks (service fixtures, no live DataStore)')
'''
with tempfile.TemporaryDirectory(prefix='hud-server-tests-') as directory:
    target = Path(directory) / 'server_tests.luau'
    target.write_text(body, encoding='utf-8')
    subprocess.run([str(CLI), str(target)], check=True)
