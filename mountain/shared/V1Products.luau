-- E02 product catalog. Every Roblox id is 0: nothing is purchasable until products are created and
-- spending is authorized (owner). Prices are the PROPOSED decision-doc numbers or unset (nil).
-- kind: 'consumable' dev product (repeatable) | 'once' dev product (one per account) | 'pass' game pass.
-- No power items, no raid stats/slots/pieces, no legacy multiplier passes (LOCKED).
local P={}
P.list={
 {key='starter_pack',kind='once',id=0,price=199,grant={coins=1000,eggTickets=3,cosmetic='trim_starter'}},
 {key='vip',kind='pass',id=0,price=599,grant={title='vip',cosmetic='trim_vip'}},
 {key='summit_pass',kind='pass',id=0,price=449,grant={title='summit_pass',cosmetic='trim_summit'}},
 {key='production_boost',kind='consumable',id=0,price=nil,grant={boost='production',seconds=3600}},
 {key='raid_reroll',kind='consumable',id=0,price=nil,grant={raidReroll=1}},
 {key='outpost_shield',kind='consumable',id=0,price=nil,grant={shield=1}},
}
P.byKey={};P.byProductId={};P.byPassId={}
for _,item in ipairs(P.list) do
 P.byKey[item.key]=item
 -- id 0 is never indexed, so no receipt or ownership check can ever match an unconfigured product.
 if item.id~=0 then if item.kind=='pass' then P.byPassId[item.id]=item else P.byProductId[item.id]=item end end
end
return P
