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
check(caps.habitats.status == 'unavailable' and #caps.habitats.reason > 0, 'missing habitat backend disclosed')
check(caps.partyInvites.status == 'unavailable' and caps.shop.status == 'unavailable', 'no invented party or purchase backend')
check(caps.training.status == 'connected' and caps.defenses.status == 'connected', 'existing validated gameplay marked connected')
for _, size in ipairs({{667,339},{812,339},{1024,700},{1920,1040},{375,700}}) do
 local l = P.layout(size[1],size[2],true)
 check(l.hubWidth <= size[1]-16 and l.hubHeight <= size[2]-16, 'hub stays inside safe area')
 check(l.columns >= 1 and l.teamWidth <= size[1]-16, 'grid and team stay in bounds')
 check(l.actionBottom > l.teamBottom and l.actionBottom + 48 <= size[2], 'context action fits above team')
end
local short = P.layout(667,339,false)
check(short.compact and short.phone and short.teamWidth <= 307, 'short landscape reserves native touch corners')
print('PASS '..count..' UI presentation checks')
