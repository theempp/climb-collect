from pathlib import Path
root=Path(__file__).resolve().parents[1]
def edit(path,old,new):
 p=root/path;s=p.read_text(encoding='utf-8');assert old in s,(path,old[:70]);p.write_text(s.replace(old,new,1),encoding='utf-8')
edit('src/core/server/Profile.luau','local P = {}','local PortfolioRules=require(game.ReplicatedStorage.CC_Core.PortfolioRules)\nlocal P = {}')
edit('src/core/server/Profile.luau','\t\tcommerce = CommerceRules.default(),','\t\tcommerce = CommerceRules.default(),\n\t\tportfolio={titleId="",showcase={},frameId=""},')
edit('src/core/server/Profile.luau','\tout.quarantine = q','\tout.portfolio=PortfolioRules.cleanSelections(d.portfolio,out.bank)\n\tout.quarantine = q')
edit('src/runtime/CC_CoreService.server.luau','"CommerceDisplays", "Commerce"','"CommerceDisplays", "Commerce", "PublicProfile"')
edit('src/runtime/CC_CoreClient.client.luau','local render, openPanel, closePanel, refreshHud','local render, openPanel, closePanel, refreshHud\nlocal profileUI,nameTags,newHUD')
edit('src/runtime/CC_CoreClient.client.luau','openPanel = function(mode)\n','openPanel = function(mode)\n\tif profileUI then profileUI.close() end\n')
edit('src/runtime/CC_CoreClient.client.luau','\tCommerceUI.fx(p)','\tif nameTags then nameTags.fx(p) end\n\tif profileUI and p.kind=="profileOwn" then profileUI.own() end\n\tCommerceUI.fx(p)')
edit('src/runtime/CC_CoreClient.client.luau','\tCommerceUI.update(st)','\tCommerceUI.update(st)\n\tif profileUI then profileUI.updateOwner(st);nameTags.update(st) end')
edit('src/runtime/CC_CoreClient.client.luau','otherOpen=function() return ui.panel.Visible end','otherOpen=function() return ui.panel.Visible or (profileUI and profileUI.isOpen()) or plr:GetAttribute("CC_SummitPresentation")==true end')
edit('src/runtime/CC_CoreClient.client.luau','closeOtherPanels=function() if ui.panel.Visible then closePanel() end;cancelHolds() end','closeOtherPanels=function() if profileUI then profileUI.close() end;if ui.panel.Visible then closePanel() end;cancelHolds() end')
edit('src/runtime/CC_CoreClient.client.luau','fit(); refreshHud(); request("state")','''profileUI=require(CoreRS.Client.ProfileUI).mount({parent=gui,request=request,modal=function(open) plr:SetAttribute("CC_MenuOpen",open);cancelHolds() end,closeOthers=function() CommerceUI.close();if ui.panel.Visible then closePanel() end end,collection=function() ui.tab="Collection";openPanel("expedition") end})
nameTags=require(CoreRS.Client.NameTags).mount({parent=gui,request=request,profile=profileUI})
newHUD=require(CoreRS.Client.ExpeditionHUD).mount({parent=gui,ui=ui,profile=profileUI,blocked=function() return ui.panel.Visible or profileUI.isOpen() or CommerceUI.isOpen() or plr:GetAttribute("CC_SummitPresentation")==true end})
if Run:IsStudio() then local r=Instance.new("BindableFunction");r.Name="PortfolioReview";r.OnInvoke=function(action) if action=="open" then profileUI.own() elseif action=="close" then profileUI.close() end end;r.Parent=gui end
fit(); refreshHud(); request("state")''')
rows=[('src/core/shared/'+n+'.luau','ReplicatedStorage/CC_Core',n) for n in ['PortfolioRules','AchievementRules','ExpeditionUITheme']]+[('src/core/server/'+n+'.luau','ServerScriptService/CC_CoreServer',n) for n in ['PublicProfile','PortfolioTests']]+[('src/core/client/'+n+'.luau','ReplicatedStorage/CC_Core/Client',n) for n in ['ProfileUI','NameTags','ExpeditionHUD']]
edit('tools/sync_core.luau','local MAN = {','local MAN = {\n'+''.join('\t{ "'+p+'", "'+f+'", "'+n+'", "ModuleScript" },\n' for p,f,n in rows))
