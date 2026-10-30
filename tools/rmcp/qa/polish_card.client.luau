-- polish_card.client.luau : HUD polish E. Card rects (compact/expanded) vs dock, plus the coordinate spaces tap-outside depends on.
local pg=game.Players.LocalPlayer.PlayerGui;local gui=pg.MountainHUD;local pr=gui.UIProbe;local GS=game:GetService('GuiService')
local function rect(o) return o and {math.floor(o.AbsolutePosition.X),math.floor(o.AbsolutePosition.Y),math.floor(o.AbsoluteSize.X),math.floor(o.AbsoluteSize.Y),o.Visible} end
local function find(n) return gui:FindFirstChild(n,true) end
local out={ignoreInset=gui.IgnoreGuiInset,screenInsets=tostring(gui.ScreenInsets),guiInset={GS:GetGuiInset().X,GS:GetGuiInset().Y},safeRoot=rect(gui.SafeRoot)}
pr:Invoke('close');pr:Invoke('hudState','sanctuary');task.wait(1)
out.compact={card=rect(find('PlayerCard')),launcher=rect(find('Launcher')),dock=rect(find('Dock'))}
pr:Invoke('card','expanded');task.wait(1)
out.expanded={card=rect(find('PlayerCard')),launcher=rect(find('Launcher')),dock=rect(find('Dock'))}
pr:Invoke('open','Shop');task.wait(.6);pr:Invoke('close');task.wait(.8)
out.afterHub={card=rect(find('PlayerCard')),launcher=rect(find('Launcher'))}
pr:Invoke('hudState','live')
return game:GetService('HttpService'):JSONEncode(out)
