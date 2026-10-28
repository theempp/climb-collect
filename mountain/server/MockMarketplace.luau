-- Mock receipt processor for tests and Studio only. It mimics Roblox delivery: the same receipt is
-- re-delivered (possibly to another server) until a server answers PurchaseGranted. Nothing is charged.
local M={}
function M.new(opts)
 opts=opts or {}
 local mock={delivered={},serial=0}
 -- Creates a receipt for a configured (non-zero) product id; real ids are 0, so tests pass their own catalog.
 function mock.receipt(userId,productId)
  mock.serial+=1
  return {PlayerId=userId,ProductId=productId,PurchaseId='mock-'..(opts.prefix or 'p')..'-'..mock.serial,CurrencySpent=0,CurrencyType='Robux',PlaceIdWherePurchased=0}
 end
 -- Delivers to each processor in turn (server change) until granted or attempts run out.
 function mock.deliver(receipt,processors,attempts)
  for i=1,attempts or 5 do
   local processor=processors[((i-1)%#processors)+1]
   local decision=processor.process(table.clone(receipt))
   table.insert(mock.delivered,{id=receipt.PurchaseId,attempt=i,decision=decision})
   if decision=='PurchaseGranted' then return true,i end
  end
  return false,attempts or 5
 end
 return mock
end
return M
