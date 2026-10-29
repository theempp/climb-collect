local P = require('../shared/UIPresentation')
local R = require('../shared/Rules')
local count = 0
local function check(value, message) assert(value, message); count += 1 end
check(type(P.remaining) == 'function', 'presentation timer API exists')
check(P.remaining(110, 100.1) == 10 and P.remaining(100, 110) == 0, 'cooldown rounds up and clamps elapsed')
check(P.remaining(nil, 100) == 0 and P.remaining(0/0, 100) == 0, 'absent and invalid deadlines are ready')
check(P.formatTime(65) == '1:05' and P.formatTime(3661) == '1:01:01', 'countdowns preserve hours')
local p = R.newProfile(100)
p.creatures[1].level = 15
table.insert(p.creatures, {id='c4', species='floravelle', level=25, xp=0})
local original = p.creatures[1]
local filtered = P.filterCreatures(p, 'NATURE', 'Common', 'Name')
check(#filtered == 2 and filtered[1].species == 'mossbun', 'case insensitive metadata search and rarity filter')
check(p.creatures[1] == original and #p.creatures == 4, 'filter does not reorder authoritative inventory')
local leveled = P.filterCreatures(p, '', nil, 'Level')
check(leveled[1].id == 'c4', 'level sorting highest first')
local rarity = P.filterCreatures(p, '', 'All', 'Rarity')
check(rarity[1].species == 'floravelle', 'rarity sorting uses actual legendary tier')
local team = P.filterCreatures(p, '', nil, 'Team')
check(team[1].id == 'c1' and team[3].id == 'c3' and team[4].id == 'c4', 'team sorting preserves equipped slot order')
check(#P.filterCreatures(nil, '', nil, 'Name') == 0, 'loading inventory is empty')
local c = P.creature(p.creatures[1])
check(c.name == 'Mossbun' and c.stage == 2 and c.xpRequired == 600, 'creature derives catalog identity and real evolution threshold')
check(math.abs(c.attack - 26.74) < .001 and math.abs(c.health - 219.65) < .001, 'stats derive existing level scaling')
local g = P.creature(p.creatures[4])
check(#g.abilityNames == 4 and g.abilityNames[1] == 'Petal Volley', 'guardian abilities use catalog names')
local unknown = P.creature({species='unknown', level=1})
check(unknown.name == 'Unknown creature' and unknown.attack == 0, 'missing species never fabricates stats')
p.creatures[1].level = 50
check(P.creature(p.creatures[1]).xpRequired == 0, 'level cap has no fictional next level')
local q = P.quest(p)
check(q.title=='Explore any of the six sections','free climb objective has no victory gate')
p.schema=1 -- retain presentation coverage for historical profile snapshots
q=P.quest(p)
check(q.total > 0 and q.progress == 0 and q.title:find('Blossom'), 'first objective reflects undiscovered route')
p.discoveries['1:entrance'] = true
check(P.quest(p).title:find('Floravelle') ~= nil, 'discovered entrance directs to actual first guardian')
p.wins['1'] = true; p.unlocked = 2
check(P.quest(p).title:find('Azure') ~= nil, 'first victory advances next kingdom objective')
for i=1,6 do p.wins[tostring(i)] = true end
check(P.quest(p).title:lower():find('summit') ~= nil, 'all wins direct to summit discovery')
p.discoveries.summit = true
check(P.quest(p).progress == P.quest(p).total, 'summit completion uses actual discovery flag')
local caps = P.capabilities()
check(caps.habitats.status == 'connected', 'implemented habitat actions are connected')
check(caps.income.reason:find('production') and caps.income.reason:find('bank'), 'income describes production collection and banking')
check(caps.habitats.reason:find('assign') and caps.habitats.reason:find('upgrade'), 'habitat contract describes available actions')
check(caps.partyInvites.status == 'unavailable', 'no invented party backend')
check(caps.shop.status == 'partial' and caps.shop.reason:find('coins') and caps.shop.reason:find('Robux'), 'shop partial: coin egg live, Robux items disabled')
check(caps.training.status == 'connected' and caps.defenses.status == 'connected', 'existing validated gameplay marked connected')
for _, size in ipairs({{667,339},{812,339},{1024,700},{1920,1040},{375,700}}) do
 local l = P.layout(size[1],size[2],true)
 check(l.hubWidth <= size[1]-16 and l.hubHeight <= size[2]-16, 'hub stays inside safe area')
 check(l.columns >= 1 and l.teamWidth <= size[1]-16, 'grid and team stay in bounds')
 check(l.actionBottom > l.teamBottom and l.actionBottom + 48 <= size[2], 'context action fits above team')
end
local short = P.layout(667,339,false)
check(short.compact and short.phone and short.teamWidth <= 307, 'short landscape reserves native touch corners')
check(not P.combatVisible(false,true,false), 'no dodge or specials in sanctuary')
check(P.combatVisible({hp=10},true,false), 'battle shows combat controls')
check(not P.combatVisible({hp=10},true,true), 'hub hides combat controls')
check(not P.combatVisible({hp=10},false,false), 'loading hides combat controls')
-- Native controls keep their screen-corner distance when the HUD root is resized (audits) and equal the plain offset otherwise.
local ref={x=40,y=0,w=750,h=343};local jump={x=40+750-95,y=343-90,w=70,h=70}
local same=P.nativeRect(jump,ref,{x=40,y=0,w=750,h=343},true)
check(same.x==750-95 and same.y==343-90,'native jump: natural root gives the plain offset')
local big=P.nativeRect(jump,ref,{x=40,y=0,w=844,h=390},true)
check(big.x==844-95 and big.y==390-90 and big.w==70,'native jump: resized root keeps the bottom-right distance')
local stick=P.nativeRect({x=40+20,y=343-150,w=120,h=120},ref,{x=40,y=0,w=844,h=390},false)
check(stick.x==20 and stick.y==390-150,'native thumbstick: resized root keeps the bottom-left distance')
-- P7 R1: menus + hatch reveal: vertical from the screen edges (no double topbar inset), horizontal inside the root (device safe
-- area). Emulator 844x391 with the topbar row (58) above the 844x333 root; iPhone 16 Pro root 750x343 in a 874x401 screen.
local eroot,phone={x=0,y=0,w=844,h=333},{x=0,y=-58,w=844,h=391}
local hp=P.hubPanel(eroot,phone)
check(hp.y-phone.y==66 and hp.x==24 and hp.w==796 and hp.h==391-76,'hub panel: 66 top from the screen, 24 sides in the root')
local iroot,ip={x=0,y=0,w=750,h=343},{x=-62,y=-58,w=874,h=401}
local hi=P.hubPanel(iroot,ip)
check(hi.x==24 and hi.w==702 and hi.x+hi.w==750-24 and hi.y==8 and hi.h==401-76,'hub panel: notch phone stays inside the safe area horizontally')
check(not hp.short and not hi.short and P.hubPanel({x=0,y=0,w=844,h=390}).short==false and P.hubPanel({x=0,y=0,w=749,h=330}).short,'hub panel: compact rule on the screen height (< 390)')
local wide=P.hubPanel({x=0,y=0,w=1920,h=1044},{x=0,y=-36,w=1920,h=1080})
check(wide.w==850 and wide.h==660 and wide.x==535 and wide.y==-36+66+math.floor((1080-76-660)/2),'hub panel: capped 850x660, centred in the inset region')
local ar=P.hubPanel({x=0,y=0,w=844,h=390});check(ar.y==66 and ar.h==314 and ar.x==24,'hub panel: audit root = screen keeps the 24 / 66 insets')
local rv=P.revealFrame(eroot,phone)
check(rv.scale==1 and rv.y==phone.y+.5 and rv.x==0,'reveal: 844x390 frame centred on the screen vertically at scale 1')
local ri=P.revealFrame(iroot,ip)
check(math.abs(ri.scale-750/844)<1e-9 and math.abs(ri.x)<1e-9 and ri.x+ri.w<=750+1e-9 and math.abs(ri.y-(-58+(401-390*ri.scale)/2))<1e-9,'reveal: notch phone scales to the root width, centred in the root')
local rs=P.revealFrame({x=0,y=0,w=749,h=330});check(math.abs(rs.scale-330/390)<1e-9 and math.abs(rs.x-(749-844*rs.scale)/2)<1e-9,'reveal: scale min(1, root W/844, screen H/390)')
-- P7 R5: coin-priced kit actions: short = "Need <shortfall>" (coin look), not ready / no price = the ghost.
local st,lb=P.coinState(2500,300,true);check(st=='short' and lb=='Need 2,200','coin action: short reads Need + comma shortfall')
check(P.coinState(25,25,true)=='buy' and P.coinState(25,nil,true)=='short','coin action: exact coins buy; no coins is short')
check(P.coinState(25,0,false)=='off' and P.coinState(nil,999,true)=='off','coin action: unavailable or maxed is off, not short')
check(P.comma(1000)=='1,000' and P.comma(27000)=='27,000' and P.comma(999)=='999','comma groups thousands like the Shop')
print('PASS '..count..' UI presentation checks')
