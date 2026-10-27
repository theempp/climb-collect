-- Review aids (forced sample nest, UI probe) run only in Studio, and only while ReplicatedStorage
-- has no StudioAids=false attribute. A phone candidate saves StudioAids=false so Studio Play behaves like live.
local F={}
function F.studioAids()
 return game:GetService('RunService'):IsStudio() and game:GetService('ReplicatedStorage'):GetAttribute('StudioAids')~=false
end
return F
