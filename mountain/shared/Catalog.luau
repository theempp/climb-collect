local C={version='ImpossibleMountain-1',seed=241026,incubation={Common=30,Uncommon=120,Rare=300,Epic=600,Mythic=1200}}
C.kingdoms={
 {id='blossom',name='Blossom Gardens',element='Nature',resource='Bloom Essence',color={109,164,112},accent={243,170,205},rock={102,121,104},material='Grass',landmarks={"Sovereign’s Garden",'Blooming Colosseum','Rootsong Ruins'}},
 {id='azure',name='Azure Falls',element='Water',resource='Tidal Pearls',color={83,153,159},accent={100,222,233},rock={89,120,139},material='Slate',landmarks={'Heart of the Falls','Veiled Grotto','Hanging Fern Sanctuary'}},
 {id='sunstone',name='Sunstone Desert',element='Earth',resource='Sunstone Ore',color={215,171,100},accent={255,211,103},rock={179,131,80},material='Sandstone',landmarks={'Solar Throne','Oasis of Echoes','Arch of the Dawn'}},
 {id='violet',name='Violet Crystals',element='Crystal',resource='Prism Shards',color={131,108,169},accent={200,157,255},rock={101,91,128},material='Rock',landmarks={'Fractured Mirror Observatory','Amethyst Hollow','Bridge of Reflections'}},
 {id='inferno',name='Inferno Heights',element='Fire',resource='Ember Cores',color={81,73,78},accent={255,151,69},rock={57,52,62},material='Basalt',landmarks={'Emberheart Crucible','Ashen Temple','Cinderfall Forge'}},
 {id='astral',name='Astral Crown',element='Cosmic',resource='Astral Fragments',color={194,210,225},accent={153,198,255},rock={123,141,171},material='Snow',landmarks={'Eternal Astral Sanctum','Star Garden','Constellation Gate'}},
}
local names={
 {'Mossbun','Petalyn','Fernox','Bloomlet','Thorncub','Floramoth'},
 {'Bubblit','Ripplet','Coralfen','Mistfin','Tidepup','Shellora'},
 {'Pebblin','Duneling','Sunscarab','Glimfox','Sandhorn','Solspike'},
 {'Shardlet','Prismite','Glowmoth','Amethyn','Crystail','Violette'},
 {'Emberkit','Ashling','Cindercub','Magmole','Flarewing','Obsidrax'},
 {'Starbit','Moonlet','Nebulyn','Cosmorin','Astralyn','Stellhorn'},
}
local shapes={
 {'rabbit','deer','fox','sprout','bear','moth'}, {'blob','otter','deer','fish','dog','turtle'},
 {'rock','worm','beetle','fox','rhino','hedgehog'}, {'shard','orb','moth','serpent','cat','jelly'},
 {'cat','ghost','bear','mole','bird','dragon'}, {'star','rabbit','cat','whale','deer','rhino'},
}
local features={
 {'moss ears','petal antlers','fern tail','flower crown','thorn armor','six petal wings'},
 {'bubble antennae','ripple tail','coral antlers','sail fins','sapphire ears','spiral shell'},
 {'stone fists','sand frill','solar elytra','glass tail','split horns','sun spines'},
 {'twin crystals','orbiting facets','glass wings','amethyst frill','prism tail','hanging gems'},
 {'ember whiskers','ash wisps','cinder shoulders','drill snout','flame wings','obsidian horns'},
 {'five rays','crescent ears','nebula tail','stellar fins','constellation antlers','comet horn'},
}
C.species={};C.byId={}
for k,row in ipairs(names) do
 for j,name in ipairs(row) do
  local s={id=string.lower(name),name=name,kingdom=k,element=C.kingdoms[k].element,rarity=({'Common','Common','Uncommon','Rare','Epic','Mythic'})[j],
   shape=shapes[k][j],feature=features[k][j],variant=j,health=90+j*16+k*9,attack=10+j*2+k*2,
   role=({'Damage','Support','Tank','Speed','Control','Magic'})[j],weight=({20,20,28,18,10,4})[j],
   encounter=({'HiddenNest','WildEncounter','Puzzle','Branch','DangerRoute','RareDiscovery'})[j],egg='egg_'..string.lower(name),levelCap=50,evolution={15,35},specialization=25}
  table.insert(C.species,s);C.byId[s.id]=s
 end
end
C.guardians={
 {id='floravelle',name='Floravelle',title='Sovereign of Life',shape='deer',legs=6,personality='Regal',abilities={'Petal Volley','Sovereign Bloom',"Garden’s Grace",'Royal Garden Awakening'}},
 {id='aquarune',name='Aquarune',title='Sovereign of the Tides',shape='otter',legs=6,personality='Playful',abilities={'Ripple Barrage','Tidal Break','Flow Momentum','Heart of the Ocean'}},
 {id='zenthari',name='Zenthari',title='Solar Juggernaut',shape='golem',legs=2,personality='Resolute',abilities={"Monarch’s Fists",'Sunstone Crusher',"Monarch’s Resolve",'Solar Dominion'}},
 {id='veylith',name='Veylith',title='Sovereign of Refraction',shape='shard',legs=0,personality='Watchful',abilities={'Shard Lance','Prism Fracture','Crystal Alignment','Shattered Star'}},
 {id='pyralune',name='Pyralune',title='Sovereign of Embers',shape='bird',legs=0,personality='Playful and proud',abilities={'Ember Barrage','Blazing Spiral','Eternal Spark','Phoenix Ascension'}},
 {id='caeloryn',name='Caeloryn',title='Sovereign of the Stars',shape='deer',legs=6,personality='Ancient',abilities={'Astral Lance','Gravity Choir','Constellation Accord','Celestial Dominion'}},
}
for i,g in ipairs(C.guardians) do
 g.kingdom=i;g.element=C.kingdoms[i].element;g.rarity='Legendary';g.attack=28+i*5;g.health=260+i*35;g.role='Guardian';g.variant=i;g.feature='sovereign';C.byId[g.id]=g
end
local TerrainProfile=if script then require(script.Parent.TerrainProfile) else require('./TerrainProfile')
local routeSweeps={2.9,2.65,2.9,2.6,2.7,2.4}
function C.route(k,t)
 local y=16+(k-1)*136+t*72+math.floor(t*4+0.000001)*16
 local a=math.pi/2
 for i=1,k-1 do a+=routeSweeps[i] end
 a+=t*routeSweeps[k]
 local r=TerrainProfile.radius(a,y+8)
 return {x=math.cos(a)*r,y=y,z=math.sin(a)*r,angle=a,radius=r}
end
function C.guardianColumnAngles(k)
 local angles={}
 local entrance=C.route(k,.875).angle+math.pi
 for j=1,12 do
  local a=j*math.pi/6
  if math.cos(a-entrance)<=0 or 38*math.abs(math.sin(a-entrance))>14 then table.insert(angles,a) end
 end
 return angles
end
function C.ladderSetback(k,i)
 local a,b=C.route(k,(i-1)/48),C.route(k,i/48)
 local distance=math.sqrt((b.x-a.x)^2+(b.z-a.z)^2)
 return math.min(11,distance*.6)
end
return C
