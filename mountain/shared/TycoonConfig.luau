-- Provisional balance, deliberately centralized for playtesting. No paid advantages.
return {
 version=1, offlineSeconds=8*3600, maxCount=1000000000,
 rarity={Common={rate=60,value=1},Uncommon={rate=72,value=1},Rare={rate=90,value=2},Epic={rate=108,value=2},Mythic={rate=132,value=3},Legendary={rate=156,value=4}},
 paths={
  habitats={label='Habitat modules',costs={50,120,250,450,750,1200}},
  habitat={label='Habitat comfort',costs={25,75,200,500}},
  production={label='Production',costs={40,120,300,700}},
  storage={label='Habitat storage',costs={25,75,180,400}},
  bag={label='Egg bag',costs={20,60,150,350}},
  banking={label='Banking',costs={80,250,600,1400}},
  automation={label='Automation',costs={100,300,650,1300,2500}},
 },
 automation={'Conveyor routing','Processor · +5% value','Sorter · valuable eggs first','Automatic collectors','Automatic banking'},
 cosmetics={'Nature','Water','Earth','Crystal','Fire','Cosmic'},
}
