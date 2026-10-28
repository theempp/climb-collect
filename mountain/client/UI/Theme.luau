-- Glassbloom tokens: every value traces to climb&collect/design/hud-glassbloom-intel.md §1 (images/slices §5).
local rgb=Color3.fromRGB
local white=rgb(255,255,255)
local T={
 -- 1a colours.
 pk=rgb(244,107,196),vi=rgb(165,91,234),ctaHi=rgb(255,143,224),flare=rgb(123,216,255),sparklePink=rgb(247,138,208),
 text=white,outline=rgb(21,10,51),deep=rgb(43,20,87),night=rgb(10,2,40),night2=rgb(20,6,60),shade=rgb(20,5,60),
 lip=rgb(90,34,153),lipDeep=rgb(58,10,106),glassFrom=rgb(130,70,220),glassTo=rgb(50,20,110),glassRim=rgb(255,210,255),
 pinkText=rgb(255,208,240),lavText=rgb(203,188,242),segText=rgb(205,189,245),togOff=rgb(139,127,181),
 danger=rgb(255,77,125),dangerRim=rgb(255,122,160),vignette=rgb(255,60,120),
 closeFrom=rgb(255,122,154),closeTo=rgb(217,43,85),closeLip=rgb(122,16,48),
 runTop=white,runMid=rgb(255,214,234),runBot=rgb(255,92,158),runStroke=rgb(90,16,80),runDrop=rgb(58,10,54),runGlow=rgb(255,61,133),
 runShock=rgb(255,122,184),runAwakeBg=rgb(60,6,30),
 go=rgb(123,255,208),go2=rgb(47,174,138),goGlow=rgb(93,255,192),goLip=rgb(20,102,77),goInk=rgb(6,40,30),goText=rgb(234,255,246),
 gold=rgb(255,216,74),goldHi=rgb(255,224,122),goldLo=rgb(245,154,0),goldBuyLo=rgb(240,160,32),goldLip=rgb(140,74,28),
 goldTail=rgb(184,106,0),goldInk=rgb(74,35,14),goldText=rgb(255,233,168),momentText=rgb(255,228,92),
 raysTint=rgb(255,214,120),raysHero=rgb(255,232,120),ribbonFrom=rgb(255,92,158),ribbonTo=rgb(255,216,74),ribbonInk=rgb(58,10,54),
 holo={rgb(255,77,141),rgb(255,181,46),rgb(255,243,92),rgb(82,224,122),rgb(63,200,255),rgb(154,92,240),rgb(255,77,141)},
 heroFrom=rgb(90,30,170),heroTo=rgb(40,12,100),cpkFrom=rgb(90,40,160),cpkTo=rgb(40,12,100),
 ticketFrom=rgb(255,140,60),ticketTo=rgb(110,30,140),mtintFrom=rgb(60,20,120),mtintTo=rgb(20,5,60),
 batFill=rgb(40,16,90),batLip=rgb(27,13,69),cardFallback=rgb(58,42,102),cardGlow=rgb(212,155,255),
 cardXpFullFrom=rgb(123,255,176),cardXpFullTo=rgb(53,194,122),revealBgIn=rgb(106,42,176),revealBgOut=rgb(29,10,69),
 -- 1b rarity colours (rcg gradient 180° → rot 90; prism 135° → rot 45).
 rarityColor={
  blue={rc=rgb(108,140,240),from=rgb(159,182,255),to=rgb(91,120,232),rot=90},
  gold={rc=rgb(247,162,27),from=rgb(255,210,122),to=rgb(240,149,42),rot=90},
  violet={rc=rgb(176,108,240),from=rgb(201,155,255),to=rgb(138,75,230),rot=90},
  prism={rc=rgb(255,184,234),stops={rgb(255,143,192),rgb(255,210,122),rgb(123,216,255),rgb(181,140,255)},rot=45},
 },
 -- 1c transparencies (T = 1 − CSS alpha).
 glassFillT={.45,.38},glassRimT=.45,glassHiT=.65,glassLipT=.4,glassGlowT=.65,ghostT={fill=.3,rim=.6,lip=.3},
 wellT={tab=.5,chip=.5,row=.55,bst=.45,track=.45,hlist=.45,rung=.4,seg=.4,trail=.35,xp=.3,sl=.3,tog=.3,tm=.3,forever=.25},
 pillT={rail=.15,distance=.08,momentSub=.2,beacon=.22,awake=.15},dbtnT={fill=.9,rim=.7},ringTrackT={xp=.84,distance=.8,boost=.82},
 dockChaseT=.75,railIdleT=.7,textDimT={.05,.1,.15,.18,.25},vignetteT=.45,tintT={.5,.25},raysT={panel=.91,hero=.76,reveal=.72},revealDimT=.88,
 -- 1d corner radii (UICorner offset px; circle = UDim scale .5; shield/roundTop are TL,TR,BR,BL → 9-slice U3/U4).
 r={circle=UDim.new(.5,0),panel=22,banner=24,pill30=30,hero=20,glass=18,btn=16,card=14,[12]=12,[11]=11,[10]=10,[9]=9,[8]=8,[7]=7,[6]=6,[5]=5,[4]=4,[3]=3,[2]=2,
  shield={20,20,50,50},roundTop={60,60,18,18}},
 -- 1e stroke widths (UIStroke Thickness).
 s={hair=1,thin=1.5,glass=2,bold=3,ring3=3,ring4=4,reveal=5,ring6=6,text={moment=3,run=4.5},focus=2},
 -- 1f gradients: stops = {position, colour, transparency?}. CSS θ → rot θ−90.
 gradGlass={rot=90,stops={{0,rgb(130,70,220),.45},{1,rgb(50,20,110),.38}}},
 gradCta={rot=90,stops={{0,rgb(255,143,224)},{1,rgb(165,91,234)}}},
 gradAction={rot=0,stops={{0,rgb(244,107,196)},{1,rgb(165,91,234)}}},
 gradGloss={rot=90,stops={{0,white,.5},{.36,white,.5},{.38,white,1},{1,white,1}}},
 gradRingConic={stops={{0,rgb(244,107,196)},{1/3,rgb(165,91,234)},{2/3,rgb(123,216,255)},{1,rgb(244,107,196)}}}, -- conic; no rotation
 gradMint={rot=90,stops={{0,rgb(123,255,208)},{1,rgb(47,174,138)}}},
 gradCoinBuy={rot=90,stops={{0,rgb(255,224,122)},{1,rgb(240,160,32)}}},
 gradGoldTitle={rot=90,stops={{0,rgb(255,224,122)},{1,rgb(245,154,0)}}},
 gradClose={rot=90,stops={{0,rgb(255,122,154)},{1,rgb(217,43,85)}}},
 gradRun={rot=90,stops={{0,white},{.38,rgb(255,214,234)},{1,rgb(255,92,158)}}},
 gradHolo={rot=20,stops={{0,rgb(255,77,141)},{1/6,rgb(255,181,46)},{2/6,rgb(255,243,92)},{3/6,rgb(82,224,122)},{4/6,rgb(63,200,255)},{5/6,rgb(154,92,240)},{1,rgb(255,77,141)}}},
 gradRibbon={rot=0,stops={{0,rgb(255,92,158)},{1,rgb(255,216,74)}}},
 gradRailLine={rot=90,stops={{0,white,.2},{1,white,.8}}},
 gradBeaconPillar={rot=90,stops={{0,rgb(123,255,208),.05},{1,rgb(123,255,208),1}}},
 gradHero={rot=90,stops={{0,rgb(90,30,170),.03},{1,rgb(40,12,100),.02}},radial={color=rgb(255,216,74),t=.65,x=.16,y=.6,fade=.45}},
 gradCpk={rot=90,stops={{0,rgb(90,40,160),.15},{1,rgb(40,12,100),.08}},radial={color=rgb(255,216,74),t=.68,x=.5,y=.3,fade=.6}},
 gradTicket={rot=10,stops={{0,rgb(255,140,60),.5},{1,rgb(110,30,140),.25}}},
 gradPass={rot=90,stops={{0,white,.86},{1,rgb(20,6,60),.12}}},
 gradSkin={rot=90,stops={{0,white,.9},{1,rgb(10,2,40),.22}}},
 gradEggCard={rot=90,stops={{0,white,.92},{1,rgb(10,2,40),.35}}},
 gradCpopOverlay={rot=90,stops={{0,white,.78},{1,rgb(20,6,60),.45}}}, -- drawn over rcg
 gradMtint={rot=90,stops={{0,rgb(60,20,120),.5},{1,rgb(20,5,60),.25}}},
 gradCardXpFull={rot=0,stops={{0,rgb(123,255,176)},{1,rgb(53,194,122)}}},
 gradShard={rot=45,stops={{0,white},{1,rgb(255,216,74)}}},
 gradRevealPill={rot=0,stops={{0,rgb(201,155,255)},{1,rgb(138,75,230)}}},
 gradStreak={rot=0,stops={{0,nil,1},{1,nil,0}}}, -- colour = the card's rarity rc, supplied by the caller
 gradShine={rot=0,stops={{0,white,1},{.5,white,.25},{1,white,1}}},
 -- 1g glows (hollow U1: tint, T, blur b, spread s). color=nil → the caller's rarity rc.
 glowGlass={color=rgb(244,107,196),t=.65,b=18,s=0},glowCta={color=rgb(244,107,196),t=.3,b=18,s=0},
 glowOrb={color=rgb(244,107,196),t=.2,b=20,s=0},glowBat={color=rgb(244,107,196),t=.4,b=12,s=0},
 glowSprint={color=rgb(93,255,192),t=0,b=14,s=0},glowBuyRobux={color=rgb(93,255,192),t=.5,b=12,s=0},
 glowBuyCoin={color=rgb(255,216,74),t=.5,b=12,s=0},glowPbtn={color=rgb(244,107,196),t=.5,b=10,s=0},
 glowPortrait={color=rgb(123,255,208),t=.45,b=14,s=0},glowBeacon={color=rgb(123,255,208),t=.2,b=18,s=0},
 glowX={color=rgb(255,77,125),t=0,b=12,s=0},glowTabOn={color=rgb(244,107,196),t=.4,b=12,s=0},
 glowShop={color=rgb(255,216,74),t=.65,b=26,s=0},glowGoldTitle={color=rgb(255,216,74),t=.3,b=18,s=0},
 glowRarity={color=nil,t=0,b={cpop=26,cpic=14,pass=14,porb=16,egg=20,skin=12,streak=10},s=0},
 glowReady={color=rgb(255,216,74),t=.45,b=14,s=0},glowBest={color=rgb(255,216,74),t=.3,b=16,s=0},
 glowBoostOn={color=rgb(93,255,192),t=.55,b=14,s=0},glowCardRare={color=rgb(212,155,255),t=0,b=14,s=2},
 glowHero={color=white,t=.55,b=18,s=0},glowMoment={color=rgb(244,107,196),t=0,b=18,s=0},
 glowRun={color=rgb(255,61,133),t=0,b=26,s=0},glowShock={color=rgb(255,61,133),t=0,b=20,s=0},
 glowSparkle={color=rgb(247,138,208),t=0,b=8,s=0},glowSparkle2={color=rgb(123,216,255),t=0,b=8,s=0}, -- sparkles 1,3 / sparkle 2
 glowRevealSel={color=rgb(255,216,74),t=0,b=18,s=0},glowHalo={color=rgb(255,216,74),t=0,b=24,s=0},
 glowRevealCard={color=rgb(255,216,74),t=.15,b=34,s=8},glowRevealTitle={color=rgb(244,107,196),t=0,b=16,s=0},
 glowHeroTitle={color=rgb(255,216,74),t=.45,b=14,s=0},
 -- 1h fonts. Legacy label/title now LuckiestGuy (D12); display/body/bold stay FredokaOne.
 fontDisplay=Enum.Font.LuckiestGuy,fontBody=Enum.Font.FredokaOne,
 label=Enum.Font.LuckiestGuy,title=Enum.Font.LuckiestGuy,display=Enum.Font.FredokaOne,body=Enum.Font.FredokaOne,bold=Enum.Font.FredokaOne,
 -- 1i text sizes (px at HUD scale M).
 t={run=104,moment=64,revealWord=62,carryName=30,revealTitle=30,revealTitleLanded=26,bannerTitle=28,heroTitle=24,heroTitleMini=18,
  revealCta=24,menuTitle=23,revealName=22,btn=20,heroBuy=20,coinPack=19,ticketTitle=18,btnSide=16,buy=16,eggName=16,
  buy3=15,pbtn=15,passName=15,claim=13,coin=15,pcardMeta=14,rowTitle=14,revealChance=14,
  toast=13,edge=13,awake=13,momentSub=13,tab=13,wallet=13,bstName=13,skinName=13,lvh=13,
  beacon=12,chip=12,seg=12,pct=12,cardName=12,railLabel=11.5,carryHint=11.5,smallHud=11,small=11,micro=10.5,
  lv=10,tag=10,ribbon=10,forever=9.5,close=20,plus=15,cardArt=30,eggQ=30},
 prefs={},
 -- 1b tier map (owner decision 2026-10-27): Common/Uncommon blue, Rare gold, Epic violet, Mythic/Legendary prismatic.
 rarity={},
 prismatic={Mythic=true,Legendary=true},
 -- §5 upload sheet (U1–U6, U8–U11; U7 held). 0 = not uploaded yet.
 -- U1-U6, U8-U11 uploaded 2026-10-28 to the owner account (MCP upload_image via localhost; verified type Image, creator, size, alpha).
 images={glow=93480268375740,rays=113155665058160,shieldFill=88476648878593,roundtopFill=89527446609971,ticketFill=136711511090816,ribbonTail=132053820424208,glossOrb=92309004506129,shieldLine=126633186000147,roundtopLine=137973034532962,ticketLine=95881953296728,radial=129945984441539},
 slice={glow=Rect.new(63,63,65,65),shieldFill=Rect.new(100,40,156,156),shieldLine=Rect.new(100,40,156,156),
  roundtopFill=Rect.new(120,120,136,220),roundtopLine=Rect.new(120,120,136,220),ticketFill=Rect.new(32,0,96,148),ticketLine=Rect.new(32,0,96,148)},
 -- Approved icon set (design/hud-v2-icons, 512 px PNG), uploaded 2026-10-27 to the owner account (Asset Manager import, verified
 -- by name/type/creator). 0 = not uploaded: Widgets falls back to vector art.
 icons={bat=79489949621094,calendar=101408301548587,chest=93290064339576,climb=133883871347895,coin=101762154408109,creature=102205177846663,['egg-cracked']=72577063796540,egg=84031222220207,gear=83884046347131,gem=130750668923756,gift=96134676501853,heart=107212691032570,jump=117549058558428,map=95680349687396,padlock=81136570252405,scroll=130731564657582,sprint=120480218410073},
}
local rc=T.rarityColor
T.rarity={Common=rc.blue.rc,Uncommon=rc.blue.rc,Rare=rc.gold.rc,Epic=rc.violet.rc,Mythic=rc.prism.rc,Legendary=rc.prism.rc}
-- 1j legacy aliases (callers keep working).
T.navy=T.deep;T.panel=T.glassFrom;T.panelBlue=T.glassFrom;T.panelPurple=T.glassTo;T.card=T.cardFallback;T.sky=T.flare
T.blue=rc.blue.rc;T.coin=T.gold;T.green=T.go;T.readyDot=T.go;T.plus=T.go;T.purple=T.vi;T.gem=T.vi;T.tert=rc.violet.rc
T.coral=T.danger;T.alertDot=T.danger;T.heart=T.danger;T.ink=T.text;T.line=T.outline;T.muted=T.lavText
T.row=T.night;T.rowT=T.wellT.row;T.textDark=T.text;T.alt=T.night2;T.off=T.togOff;T.close=T.closeTo
T.cta={base=T.ctaHi,shade=T.vi,lip=T.lip,ink=T.text}
T.ok={base=T.go,lip=T.goLip};T.no={base=T.closeFrom,lip=T.closeLip}
-- bar.fill/bar.ready are Color3 for legacy callers: first stop of gradAction / gradCardXpFull.
T.bar={fill=T.gradAction.stops[1][2],ready=T.gradCardXpFull.stops[1][2],max=T.gold}
function T.configure(p) T.prefs=p or {} end
function T.size(n) return n+(if T.prefs.largeText then 2 else 0) end
return T
