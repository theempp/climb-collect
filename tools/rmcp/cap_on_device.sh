#!/bin/bash
# cap_on_device.sh <studio_id> <device> <ActualResolution|ScaleToPhysicalSize> <cmd...> : Edit: StudioAids on + emulator device, Play, run cmd, Stop.
S="$(dirname "$0")";ID=$1;DEV=$2;MODE=$3;shift 3;R="python $S/rmcp.py"
luau() { python - "$1" "$ID" Edit > "$S/args.json" <<'PY'
import json,sys;print(json.dumps({"studio_id":sys.argv[2],"datamodel_type":sys.argv[3],"code":open(sys.argv[1],encoding='utf-8').read()}))
PY
timeout 300 $R call execute_luau "$S/args.json"; }
timeout 120 $R call start_stop_play "{\"is_start\":false,\"studio_id\":\"$ID\"}" >/dev/null
echo "assert(game.PlaceId==0) game.ReplicatedStorage:SetAttribute('StudioAids',true) local s=game:GetService('StudioDeviceSimulatorService') s:SetDeviceAsync('$DEV') s:SetScalingModeAsync(Enum.DeviceSimulatorScalingMode.$MODE) return 'on $DEV'" > "$S/qa/_dev.luau"; luau "$S/qa/_dev.luau"
timeout 120 $R call start_stop_play "{\"is_start\":true,\"studio_id\":\"$ID\"}"; sleep 25
"$@"
timeout 120 $R call start_stop_play "{\"is_start\":false,\"studio_id\":\"$ID\"}" >/dev/null
