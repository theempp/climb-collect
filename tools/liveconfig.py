"""Owner tool for LiveConfig: read, change and revert the live config key over Open Cloud.

Env (set by the owner, never printed or stored): ROBLOX_API_KEY (DataStore read+write on this universe),
ROBLOX_UNIVERSE_ID. Schema comes from mountain/shared/LiveConfig.luau, so the game and this tool agree.

  python tools/liveconfig.py show
  python tools/liveconfig.py set shop.ladders=false economy.coinRate=1.5 [--yes] [--note "why"]
  python tools/liveconfig.py unset shop.ladders [--yes]          (back to the code default)
  python tools/liveconfig.py revert <version> [--yes]           (re-applies that version's values as a new version)
  python tools/liveconfig.py log

Without --yes a write is a dry run. Every write appends to liveops/config-log.jsonl (who, when, old, new).
After a write, servers pick it up within 60 s; `--nudge` also publishes on MessagingService topic CC_LiveConfig.
"""
import argparse, base64, getpass, hashlib, json, os, re, sys, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_SRC = ROOT / "mountain" / "shared" / "LiveConfig.luau"
LOG = ROOT / "liveops" / "config-log.jsonl"
STORE, KEY, TOPIC = "CC_LiveConfig", "config", "CC_LiveConfig"
API = "https://apis.roblox.com"


def load_schema(src=None):
    text = (src or SCHEMA_SRC).read_text(encoding="utf-8")
    schema = {}
    for key, body in re.findall(r"\['([\w.]+)'\]=\{(t='\w+'[^\n]*?)\},?\n", text):
        s = {"t": re.search(r"t='(\w+)'", body).group(1)}
        for f in ("min", "max"):
            m = re.search(rf"{f}=([-\d.]+)", body)
            if m: s[f] = float(m.group(1))
        m = re.search(r"enum=\{(.*)\}", body)
        if m: s["enum"] = {a or b for a, b in re.findall(r"(?:\['([^']*)'\]|(\w+))=true", m.group(1))}
        schema[key] = s
    loop = re.search(r"for _,k in \{([^}]*)\} do\s*\n((?:\s*C\.SCHEMA\['[\w.]+'\.\.k\]=\{t='\w+'.*\n)+)", text)
    if loop:
        names = re.findall(r"'(\w+)'", loop.group(1))
        for prefix, t in re.findall(r"C\.SCHEMA\['([\w.]+)'\.\.k\]=\{t='(\w+)'", loop.group(2)):
            for n in names: schema[prefix + n] = {"t": t}
    return schema


def parse_value(s, raw):
    if s["t"] == "boolean":
        if raw.lower() in ("true", "on", "1"): return True
        if raw.lower() in ("false", "off", "0"): return False
        raise ValueError("expected true/false")
    if s["t"] == "number":
        v = float(raw)
        if v != v or v < s["min"] or v > s["max"]: raise ValueError(f"must be {s['min']:g}..{s['max']:g}")
        return int(v) if v.is_integer() else v
    if "enum" in s and raw not in s["enum"]: raise ValueError("must be one of " + ", ".join(sorted(x or "''" for x in s["enum"])))
    return raw


def validate(schema, values):
    errs = []
    for k, v in values.items():
        s = schema.get(k)
        if not s: errs.append(f"unknown key {k}"); continue
        try: parse_value(s, json.dumps(v) if s["t"] != "string" else v)
        except ValueError as e: errs.append(f"{k}: {e}")
    return errs


class Cloud:
    def __init__(self):
        self.key, self.uid = os.environ.get("ROBLOX_API_KEY"), os.environ.get("ROBLOX_UNIVERSE_ID")
        if not (self.key and self.uid): sys.exit("Set ROBLOX_API_KEY and ROBLOX_UNIVERSE_ID in the environment first.")

    def _url(self):
        q = urllib.parse.urlencode({"datastoreName": STORE, "entryKey": KEY})
        return f"{API}/datastores/v1/universes/{self.uid}/standard-datastores/datastore/entries/entry?{q}"

    def _send(self, req):
        try:
            with urllib.request.urlopen(req, timeout=30) as r: return r.status, r.read()
        except urllib.error.HTTPError as e:
            if e.code == 404: return 404, b""
            sys.exit(f"HTTP {e.code} from Roblox: {e.read().decode()[:300]}")

    def get(self):
        code, body = self._send(urllib.request.Request(self._url(), headers={"x-api-key": self.key}))
        return None if code == 404 else json.loads(body)

    def put(self, doc):
        data = json.dumps(doc, separators=(",", ":")).encode()
        md5 = base64.b64encode(hashlib.md5(data).digest()).decode()
        self._send(urllib.request.Request(self._url(), data=data, method="POST",
                   headers={"x-api-key": self.key, "content-md5": md5, "content-type": "application/json"}))

    def nudge(self, version):
        data = json.dumps({"message": json.dumps({"version": version})}).encode()
        self._send(urllib.request.Request(f"{API}/messaging-service/v1/universes/{self.uid}/topics/{TOPIC}", data=data,
                   method="POST", headers={"x-api-key": self.key, "content-type": "application/json"}))


def read_log():
    if not LOG.exists(): return []
    return [json.loads(l) for l in LOG.read_text(encoding="utf-8").splitlines() if l.strip()]


def write(cloud, current, values, note, yes, nudge, action):
    old = (current or {}).get("values", {})
    version = max((current or {}).get("version", 0), max((e["version"] for e in read_log()), default=0)) + 1
    diff = {k: [old.get(k), values.get(k)] for k in sorted(set(old) | set(values)) if old.get(k) != values.get(k)}
    if not diff: print("No change."); return None
    for k, (a, b) in diff.items(): print(f"  {k}: {json.dumps(a)} -> {json.dumps(b)}{'  (default)' if b is None else ''}")
    if not yes: print(f"Dry run: would write version {version}. Add --yes to apply."); return None
    cloud.put({"version": version, "values": values})
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"version": version, "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "by": getpass.getuser(),
                            "action": action, "note": note or "", "old": old, "new": values}) + "\n")
    if nudge: cloud.nudge(version)
    print(f"Wrote version {version}. Servers apply it within 60 s{' (nudged)' if nudge else ''}.")
    return version


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["show", "set", "unset", "revert", "log"])
    ap.add_argument("args", nargs="*")
    ap.add_argument("--yes", action="store_true")
    ap.add_argument("--nudge", action="store_true")
    ap.add_argument("--note")
    a = ap.parse_args(argv)
    schema = load_schema()
    if a.cmd == "log":
        for e in read_log(): print(f"v{e['version']} {e['at']} {e['by']} {e['action']} {e['note']}")
        return
    cloud = Cloud()
    current = cloud.get()
    values = dict((current or {}).get("values", {}))
    if a.cmd == "show":
        print(f"version {(current or {}).get('version', 0)} (unset keys use code defaults)")
        for k in sorted(schema): print(f"  {k} = {json.dumps(values[k]) if k in values else '(default)'}")
        return
    if a.cmd == "set":
        for pair in a.args:
            k, _, raw = pair.partition("=")
            if k not in schema: sys.exit(f"Unknown key {k}.")
            try: values[k] = parse_value(schema[k], raw)
            except ValueError as e: sys.exit(f"{k}: {e}")
    elif a.cmd == "unset":
        for k in a.args: values.pop(k, None)
    elif a.cmd == "revert":
        if len(a.args) != 1: sys.exit("revert needs one version number (see `log`).")
        entry = next((e for e in read_log() if e["version"] == int(a.args[0])), None)
        if not entry: sys.exit("That version is not in the local change log.")
        values = dict(entry["new"])
    errs = validate(schema, values)
    if errs: sys.exit("Refused: " + "; ".join(errs))
    write(cloud, current, values, a.note, a.yes, a.nudge, a.cmd + (" " + " ".join(a.args) if a.args else ""))


if __name__ == "__main__":
    main()
