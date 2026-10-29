-- Durable cargo ownership and compare/swap offers. Only server-authored items enter this module.
local HS = game:GetService("HttpService")
local Cargo = {}
local ctx
local offers = {}
-- Copy for transport: a Heartstone's stored hatch species stays server-only until deliberate hatching.
-- Banked stones have no kind field, so their view passes isStone explicitly.
function Cargo.clientItem(item,isStone)
	local view=table.clone(item)
	if isStone or item.kind=="heartstone" then view.species=nil end
	return view
end
local function used(items)
	local n=0 for _,it in ipairs(items) do n+=it.slots or 1 end return n
end
local function locate(items,uid)
	for i,it in ipairs(items) do if it.uid==uid then return i,it end end
end
local function result(plr,r)
	if not r.ok then ctx.toast(plr,r.pending and "Saving this find. Please wait while we reconnect." or "Couldn't save the change. Your items remain safe; try again.","warn") end
	ctx.invChanged(plr)
end

function Cargo.acquire(plr,item,opts,replaceUid)
	local s=ctx.sessions[plr]
	if not s or ctx.Inv.locked(plr.UserId) then return {ok=false,reason="busy"} end
	if opts.valid and not opts.valid() then return {ok=false,reason="unavailable"} end
	if not replaceUid and ctx.Inv.free(plr.UserId)<(item.slots or 1) then
		local token=HS:GenerateGUID(false)
		offers[plr]={token=token,item=item,opts=opts,expiresAt=ctx.Clock.now()+90}
		ctx.toast(plr,"Backpack full. Compare this find, swap one, or leave it here.","info")
		ctx.push(plr)
		return {ok=false,reason="full",offered=true}
	end
	if opts.reserve and not opts.reserve() then return {ok=false,reason="claimed"} end
	local tx="acquire:"..item.uid
	local r=ctx.transaction(plr,tx,function(d)
		if locate(d.cargo,item.uid) then return {ok=false,reason="already_owned"} end
		local idx,old
		if replaceUid then idx,old=locate(d.cargo,replaceUid) if not old then return {ok=false,reason="missing"} end end
		if used(d.cargo)-(old and old.slots or 0)+(item.slots or 1)>d.slots then return {ok=false,reason="full"} end
		if opts.write then local ok,why=opts.write(d) if ok==false then return {ok=false,reason=why or "unavailable"} end end
		if old then
			table.remove(d.cargo,idx)
			local at=opts.pos or Vector3.zero
			table.insert(d.drops,{id="released:"..old.uid,items={old},pos={x=at.X,y=at.Y,z=at.Z},expiresAt=0,reason="released"})
		end
		table.insert(d.cargo,item)
		return {ok=true,itemUid=item.uid,replaced=old and old.uid or nil}
	end,function(committed)
		offers[plr]=nil
		if committed.dup then
			if opts.unreserve then opts.unreserve() end
		elseif opts.commit then opts.commit(item) end
		if ctx.DropPacks then ctx.DropPacks.refresh(plr) end
		ctx.invChanged(plr)
		if committed.replaced and not committed.dup then ctx.toast(plr,"Swapped. Your previous find is safely waiting here in the world.","good") end
	end)
	if not r.ok and not r.pending and opts.unreserve then opts.unreserve() end
	result(plr,r)
	return r
end

function Cargo.init(c)
	ctx=c
	ctx.handlers.swapConfirm=function(plr,p)
		local o=offers[plr]
		if not o or p.token~=o.token or type(p.uid)~="string" or #p.uid>128 then return end
		if ctx.Clock.now()>o.expiresAt or (o.opts.valid and not o.opts.valid()) then offers[plr]=nil ctx.toast(plr,"That find is no longer within reach.","info") ctx.push(plr) return end
		Cargo.acquire(plr,o.item,o.opts,p.uid)
	end
	ctx.handlers.swapLeave=function(plr,p)
		local o=offers[plr]
		if o and (p.token==nil or p.token==o.token) then offers[plr]=nil ctx.push(plr) end
	end
end
function Cargo.state(plr,st)
	local o=offers[plr]
	if o and ctx.Clock.now()<=o.expiresAt then st.swapOffer={token=o.token,item=Cargo.clientItem(o.item),sourceName=o.opts.label or "New find",expiresAt=o.expiresAt} end
end
function Cargo.onLeave(plr) offers[plr]=nil end
Cargo.used=used
Cargo.locate=locate
return Cargo
