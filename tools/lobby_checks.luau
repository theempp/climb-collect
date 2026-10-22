local M={}
function M.anchors(world)
 world=world or workspace.World
 local module=game.ServerScriptService.CC_CoreServer:FindFirstChild('LobbyAnchors')
 assert(module,'LobbyAnchors missing: service contract not implemented')
 local A=require(module)
 local a=A.resolve(world)
 assert(a.Bank and a.HomeDoor and a.Exchange_Bundle,'required services')
 assert(A.resolve(world).Bank==a.Bank,'stable live identity')
 if world:FindFirstChild('Fairground') then
  for _,id in A.required do
   local n=0 for _,p in world.Fairground.Anchors:GetChildren() do if p:GetAttribute('ServiceId')==id then n+=1 end end
   assert(n==1,'duplicate/missing '..id)
  end
  local copy=world:Clone();copy.Fairground.Anchors.Bank:Destroy()
  local ok,err=pcall(A.resolve,copy);copy:Destroy()
  assert(not ok and tostring(err):find('Bank'),'named Bank error')
  assert(A.contains(a.Spawn.Position,world),'spawn safe')
  assert(not A.contains(Vector3.new(0,3000,0),world),'mountain unsafe')
 end
 return {ok=true,case='anchors'}
end
function M.services()
 local A=require(game.ServerScriptService.CC_CoreServer.LobbyAnchors).resolve(workspace.World)
 assert(A.Bank:FindFirstChild('BankPrompt'),'bank prompt')
 assert(A.HomeDoor:FindFirstChild('HomePortalPrompt'),'home prompt')
 assert(A.PracticeStart:FindFirstChild('PracticePrompt'),'practice prompt')
 assert(#workspace.World.CommerceDisplays:GetChildren()==5,'five offers')
 return {ok=true,case='services'}
end
return M
