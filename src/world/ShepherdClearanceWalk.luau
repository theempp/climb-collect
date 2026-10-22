-- Additive maintenance decks around physically verified Shepherd terrain obstructions.
-- Original terrain, route samples, traversal definitions and checkpoints are untouched.
local M={}
M.points={{935,1173.4,-824.7},{947,1176,-837},{927,1183,-858},{907,1188,-877},{894,1193,-883},{880,1195,-881}}
M.secondPoints={{837.6,1209.7,-923.7},{851,1211,-935},{836,1220,-960},{820,1224,-980},{796,1232,-1004},{770,1240,-1026},{762,1236,-1050},{748,1244,-1068},{728,1253,-1064},{720,1257,-1080},{705.4,1259,-1061.2}}
M.shelfAccess={{746,1233,-1034},{762,1236,-1050}}
M.thirdPoints={{-398.1,1897.6,-504.5},{-408,1902,-506},{-435,1907,-520},{-475,1912,-480},{-485,1915,-445},{-470,1926,-410},{-458.2,1928.8,-400.3}}
M.lowerAccess={{-418.2,1870,-472},{-430,1880,-478},{-450,1885,-490},{-475,1900,-460},{-500,1912,-480},{-475,1912,-480}}
M.fourthPoints={{-412.7,2100.2,-348.5},{-425,2104,-365},{-405,2115,-390},{-380,2125,-400},{-355,2133,-397},{-347.3,2131,-389.4}}
M.fifthPoints={{-343.85,2146.4,-381.76},{-369.13,2147.8,-402.48},{-388.99,2153.4,-386.76},{-406.81,2159,-368.69},{-424.38,2164.6,-350.17},{-440.8,2170.1,-330.6},{-456.64,2175.7,-311.43},{-473.09,2181.3,-293.57},{-491.59,2187,-276.49},{-510.03,2192.7,-259.09},{-528.22,2198.3,-240.46},{-544.97,2203.9,-220.19},{-546.65,2205,-194.42},{-545.66,2207.27,-169.18},{-542.23,2218.65,-144.12},{-538.95,2230.14,-118.79},{-535.02,2241.51,-93.83},{-530.23,2248.06,-69.03},{-524.58,2259.06,-45.25},{-517.87,2270.47,-20.78},{-510.2,2281.9,3.41},{-501.66,2292.88,26.27},{-491.54,2304.15,49.19},{-480.15,2315.6,71.94},{-468.67,2327.04,94.63},{-460.69,2338.35,118.47},{-450.72,2349.95,142.23},{-434.46,2361.84,163.04},{-411.35,2374.41,178.75},{-390.28,2385.88,193.09},{-374.36,2395.77,208.26},{-357.97,2405.64,222.81},{-337.85,2408.76,227.26},{-312.38,2412,224.69},{-288.88,2415,210},{-267.22,2420,210},{-250,2420,210},{-239,2420,220},{-236.49,2420.2,230.22}}
local function build(name,points)
 local world=workspace.World
 if world:FindFirstChild(name) then return end
 local root=Instance.new('Model');root.Name=name;root.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local function part(name,size,cf,color,solid)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.Wood
  p.Anchored=true;p.CanCollide=solid;p.CanTouch=false;p.CanQuery=solid;p.Parent=root;return p
 end
 local wood=Color3.fromRGB(153,112,68);local ink=Color3.fromRGB(40,57,62);local gold=Color3.fromRGB(235,184,65)
 for i=2,#points do
  local a,b=Vector3.new(table.unpack(points[i-1])),Vector3.new(table.unpack(points[i]));local cf=CFrame.lookAt((a+b)/2,b);local length=(a-b).Magnitude
  part('WalkingDeck',Vector3.new(6,.5,length+2),cf,wood,true)
  for _,side in {-1,1} do
   part('EdgeBeam',Vector3.new(.3,.45,length+2),cf*CFrame.new(side*2.85,.18,0),ink,true)
   part('SafetyRail',Vector3.new(.15,.15,length+2),cf*CFrame.new(side*2.85,2.8,0),gold,false)
   for _,z in {-length/2,0,length/2} do
    part('RailPost',Vector3.new(.3,3,.3),cf*CFrame.new(side*2.85,1.5,z),ink,false)
   end
  end
  for z=-length/2,length/2,3 do part('PlankSeam',Vector3.new(5.4,.03,.08),cf*CFrame.new(0,.27,z),ink,false) end
 end
 root.Parent=world;return #root:GetDescendants()
end
function M.build() return {build('ShepherdClearanceWalk',M.points),build('ShepherdUpperClearanceWalk',M.secondPoints),build('ShepherdShelfAccess',M.shelfAccess),build('ShepherdRidgeClearanceWalk',M.thirdPoints),build('ShepherdLowerAccess',M.lowerAccess),build('ShepherdCliffClearanceWalk',M.fourthPoints),build('ShepherdHighClearanceWalk',M.fifthPoints)} end
return M
