#!/bin/bash
# cycle.sh <studio_id> : stop play, sync HUD sources (preview icons), start play, wait for the probe.
S="$(dirname "$0")";ID=$1
timeout 120 python "$S/rmcp.py" call start_stop_play "{\"is_start\":false,\"studio_id\":\"$ID\"}"
timeout 200 python "$S/sync_hud.py" "$ID" --preview-icons
timeout 120 python "$S/rmcp.py" call start_stop_play "{\"is_start\":true,\"studio_id\":\"$ID\"}"
