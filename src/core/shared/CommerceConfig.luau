-- IDs deliberately unset. Draft prices are labels for local review, never checkout prices.
local C = { tiers = {2,4,6,8,10,12}, offers = {}, order = {}, cosmetics = {lantern=true,banner=true,flag=true,trail=true} }
local function add(id, o)
 o.id=id; o.platformId=0; C.offers[id]=o; table.insert(C.order,id)
end
add("bundle", {name="Camp Glow",kind="pass",draftPrice=19,items={"lantern","banner"},detail="Sunbeam lantern skin + camp banner. Two permanent cosmetics."})
for i,n in ipairs(C.tiers) do add("upgrade"..(i-1), {name=n.."× coin earnings",kind="pass",tier=i,draftPrice=({3,9,19,39,79,149})[i],detail="Permanent total earned-coin multiplier. Bank discoveries and home income only; purchased coins excluded."}) end
for i,n in ipairs({100,350,900,2000}) do add("coins"..n,{name=n.." Cairn Coins",kind="product",coins=n,draftPrice=({9,25,59,119})[i],detail="Exact coin amount. Never multiplied. Spend it when you choose."}) end
for _,r in ipairs({{"flag","Trail pennant",3},{"trail","Sparkle trail",5},{"lantern","Sunbeam lantern skin",19},{"banner","Sunbeam camp banner",19}}) do add(r[1],{name=r[2],kind="pass",items={r[1]},draftPrice=r[3],detail="Permanent cosmetic. Equip or tuck away anytime. No gameplay advantage."}) end
return C
