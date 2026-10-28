from service_harness import *
# Guardians runs with plain-table vectors; only home-position ticks (no movement) are exercised.
body += '\nlocal Guardians=' + module('mountain/server/Guardians.luau', 'local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z,Magnitude=math.sqrt(x*x+y*y+z*z)} end}\nlocal workspace={GetServerTimeNow=function() return 0 end}')
body += '\n' + (ROOT/'mountain/tests/combat_raids.luau').read_text()
with tempfile.TemporaryDirectory(prefix='combat-raids-') as directory:
    target=Path(directory)/'tests.luau'
    target.write_text(body,encoding='utf8')
    subprocess.run([str(CLI),str(target)],check=True)
