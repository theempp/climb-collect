-- HUD v2 tokens: every value traces to design/hud-v2-intel.md §1–§3 (Climb & Collect references only).
local rgb=Color3.fromRGB
local T={
 -- Legacy keys kept so callers keep working; values now come from the v2 palette.
 navy=rgb(27,43,90),panel=rgb(46,111,226),card=rgb(27,43,90),
 sky=rgb(59,182,240),blue=rgb(61,142,242),gold=rgb(255,210,60),
 green=rgb(63,197,58),purple=rgb(122,62,226),coral=rgb(236,59,78),
 ink=rgb(255,255,255),muted=rgb(213,224,243),line=rgb(20,32,63),
 -- v2 tokens (intel §1).
 outline=rgb(20,32,63),panelBlue=rgb(46,111,226),panelPurple=rgb(122,62,226),row=rgb(213,224,243),textDark=rgb(28,30,60),
 cta={base=rgb(255,196,20),shade=rgb(242,154,0),lip=rgb(140,74,28),ink=rgb(74,35,14)},
 ok={base=rgb(63,197,58),lip=rgb(35,137,42)},no={base=rgb(236,59,78),lip=rgb(166,30,51)},
 close=rgb(228,58,54),alt=rgb(61,142,242),tert=rgb(198,108,242),off=rgb(174,182,192),
 alertDot=rgb(238,58,72),readyDot=rgb(72,200,60),plus=rgb(69,196,58),
 bar={fill=rgb(59,182,240),ready=rgb(92,203,58),max=rgb(246,192,42)},
 coin=rgb(255,199,44),gem=rgb(178,61,232),heart=rgb(232,50,60),
 -- Type (owner decisions 2026-10-27): Bangers labels, FredokaOne numbers/small text, LuckiestGuy reward titles.
 label=Enum.Font.Bangers,display=Enum.Font.FredokaOne,title=Enum.Font.LuckiestGuy,body=Enum.Font.FredokaOne,bold=Enum.Font.FredokaOne,
 prefs={},
 -- PROVISIONAL tier mapping (intel ladder; owner still picks tier count/names): Common/Uncommon blue, Rare golden, Epic royal, Mythic/Legendary prismatic.
 rarity={Common=rgb(58,139,238),Uncommon=rgb(58,139,238),Rare=rgb(247,162,27),Epic=rgb(138,75,230),Mythic=rgb(255,95,160),Legendary=rgb(255,201,60)},
 prismatic={Mythic=true,Legendary=true},
}
function T.configure(p) T.prefs=p or {} end
function T.size(n) return n+(if T.prefs.largeText then 2 else 0) end
return T
