-- Read-only live observations; fixture outcomes are supplied separately and never labeled input.
return function(options)
 options=options or {}
 local p=game.Players.LocalPlayer or game.Players:GetPlayers()[1]
 local ch=p and p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid')
 local tracks={}
 for _,t in ipairs(h and h:FindFirstChildOfClass('Animator') and h.Animator:GetPlayingAnimationTracks() or {}) do
  table.insert(tracks,{name=t.Name,asset=t.Animation and t.Animation.AnimationId,length=t.Length,speed=t.Speed,priority=tostring(t.Priority)})
 end
 local button=p and p.PlayerGui:FindFirstChild('SprintToggle',true)
 local report={fixtures=options.fixtures or {},observations={character=ch and ch.Name,rig=h and tostring(h.RigType),speed=h and h.WalkSpeed,stamina=ch and ch:GetAttribute('CC_Stamina'),attributes=ch and ch:GetAttributes(),togglePresent=button~=nil,toggleText=button and button.Text,tracks=tracks},cleanup='read-only; no character/state mutations'}
 if options.requireToggle then assert(button,'Missing sprint toggle and feedback') end
 return report
end
