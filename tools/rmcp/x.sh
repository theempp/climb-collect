#!/bin/bash
# x.sh <luau-file> : run Luau in the HUDv2 copy (edit DM unless DM env set)
S="$(dirname "$0")"
python - "$1" "${DM:-Edit}" > "$S/args.json" <<'PY'
import json,sys
print(json.dumps({"studio_id":"f7fbe98e-71e9-48f3-9dc3-84e477edad3b","datamodel_type":sys.argv[2],"code":open(sys.argv[1],encoding='utf-8').read()}))
PY
timeout 300 python "$S/rmcp.py" call execute_luau "$S/args.json"
