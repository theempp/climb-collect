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
 -- C16 (Q5): looks only; knockback and reach always come from BatRules. No server token module exists, so the look is the
 -- Epic violet already in code (Theme.rarity.Epic #8A4BE6, the board card's rarity.violet gradient end) for barrel and trail.
 candy_swirl={id='candy_swirl',kind='skin',name='Candy Swirl',currency='coin',price=5000,productId=0,look={color={138,75,230},trail={138,75,230}}},
}
function S.validReceipt(v) return type(v)=='string' and #v>=8 and #v<=64 and v:match('^[%w%-]+$')~=nil end
function S.has(p,receipt)
 if type(p.receipts)~='table' then return false end
 for _,v in pairs(p.receipts) do if v==receipt then return true end end
 return false
end
function S.isSkin(id) local item=type(id)=='string' and S.catalog[id];return item and item.kind=='skin' or false end
-- p.cosmetics={skins={[id]=true},batSkin=id|nil}, kept outside p.bats (BatRules.normalize rebuilds that). Read-only view:
-- unknown or non-true skin ids and an unowned batSkin are ignored, so a malformed save never errors.
function S.cosmetics(p)
 local c=type(p.cosmetics)=='table' and p.cosmetics or {};local skins={}
 if type(c.skins)=='table' then for id,v in pairs(c.skins) do if v==true and S.isSkin(id) then skins[id]=true end end end
 return {skins=skins,batSkin=if type(c.batSkin)=='string' and skins[c.batSkin] then c.batSkin else nil}
end
-- Load: unknown skin ids are dropped (persisted in the load write).
function S.normalizeCosmetics(p) p.cosmetics=S.cosmetics(p);return p.cosmetics end
function S.owns(p,id) return S.cosmetics(p).skins[id]==true end
-- Skin{op='equip'|'clear',id}: equip needs an owned skin; clear always succeeds.
function S.skin(p,op,id)
 if op=='clear' then if p.cosmetics~=nil then S.normalizeCosmetics(p).batSkin=nil end;return true end
 if op~='equip' or not S.owns(p,id) then return false,'not_owned' end
 S.normalizeCosmetics(p).batSkin=id;return true
end
-- The equipped skin's colours, or nil. Never stats.
function S.batLook(p) local id=S.cosmetics(p).batSkin;return if id then S.catalog[id].look else nil end
-- r in [0,100) for EggOdds.pick (eggs only). Returns true,'bought',egg|skinId or false,reason.
function S.buy(p,itemId,receipt,r)
 if not S.validReceipt(receipt) then return false,'invalid' end
 if S.has(p,receipt) then return false,'duplicate' end
 local item=type(itemId)=='string' and S.catalog[itemId]
 if not item then return false,'unknown' end
 if item.currency~='coin' or (item.kind~='egg' and item.kind~='skin') or type(item.price)~='number' then return false,'unavailable' end
 if item.kind=='egg' and (type(r)~='number' or r~=r or r<0 or r>=100) then return false,'invalid' end
 -- An owned skin is refused before any debit.
 if item.kind=='skin' and S.owns(p,item.id) then return false,'owned' end
 if type(p.coins)~='number' or p.coins<item.price then return false,'coins' end
 local granted
 if item.kind=='skin' then
  p.coins-=item.price;S.normalizeCosmetics(p).skins[item.id]=true;granted=item.id
 else
  if type(p.eggs)~='table' or #p.eggs>=S.eggCap then return false,'egg_cap' end
  local species=O.pick(item.section,r);if not species then return false,'invalid' end
  p.coins-=item.price;p.serial+=1
  granted={id='e'..p.serial,species=species,origin='coin'};table.insert(p.eggs,granted)
 end
 -- Dense and newest last; past 64 the oldest leaves first (the securedRunIds pattern).
 local list={};if type(p.receipts)=='table' then for _,v in ipairs(p.receipts) do if S.validReceipt(v) then table.insert(list,v) end end end
 table.insert(list,receipt);while #list>S.receiptCap do table.remove(list,1) end
 p.receipts=list
 return true,'bought',granted
end
return S
