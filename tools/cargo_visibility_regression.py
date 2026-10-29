"""Exercise public Cargo offers without revealing or mutating stored hatch outcomes."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "src/core/server/Cargo.luau").read_text(encoding="utf-8")
INVENTORY_SOURCE = (ROOT / "src/core/server/Inventory.luau").read_text(encoding="utf-8")
HARNESS = r'''
local chunk=assert(loadstring([====[__CARGO_SOURCE__]====]))
setfenv(chunk,setmetatable({game={GetService=function() return {GenerateGUID=function() return 'offer-token' end} end}},{__index=getfenv(0)}))
local Cargo=chunk()
local plr={UserId=7}
local ctx={sessions={[plr]={}},handlers={},Inv={locked=function() return false end,free=function() return 0 end},Clock={now=function() return 100 end},toast=function() end,push=function() end}
Cargo.init(ctx)
local discovery={id='stone-origin',place='Hollow',method='guardian distraction',at=12}
local stone={uid='stone-id',kind='heartstone',species='secret_species',tier='Rare',slots=2,source='hollow',discovery=discovery}
assert(Cargo.acquire(plr,stone,{label='Hollow'}).offered)
local st={};Cargo.state(plr,st)
assert(st.swapOffer.item.species==nil,'full-bag preview exposes hidden hatch species')
assert(st.swapOffer.item.uid=='stone-id' and st.swapOffer.item.discovery.id=='stone-origin','public preview lost identity/provenance')
assert(stone.species=='secret_species','public serialization altered authoritative outcome')
assert(st.swapOffer.item~=stone,'public preview aliases authoritative item')
local creature={uid='creature-id',kind='creature',species='visible_species',rarity='Rare',slots=1}
assert(Cargo.acquire(plr,creature,{label='Hollow'}).offered)
st={};Cargo.state(plr,st)
assert(st.swapOffer.item.species=='visible_species','claimed creature identity was hidden')
local bankedStone={id='banked-stone',species='hidden_banked_species',tier='Epic',progress=3,required=9,ready=false,discovery=discovery}
assert(Cargo.clientItem(bankedStone,true).species==nil,'banked stone outcome exposed')
assert(bankedStone.species=='hidden_banked_species','banked authoritative outcome changed')
local config={SLOTS_BASE=6}
local folder={WaitForChild=function(self) return self end}
local cargoModule={}
local inventoryChunk=assert(loadstring([====[__INVENTORY_SOURCE__]====]))
setfenv(inventoryChunk,setmetatable({
 game={GetService=function() return folder end},script={Parent={Cargo=cargoModule}},
 require=function(module) return module==cargoModule and Cargo or config end,
},{__index=getfenv(0)}))
local Inv=inventoryChunk()
Inv.bind(plr.UserId,{data={cargo={stone,creature},slots=6}})
local view=Inv.view(plr.UserId)
assert(view[1].species==nil and view[2].species=='visible_species','inventory snapshot did not distinguish hidden outcomes from creatures')
assert(Inv.bag(plr.UserId).items[1].species=='secret_species','inventory projection mutated durable cargo')
print('Cargo visibility: 9/9 passed (real Cargo + Inventory modules)')
'''
with tempfile.TemporaryDirectory(prefix="cc-cargo-") as temp:
    harness = Path(temp) / "cargo.luau"
    harness.write_text(HARNESS.replace("__CARGO_SOURCE__", SOURCE).replace("__INVENTORY_SOURCE__", INVENTORY_SOURCE), encoding="utf-8")
    result = subprocess.run([str(ROOT / "tools/.luau/luau.exe"), str(harness)], cwd=ROOT)
    raise SystemExit(result.returncode)
