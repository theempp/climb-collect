-- Shared rescue interactions use the authoritative Traversal state. No income or repeatable reward.
local Coop={}
local ctx
function Coop.init(c)
 ctx=c
 -- Retire legacy client state and free-form rope placement remotes.
 ctx.handlers.climbState=function() end
 ctx.handlers.ropePlace=function() end
end
function Coop.onCharacter(plr,ch)
 local root=ch:WaitForChild("HumanoidRootPart",10)
 if not root then return end
 local p=require(script.Parent.Prompts).make(root,{Name="RescuePrompt",ActionText="Help regain grip",ObjectText=plr.DisplayName,HoldDuration=0.6,MaxActivationDistance=14,Enabled=false})
 p.KeyboardKeyCode=Enum.KeyCode.F; p.GamepadKeyCode=Enum.KeyCode.ButtonY
 ch:GetAttributeChangedSignal("CC_TraversalState"):Connect(function() p.Enabled=ch:GetAttribute("CC_TraversalState")=="hanging" end)
 p.Triggered:Connect(function(helper)
  if helper~=plr and require(script.Parent.Prompts).validate(p,helper) and ctx.Traversal then ctx.Traversal.rescue(helper,plr) end
 end)
end
return Coop
