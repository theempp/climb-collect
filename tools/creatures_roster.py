"""Build creatures/roster.json from the approved brief + selections.json + Blender manifests.

Usage (project root): python tools/creatures_roster.py
Then: python tools/roster_to_luau.py creatures/roster.json src/core/shared/SpeciesRoster.luau
Measured numbers (tris, mesh parts) come from creatures/build/out/<id>/manifest.json when present, else null.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CR = ROOT / "creatures"
REGION = {"GREEN VALLEY": 1, "WHISPERING FOREST": 2, "BROKEN CLIFFS": 3, "STORM RIDGE": 4, "FROZEN SUMMIT": 5, "WEATHER-LINKED": 0}
REGION_DIR = {1: "green_valley", 2: "whispering_forest", 3: "broken_cliffs", 4: "storm_ridge", 5: "frozen_summit", 0: "weather_linked"}
# coarse spawn ecology used by Species.query (ground | hopping | perched | floating | hiding | pup); the brief's prose goes in ecologyNote
COARSE = {
    "budskip": "hopping", "brookspool": "ground", "petalstilts": "perched", "sailsprig": "floating", "cupmuzzle": "hiding", "hollowhush": "hiding", "springmantle_pup": "pup", "fallsong": "floating",
    "rootruck": "ground", "hoodwinklet": "hopping", "lanterncrop": "perched", "archwhisk": "floating", "scrolltail": "hiding", "knothollow": "hiding", "rootwarden_pup": "pup", "vesperbough": "floating",
    "ledgebutton": "ground", "pebblepouch": "hopping", "cragbeak": "perched", "spanwing": "floating", "screecoil": "hiding", "cleftlistener": "hiding", "archback_pup": "pup", "horizonstride": "floating",
    "gustpuff": "ground", "runeheel": "hopping", "stormpleat": "perched", "vanecrest": "floating", "chimebelly": "hiding", "stillocket": "hiding", "tempestmane_pup": "pup", "spirewake": "floating",
    "frostmitten": "ground", "notchhorn": "hopping", "icefrill": "perched", "facetstep": "floating", "veilfin": "hiding", "snowfold": "hiding", "crownward_pup": "pup", "crownlume": "floating",
    "thunderhinge": "floating", "auroraloop": "floating", "whiteout_shelter": "floating",
}
WEATHER = {"thunderhinge": "Storm", "auroraloop": "AuroraNight", "whiteout_shelter": "SnowWhiteout"}
ANIMS = ["idle", "move", "react", "claimed"]
MUTATION_NOTE = "Visual variants for Clear, Rain, Fog, Storm, Snow, Aurora Night recolour/overlay broad existing surfaces only; silhouette, openings and face stay unchanged. Server owns mutation."


def main():
    sel = json.loads((CR / "selections.json").read_text(encoding="utf-8"))
    chosen = {}
    for region, d in sel.items():
        if isinstance(d, dict) and region in REGION_DIR.values():
            chosen.update(d)
    chosen.setdefault("snowfold", "B")  # no clean pick: B is the agreed starting point (HOLD resolved by build-from-brief)
    rows, region = [], None
    for line in (CR / "approved-brief.txt").read_text(encoding="utf-8").splitlines():
        head = re.match(r"^([A-Z][A-Z \-]+?)(?: —.*)?$", line.strip())
        if head and head.group(1) in REGION:
            region = REGION[head.group(1)]
            continue
        parts = [p.strip() for p in line.split("|")]
        if region is not None and len(parts) == 6 and re.fullmatch(r"[a-z_]+", parts[0]):
            rows.append((region, *parts))
    counts = {}
    out = []
    for region, cid, name, rarity, sil, pers, eco in rows:
        n = counts[(region, rarity)] = counts.get((region, rarity), 0) + 1
        if region == 0:
            stub = f"stub_legendary_{5 + n}"
        elif rarity == "Common":
            stub = f"stub_common_{(region - 1) * 3 + n}"
        elif rarity == "Uncommon":
            stub = f"stub_uncommon_{(region - 1) * 2 + n}"
        else:
            stub = f"stub_{rarity.lower()}_{region}"
        mp = CR / "build" / "out" / cid / "manifest.json"
        man = json.loads(mp.read_text()) if mp.exists() else {}
        e = {
            "id": cid, "name": name, "region": region, "rarity": rarity, "kind": "creature",
            "ecology": COARSE[cid], "ecologyNote": eco, "silhouette": sil, "personality": pers,
            "reference": f"creatures/references/{REGION_DIR[region]}/{cid}_{chosen.get(cid, '?')}.png",
            "animations": ANIMS, "replaces": stub,
            "partsBudget": {"proposedTris": 6000 if rarity == "Legendary" else 3500, "measuredTris": man.get("tris"), "meshParts": man.get("mesh_parts"), "status": "PROPOSED budget; measured = Blender export, Studio/mobile UNVERIFIED"},
            "mutationNotes": MUTATION_NOTE,
        }
        if cid in WEATHER:
            e["weather"] = WEATHER[cid]
        if rarity == "Epic":
            e["guardian"] = f"stub_guardian_{region}"
        out.append(e)
    (CR / "roster.json").write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    missing = [e["id"] for e in out if "?" in e["reference"]]
    print(f"{len(out)} species -> creatures/roster.json; missing ref choice: {missing}")


if __name__ == "__main__":
    main()
