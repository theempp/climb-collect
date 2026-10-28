-- Coin shop (Glassbloom P2 T9, C14/C15, Q5): exact debit, refusals change nothing, receipts, caps, EggOdds roll.
local R=require('../shared/Rules')
local O=require('../shared/EggOdds')
local S=require('../shared/ShopRules')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local function rich(coins) local p=R.newProfile(100);p.coins=coins;return p end
local function same(a,b) return a.coins==b.coins and a.serial==b.serial and #a.eggs==#b.eggs and #(a.receipts or {})==#(b.receipts or {}) end
local function snapshot(p) return {coins=p.coins,serial=p.serial,eggs=table.clone(p.eggs),receipts=p.receipts and table.clone(p.receipts)} end
-- Catalog: shown = sold. Currency and section match EggOdds.items; every product id is 0; Robux items carry no price.
for id,item in pairs(S.catalog) do
 local o=O.items[id]
 check(o and item.id==id and item.currency==o.currency and item.section==o.section and item.productId==0,'catalog_matches_egg_odds_'..id)
 check(item.currency=='coin' or item.price==nil,'robux_item_has_no_price_'..id)
end
for id in pairs(O.items) do check(S.catalog[id]~=nil,'egg_odds_item_listed_'..id) end
local meadow=S.catalog.meadow_egg
check(meadow.price==2500 and meadow.section==1 and meadow.kind=='egg' and S.eggCap==24 and S.receiptCap==64 and S.cooldown==2,'meadow_egg_2500_section_1_caps')
-- Exact debit and grant; the egg rolls EggOdds.pick(1,r) and carries origin 'coin'.
local p=rich(2600);local ok,why,egg=S.buy(p,'meadow_egg','receipt-0001',50)
check(ok and why=='bought' and p.coins==100 and #p.eggs==1 and p.eggs[1]==egg,'exact_debit_one_egg')
check(egg.id=='e4' and p.serial==4 and egg.species==O.pick(1,50) and egg.origin=='coin' and egg.readyAt==nil,'egg_id_serial_species_origin')
check(#p.receipts==1 and p.receipts[1]=='receipt-0001' and S.has(p,'receipt-0001'),'receipt_appended')
for _,r in ipairs({0,19.5,20,40,40.5,68,85.9,86,95.99,96,99.999}) do
 local q=rich(2500);check(S.buy(q,'meadow_egg','roll-receipt',r) and q.eggs[1].species==O.pick(1,r),'roll_via_egg_odds_'..r)
end
-- Refusals change nothing.
local poor=rich(2499);local before=snapshot(poor);ok,why=S.buy(poor,'meadow_egg','receipt-poor',10)
check(not ok and why=='coins' and same(poor,before) and poor.receipts==nil,'insufficient_coins_changes_nothing')
local q=rich(9000);before=snapshot(q)
ok,why=S.buy(q,'unknown_egg','receipt-unk1',10);check(not ok and why=='unknown' and same(q,before),'unknown_item_refused')
ok,why=S.buy(q,nil,'receipt-unk2',10);check(not ok and why=='unknown' and same(q,before),'missing_item_refused')
for _,id in ipairs({'mystery_egg','golden_egg','egg_luck'}) do ok,why=S.buy(q,id,'receipt-'..id:gsub('_','-'),10);check(not ok and why=='unavailable' and same(q,before),'robux_item_unavailable_'..id) end
for _,bad in ipairs({'short','has space!','x:receipt1',string.rep('a',65),7,nil}) do ok,why=S.buy(q,'meadow_egg',bad,10);check(not ok and why=='invalid' and same(q,before),'invalid_receipt_refused') end
for _,bad in ipairs({0/0,-1,100,math.huge,'50'}) do ok,why=S.buy(q,'meadow_egg','receipt-roll',bad);check(not ok and why=='invalid' and same(q,before),'invalid_roll_refused') end
-- Duplicate receipt: false,'duplicate' with no debit.
ok=S.buy(q,'meadow_egg','receipt-dupe',10);before=snapshot(q)
ok,why=S.buy(q,'meadow_egg','receipt-dupe',90);check(not ok and why=='duplicate' and same(q,before),'duplicate_receipt_refused')
-- Egg cap 24 (unhatched, incubating included).
local full=rich(1e6);for i=1,23 do table.insert(full.eggs,{id='x'..i,species='mossbun',readyAt=if i<=3 then 500 else nil}) end
check(S.buy(full,'meadow_egg','receipt-cap23',10) and #full.eggs==24,'twenty_fourth_egg_allowed')
before=snapshot(full);ok,why=S.buy(full,'meadow_egg','receipt-cap24',10)
check(not ok and why=='egg_cap' and same(full,before),'egg_cap_24_refuses_25th')
-- FIFO receipts of 64: dense, newest last, oldest dropped.
local fifo=rich(1e6);fifo.eggs={}
for i=1,70 do fifo.eggs={};check(S.buy(fifo,'meadow_egg',string.format('fifo-%04d',i),10),'fifo_buy_'..i) end
check(#fifo.receipts==64 and fifo.receipts[1]=='fifo-0007' and fifo.receipts[64]=='fifo-0070' and not S.has(fifo,'fifo-0006'),'fifo_64_drops_oldest')
local dense=0;for k in pairs(fifo.receipts) do dense+=1;check(type(k)=='number' and k%1==0 and k>=1 and k<=64,'receipts_dense_key') end
check(dense==64,'receipts_dense')
-- Malformed receipts never error: junk entries are dropped on the next buy.
local junk=rich(2500);junk.receipts={'receipt-keep',7,'bad receipt',{}}
check(S.buy(junk,'meadow_egg','receipt-next',10) and #junk.receipts==2 and junk.receipts[1]=='receipt-keep' and junk.receipts[2]=='receipt-next','malformed_receipts_normalized')
local str=rich(2500);str.receipts='junk';check(not S.has(str,'receipt-next') and S.buy(str,'meadow_egg','receipt-next',10) and #str.receipts==1,'string_receipts_replaced')
-- The grant is a valid saved egg (never Legendary, id unique to the profile).
local seen={};local many=rich(1e6);many.eggs={}
for i=1,24 do S.buy(many,'meadow_egg',string.format('many-%04d',i),(i*4.1)%100) end
for _,e in ipairs(many.eggs) do check(not seen[e.id] and e.origin=='coin',"grant_unique_coin_egg");seen[e.id]=true end
print('PASS '..n..' shop rules checks')
