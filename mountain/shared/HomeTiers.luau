-- Plot tiers and the coin decor catalog (home-base P2). Pure data; every number is PROPOSED until STOP 3.
-- A tier is raised with rank level AND coins (owner Q1). It only unlocks the right to buy: the habitat comfort cap
-- and the number of usable decor slots. `style` keys WorldStyle.tier (s1-plan §2a); no colour here, names display-only.
local H={slots=14,stockCap=4}
H.tiers={
 {name='Hut',rank=1,fee=0,habitatCap=1,usable=4,style='hut'},
 {name='Villa',rank=5,fee=1000,habitatCap=2,usable=7,style='villa'},
 {name='Manor',rank=15,fee=5000,habitatCap=3,usable=10,style='manor'},
 {name='Palace',rank=30,fee=15000,habitatCap=4,usable=14,style='palace'},
}
-- Coin props (owner Q6). Forms come from the harvested ServerStorage.HomeProtos (Boulder, PlantingBed, Divider hedge,
-- Lantern, Tree) until S5; S2 names per decisions S1 STOP, forms = WorldKit (s1-plan §2b). tier = lowest plot tier that may buy it.
H.props={
 boulder={id='boulder',name='Candy boulder',price=150,tier=1,proto='Boulder'},
 bed={id='bed',name='Bloom bed',price=300,tier=1,proto='PlantingBed'},
 hedge={id='hedge',name='Puff hedge',price=500,tier=2,proto='Divider_01'},
 lantern={id='lantern',name='Globe lamp',price=800,tier=2,proto='Lantern'},
 sapling={id='sapling',name='Cloud tree',price=1200,tier=3,proto='Tree'},
 basin={id='basin',name='Gem basin',price=2500,tier=4,proto=nil},
}
H.propOrder={'boulder','bed','hedge','lantern','sapling','basin'}
return H
