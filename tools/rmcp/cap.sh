#!/bin/bash
# cap.sh <name> <eyeX,Y,Z> <targetX,Y,Z> : set the edit camera and screen_capture into evidence/homebase_rebuild_2026-10-27/<name>.png
S="$(dirname "$0")";E="$S/../../evidence/homebase_rebuild_2026-10-27";mkdir -p "$E"
echo "workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new($2),Vector3.new($3));return 'ok'" > "$S/cam.luau"
RMCP_WARM=10 "$S/x.sh" "$S/cam.luau" >/dev/null
RMCP_WARM=10 python "$S/rmcp.py" call screen_capture "{\"studio_id\":\"${STUDIO:-e3617e97-c480-47e7-930c-74a64d1ad837}\",\"capture_id\":\"$1\"}" "$E/$1.png" | tail -1
