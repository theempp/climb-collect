#!/bin/bash
# x.sh <luau-file> : run Luau in ONE pinned Studio (set STUDIO=<studio id>; edit DM unless DM env set)
[ -z "$STUDIO" ] && { echo "set STUDIO=<studio id> (list_roblox_studios)"; exit 2; }
S="$(dirname "$0")"
python - "$1" "${DM:-Edit}" "$STUDIO" > "$S/args.json" <<'PY'
import json,sys
print(json.dumps({"studio_id":sys.argv[3],"datamodel_type":sys.argv[2],"code":open(sys.argv[1],encoding='utf-8').read()}))
PY
timeout 600 python "$S/rmcp.py" call execute_luau "$S/args.json"
