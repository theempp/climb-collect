"""Offline checks for tools/liveconfig.py: schema parity with LiveConfig.luau, validation, dry run, log + revert."""
import importlib.util, io, json, sys, tempfile, contextlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("liveconfig", ROOT / "tools" / "liveconfig.py")
T = importlib.util.module_from_spec(spec); spec.loader.exec_module(T)
n = 0
def check(v, msg):
    global n
    assert v, msg; n += 1

S = T.load_schema()
check(len(S) == 25, f"schema has 13 fixed + 12 kingdom keys (got {len(S)})")
check(S["economy.coinMultCap"] == {"t": "number", "min": 1, "max": 100}, "number range parsed")
check(S["banner"]["enum"] == {"", "maintenance", "event_live", "new_content", "known_issue"}, "banner presets parsed")
check(S["mountain.azure"]["t"] == "boolean" and "guardian.inferno" in S, "kingdom loop expanded")
check(T.parse_value(S["shop.ladders"], "off") is False, "bool parse")
for bad in [("economy.coinRate", "1e9"), ("economy.coinRate", "nan"), ("banner", "hello players"), ("shop.enabled", "maybe")]:
    try: T.parse_value(S[bad[0]], bad[1]); check(False, f"{bad} must be refused")
    except ValueError: check(True, "")
check(T.validate(S, {"shopp.enabled": False}) == ["unknown key shopp.enabled"], "typo key refused")
check(T.validate(S, {"economy.coinRate": 1.5, "shop.ladders": False}) == [], "good values pass")

class Fake:
    def __init__(self): self.doc, self.puts, self.nudges = None, 0, 0
    def get(self): return self.doc
    def put(self, d): self.doc = json.loads(json.dumps(d)); self.puts += 1
    def nudge(self, v): self.nudges += 1
fake = Fake()
T.Cloud = lambda: fake
T.LOG = Path(tempfile.mkdtemp()) / "config-log.jsonl"
def run(*a):
    out = io.StringIO()
    with contextlib.redirect_stdout(out): T.main(list(a))
    return out.getvalue()
check("Dry run" in run("set", "shop.ladders=false") and fake.puts == 0, "no --yes = no write")
run("set", "shop.ladders=false", "--yes", "--note", "receipt bug")
check(fake.doc == {"version": 1, "values": {"shop.ladders": False}}, "write version 1")
run("set", "economy.coinRate=2", "--yes", "--nudge")
check(fake.doc["version"] == 2 and fake.doc["values"]["shop.ladders"] is False and fake.nudges == 1, "set merges, nudge sent")
run("unset", "shop.ladders", "--yes")
check("shop.ladders" not in fake.doc["values"] and fake.doc["version"] == 3, "unset returns to default")
run("revert", "1", "--yes")
check(fake.doc == {"version": 4, "values": {"shop.ladders": False}}, "revert re-applies v1 as a new version")
log = T.read_log()
check([e["version"] for e in log] == [1, 2, 3, 4] and log[0]["note"] == "receipt bug" and log[1]["old"] == {"shop.ladders": False}, "change log keeps old/new")
check("No change." in run("revert", "4", "--yes") and fake.puts == 4, "identical write skipped")
try: run("set", "economy.coinRate=99", "--yes"); check(False, "")
except SystemExit as e: check("must be" in str(e) and fake.puts == 4, "range refusal never writes")
print(f"PASS {n} liveconfig tool checks")
