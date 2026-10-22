-- Disposable Play-only evidence writer. Enable HTTP through privileged Studio MCP first.
-- No movement, profile, eligibility or reward writes. Never save this Script in the place.
local H=game.HttpService
while true do
 local p=game.Players:GetPlayers()[1]
 local root=p and p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 local segments={}
 for _,s in game.ServerScriptService:GetChildren() do
  if s.Name:find('Ascent') or s.Name:find('Recovery') then
   local row={name=s.Name,attributes=s:GetAttributes()}
   local trace=s:FindFirstChild('Trace');if trace then row.traceRaw=trace.Value end
   table.insert(segments,row)
  end
 end
 local report={kind='natural-spawn physical ascent; no position or eligibility injection',
  profile=game.ServerStorage.CC_SummitReview:Invoke('profile'),segments=segments,
  player=p and p:GetAttributes(),position=root and {root.Position.X,root.Position.Y,root.Position.Z},
  capturedAt=os.time()}
 local ok,err=pcall(function()
  H:PostAsync('http://127.0.0.1:8772/polish-verified-ascent.json',H:JSONEncode(report),Enum.HttpContentType.ApplicationJson)
 end)
 script:SetAttribute('LastExport',ok and os.time() or nil)
 script:SetAttribute('ExportError',not ok and tostring(err) or nil)
 task.wait(30)
end
