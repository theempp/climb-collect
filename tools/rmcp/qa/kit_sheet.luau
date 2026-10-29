-- S2 kit sheet (Edit): builds every WorldKit item on a grid in Workspace.KitSheet (lilac floor), returns JSON per item:
-- parts vs S.caps.kit, materials ⊂ {SmoothPlastic, Neon, Glass}, Glass T = .25, 0 lights, 0 textures/decals/MeshParts (unions allowed, counted in r.unions).
-- Needs ServerStorage.MountainWorld.WorldKit + ReplicatedStorage.MountainShared.WorldStyle synced. Clones bypass the
-- Edit require cache (CLAUDE.md gotcha). Leaves the sheet in place for the contact-sheet capture; delete it after.
local S=require(game.ReplicatedStorage.MountainShared.WorldStyle:Clone())
local src=game.ServerStorage.MountainWorld.WorldKit:Clone();src.Parent=game.ServerStorage.MountainWorld
local ok,Kit=pcall(require,src);src:Destroy();if not ok then return 'require failed: '..tostring(Kit) end
local old=workspace:FindFirstChild('KitSheet');if old then old:Destroy() end
local sheet=Instance.new('Folder');sheet.Name='KitSheet';sheet.Parent=workspace
local origin=CFrame.new(0,600,0) -- PROPOSED: clear air above the place origin; move if it intersects the world
local cols,pitch=6,16;local rows=math.ceil(#Kit.items/cols)
local floor=Instance.new('Part');floor.Name='Floor';floor.Anchored=true;floor.CanTouch=false;floor.Material=Enum.Material.SmoothPlastic
floor.Size=Vector3.new(cols*pitch,1,rows*pitch);floor.CFrame=origin*CFrame.new((cols-1)*pitch/2,-.5,(rows-1)*pitch/2)
floor.Color=Kit.rgb('paver');floor.Parent=sheet -- lilac = intel A paver lavText
local out={items={},allOk=true}
for i,key in Kit.items do
 local cf=origin*CFrame.new(((i-1)%cols)*pitch,0,math.floor((i-1)/cols)*pitch)
 local opts={index=3,pen=((i-1)%6)+1,text=key,price=150,tint=2}
 local good,m=pcall(Kit[key],sheet,cf,opts)
 local r={item=key,cap=S.caps.kit[key]}
 if not good then r.ok=false;r.error=tostring(m) else
  local parts,lights,tex,mats,glassOk,anch,touch,collide,billboards,inst=0,0,0,{},true,true,true,0,0,0
  for _,d in m:GetDescendants() do
   inst+=1
   if d:IsA('BasePart') then
    parts+=1;mats[d.Material.Name]=(mats[d.Material.Name] or 0)+1
    if d:IsA('MeshPart') then tex+=1 elseif d:IsA('UnionOperation') then r.unions=(r.unions or 0)+1 end -- unions allowed (S2 answer)
    if d.Material==Enum.Material.Glass and math.abs(d.Transparency-S.glassT)>1e-4 then glassOk=false end
    if not d.Anchored then anch=false end;if d.CanTouch then touch=false end;if d.CanCollide then collide+=1 end
   elseif d:IsA('Light') then lights+=1
   elseif d:IsA('Texture') or d:IsA('Decal') or d:IsA('SurfaceAppearance') or d:IsA('SpecialMesh') then tex+=1
   elseif d:IsA('BillboardGui') then billboards+=1 end
  end
  local matOk=true;for k in mats do if not S.allowedMaterials[k] then matOk=false end end
  r.parts=parts;r.attrParts=m:GetAttribute('Parts');r.materials=mats;r.lights=lights;r.textures=tex;r.glassT=glassOk
  r.anchored=anch;r.canTouchOff=touch;r.colliders=collide;r.billboards=billboards;r.instances=inst
  r.ok=parts<=(r.cap or 0) and r.attrParts==parts and matOk and lights==0 and tex==0 and glassOk and anch and touch and collide==0
 end
 if not r.ok then out.allOk=false end
 table.insert(out.items,r)
end
return game:GetService('HttpService'):JSONEncode(out)
