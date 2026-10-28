-- The one egg odds table: the server rolls it and the shop shows it (odds shown = odds used).
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local O={}
-- Owner tier -> colour (intel 1b, 2026-10-27). Odds-bar order Blue / Gold / Violet / Prismatic.
O.colours={'Blue','Gold','Violet','Prismatic'}
O.colourOf={Common='Blue',Uncommon='Blue',Rare='Gold',Epic='Violet',Mythic='Prismatic',Legendary='Prismatic'}
-- Shop eggs. Robux items have no table (Q7): display is nil and the shop shows 'Odds TBD · Coming soon'.
O.items={meadow_egg={currency='coin',section=1},mystery_egg={currency='robux'},golden_egg={currency='robux'},egg_luck={currency='robux'}}
function O.table(k)
 if type(k)~='number' or k%1~=0 or k<1 or k>#C.kingdoms then return nil end
 local t={}
 for i=1,6 do local s=C.species[(k-1)*6+i];table.insert(t,{id=s.id,rarity=s.rarity,weight=s.weight}) end
 return t
end
-- r in [0,100). Same loop and boundaries as the former Main roll.
function O.pick(k,r)
 local t=O.table(k);if not t or type(r)~='number' then return nil end
 for _,s in ipairs(t) do r-=s.weight;if r<=0 then return s.id end end
 return t[#t].id
end
function O.byColour(k)
 local t=O.table(k);if not t then return nil end
 local sum={};for _,s in ipairs(t) do local c=O.colourOf[s.rarity];sum[c]=(sum[c] or 0)+s.weight end
 local out={};for _,c in ipairs(O.colours) do table.insert(out,{colour=c,percent=sum[c] or 0}) end
 return out
end
function O.display(itemId)
 local item=type(itemId)=='string' and O.items[itemId]
 if not item or item.currency~='coin' or not item.section then return nil end
 return {section=item.section,colours=O.byColour(item.section)}
end
return O
