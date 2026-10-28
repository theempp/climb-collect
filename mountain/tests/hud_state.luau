-- Glassbloom HUD state (P2 T6): states, carry/regrab, chase, section, checkpoint, XP diffs, tier map, legacy toasts.
local C=require('../shared/Catalog')
local R=require('../shared/Rules')
local Run=require('../shared/RunRules')
local X=require('../shared/ExplorerRules')
local H=require('../shared/HudState')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local function kinds(list) local t={};for _,m in ipairs(list) do table.insert(t,m.kind) end;return table.concat(t,',') end
-- Tier map (intel §4; board text wins: XP line 1.5 s, carry pop-up 2.5 s, RUN! 1.5 s).
local want={coin={1,'toast',1.5},xp={1,'toast',1.5},xpLine={1,'xpLine',1.5},pickup={1,'toast',1.5},toast={1,'toast',1.5},
 carry={2,'carryPop',2.5},regrab={2,'carryPop',2.5},alert={2,'run',1.5},section={2,'banner',2.5},safe={2,'banner',2.5},
 knocked={1,'toast',1.5},lost={2,'banner',2.5},
 levelUp={3,'moment',2.5},summit={3,'moment',2.5}}
for kind,w in pairs(want) do
 local m=H.message(kind)
 check(m.kind==kind and m.tier==w[1] and m.slot==w[2] and m.duration==w[3] and not m.collect,'tier_'..kind)
end
check(H.message('alert').danger==true and not H.message('section').danger,'alert_is_the_danger_banner')
local cp=H.message('checkpoint');check(cp.tier==nil and cp.slot=='rail' and cp.duration==3,'checkpoint_is_rail_not_tier')
local hatch=H.message('hatch');check(hatch.tier==3 and hatch.slot=='reveal' and hatch.land==3.5 and hatch.cta==5.7 and hatch.collect and hatch.duration==nil,'hatch_reveal_waits_for_collect')
for _,gap in ipairs({'calm','purchase','nope'}) do check(H.message(gap)==nil,'gap_has_no_tier_'..gap) end
local up=H.message('levelUp',{level=2},true);check(up.tier==3 and up.collect and up.duration==nil and up.data.level==2,'sanctuary_tier3_waits_for_collect')
check(H.message('summit',nil,false).duration==2.5 and H.message('section',nil,true).duration==2.5 and not H.message('section',nil,true).collect,'collect_only_for_tier3_in_sanctuary')
-- Legacy toasts: unknown text is tier 1; typed duplicates and the summit are mapped.
local g=C.guardians[2].name;local sp=C.byId.mossbun.name
for _,text in ipairs({'Rest point saved. Unsecured creatures still need the sanctuary exit.','Hit! Grab the '..sp..' before it escapes.','Landmark discovered • +10 Petals','Movement corrected.','anything at all'}) do
 local m=H.classify(text);check(m.kind=='toast' and m.tier==1 and m.duration==1.5 and m.text==text and not m.typed and not m.priority,'legacy_default_tier1_'..text)
end
local a=H.classify(g..' heard your strike! Watch its approach.');check(a.kind=='alert' and a.tier==2 and a.typed,'legacy_alert_typed')
local s=H.classify('Safe! '..sp..' is yours. Carry it home.');check(s.kind=='safe' and s.tier==2 and s.typed,'legacy_safe_typed')
-- G5: the knocked/lost toasts the server sends next to the typed events are skipped (the typed event drives the message).
local kn=H.classify('Knocked! Your '..sp..' dropped — grab it back!');check(kn.kind=='knocked' and kn.tier==1 and kn.typed,'legacy_knocked_typed')
for _,text in ipairs({'Unsecured '..sp..' lost. Try another egg.','Your creature was taken. Unsecured creatures stay at risk until the sanctuary gate.','Your dropped creature escaped.'}) do
 local m=H.classify(text);check(m.kind=='lost' and m.tier==2 and m.slot=='banner' and m.typed,'legacy_lost_typed_'..text)
end
check(H.classify('Not Safe! here').kind=='toast','safe_matches_only_at_start')
local top=H.classify('IMPOSSIBLE MOUNTAIN CONQUERED • Sovereign Explorer!');check(top.kind=='summit' and top.tier==3 and top.duration==2.5 and not top.typed,'legacy_summit_moment')
check(H.classify('Find the golden heart. Use a special nearby to interrupt healing!').priority and H.classify('Align all three constellation stones before the gravity wave!').priority,'battle_objectives_keep_priority')
check(H.classify(nil)==nil and H.classify('')==nil and H.classify(5)==nil,'classify_ignores_non_text')
-- Section: server ui.section wins; false = outside; only nil/malformed uses the client fallback, never in the sanctuary.
check(H.section({section=3},5)==3 and H.section({section=false},5)==nil and H.section({},5)==5 and H.section(nil,2)==2,'server_section_wins')
check(H.section({section=7},4)==4 and H.section({section='2'},nil)==nil and H.section({inSanctuary=true},4)==nil and H.section({},9)==nil,'malformed_section_falls_back')
-- Fallback X/Z test (Controller): altitude band, then the GuardianBounds box holding the position (X/Z only).
local function box(name,cx,cz,sx,sz) return {Name=name,Size={X=sx,Y=120,Z=sz},CFrame={PointToObjectSpace=function(_,p) return {X=p.X-cx,Y=0,Z=p.Z-cz} end}} end
local bounds={box('1',4096,-310,344,196),box('2',4096,-510,344,196),{Name='3'}}
check(H.fallbackSection({X=4096,Y=16,Z=-500},1,bounds)==2,'fallback_box_wins_over_band')
check(H.fallbackSection({X=0,Y=16+64*2+1,Z=0},1,bounds)==3 and H.fallbackSection({X=0,Y=16+136+1,Z=0},nil,bounds)==2,'fallback_band_free_64_legacy_136')
check(H.fallbackSection({X=0,Y=-100,Z=0},1,{})==1 and H.fallbackSection({X=0,Y=9999,Z=0},1,{})==6,'fallback_band_clamped')
check(H.fallbackSection(nil,1,bounds)==nil and H.fallbackSection({X=0,Y=0/0,Z=0},1,bounds)==nil,'fallback_needs_a_position')
-- The engine passes rr.Position, a native Vector3 (type 'vector'), not a table.
local vec=vector.create(4096,16,-500)
check(type(vec)=='vector' and H.fallbackSection(vec,1,bounds)==2 and H.fallbackSection(vector.create(0,16+64*2+1,0),1,{})==3,'fallback_accepts_native_vector')
-- Checkpoint ids: route order entrance, recovery, guardian (1..18); legacy ids carry no order.
check(H.checkpoint('1:entrance').order==1 and H.checkpoint('3:recovery').order==8 and H.checkpoint('6:guardian').order==18 and H.checkpoint('6:guardian').section==6,'checkpoint_order')
check(H.checkpoint('summit')==nil and H.checkpoint('1:discovery')==nil and H.checkpoint('7:entrance')==nil and H.checkpoint(4)==nil,'legacy_checkpoint_no_order')
-- Observe: the first snapshot is a baseline; later diffs give carry, section, checkpoint and XP messages.
local function profile() local p=R.newProfile(100);p.ui={section=1,inSanctuary=false,explorer=X.summary(p)};return p end
local m=H.new();local p=profile()
check(#H.observe(m,p)==0 and m.seeded and H.state(m,p,false)=='rest','baseline_has_no_messages')
check(#H.observe(m,p)==0,'unchanged_snapshot_no_messages')
check(Run.strike(p,{id='raid:1:1',runId='r1',species='glimfox',section=1,hitsRequired=2},1),'strike')
check(#H.observe(m,p)==0 and H.state(m,p,false)=='rest','breaking_is_rest')
Run.strike(p,{id='raid:1:1',runId='r1',species='glimfox',section=1,hitsRequired=2},2)
check(p.run.phase=='revealed' and #H.observe(m,p)==0,'revealed_is_not_a_carry')
Run.pickup(p,'r1');local out=H.observe(m,p)
check(kinds(out)=='carry' and out[1].data.runId=='r1' and out[1].data.species=='glimfox' and out[1].data.section==1 and not out[1].data.stolen and out[1].duration==2.5,'carry_start_from_profile')
check(H.state(m,p,false)=='carry' and H.carrying(p),'carry_state')
check(#H.observe(m,p)==0 and #H.event(m,{kind='carry',runId='r1',species='glimfox',section=1})==0,'one_pop_up_per_run_id')
-- Chase from alert/calm; the chase frame keeps the carry portrait.
out=H.event(m,{kind='alert',guardian=C.guardians[1].name,guardianId=C.guardians[1].id,section=1,sectionName=C.kingdoms[1].name,eggId='raid:1:1'})
check(kinds(out)=='alert' and out[1].tier==2 and out[1].duration==1.5 and out[1].data.guardian==C.guardians[1].name and out[1].data.section==1,'alert_message')
check(H.state(m,p,false)=='chase' and H.carrying(p),'chase_while_carrying')
H.event(m,{kind='alert',section=2});H.event(m,{kind='calm',section=1,reason='step'})
check(H.state(m,p,false)=='chase','chase_until_every_threat_is_calm')
check(#H.event(m,{kind='calm',section=2,reason='respite'})==0 and H.state(m,p,false)=='carry','calm_ends_chase')
for _,bad in ipairs({0,7,1.5,'1'}) do check(#H.event(m,{kind='alert',section=bad})==0 and not H.chased(m),'malformed_alert_ignored_'..tostring(bad)) end
check(#H.event(m,{kind='calm',section=4})==0 and not H.chased(m),'calm_without_threat_harmless')
H.event(m,{kind='alert',section=1});p.ui.inSanctuary=true
check(H.state(m,p,false)=='sanctuary','sanctuary_beats_chase')
check(H.state(m,p,{name='Guardian'})=='battle' and H.state(m,p,false)~='battle' and H.state(m,p,nil)~='battle','battle_beats_all')
p.ui.inSanctuary=false;H.event(m,{kind='calm',section=1})
-- Regrab: my previous run id comes back as stolenFrom (RunRules.receive).
local snap=Run.drop(p);check(snap and snap.from=='r1' and p.run==nil,'knocked_drop')
check(#H.observe(m,p)==0 and H.state(m,p,false)=='rest','knocked_is_rest')
Run.receive(p,snap,'r2',3);out=H.observe(m,p)
check(kinds(out)=='regrab' and out[1].data.runId=='r2' and out[1].slot=='carryPop' and out[1].duration==2.5,'regrab_from_profile')
-- A snapshot that skips the empty-hands state still reads as a regrab.
local m2=H.new();local q=profile();Run.strike(q,{id='raid:1:2',runId='a',species='glimfox',section=1,hitsRequired=1},1);Run.pickup(q,'a')
H.observe(m2,q);local s2=Run.drop(q);Run.receive(q,s2,'b',2)
check(kinds(H.observe(m2,q))=='regrab','regrab_without_seeing_the_drop')
-- A thief's grab is a stolen carry: stolenFrom is someone else's run.
local m3=H.new();local thief=profile();H.observe(m3,thief)
Run.receive(thief,{species='glimfox',section=1,from='victim-run'},'t1',4);out=H.observe(m3,thief)
check(kinds(out)=='carry' and out[1].data.stolen==true,'thief_grab_is_stolen_carry')
-- Typed events first, profile diff second (and the reverse above): still one pop-up.
local m4=H.new();local r=profile();H.observe(m4,r)
out=H.event(m4,{kind='regrab',runId='z9',species='glimfox',section=1,auto=true})
check(kinds(out)=='regrab' and out[1].data.auto==true,'typed_auto_regrab')
Run.receive(r,{species='glimfox',section=1,from='z8'},'z9',5);check(#H.observe(m4,r)==0,'typed_then_profile_deduped')
check(#H.event(m4,{kind='carry'})==0 and #H.event(m4,{kind='carry',runId=5})==0,'carry_needs_run_id')
for i=1,40 do H.event(m4,{kind='carry',runId='bulk'..i}) end
check(#m4.order<=32 and not m4.announced.bulk1 and m4.announced.bulk40,'announced_memory_bounded')
-- Other typed events: safe/lost banners, knocked and xp toasts (G5).
out=H.event(m,{kind='safe',species='glimfox',runId='r2'});check(kinds(out)=='safe' and out[1].tier==2 and out[1].slot=='banner','safe_banner')
out=H.event(m,{kind='xp',amount=25,source='rest',level=1});check(kinds(out)=='xp' and out[1].tier==1 and out[1].data.source=='rest' and out[1].data.amount==25,'xp_toast_names_source')
check(#H.event(m,{kind='xp',amount=0})==0 and #H.event(m,{kind='xp',amount=0/0})==0,'xp_without_gain_ignored')
out=H.event(m,{kind='knocked',species='glimfox',dropId='d1'});check(kinds(out)=='knocked' and out[1].tier==1 and out[1].slot=='toast' and out[1].data.species=='glimfox','knocked_toast')
out=H.event(m,{kind='lost',species='glimfox',reason='stolen'});check(kinds(out)=='lost' and out[1].tier==2 and out[1].slot=='banner' and out[1].data.reason=='stolen','lost_banner')
check(#H.event(m,{kind='unknown',species='glimfox'})==0,'unknown_event_no_message')
check(#H.event(m,nil)==0 and #H.event(m,'junk')==0,'event_ignores_non_table')
-- Section banner: changes only; box gaps (false) don't re-banner; the sanctuary resets it.
m=H.new();p=profile();H.observe(m,p)
p.ui.section=2;out=H.observe(m,p);check(kinds(out)=='section' and out[1].data.section==2 and out[1].data.name==C.kingdoms[2].name and out[1].duration==2.5,'section_change_banner')
p.ui.section=false;check(#H.observe(m,p)==0,'leaving_boxes_no_banner')
p.ui.section=2;check(#H.observe(m,p)==0,'box_gap_same_section_no_rebanner')
p.ui.section=false;p.ui.inSanctuary=true;H.observe(m,p);p.ui.section=2;p.ui.inSanctuary=false
check(kinds(H.observe(m,p))=='section','sanctuary_resets_section_banner')
p.ui.inSanctuary=true;p.ui.section=4;check(#H.observe(m,p)==0,'no_section_banner_in_sanctuary');p.ui.inSanctuary=false
p.ui.section=nil;out=H.observe(m,p,3);check(kinds(out)=='section' and out[1].data.section==3,'client_fallback_when_server_section_missing')
p.ui.section=false;check(#H.observe(m,p,5)==0,'server_false_ignores_fallback')
-- Checkpoint: profile.checkpoint changes drive the rail label.
p.checkpoint='2:recovery';out=H.observe(m,p)
check(kinds(out)=='checkpoint' and out[1].slot=='rail' and out[1].tier==nil and out[1].data.order==5 and out[1].data.section==2,'checkpoint_rail_label')
check(#H.observe(m,p)==0,'same_checkpoint_no_repeat')
p.checkpoint='summit';out=H.observe(m,p);check(kinds(out)=='checkpoint' and out[1].data.id=='summit' and out[1].data.order==nil,'legacy_checkpoint_id_only')
-- Explorer XP diff: the XP line on every gain, the level-up moment on a level rise (Collect in the sanctuary).
local e=profile();local em=H.new();H.observe(em,e)
e.discoveries['1:entrance']=true;e.ui.explorer=X.summary(e);out=H.observe(em,e)
check(kinds(out)=='xpLine' and out[1].data.amount==25 and out[1].data.level==1 and not out[1].data.levelUp and out[1].duration==1.5,'explorer_xp_line')
e.discoveries['1:recovery']=true;e.discoveries['1:guardian']=true;e.ui.explorer=X.summary(e);out=H.observe(em,e)
check(kinds(out)=='xpLine,levelUp' and out[1].data.amount==50 and out[2].data.level==2 and out[2].data.from==1 and out[2].duration==2.5,'explorer_level_up_moment')
e.discoveries['2:entrance']=true;e.explorer.won['3']=true;e.ui.explorer=X.summary(e);e.ui.inSanctuary=true;out=H.observe(em,e)
check(kinds(out)=='xpLine,levelUp' and out[2].collect and out[2].duration==nil,'sanctuary_level_up_waits_for_collect')
e.discoveries['2:entrance']=nil;e.ui.explorer=X.summary(e);check(#H.observe(em,e)==0,'explorer_xp_drop_no_message')
check(H.explorerDiff(nil,X.summary(e))==nil and H.explorerDiff({xp=0/0,level=1},X.summary(e))==nil and H.explorerDiff(X.summary(e),{xp=1,level=0})==nil,'explorer_diff_malformed')
e.ui.explorer='junk';check(#H.observe(em,e)==0,'explorer_junk_is_baseline');e.ui.explorer=X.summary(e);check(#H.observe(em,e)==0,'explorer_after_junk_is_baseline')
-- Creature XP diff: totals across level-ups match Rules.addXP; new creatures are not gains.
local c=profile();local cm=H.new();H.observe(cm,c)
R.addXP(c.creatures[1],100);R.addXP(c.creatures[2],40*2)
table.insert(c.creatures,{id='c9',species='glimfox',level=3,xp=5})
out=H.observe(cm,c);local d=out[1] and out[1].data
check(kinds(out)=='creatureXp' and d.amount==180 and #d.creatures==2 and d.creatures[1].id=='c1' and d.creatures[1].amount==100 and d.creatures[1].level==2 and d.creatures[1].levelUp and d.creatures[2].amount==80 and out[1].tier==1,'creature_xp_diff')
local before={{id='c1',species='mossbun',level=49,xp=1900}};local after={{id='c1',species='mossbun',level=49,xp=1900}};R.addXP(after[1],100000)
check(after[1].level==50 and H.creatureXp(before,after).amount==20*50*49-(20*49*48+1900),'creature_xp_to_cap')
check(H.creatureXp(nil,after)==nil and H.creatureXp(after,after)==nil and H.creatureXp({{id='c1',level=0/0,xp=0}},after)==nil and H.creatureXp({'x',{id=5}},{'y'})==nil,'creature_xp_malformed')
-- Robustness: garbage profiles never error.
for _,bad in ipairs({nil,5,'x',{},{ui='x',run='y',creatures='z',checkpoint=4},{ui={section='x',explorer={xp='a'}},run={phase='carried'},creatures={1,{id='q'}}}}) do
 local bm=H.new();local ok=pcall(function() H.observe(bm,bad);H.observe(bm,bad);H.state(bm,bad,false) end)
 check(ok,'observe_total_'..type(bad))
end
check(H.state(H.new(),nil,nil)=='rest' and H.states.rest and H.states.carry and H.states.chase and H.states.sanctuary and H.states.battle,'five_states')
print('PASS '..n..' hud state checks')
