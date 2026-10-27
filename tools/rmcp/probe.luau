local probe=game.Players.LocalPlayer.PlayerGui.MountainHUD:FindFirstChild('UIProbe')
if not probe then return 'no probe' end
local r=probe:Invoke(ACTION,VALUE)
return game:GetService('HttpService'):JSONEncode({hub=r.hub,tab=r.tab,view=r.view,ready=r.ready})
