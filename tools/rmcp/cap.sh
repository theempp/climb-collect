#!/bin/bash
# cap.sh <name> <eyeX,Y,Z> <targetX,Y,Z> : set the edit camera and screen_capture into evidence/homebase_rebuild_2026-10-27/<name>.png
S="$(dirname "$0")";E="$S/../../evidence/${EVID:-homebase_rebuild_2026-10-27}";mkdir -p "$E"
if [ "$DM" = "Client" ]; then
echo "local cf=CFrame.lookAt(Vector3.new($2),Vector3.new($3));local cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Scriptable;local RS=game:GetService('RunService');pcall(function() RS:UnbindFromRenderStep('QACam') end);RS:BindToRenderStep('QACam',Enum.RenderPriority.Last.Value,function() cam.CFrame=cf end);for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end;task.wait(.6);return 'ok'" > "$S/cam.luau"
else
echo "workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new($2),Vector3.new($3));return 'ok'" > "$S/cam.luau"
fi
RMCP_WARM=10 "$S/x.sh" "$S/cam.luau" >/dev/null
RMCP_WARM=10 python "$S/rmcp.py" call screen_capture "{\"studio_id\":\"${STUDIO:-e3617e97-c480-47e7-930c-74a64d1ad837}\",\"capture_id\":\"$1\"}" "$E/$1.png" | tail -1
