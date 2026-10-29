"""mutate_home.py [out.json] : break each home-base P2 gate once and confirm a suite catches it (file restored after each)."""
import json, pathlib, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
L = 'C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe'
SUITES = [[L, 'mountain/tests/' + n] for n in ('home_rules.luau', 'world_style.luau', 'home_profile.luau', 'tycoon.luau', 'explorer_rules.luau', 'egg_raids.luau', 'ui_protocol.luau', 'ui_server.luau')] \
    + [[sys.executable, 'mountain/tests/' + n] for n in ('run_persistence.py', 'run_ui_server.py')]
M = [  # (file, old, new, gate)
 ('shared/HomeRules.luau', "if level<def.rank then 'rank'", "if false then 'rank'", 'tier rank gate'),
 ('shared/HomeRules.luau', "elseif type(p.coins)~='number' or p.coins<def.fee then 'coins'", "elseif false then 'coins'", 'tier coin gate'),
 ('shared/HomeRules.luau', "p.coins-=q.fee;", "", 'tier fee debit'),
 ('shared/HomeRules.luau', "if slot>H.usable(p) then return false,'locked' end", "", 'usable slot cap'),
 ('shared/HomeRules.luau', "if home.decor[tostring(slot)] then return false,'occupied' end", "", 'occupied slot'),
 ('shared/HomeRules.luau', "if type(id)~='string' or not owned(p,id) then return false,'owned' end", "", 'creature ownership'),
 ('shared/HomeRules.luau', "if inHabitat(p,id) then return false,'habitat' end", "", 'habitat/display exclusive'),
 ('shared/HomeRules.luau', "if H.displayed(p,id) then return false,'displayed' end", "", 'one display per creature'),
 ('shared/HomeRules.luau', "if H.tier(p)<def.tier then return false,'tier' end", "", 'prop tier gate'),
 ('shared/HomeRules.luau', "if type(p.coins)~='number' or p.coins<def.price then return false,'coins' end", "", 'prop coin gate'),
 ('shared/HomeRules.luau', "p.coins-=def.price;", "", 'prop debit'),
 ('shared/HomeRules.luau', "if (home.stock[d.id] or 0)>=T.stockCap then return false,'stock' end", "", 'stock cap'),
 ('shared/HomeRules.luau', "not integer(home.v,1,H.version)", "not integer(home.v,1,9)", 'newer home version refused'),
 ('shared/HomeRules.luau', "if k~='v' and k~='tier' and k~='decor' and k~='stock' then return false end", "", 'unknown home key refused'),
 ('shared/HomeRules.luau', "for l=1,h.level do report.refund+=Config.paths.habitat.costs[l] end", "", 'comfort refund'),
 ('shared/HomeRules.luau', "report.refund+=moduleCost[slot-H.habitatMax]", "report.refund+=0", 'module refund'),
 ('shared/HomeRules.luau', "if seen[d.id] or not owned(p,d.id) or inHabitat(p,d.id) then", "if false then", 'load normalize'),
 ('shared/HomeRules.luau', "return {kind='creature',species=s.id,name=s.name,rarity=s.rarity,level=c.level}", "return {kind='creature',species=s.id,name=s.name,rarity=s.rarity,level=c.level,id=c.id}", 'inspect hides ids'),
 ('server/Profiles.luau', "if p.home~=nil and not Home.valid(p.home) then return false end", "", 'profile fails closed on bad home'),
 ('server/Profiles.luau', "  Home.migrate(p)\n", "", 'load migration'),
 ('shared/Tycoon.luau', " or not find(p,id) or displayed(p,id))", " or not find(p,id))", 'displayed creature not in habitat'),
 ('shared/Tycoon.luau', "if path=='habitat' and level+1>comfortCap(p) then", "if false then", 'comfort tier cap'),
 ('shared/TycoonConfig.luau', "costs={50,120,250,450}}", "costs={50,120,250,450,750,1200}}", 'six module cap'),
 ('shared/ExplorerRules.luau', "e.repeatXp+=X.secureFor(species)", "e.repeatXp+=10*k", 'secure XP by rarity'),
 ('shared/ExplorerRules.luau', "e.secures=math.min(e.secures+1,X.secureCountMax);e.repeatXp+=X.secureFor(species)", "if e.secures<20 then e.secures+=1;e.repeatXp+=X.secureFor(species) end", 'no daily secure cap (STOP 3)'),
 ('server/UIRequests.luau', "if not context.atHome or not context.atHome(player) then return false,'Use your own sanctuary plot.' end\n   if P.pending", "if P.pending", 'Home needs own plot'),
 ('server/UIRequests.luau', "   if p.run then return false,'Finish your current creature run first.' end\n   local bought", "   local bought", 'Home refused mid-run'),
 ('server/UIRequests.luau', "if now<(inspectAt[player] or -math.huge) then return false,'Please wait a moment.' end;", "", 'Inspect rate limit'),
 ('server/UIRequests.luau', "if not context.inSanctuary or not context.inSanctuary(player) then return false,'Visit the sanctuary to look closer.' end\n   local now", "local now", 'Inspect needs sanctuary'),
 ('shared/UIProtocol.luau', "if payload.op=='tier' then valid=fields(payload,{op=true})", "if payload.op=='tier' then valid=true", 'Home tier payload strict'),
 ('shared/UIProtocol.luau', "payload.index<=(if payload.kind=='habitat' then 6 else 14)", "payload.index<=14", 'Inspect habitat index <= 6'),
 ('shared/HomeTiers.luau', "usable=4,style='hut'", "usable=4,style='villa'", 'tier style keys distinct (S2)'),
 ('shared/WorldStyle.luau', "{min=5,key='gold'", "{min=6,key='gold'", 'rank band edge 5 (S0.1)'),
 ('shared/WorldStyle.luau', "{min=30,key='prism'", "{min=29,key='prism'", 'rank band edge 30 (S0.1)'),
]
def caught():
    for cmd in SUITES:
        if subprocess.run(cmd, cwd=ROOT, capture_output=True).returncode != 0: return pathlib.Path(cmd[1]).name
    return None
rows = []
for rel, old, new, gate in M:
    f = ROOT / 'mountain' / rel; src = f.read_text(encoding='utf-8')
    if src.count(old) != 1: rows.append({'gate': gate, 'error': f'pattern count {src.count(old)}'}); continue
    try:
        f.write_text(src.replace(old, new, 1), encoding='utf-8'); by = caught()
    finally:
        f.write_text(src, encoding='utf-8')
    rows.append({'gate': gate, 'file': rel, 'caught_by': by}); print(('KILLED ' if by else 'SURVIVED ') + gate + (' <- ' + by if by else ''))
out = {'mutants': len(M), 'killed': sum(1 for r in rows if r.get('caught_by')), 'rows': rows}
print(f"KILLED {out['killed']}/{out['mutants']}")
if len(sys.argv) > 1: pathlib.Path(sys.argv[1]).write_text(json.dumps(out, indent=1), encoding='utf-8')
