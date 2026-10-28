#!/bin/bash
# p3_checks.sh <studio_id> <outdir> : StudioAids on (edit) -> sync -> play -> overflow audit (6 sizes) + perf/counts + console -> stop -> StudioAids off.
S="$(dirname "$0")";ID=$1;OUT=$2;mkdir -p "$OUT";R="python $S/rmcp.py"
luau() { python - "$1" "$ID" "$2" > "$S/args.json" <<'PY'
import json,sys;print(json.dumps({"studio_id":sys.argv[2],"datamodel_type":sys.argv[3],"code":open(sys.argv[1],encoding='utf-8').read()}))
PY
RMCP_TIMEOUT=600 timeout 650 $R call execute_luau "$S/args.json"; }
timeout 120 $R call start_stop_play "{\"is_start\":false,\"studio_id\":\"$ID\"}" >/dev/null
echo "assert(game.PlaceId==0) game.ReplicatedStorage:SetAttribute('StudioAids',true) return 'aids on'" > "$S/qa/_on.luau"; luau "$S/qa/_on.luau" Edit
timeout 300 python "$S/sync_hud.py" "$ID" | tail -1
timeout 120 $R call start_stop_play "{\"is_start\":true,\"studio_id\":\"$ID\"}"; sleep 25
{ echo "SIZES={{749,330},{844,390},{932,430},{1024,700},{1180,780},{1600,860}}"; cat "$S/../../mountain/tools/hud_overflow_audit.client.luau"; } > "$S/qa/_audit.luau"
luau "$S/qa/_audit.luau" Client > "$OUT/overflow_audit.json"; head -c 600 "$OUT/overflow_audit.json"; echo
luau "$S/qa/perf_counts.client.luau" Client > "$OUT/perf_counts.json"; cat "$OUT/perf_counts.json"; echo
timeout 120 $R call get_console_output "{\"studio_id\":\"$ID\"}" > "$OUT/console.txt"; grep -ci "error\|warn" "$OUT/console.txt"
timeout 120 $R call start_stop_play "{\"is_start\":false,\"studio_id\":\"$ID\"}" >/dev/null
echo "game.ReplicatedStorage:SetAttribute('StudioAids',false) return {game.PlaceId, game.ReplicatedStorage:GetAttribute('StudioAids')}" > "$S/qa/_off.luau"; luau "$S/qa/_off.luau" Edit
