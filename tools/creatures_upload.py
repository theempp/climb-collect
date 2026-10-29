"""Upload creature GLBs to Roblox via Open Cloud (Assets API) and record asset ids.

Env (set by the user, never printed or stored): ROBLOX_API_KEY (Assets read+write), ROBLOX_USER_ID.
Usage: python tools/creatures_upload.py [--only id,id] [--force] [--dry-run]
Ledger: creatures/build/asset_ids.json {id: {assetId, sha256, uploadedAt, displayName}}. Unchanged GLBs are skipped.
"""
import argparse, hashlib, json, os, sys, time, uuid, urllib.request, urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "creatures" / "build" / "out"
LEDGER = ROOT / "creatures" / "build" / "asset_ids.json"
API = "https://apis.roblox.com/assets/v1"


def multipart(fields, files):
    b = "----cc" + uuid.uuid4().hex
    body = b""
    for k, v in fields.items():
        body += f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode()
    for k, (name, data, ctype) in files.items():
        body += f'--{b}\r\nContent-Disposition: form-data; name="{k}"; filename="{name}"\r\nContent-Type: {ctype}\r\n\r\n'.encode() + data + b"\r\n"
    body += f"--{b}--\r\n".encode()
    return body, f"multipart/form-data; boundary={b}"


def call(req):
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code} from Roblox: {e.read().decode()[:400]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    key, uid = os.environ.get("ROBLOX_API_KEY"), os.environ.get("ROBLOX_USER_ID")
    if not a.dry_run and not (key and uid):
        sys.exit("Set ROBLOX_API_KEY and ROBLOX_USER_ID in the environment first.")
    ledger = json.loads(LEDGER.read_text()) if LEDGER.exists() else {}
    ids = a.only.split(",") if a.only else sorted(p.name for p in OUT.iterdir() if (p / f"{p.name}.glb").exists())
    for cid in ids:
        glb = OUT / cid / f"{cid}.glb"
        data = glb.read_bytes()
        sha = hashlib.sha256(data).hexdigest()
        if not a.force and ledger.get(cid, {}).get("sha256") == sha:
            print(f"skip {cid} (unchanged, asset {ledger[cid]['assetId']})")
            continue
        name = f"CC_{cid}"
        print(f"{'would upload' if a.dry_run else 'upload'} {cid} ({len(data)//1024} KB)")
        if a.dry_run:
            continue
        req_json = json.dumps({"assetType": "Model", "displayName": name, "description": "Climb & Collect creature mesh", "creationContext": {"creator": {"userId": uid}}})
        body, ctype = multipart({"request": req_json}, {"fileContent": (f"{cid}.glb", data, "model/gltf-binary")})
        op = call(urllib.request.Request(f"{API}/assets", data=body, method="POST", headers={"x-api-key": key, "Content-Type": ctype}))
        opid = op["path"].split("/")[-1]
        for _ in range(60):
            time.sleep(2)
            st = call(urllib.request.Request(f"{API}/operations/{opid}", headers={"x-api-key": key}))
            if st.get("done"):
                if "error" in st:
                    sys.exit(f"{cid}: upload failed: {st['error']}")
                ledger[cid] = {"assetId": st["response"]["assetId"], "sha256": sha, "uploadedAt": int(time.time()), "displayName": name}
                LEDGER.write_text(json.dumps(ledger, indent=2))
                print(f"  ok {cid} -> {ledger[cid]['assetId']}")
                break
        else:
            sys.exit(f"{cid}: timed out waiting for operation {opid}")


if __name__ == "__main__":
    main()
