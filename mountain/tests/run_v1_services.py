"""Run the v1 service suites against the REAL Profiles/Store modules (service fixtures, no Studio, no live DataStore)."""
from service_harness import *
SH = 'local script={Parent={}}'
body += '\nlocal V1Products=' + module('mountain/shared/V1Products.luau')
body += '\ngame.ReplicatedStorage.MountainShared.V1Products=V1Products'
body += '\nlocal UIRequests=' + module('mountain/server/UIRequests.luau', 'local script={}')
body += '\nlocal Receipts=' + module('mountain/server/Receipts.luau', SH)
body += '\nlocal MockMarketplace=' + module('mountain/server/MockMarketplace.luau')
extra = ['Dailies', 'PartyRules', 'OutpostRules', 'OutpostSim', 'Seasons', 'Recognition', 'CaelorynAbilities', 'V1Protocol']
for name in extra:
    if (ROOT / f'mountain/shared/{name}.luau').exists():
        body += f'\nlocal {name}=' + module(f'mountain/shared/{name}.luau', 'local script={Parent=game.ReplicatedStorage.MountainShared}')
        body += f'\ngame.ReplicatedStorage.MountainShared.{name}={name}'
for name in ['PartyService', 'OutpostService', 'V1Services']:
    if (ROOT / f'mountain/server/{name}.luau').exists():
        body += f'\nlocal {name}=' + module(f'mountain/server/{name}.luau', 'local script={Parent={Store=Store,Receipts=Receipts,PartyService=PartyService,OutpostService=OutpostService}}' if name=='V1Services' else SH)
body += '\nlocal suites={}'
for f in sorted((ROOT / 'mountain/tests/v1_services').glob('*.luau')):
    body += f'\ndo -- {f.name}\n' + f.read_text(encoding='utf-8') + '\nend'
body += "\nprint('PASS '..checks..' v1 service checks (real Profiles/Store adapters, no live DataStore)')"
with tempfile.TemporaryDirectory(prefix='v1-services-') as directory:
    target = Path(directory) / 'tests.luau'
    target.write_text(body, encoding='utf8')
    subprocess.run([str(CLI), str(target)], check=True)
