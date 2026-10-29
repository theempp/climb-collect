-- Sfx: the one sound + haptics tokens file (design/audio-juice-plan-2026-10-28.md), like Motion.luau for motion.
-- No sound ids live anywhere else. id 0 = not sourced yet: the cue stays silent and never blocks gameplay.
-- Ids are filled only after GetProductInfo + PreloadAsset checks and a G05 manifest entry; never invent one.
local S={}

S.GROUPS={Music=true,SFX=true,Ambience=true,UI=true}
S.MAX_CONCURRENT=24
S.MAX_CONCURRENT_LOW=12

-- haptic: nil | 'light' | 'medium' | 'heavy' | 'strong'. cooldown in seconds.
S.CUES={
 egg_strike={id=0,group='SFX',volume=.8,cooldown=.15,haptic='light'},
 egg_secured={id=0,group='SFX',volume=.7,cooldown=.3,haptic='medium'},
 hatch_riser={id=0,group='SFX',volume=.7,cooldown=1},
 hatch_reveal={id=0,group='SFX',volume=.9,cooldown=1,haptic='heavy'},
 hatch_reveal_rare={id=0,group='SFX',volume=1,cooldown=1,haptic='heavy'},
 rank_up={id=0,group='SFX',volume=.8,cooldown=1,haptic='medium'},
 fall_lost={id=0,group='SFX',volume=.8,cooldown=.5,haptic='strong'},
 ui_tap={id=0,group='UI',volume=.4,cooldown=.05},
 ui_open={id=0,group='UI',volume=.45,cooldown=.1},
 ui_close={id=0,group='UI',volume=.4,cooldown=.1},
 ui_back={id=0,group='UI',volume=.4,cooldown=.1},
 ui_locked={id=0,group='UI',volume=.45,cooldown=.2},
 purchase_ok={id=0,group='UI',volume=.6,cooldown=.5,haptic='light'},
 ladder_step={id=0,group='SFX',volume=.7,cooldown=.5,haptic='medium'},
 ladder_step_big={id=0,group='SFX',volume=.85,cooldown=.5,haptic='heavy'},
 quest_complete={id=0,group='UI',volume=.6,cooldown=.5},
 daily_claim={id=0,group='UI',volume=.6,cooldown=.5,haptic='light'},
}

-- Stings duck music 3-4 dB for 1 s (plan mix targets).
S.DUCK={db=-3.5,seconds=1,by={hatch_reveal=true,hatch_reveal_rare=true,rank_up=true,ladder_step_big=true}}
S.HAPTIC_STRENGTH={light=.25,medium=.5,heavy=.8,strong=1}

function S.hatchCue(rarity) -- Rare and up get the bigger sting
 return (rarity=='Rare' or rarity=='Epic' or rarity=='Legendary' or rarity=='Mythic') and 'hatch_reveal_rare' or 'hatch_reveal'
end
function S.ladderCue(step) return (step==4 or step==5) and 'ladder_step_big' or 'ladder_step' end -- x16, x32

-- Player-side state. deps: play(cue, spec) -> handle|nil, haptic(strength), now(), settings() ->
-- {low=bool, reduceEffects=bool, haptics=bool, phone=bool}.
function S.new(deps)
 local self={now=deps.now or os.clock,last={},active=0,played=0,skipped=0}
 local function settings() return deps.settings and deps.settings() or {} end

 -- Returns true if the sound was started.
 function self.play(name)
  local c=S.CUES[name]
  if not c then return false end
  local st,t=settings(),self.now()
  if self.last[name] and t-self.last[name]<c.cooldown then self.skipped+=1;return false end
  if self.active>=(st.low and S.MAX_CONCURRENT_LOW or S.MAX_CONCURRENT) then self.skipped+=1;return false end
  self.last[name]=t
  if c.haptic and st.phone and st.haptics~=false and not st.reduceEffects and deps.haptic then
   pcall(deps.haptic,S.HAPTIC_STRENGTH[c.haptic])
  end
  if c.id==0 or not deps.play then return false end
  local ok,h=pcall(deps.play,name,c)
  if not ok or not h then return false end
  self.active+=1;self.played+=1
  return true
 end
 function self.ended() self.active=math.max(0,self.active-1) end
 return self
end

return S
