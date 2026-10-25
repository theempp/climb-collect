local T={
 navy=Color3.fromRGB(11,23,48),panel=Color3.fromRGB(20,44,82),card=Color3.fromRGB(30,61,103),
 sky=Color3.fromRGB(33,184,255),blue=Color3.fromRGB(52,120,246),gold=Color3.fromRGB(255,194,71),
 green=Color3.fromRGB(66,217,121),purple=Color3.fromRGB(163,107,255),coral=Color3.fromRGB(255,102,95),
 ink=Color3.fromRGB(248,251,255),muted=Color3.fromRGB(189,211,237),line=Color3.fromRGB(65,99,146),
 display=Enum.Font.FredokaOne,body=Enum.Font.GothamMedium,bold=Enum.Font.GothamBold,
 prefs={},
 rarity={Common=Color3.fromRGB(190,211,227),Uncommon=Color3.fromRGB(89,222,153),Rare=Color3.fromRGB(70,186,255),Epic=Color3.fromRGB(181,133,255),Mythic=Color3.fromRGB(255,136,185),Legendary=Color3.fromRGB(255,204,91)},
}
function T.configure(p) T.prefs=p or {} end
function T.size(n) return n+(if T.prefs.largeText then 2 else 0) end
return T
