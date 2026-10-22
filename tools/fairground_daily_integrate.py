from pathlib import Path
root=Path(__file__).resolve().parents[1]
def edit(path,old,new):
 p=root/path;s=p.read_text(encoding='utf-8');assert old in s,(path,old[:70]);p.write_text(s.replace(old,new,1),encoding='utf-8')
edit('src/core/server/Profile.luau','\t\tportfolio={','\t\tdailyPractice=require(game.ReplicatedStorage.CC_Core.DailyPracticeRules).default(),\n\t\tportfolio={')
edit('src/core/server/Profile.luau','\tout.portfolio=','\tout.dailyPractice=require(game.ReplicatedStorage.CC_Core.DailyPracticeRules).clean(d.dailyPractice)\n\tout.portfolio=')
edit('src/core/server/Training.luau','function Training.canUseSection(plr,i)','function Training.cancel(plr) if active[plr] and active[plr].finishing then return false end;active[plr]=nil;return true end\nfunction Training.canUseSection(plr,i)')
edit('src/core/server/Training.luau','  active[plr]={id=i,next=1,session=s}','  if ctx.DailyPractice then ctx.DailyPractice.cancel(plr) end\n  active[plr]={id=i,next=1,session=s}')
edit('src/core/server/Traversal.luau','return ctx.Training.canUseSection(plr, section.practice)','return ctx.Training.canUseSection(plr, section.practice) or (ctx.DailyPractice and ctx.DailyPractice.canUseSection(plr, section.practice))')
edit('src/runtime/CC_CoreService.server.luau','"Commerce", "PublicProfile"','"Commerce", "PublicProfile", "DailyPractice"')
edit('src/runtime/CC_CoreClient.client.luau','local profileUI,nameTags,newHUD','local profileUI,nameTags,newHUD,dailyUI')
edit('src/runtime/CC_CoreClient.client.luau','\tif nameTags then nameTags.fx(p) end','\tif dailyUI and p.kind=="practiceDailyOpen" then dailyUI.open() end\n\tif nameTags then nameTags.fx(p) end')
edit('src/runtime/CC_CoreClient.client.luau','\tif profileUI then profileUI.updateOwner(st);nameTags.update(st) end','\tif profileUI then profileUI.updateOwner(st);nameTags.update(st) end\n\tif dailyUI then dailyUI.update(st) end')
edit('src/runtime/CC_CoreClient.client.luau','\tif profileUI then profileUI.close() end','\tif dailyUI then dailyUI.close() end\n\tif profileUI then profileUI.close() end')
edit('src/runtime/CC_CoreClient.client.luau','or (profileUI and profileUI.isOpen()) or plr:GetAttribute','or (profileUI and profileUI.isOpen()) or (dailyUI and dailyUI.isOpen()) or plr:GetAttribute')
edit('src/runtime/CC_CoreClient.client.luau','closeOtherPanels=function() if profileUI','closeOtherPanels=function() if dailyUI then dailyUI.close() end;if profileUI')
edit('src/runtime/CC_CoreClient.client.luau','fit(); refreshHud(); request("state")','''dailyUI=require(CoreRS.Client.DailyPracticeUI).mount({parent=gui,request=request,modal=function(open) plr:SetAttribute("CC_MenuOpen",open);cancelHolds() end,closeOthers=function() profileUI.close();CommerceUI.close();if ui.panel.Visible then closePanel() end end})
fit(); refreshHud(); request("state")''')
rows=[('src/core/shared/DailyPracticeRules.luau','ReplicatedStorage/CC_Core','DailyPracticeRules'),('src/core/server/DailyPractice.luau','ServerScriptService/CC_CoreServer','DailyPractice'),('src/core/server/DailyPracticeTests.luau','ServerScriptService/CC_CoreServer','DailyPracticeTests'),('src/core/client/DailyPracticeUI.luau','ReplicatedStorage/CC_Core/Client','DailyPracticeUI'),('src/world/StarterSetPreview.luau','ServerStorage/CC_Generators','StarterSetPreview')]
edit('tools/sync_core.luau','local MAN = {','local MAN = {\n'+''.join('\t{ "'+p+'", "'+f+'", "'+n+'", "ModuleScript" },\n' for p,f,n in rows))
