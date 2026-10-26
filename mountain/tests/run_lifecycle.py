"""Exercise Main's actual loss hook with real profile/save and raid services."""
from service_harness import *
body += '\ngame.ReplicatedStorage.MountainShared.RunRules=RunRules'
body += '\nlocal EggRaids=' + module('mountain/server/EggRaids.luau', 'local script=true')
body += r'''
local backend=Store.memory();local P=Profiles.newForTests(backend,'lifecycle')
local player={UserId=550};local p=P.load(player);local now=100
local raids=EggRaids.new({profiles=P,clock=function() return now end,guid=function() return 'r1' end,
 eggs={egg={id='egg',section=1,species='mossbun'}},alive=function() return true end,
 near=function() return true end,atExit=function() return true end})
local R=Rules;local function restoreRecovery() end;local function publish() end
'''
main = (ROOT/'mountain/server/Main.server.luau').read_text(encoding='utf-8')
body += '\n' + main[main.index('local function loseCargo(player)'):main.index('local loadCharacter')]
body += r'''
for i=1,3 do check(raids.strike(player,'egg'),'accepted strike');now+=1 end
check(raids.pickup(player,'r1'),'carried before failed save')
backend.failAll=true;check(not P.save(player,false),'ordinary save unavailable')
loseCargo(player)
backend.failAll=false;check(P.save(player,false),'ordinary save recovers')
now+=500;raids.tick(now)
check(not p.run,'death_while_save_unavailable_forfeits_after_recovery')
check(not raids.exit(player,'r1') and #p.creatures==3,'dead_run_never_secures')
print('PASS '..checks..' Main lifecycle checks')
'''
with tempfile.TemporaryDirectory(prefix='run-lifecycle-') as directory:
    target=Path(directory)/'tests.luau'
    target.write_text(body,encoding='utf8')
    subprocess.run([str(CLI),str(target)],check=True)
