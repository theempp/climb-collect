-- Home-base S2: WorldStyle tokens equal the atlas pass 3 hexes (intel A/B), rank band edges, tier keys, caps.
local S=require('../shared/WorldStyle')
local T=require('../shared/HomeTiers')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local function hex(c) return string.format('#%02X%02X%02X',c[1],c[2],c[3]) end
-- Expected = intel A/B row hexes, transcribed independently of the module.
local want={lawn='#2FAE8A',lawnLight='#7BFFD0',paver='#CBBCF2',inlay='#F46BC4',pathGlow='#7BD8FF',speedLane='#7BD8FF',
 kerb='#5A2299',door='#2B1457',doorArch='#FFD2FF',porthole='#FFDD9B',portholeRim='#FF8FE0',gateBody='#A55BEA',gateTrim='#5A2299',
 gateGlow='#FF8FE0',gemIdle='#FF8FE0',gemBurst='#7BFFD0',sparklePink='#F78AD0',sparkleFlare='#7BD8FF',bannerPole='#A55BEA',
 lampPole='#A55BEA',lampCollar='#5A2299',lampRing='#FF8FE0',globeWarm='#FFDD9B',globePink='#F78AD0',signNight='#14063C',
 signText='#FFFFFF',signStroke='#F46BC4',plaque='#8246DC',plaquePost='#5A2299',coin='#FFD84A',coinRim='#FFE07A',coinHalo='#FFD84A',
 coinStand='#CBBCF2',coinStandLip='#5A2299',coinStroke='#FFD84A',water='#7BD8FF',fountainGem='#7BD8FF',flame='#F46BC4',ember='#FFD84A',
 boardPanel='#8246DC',boardFrame='#5A2299',plazaDisc='#CBBCF2',plazaRing='#F46BC4',beacon='#7BFFD0',
 vi='#A55BEA',pk='#F46BC4',ctaHi='#FF8FE0',go='#7BFFD0',go2='#2FAE8A',lavText='#CBBCF2',pinkText='#FFD0F0',text='#FFFFFF',
 gold='#FFD84A',flare='#7BD8FF',lip='#5A2299'}
for k,h in pairs(want) do check(S.color[k] and hex(S.color[k])==h,'color_'..k) end
for k,c in pairs(S.color) do check(want[k]~=nil and #c==3,'color_traced_'..k) end
local pens={'#FFD0F0','#CBBCF2','#9FB6FF','#FFD27A','#C99BFF','#7BFFD0'}
check(#S.pens==6,'six pens');for i,h in ipairs(pens) do check(hex(S.pens[i])==h,'pen_'..i) end
local gum={'#9FB6FF','#FFD27A','#C99BFF'};for i,h in ipairs(gum) do check(hex(S.gumdrop[i])==h,'gumdrop_'..i) end
check(S.glassT==.25 and S.material.body=='SmoothPlastic' and S.material.trim=='Neon' and S.material.accent=='Glass','materials, glass T.25')
local nm=0;for m in pairs(S.allowedMaterials) do nm+=1;check(m=='SmoothPlastic' or m=='Neon' or m=='Glass','allowed_'..m) end;check(nm==3,'three materials')
-- Rank bands (S0.1).
local band={{1,'blue','#6C8CF0'},{4,'blue'},{5,'gold','#F7A21B'},{14,'gold'},{15,'violet','#B06CF0'},{29,'violet'},{30,'prism','#FFB8EA'},{99,'prism'}}
for _,b in ipairs(band) do local r=S.rankBand(b[1]);check(r.key==b[2] and (b[3]==nil or hex(r.color)==b[3]),'band_'..b[1]) end
check(#S.rank==4 and S.rank[2].min==5 and S.rank[3].min==15 and S.rank[4].min==30,'band minimums 5/15/30')
-- Tiers (s1-plan §2a): HomeTiers style keys resolve, four distinct, colours per A.
local tw={hut={'#6C8CF0','#5B78E8','#9FB6FF'},villa={'#F7A21B','#F0952A','#FFD27A'},manor={'#B06CF0','#8A4BE6','#C99BFF'}}
local seen={}
for i,t in ipairs(T.tiers) do
 local s=S.tier[t.style];check(s~=nil and not seen[t.style],'tier_style_'..i);seen[t.style]=true
 check(s.body and s.ridge and s.gem and (s.roof or s.roofBands),'tier_roles_'..i)
end
check(T.tiers[1].style=='hut' and T.tiers[2].style=='villa' and T.tiers[3].style=='manor' and T.tiers[4].style=='palace','tier order')
for k,w in pairs(tw) do local s=S.tier[k];check(hex(s.body)==w[1] and hex(s.roof)==w[2] and hex(s.ridge)==w[3] and hex(s.gem)==w[1],'tier_hex_'..k) end
local P=S.tier.palace;local pb={'#FF8FC0','#FFD27A','#7BD8FF','#B58CFF'}
check(hex(P.body)=='#FFB8EA' and hex(P.ridge)=='#FFD27A' and #P.roofBands==4 and P.roof==nil,'palace')
for i,h in ipairs(pb) do check(hex(P.roofBands[i])==h,'palace_band_'..i) end
-- Caps (S0.4, s1-plan §1a).
local C=S.caps
check(C.plot==937 and C.commons==1500 and C.gate==200 and C.billboards==12 and C.houseLights==1,'top caps')
check(C.house.hut==40 and C.house.villa==65 and C.house.manor==105 and C.house.palace==157,'house caps')
check(C.house.hut<C.house.villa and C.house.villa<C.house.manor and C.house.manor<C.house.palace,'houses grow')
for k,v in pairs(C.kit) do check(v>=1 and v<=14 and v%1==0,'kit_cap_'..k) end
for _,k in ipairs({'lollipopTree','swirlTree','cloudTree','gumdrop','puffHedge','boulder','bloomBed','mushroom','gemCluster','daisy','gemBasin','globeLamp'}) do check(C.kit[k] and C.kit[k]<=8,'b7_le_8_'..k) end
check(6*(C.kit.fence+C.kit.plaque)<=110,'habitats x6 within 110')
check(4*C.kit.globeLamp<=25,'lamps x4 within 25')
check(C.billboards*C.pillInstances<=84,'billboards within 84')
-- §1a cap column with the Palace cap from S.caps: shell 50, ground 30, house, banner 6, habitats 110, creatures 150,
-- spine 45, hatchery 45, beast 65, lamps 25, flora 30, stands 28, decor 84, billboards 84.
local sum=50+30+C.house.palace+6+110+150+45+45+65+25+30+28+84+C.billboards*C.pillInstances
check(sum<=C.plot,'plot caps sum '..sum..' <= 937')
check(S.fonts.display=='LuckiestGuy' and S.fonts.body=='FredokaOne' and S.sign.maxDistance==45,'fonts, sign')
print('world_style: '..n..' checks passed')
