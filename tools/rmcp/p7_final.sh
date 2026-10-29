#!/bin/bash
# p7_final.sh <studio_id> : P7 final evidence into evidence/hud_glassbloom_2026-10-27/final/ (checks at iPhone 16 Pro, captures per device).
S="$(dirname "$0")";ID=$1;F="$S/../../evidence/hud_glassbloom_2026-10-27/final";R="python $S/rmcp.py"
timeout 300 python "$S/sync_hud.py" "$ID" --changed f6da03b | tail -1
echo "local s=game:GetService('StudioDeviceSimulatorService') s:SetDeviceAsync('iphone_16_pro') s:SetScalingModeAsync(Enum.DeviceSimulatorScalingMode.ScaleToPhysicalSize) return 'ok'" > "$S/qa/_dev.luau"; bash "$S/x.sh" "$S/qa/_dev.luau"
bash "$S/p6_checks.sh" "$ID" "$F/checks" > "$F/checks.log" 2>&1
bash "$S/cap_on_device.sh" "$ID" iphone_16_pro ScaleToPhysicalSize bash -c "
 DM=Client bash $S/x.sh $S/qa/p7_centre.client.luau > $F/checks/centre.json
 DM=Client bash $S/x.sh $S/qa/p7_insets.client.luau > $F/checks/insets.json
 DM=Client bash $S/x.sh $S/qa/p7_tabsync.client.luau > $F/checks/tabsync.json
 DM=Client bash $S/x.sh $S/qa/p7_open_ab.client.luau > $F/checks/open_ab.json
 python $S/capture_states.py $ID $F/states i16p
 python $S/capture_extras.py $ID $F/extras
 python $S/capture_motion.py $ID $F/motion/frames
 REDUCED=1 python $S/capture_motion.py $ID $F/motion/reduced run banner moment carry"
bash "$S/cap_on_device.sh" "$ID" iphone_16_pro_max ScaleToPhysicalSize python "$S/capture_states.py" "$ID" "$F/states" i16pm
bash "$S/cap_on_device.sh" "$ID" GB_844x411 ActualResolution bash -c "python $S/capture_states.py $ID $F/states 844; python $S/capture_hubs.py $ID $F/hubs; python $S/capture_shop.py $ID $F/shop"
echo "game.ReplicatedStorage:SetAttribute('StudioAids',false) local s=game:GetService('StudioDeviceSimulatorService') s:SetDeviceAsync('iphone_16_pro') s:SetScalingModeAsync(Enum.DeviceSimulatorScalingMode.ScaleToPhysicalSize) return {game.PlaceId, game.ReplicatedStorage:GetAttribute('StudioAids'), s:GetDeviceAsync()}" > "$S/qa/_off.luau"; bash "$S/x.sh" "$S/qa/_off.luau"
echo FINAL_DONE
