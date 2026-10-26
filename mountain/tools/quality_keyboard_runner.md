# Reproduce observed all-section jumps

Use only the isolated local review. Enter Play as a fresh character at home; execute `quality_walk.client.luau` in Client. The probe performs natural MoveTo traversal and publishes `MountainQA_QualityWalk` JSON.

At each new nonempty `workspace:GetAttribute('MountainQA_RequestJump')`, send the Studio MCP `user_keyboard_input` tool to that same Studio/Client:

```json
{"actions":[{"action":"keyDown","key_code":"Space"},{"action":"wait","wait_time_ms":200},{"action":"keyUp","key_code":"Space"}]}
```

Send once per distinct label, within the waypoint timeout. Twelve labels cover west ascent and east descent in six sections. This uses the real default keyboard controller; no forced state, velocity, position, health, inventory or tuning changes. Wait for `MountainQA_QualityWalk.done`, export its full JSON to `observed-jump-traversal.json`, and retain an input log. The delivery check requires exactly12 successful Jumping/Freefall/Landed-or-Running transitions plus upward velocity, all165 route steps passing, and normal physical exit.

The prior `natural-traversal.json` remains valid traversal evidence but recorded only12 jump requests. `jump-observation-attempt01.json` and `attempt02.json` retain missed jumps from one-frame/PreSimulation input attempts. The existing project instructions warn that ControlModule can clear Humanoid.Jump. Actual keyboard input removes that QA ambiguity.
