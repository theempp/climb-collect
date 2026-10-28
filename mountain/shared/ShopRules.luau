-- Coin shop (Glassbloom P2 D7, Q5). Pure: buy() mutates only a caller-owned draft and changes nothing on refusal.
-- Robux items stay disabled: product id 0, no price, and buy() refuses them. Single buy only (no ×3).
local O=if script then require(script.Parent.EggOdds) else require('./EggOdds')
local S={eggCap=24,receiptCap=64,cooldown=2}
-- Currency and section match EggOdds.items, so an egg rolls exactly the table the shop shows.
S.catalog={
 meadow_egg={id='meadow_egg',kind='egg',currency='coin',price=2500,section=1,productId=0},
 mystery_egg={id='mystery_egg',kind='egg',currency='robux',productId=0},
 golden_egg={id='golden_egg',kind='egg',currency='robux',productId=0},
 egg_luck={id='egg_luck',kind='boost',currency='robux',productId=0},
}
function S.validReceipt(v) return type(v)=='string' and #v>=8 and #v<=64 and v:match('^[%w%-]+$')~=nil end
function S.has(p,receipt)
 if type(p.receipts)~='table' then return false end
 for _,v in pairs(p.receipts) do if v==receipt then return true end end
 return false
end
-- r in [0,100) for EggOdds.pick. Returns true,'bought',egg or false,reason.
function S.buy(p,itemId,receipt,r)
 if not S.validReceipt(receipt) then return false,'invalid' end
 if S.has(p,receipt) then return false,'duplicate' end
 local item=type(itemId)=='string' and S.catalog[itemId]
 if not item then return false,'unknown' end
 if item.currency~='coin' or item.kind~='egg' or type(item.price)~='number' then return false,'unavailable' end
 if type(r)~='number' or r~=r or r<0 or r>=100 then return false,'invalid' end
 if type(p.coins)~='number' or p.coins<item.price then return false,'coins' end
 if type(p.eggs)~='table' or #p.eggs>=S.eggCap then return false,'egg_cap' end
 local species=O.pick(item.section,r);if not species then return false,'invalid' end
 p.coins-=item.price;p.serial+=1
 local egg={id='e'..p.serial,species=species,origin='coin'};table.insert(p.eggs,egg)
 -- Dense and newest last; past 64 the oldest leaves first (the securedRunIds pattern).
 local list={};if type(p.receipts)=='table' then for _,v in ipairs(p.receipts) do if S.validReceipt(v) then table.insert(list,v) end end end
 table.insert(list,receipt);while #list>S.receiptCap do table.remove(list,1) end
 p.receipts=list
 return true,'bought',egg
end
return S
