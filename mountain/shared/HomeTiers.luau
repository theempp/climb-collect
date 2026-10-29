-- Plot tiers and the coin decor catalog (home-base P2). Pure data; every number is PROPOSED until STOP 3.
-- A tier is raised with rank level AND coins (owner Q1). It only unlocks the right to buy: the habitat comfort cap
-- and the number of usable decor slots. Role names are intel A1 token names (atlas confirms them in P3); no colour here.
local H={slots=14,stockCap=4}
H.tiers={
 {name='Dry-stone Yard',rank=1,fee=0,habitatCap=1,usable=4,roles={'dryStone','stoneCoping','meadow'}},
 {name='Cedar Cloister',rank=5,fee=1000,habitatCap=2,usable=7,roles={'dryStone','stoneCoping','meadow','cedar','pierFoot'}},
 {name='Brass & Lantern',rank=15,fee=5000,habitatCap=3,usable=10,roles={'dryStone','stoneCoping','meadow','cedar','pierFoot','brass','lanternGlass','tealCornice'}},
 {name='Azure Terrace',rank=30,fee=15000,habitatCap=4,usable=14,roles={'dryStone','stoneCoping','meadow','cedar','pierFoot','brass','lanternGlass','tealCornice','azureWater','crest'}},
}
-- Coin props (owner Q6). Forms come from the harvested ServerStorage.HomeProtos (Boulder, PlantingBed, Divider hedge,
-- Lantern, Tree) plus the Azure channel water; looks are built in P4. tier = lowest plot tier that may buy it.
H.props={
 boulder={id='boulder',name='Weathered boulder',price=150,tier=1,proto='Boulder'},
 bed={id='bed',name='Alpine planting bed',price=300,tier=1,proto='PlantingBed'},
 hedge={id='hedge',name='Hedge planter',price=500,tier=2,proto='Divider_01'},
 lantern={id='lantern',name='Cedar lantern',price=800,tier=2,proto='Lantern'},
 sapling={id='sapling',name='Pine sapling',price=1200,tier=3,proto='Tree'},
 basin={id='basin',name='Azure basin',price=2500,tier=4,proto=nil},
}
H.propOrder={'boulder','bed','hedge','lantern','sapling','basin'}
return H
