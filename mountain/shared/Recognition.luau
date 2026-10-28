-- C06 titles, badges and trophy-gallery data. Titles/badges are earned from saved play only; Roblox badge
-- ids are 0 (stubs: award calls are skipped until real badges exist). Display text belongs to the HUD.
local R={}
R.titles={
 {id='summit_conqueror',source='summit'},
 {id='guardian_tamer',source='captures:1'},
 {id='sovereign_keeper',source='captures:6'},
 {id='steadfast_7',source='streak:7'},
 {id='friendly_rival',source='friendly:10'},
 {id='gold_climber',source='season:gold'},
 {id='crystal_raider',source='season:crystal'},
 {id='astral_sovereign',source='season:astral'},
 {id='vip',source='pass:vip'},
 {id='summit_pass',source='pass:summit_pass'},
}
R.badges={
 {key='season_crystal',robloxId=0},
 {key='season_astral',robloxId=0},
 {key='summit_conqueror',robloxId=0},
 {key='first_raid',robloxId=0},
}
R.byTitle={};for _,t in ipairs(R.titles) do R.byTitle[t.id]=t end
R.byBadge={};for _,b in ipairs(R.badges) do R.byBadge[b.key]=b end
local function captures(p) local n=0;for _ in pairs(p.captures or {}) do n+=1 end;return n end
-- Titles earned from profile state that are not yet stored. Season/pass titles arrive via their grants.
function R.earned(p)
 local list={}
 local function add(id,ok) if ok and not p.v1.titles[id] then table.insert(list,id) end end
 add('summit_conqueror',p.discoveries and p.discoveries.summit==true)
 add('guardian_tamer',captures(p)>=1)
 add('sovereign_keeper',captures(p)>=6)
 add('steadfast_7',p.v1.daily.streak>=7)
 add('friendly_rival',p.v1.raid.friendlyWins>=10)
 return list
end
function R.badgesEarned(p)
 local list={}
 if p.discoveries and p.discoveries.summit and not p.v1.badges.summit_conqueror then table.insert(list,'summit_conqueror') end
 return list
end
function R.equip(v1,id)
 if id==false then v1.title=nil;return true end
 if type(id)~='string' or not R.byTitle[id] or not v1.titles[id] then return false,'title_not_owned' end
 v1.title=id;return true
end
function R.gallery(p,history)
 local guardians={};for id in pairs(p.captures or {}) do table.insert(guardians,id) end;table.sort(guardians)
 local titles={};for id in pairs(p.v1.titles) do table.insert(titles,id) end;table.sort(titles)
 local badges={};for id in pairs(p.v1.badges) do table.insert(badges,id) end;table.sort(badges)
 return {seasons=history or {},guardians=guardians,summit=p.discoveries and p.discoveries.summit==true,titles=titles,equipped=p.v1.title,badges=badges,
  friendlyWins=p.v1.raid.friendlyWins,friendlyPlayed=p.v1.raid.friendlyPlayed,streak=p.v1.daily.streak}
end
return R
