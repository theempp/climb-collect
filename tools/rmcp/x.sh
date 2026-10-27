#!/bin/bash
# x.sh <luau-file> : run Luau in the HomeBase work copy ONLY (studio id pinned; edit DM unless DM env set)
S="$(dirname "$0")"
python - "$1" "${DM:-Edit}" "${STUDIO:-e3617e97-c480-47e7-930c-74a64d1ad837}" > "$S/args.json" <<'PY'
import json,sys
print(json.dumps({"studio_id":sys.argv[3],"datamodel_type":sys.argv[2],"code":open(sys.argv[1],encoding='utf-8').read()}))
PY
timeout 600 python "$S/rmcp.py" call execute_luau "$S/args.json"
