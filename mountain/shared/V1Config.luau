-- v1 services tuning. Every number here is PROPOSED (design/v1-big-scope-design-decisions-2026-10-28.md),
-- untested with players. LOCKED rules are enforced in code, not here.
local V={version=1,provisional=true}
V.checkoutEnabled=false -- E02: no real checkout until products exist and spending is authorized.
V.day=86400
function V.dayIndex(now) return math.floor(now/86400) end
-- Unix day 0 was a Thursday, so +3 aligns week boundaries to Monday 00:00 UTC.
function V.weekIndex(now) return math.floor((math.floor(now/86400)+3)/7) end
function V.weekStart(week) return (week*7-3)*86400 end
V.receipts={ring=200}
V.wallet={boostCapSeconds=2*3600,maxEggTickets=999,maxTokens=50}
V.daily={trackLength=7,questsPerDay=3,rerollsPerDay=1,rerollsPerWeek=1,
 login={{coins=100},{coins=150},{eggTickets=1},{coins=250},{boost='production',seconds=1800},{coins=400},{eggTickets=2,cosmetic='trim_daybreak'}}}
V.party={maxSize=2,inviteSeconds=60,readySeconds=20,followSeconds=120,codeLength=6}
V.outpost={slots={'gate','wall','wall','wall','wall','wall','trap','trap','trap','trap'},defenders=3,
 vaultShareOfProduction=.10,vaultMinCap=150,vaultMaxCap=2500,vaultCapHours=4,
 lootShare={[0]=0,.20,.35,.50},dailyLootCap=1500,botLoot={[0]=0,20,35,50},
 shieldSeconds=4*3600,paidShieldSeconds=4*3600,paidShieldsPerDay=1,shieldCapSeconds=8*3600,
 revengeSeconds=24*3600,attacksPerDay=5,freeRerollsPerDay=3,offerSeconds=600,lockSeconds=180,
 activeDays=14,bucketSize=100,bucketKeep=60,trophyWin={[0]=-12,8,14,20},trophyDefend={[0]=10,-6,-10,-14},
 botTrophyFactor=.5,logKeep=20,resultKeep=32,replaySeconds=20,practiceXP=60}
V.season={softResetFactor=.5,historyKeep=8,
 tiers={{id='bronze',min=0},{id='silver',min=200},{id='gold',min=500},{id='crystal',min=1000},{id='astral',min=1600}},
 rewards={bronze={coins=150},silver={coins=300,eggTickets=1},gold={coins=500,eggTickets=2,title='gold_climber'},
  crystal={coins=800,eggTickets=3,title='crystal_raider',badge='season_crystal'},astral={coins=1200,eggTickets=5,title='astral_sovereign',badge='season_astral',cosmetic='trim_astral'}}}
V.duo={guardianHealth={1,1.5},trialHealth={1,1.45}}
return V
