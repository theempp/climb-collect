local T={}
function T.run()
 local rs=game.ReplicatedStorage.CC_Core
 assert(rs:FindFirstChild('PortfolioRules'),'PortfolioRules not implemented')
 local R=require(rs.PortfolioRules);local A=require(rs.AchievementRules);local P=require(script.Parent.Profile)
 local roster={entries={{id='a',rarity='Common',collectible=true,obtainable=true},{id='b',rarity='Rare',collectible=true,obtainable=true},{id='guardian',collectible=false,obtainable=true},{id='future',rarity='Epic',collectible=true,obtainable=false}},replacements={old='a'}}
 local n=0;local function check(v,msg) assert(v,msg);n+=1 end
 local d=P.default();d.bank={{creatureId='1',species='a',rarity='Common'},{creatureId='2',species='a',rarity='Common',mutation='Aurora'},{creatureId='3',species='old',rarity='Common'}};d.cargo={{species='b'}}
 local s=R.summarize(d,roster)
 check(s.collected==1,'duplicates and retired aliases count once');check(s.obtainable==2,'guardian/unreleased excluded');check(s.percent==50,'cargo excluded');check(s.mutationCount==1,'mutation separate')
 table.insert(roster.entries,{id='new',rarity='Common',collectible=true,obtainable=true});check(R.summarize(d,roster).obtainable==3,'roster additions')
 check(R.summarize(d,{entries={},replacements={}}).percent==0,'empty denominator')
 d.portfolio={titleId='first_ascent',frameId='',showcase={'1','1','gone','2','3','4'}};local clean=P.sanitize(d);check(#clean.portfolio.showcase==3,'bounded owned selections')
 local title=A.unlocked(s,{Shepherd=5});check(title.first_ascent and title.peak_regular,'historical titles');check(d.coins==0,'no historical prizes')
 return {pass=n,fail=0,kind='pure rules and profile fixtures'}
end
return T
