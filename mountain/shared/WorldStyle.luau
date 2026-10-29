-- World style tokens (home-base S2). The one candy-glass world table; pure data, RGB triples {r,g,b}, no Color3.
-- Every value cites design/homebase-world-style-intel.md (atlas pass 3): A = role map row, B = recipe. REC = atlas
-- recommendation (allowed, not owner-fixed). Only WorldKit turns these into Color3 (s1-plan §3a).
local S={}
S.color={
 lawn={47,174,138}, -- A Lawn go2 #2FAE8A (DEC#13)
 lawnLight={123,255,208}, -- A Lawn light patches go #7BFFD0
 paver={203,188,242}, -- A Paver lavText #CBBCF2 (S0.5)
 inlay={244,107,196}, -- A Paver centre inlay pk #F46BC4
 pathGlow={123,216,255}, -- A Path glow strip flare #7BD8FF Neon (S0.9)
 speedLane={123,216,255}, -- A Speed-lane strip flare #7BD8FF Neon (S0.10)
 kerb={90,34,153}, -- A Kerb / basin lip #5A2299
 door={43,20,87}, -- A Door deep #2B1457 (S0.11)
 doorArch={255,210,255}, -- A Door frame arch glass.rim #FFD2FF (S0.11)
 porthole={255,221,155}, -- A Windows lanternGlass warm #FFDD9B Neon (window use REC)
 portholeRim={255,143,224}, -- A Porthole rim ctaHi #FF8FE0 -- REC
 gateBody={165,91,234}, -- A Gate arch body vi #A55BEA -- REC
 gateTrim={90,34,153}, -- A Gate arch base / trim edge lip #5A2299 -- REC
 gateGlow={255,143,224}, -- A Gate arch inner glow trim ctaHi #FF8FE0 Neon -- REC
 gemIdle={255,143,224}, -- A Gate crest gem idle ctaHi #FF8FE0 -- REC
 gemBurst={123,255,208}, -- A Gate crest gem burst go #7BFFD0 (DEC#12)
 sparklePink={247,138,208}, -- A Gate sparkles sparkle.pink #F78AD0
 sparkleFlare={123,216,255}, -- A Gate sparkles flare #7BD8FF
 bannerPole={165,91,234}, -- A Banner pole vi #A55BEA -- REC
 lampPole={165,91,234}, -- A Globe lamp pole vi #A55BEA (DEC#14)
 lampCollar={90,34,153}, -- A Globe lamp collar / foot lip #5A2299 -- REC
 lampRing={255,143,224}, -- B3 ctaHi ring #FF8FE0
 globeWarm={255,221,155}, -- A Globe warm #FFDD9B Neon (DEC#14; S2 answer: default)
 globePink={247,138,208}, -- A Globe pink tint #F78AD0 (S2 answer: every 3rd lamp)
 signNight={20,6,60}, -- A Pill sign body night2 #14063C
 signText={255,255,255}, -- A Pill sign text #FFFFFF
 signStroke={244,107,196}, -- A Pill sign stroke pk #F46BC4
 plaque={130,70,220}, -- A Habitat plaque glass.from #8246DC Glass T.25 (S0.7)
 plaquePost={90,34,153}, -- B8 notice board "lip post" #5A2299, reused for the B4 plaque post -- REC
 coin={255,216,74}, -- A Coin prop body gold #FFD84A (DEC#17)
 coinRim={255,224,122}, -- A Coin prop rim gold.hi #FFE07A Neon
 coinHalo={255,216,74}, -- A Coin prop glow halo #FFD84A T.5
 coinStand={203,188,242}, -- B6 stand lavText #CBBCF2
 coinStandLip={90,34,153}, -- B6 stand lip ring #5A2299
 coinStroke={255,216,74}, -- A Coin price pill gold stroke #FFD84A -- REC
 water={123,216,255}, -- A Water flare #7BD8FF Glass T.25 (DEC#19)
 fountainGem={123,216,255}, -- A Fountain gem flare #7BD8FF Neon
 flame={244,107,196}, -- A Streak shrine flame gem pk #F46BC4 -- REC
 ember={255,216,74}, -- A Streak shrine ember tip gold #FFD84A -- REC
 boardPanel={130,70,220}, -- A Board panel glass.from #8246DC Glass T.25
 boardFrame={90,34,153}, -- A Board frame lip #5A2299 -- REC
 plazaDisc={203,188,242}, -- A Plaza disc lavText #CBBCF2
 plazaRing={244,107,196}, -- A Plaza inlay ring pk #F46BC4 Neon
 beacon={123,255,208}, -- A Secured / safe beacon go #7BFFD0 Neon
 -- B7 flora (GB tokens; hexes as in A rows)
 vi={165,91,234}, -- B7 #2 vi #A55BEA (= A Gate body hex)
 pk={244,107,196}, -- B7 #1/#2/#7/#9 pk #F46BC4 (= A inlay)
 ctaHi={255,143,224}, -- B7 #1/#2 ctaHi #FF8FE0 (= A porthole rim)
 go={123,255,208}, -- B7 #3/#5/#9 go #7BFFD0 (= A lawn light)
 go2={47,174,138}, -- B7 #1/#3/#5/#7 go2 #2FAE8A (= A lawn)
 lavText={203,188,242}, -- B7 #1 trunk, #6 boulder lavText #CBBCF2 (= A paver)
 pinkText={255,208,240}, -- B7 #6/#8 pinkText #FFD0F0 (= A pen tint 1; GB:46)
 text={255,255,255}, -- B7 #8 stem, #10 petals text #FFFFFF (= A sign text)
 gold={255,216,74}, -- B7 #7 petals, #10 centre gold #FFD84A (= A coin)
 flare={123,216,255}, -- B7 #7/#9/#12 flare #7BD8FF (= A water)
 lip={90,34,153}, -- B7 #5/#7/#12 lip #5A2299 (= A kerb)
}
-- B7 #4 gumdrop "rcg tops" = the three tier ridge stops (A Roof ridge row, S0.12).
S.gumdrop={{159,182,255},{255,210,122},{201,155,255}} -- #9FB6FF #FFD27A #C99BFF
-- Pen fence post + rail + floor tint, one per habitat, S0.6 order (A Pen fence row).
S.pens={
 {255,208,240}, -- #FFD0F0
 {203,188,242}, -- #CBBCF2
 {159,182,255}, -- #9FB6FF
 {255,210,122}, -- #FFD27A
 {201,155,255}, -- #C99BFF
 {123,255,208}, -- #7BFFD0
}
S.material={body='SmoothPlastic',trim='Neon',accent='Glass'} -- DEC#4, intel conventions
S.allowedMaterials={SmoothPlastic=true,Neon=true,Glass=true} -- DEC#4
S.glassT=.25 -- DEC#4, A Plaque/Water rows
S.signT=.15 -- B4 night2 T.15
S.haloT=.5 -- A Coin prop glow halo T.5
-- Rank bands (S0.1; A Banner row): L<5 blue, 5-14 gold, 15-29 violet, 30+ prism.
S.rank={
 {min=1,key='blue',color={108,140,240}}, -- #6C8CF0
 {min=5,key='gold',color={247,162,27}}, -- #F7A21B
 {min=15,key='violet',color={176,108,240}}, -- #B06CF0
 {min=30,key='prism',color={255,184,234}}, -- #FFB8EA
}
function S.rankBand(level)
 local b=S.rank[1];for _,r in ipairs(S.rank) do if level>=r.min then b=r end end;return b
end
-- Tier house roles (s1-plan §2a; A House body / Roof / Ridge / Chimney gem rows; S0.12). gem = tier rc (A Chimney row, REC).
S.tier={
 hut={body={108,140,240},roof={91,120,232},ridge={159,182,255},gem={108,140,240}}, -- #6C8CF0 #5B78E8 #9FB6FF
 villa={body={247,162,27},roof={240,149,42},ridge={255,210,122},gem={247,162,27}}, -- #F7A21B #F0952A #FFD27A
 manor={body={176,108,240},roof={138,75,230},ridge={201,155,255},gem={176,108,240}}, -- #B06CF0 #8A4BE6 #C99BFF
 palace={body={255,184,234},roofBands={{255,143,192},{255,210,122},{123,216,255},{181,140,255}}, -- #FFB8EA; A T4 roof #FF8FC0 #FFD27A #7BD8FF #B58CFF
  ridge={255,210,122},gem={255,184,234}}, -- s1-plan §2a ridge #FFD27A
}
-- Part caps (S0.4 plot, s1-plan §1a/§1b; kit = intel B3-B7 part counts).
S.caps={
 plot=937,commons=1500,gate=200,billboards=12,houseLights=1,
 house={hut=40,villa=65,manor=105,palace=157},
 kit={
  globeLamp=6, -- B3 5 + soft collar Ball (chunk pass, +20%; 5 when unioned)
  pillSign=1, -- B4 billboard only; 1 invisible anchor part when no adornee is given
  plaque=3, -- B4 habitat variant
  fence=14, -- B5 floor 1 + posts 6 + caps 4 + rails 3 (plaque counted separately)
  coinMarker=5, -- B6
  lollipopTree=4,swirlTree=5,cloudTree=4,gumdrop=4,puffHedge=5,boulder=3, -- B7 #1-#6 (chunk pass: gumdrop 2 domes x2, boulder dome 2 + Ball)
  bloomBed=8,mushroom=3,gemCluster=3,daisy=8,gemBasin=4, -- B7 #7-#10, #12 (#11 = globeLamp)
 },
 pillInstances=7, -- B4 billboard instances
}
S.sign={maxDistance=45,radius=11,stroke=1.5,textSize=12} -- B4
S.fonts={display='LuckiestGuy',body='FredokaOne'} -- A Fonts (GB:227, 229)
return S
