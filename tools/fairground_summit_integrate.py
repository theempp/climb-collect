from pathlib import Path
root=Path(__file__).resolve().parents[1]
def edit(path,old,new):
 p=root/path;s=p.read_text(encoding='utf8');assert old in s,(path,old);p.write_text(s.replace(old,new),encoding='utf8')
edit('src/core/client/ResultsUI.luau',"local go=T.button", "local go;go=T.button")
edit('src/runtime/CC_CoreService.server.luau','"PublicProfile", "DailyPractice"','"PublicProfile", "DailyPractice", "ExpeditionRun", "SummitFinish"')
edit('src/core/server/Camps.luau','function Camps.onLoaded(plr, s)\n',"function Camps.onLoaded(plr, s)\n local summit=s.data.expedition.summit;if summit and (summit.active or summit.pendingResult) then return end\n")
edit('src/core/server/DropPacks.luau','if s and not s.data.expedition.homeReturn and #s.data.cargo>0',"if s and not (s.data.expedition.summit and (s.data.expedition.summit.active or s.data.expedition.summit.pendingResult)) and not s.data.expedition.homeReturn and #s.data.cargo>0")
edit('src/core/server/Home.luau','local ret = s.data.expedition.homeReturn','local ret = not (s.data.expedition.summit and s.data.expedition.summit.pendingResult) and s.data.expedition.homeReturn')
edit('src/core/server/Camps.luau','function Camps.isSafe(pos)\n',"function Camps.isSafe(pos)\n local stage=workspace.World:FindFirstChild('SummitStage');local zone=stage and stage:FindFirstChild('Arrival');if zone then local p=zone.CFrame:PointToObjectSpace(pos);if math.abs(p.X)<=zone.Size.X/2 and math.abs(p.Y)<=zone.Size.Y/2 and math.abs(p.Z)<=zone.Size.Z/2 then return true end end\n")
edit('src/core/server/DailyPractice.luau',"function D.cancel(p) local a=active[p];if not a or not a.finishing then active[p]=nil end end", "function D.cancel(p) local a=active[p];if a and a.finishing then return false end;active[p]=nil;return true end")
edit('src/core/server/Training.luau','if ctx.DailyPractice then ctx.DailyPractice.cancel(plr) end','if ctx.DailyPractice and not ctx.DailyPractice.cancel(plr) then return end')
p=root/'src/runtime/CC_CoreClient.client.luau';s=p.read_text(encoding='utf8')
s='local resultsUI\n'+s
s=s.replace('CommerceUI.tick()',"CommerceUI.tick()\n if resultsUI then resultsUI.update(state) end")
s=s.replace('if CommerceUI.isOpen() then ui.hud.Visible=false;',"if CommerceUI.isOpen() or plr:GetAttribute('CC_SummitPresentation') then ui.hud.Visible=false;")
s=s.replace('closeOthers=function() CommerceUI.close();','closeOthers=function() if dailyUI then dailyUI.close() end;CommerceUI.close();')
s=s.replace('return ui.panel.Visible or profileUI.isOpen() or CommerceUI.isOpen()', 'return ui.panel.Visible or profileUI.isOpen() or (dailyUI and dailyUI.isOpen()) or CommerceUI.isOpen()')
s=s.replace('fit(); refreshHud(); request("state")',"resultsUI=require(CoreRS.Client.ResultsUI).mount({parent=gui,request=request,settings=function() return state.settings or {} end,modal=function(open) plr:SetAttribute('CC_MenuOpen',open);cancelHolds() end,closeOthers=function() profileUI.close();dailyUI.close();CommerceUI.close();closePanel() end})\nfit(); refreshHud(); request(\"state\")")
p.write_text(s,encoding='utf8')
entries=[]
for folder,names,place in [('shared',['SummitConfig','ExpeditionRunRules','SummitArt'],'ReplicatedStorage/CC_Core'),('server',['ExpeditionRun','SummitFinish','SummitTests'],'ServerScriptService/CC_CoreServer'),('client',['SummitCinematic','ResultsUI'],'ReplicatedStorage/CC_Core/Client')]:
 for name in names: entries.append(f'\t{{ "src/core/{folder}/{name}.luau", "{place}", "{name}", "ModuleScript" }},')
entries.append('\t{ "src/world/SummitStage.luau", "ServerStorage/CC_Generators", "SummitStage", "ModuleScript" },')
edit('tools/sync_core.luau','local MAN = {','local MAN = {\n'+'\n'.join(entries))
