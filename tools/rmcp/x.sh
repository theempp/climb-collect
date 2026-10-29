#!/bin/bash
# x.sh <luau-file> : run Luau in the HomeBase copy (edit DM unless DM env set)
S="$(dirname "$0")"
python - "$1" "${DM:-Edit}" > "$S/args.json" <<'PY'
import json,sys
print(json.dumps({"studio_id":"63f33fc1-a0a8-4547-badb-4c7cb9d6c65c","datamodel_type":sys.argv[2],"code":open(sys.argv[1],encoding='utf-8').read()}))
PY
timeout 300 python "$S/rmcp.py" call execute_luau "$S/args.json"
