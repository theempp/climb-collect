# v1 services — UI contract (for the Glassbloom HUD chat)

Branch `codex/v1-services`. Server/shared only; no HUD source was changed. Everything here is additive: no existing remote, action or profile field was renamed or removed. All numbers are PROPOSED (`mountain/shared/V1Config.luau`).

## Transport

Three new RemoteEvents in `ReplicatedStorage.MountainRemotes`:

| Remote | Direction | Arguments |
|---|---|---|
| `V1_Request` | client → server | `id, action, payload` |
| `V1_Result` | server → client | `{id, action, ok, message, data}` |
| `V1_Event` | server → client | `kind, data` (push) |

- `id` uses the existing UIRequest format `token:sequence` (token `[%w_-]{1,48}`, sequence a positive integer that must increase per token; at most 4 tokens per connection). Same id twice returns the cached result. Minimum 0.12 s between requests.
- On failure `message` is an **error code** (table below) or one of the gateway strings: `Invalid request id.`, `Unknown action.`, `Invalid action payload.`, `Please wait before trying another action.`, `Another action is in progress. Please wait.`, `Request expired. Refresh before trying again.`, `Profile or saving unavailable. Please retry when saving resumes.`
- Store-heavy actions also have per-action cooldowns (seconds): `Raid_Find` 3, `Raid_Log` 3, `Raid_Practice` 3, `Raid_Friendly` 5, `Raid_Reroll` 2, `Outpost_State`/`Season_State`/`Outpost_Collect`/`Outpost_Shield` 2, `Outpost_SetSlot`/`SetDefenders`/`Party` 0.5 → `cooldown`. Outpost writes return `busy_try_later` when the server's DataStore budget is low (profile saves keep priority). Outpost/season views may be up to 20 s old.
- Payloads are validated strictly (`mountain/shared/V1Protocol.luau`): unknown fields reject. Use `nil` where the table says `nil`.
- Never treat a client-side purchase callback as success. Ownership changes arrive only through `V1_Result`/`V1_Event` after the server commits.

## Actions

| Action | Payload | `data` on success | Error codes |
|---|---|---|---|
| `V1_State` | nil | `State` (below) | `unavailable` |
| `Daily_ClaimLogin` | nil | `{granted=Reward, daily=DailyView}` | `login_first`, `already_claimed`, `save_pending`, `unavailable` |
| `Daily_Claim` | `{slot=1..3 \| 'weekly'}` | `{granted, daily}` | `invalid_slot`, `not_complete`, `already_claimed`, `invalid_reward`, `save_pending` |
| `Daily_Reroll` | `{slot=1..3 \| 'weekly'}` | `{daily}` | `invalid_slot`, `already_claimed`, `no_rerolls`, `no_alternatives` |
| `Shop_State` | nil | `{checkoutEnabled, items={ {key,kind,price,grant,state} } }` | — |
| `Shop_Prompt` | `{key}` | `{key, state}` | `unavailable`, `owned`, `pending` |
| `Party` | `{op, ...}` (ops below) | `PartyState` | party codes |
| `Outpost_State` | nil | `OutpostView` | `unavailable`, `store_unavailable`, `invalid_record` |
| `Outpost_SetSlot` | `{slot=1..10, piece=id \| false}` | `OutpostView` | `invalid_slot`, `gate_required`, `unknown_piece`, `wrong_slot_type`, `locked` |
| `Outpost_SetDefenders` | `{ids={creatureId x0-3}}` | `OutpostView` | `invalid_defenders`, `not_owned`, `robux_creature_excluded` |
| `Outpost_Collect` | nil | `{coins}` | `vault_empty`, `store_unavailable` |
| `Outpost_Shield` | nil | `{untilTime}` | `no_shield_token`, `daily_paid_shield_used`, `shield_cap` |
| `Raid_Find` | nil or `{revenge=userId}` | `Offer` | `attack_in_progress`, `daily_attack_cap`, `daily_revenge_cap`, `no_revenge`, `target_protected` |
| `Raid_Reroll` | nil | `Offer` | `no_offer`, `revenge_fixed`, `no_reroll_token`, `save_pending` |
| `Raid_Start` | `{offerId}` | `{attackId, snapshot, expires, bot}` | `offer_expired`, `daily_attack_cap`, `target_gone`, `shielded`, `under_attack`, `save_pending` |
| `Raid_Submit` | `{attackId, creatures={id x1-3}, lanes={1..3 each}, ability={seconds 0-20 \| false each}?}` | `RaidResult` | `stale_attack`, `attack_expired`, `invalid_team`, `not_owned`, `robux_creature_excluded`, `invalid_plan`, `target_gone`, `store_unavailable` |
| `Raid_Abandon` | nil | message `forfeited` | `no_attack` |
| `Raid_Log` | nil | `{entries={LogEntry}, report={attacks,defended,coinsLost,trophies}, since}` | `unavailable` |
| `Raid_Practice` | plan (as Submit, no attackId) | `{stars,destruction,events,xp,coins=0,trophies=0}` | `invalid_team`, `invalid_plan` |
| `Raid_Friendly` | plan + `{userId}` | `{stars,destruction,events,coins=0,trophies=0,friendlyWins}` | `not_friends`, `no_outpost`, `daily_friendly_cap` |
| `Season_State` | nil | `{season=SeasonView, gallery=Gallery}` | `unavailable` |
| `Title_Equip` | `{id=titleId \| false}` | `{title}` | `title_not_owned` |

Profile freeze: any action that commits a reward can return `save_pending` (or the gateway "saving unavailable" string). The profile is frozen until the save commits; show "saving…" and retry the same action later. Nothing is granted until the commit.

### Party ops

`create`, `leave`, `ready_start`, `follow` (no fields); `invite {userId}`, `kick {userId}`, `friend {userId}`, `accept {partyId}`, `decline {partyId}`, `code {code}` (4–12 alphanumerics, case-insensitive), `ready {ready=bool}`.
Codes: `already_in_party`, `code_unavailable`, `invalid_target`, `target_not_in_server`, `not_leader`, `party_full`, `target_in_party`, `no_invite`, `invite_expired`, `party_gone`, `invalid_code`, `code_not_here`, `code_not_found`, `friend_not_in_party`, `not_friends`, `not_in_party`, `ready_check_running`, `no_ready_check`, `ready_check_expired`, `nothing_to_follow`, `already_traveled`, `follow_expired`, `follow_unavailable`, `teleporting`, `teleport_failed`, `unknown_op`.

Flow: invite (60 s) → accept → leader `ready_start` (20 s) → members `ready` → all ready: both travel to the Blossom entrance; timeout: ready members travel, the other may `follow` within 120 s. Travel needs: in sanctuary, not carrying, not in battle. Max 2.

## Push events (`V1_Event`)

| kind | data |
|---|---|
| `v1_state` | `State` (on join) |
| `daily` | `DailyView` (progress or new UTC day) |
| `party` | `{party=PartySnapshot \| nil, invites={ {partyId,from,expires} } }` |
| `raided` | `{attacker, stars, loot}` (defender online on the attacker's server) |
| `friendly_result` | `{attacker, stars, destruction, events}` |
| `season_rewards` | `{seasons={ {season,trophies,tier} } }` |
| `purchase` | `{key, state='owned_or_granted'}` |

## Shapes

- `State = {daily=DailyView, wallet=Wallet, shop=Shop, party=PartyState, raid={attacks,loot,friendlyWins,friendlyPlayed}, serverNow}`
- `Wallet = {eggTickets, tokens={raidReroll,shield}, boosts={production=untilUnix, xp=untilUnix}, cosmetics=set, titles=set, badges=set, title, passes=set}`
- `DailyView = {day, week, resetAt, weeklyResetAt, streak, trackLength, loginClaimable, loginReward=Reward, quests={ {slot,id,group,event,goal,progress,claimed,reward} }, rerollsLeft, weekly={slot='weekly',id,event,goal,progress,claimed,reward}, weeklyRerollsLeft}`
- `Reward` keys: `coins, eggTickets, cosmetic, title, badge, boost ('production'|'xp') + seconds, raidReroll, shield`
- `PartySnapshot = {id, leader, members={userId}, code, state='idle'|'ready_check'|'departed', readyExpires, ready={userId}, departedAt, travelers}`
- `OutpostView = {snapshot={version,rev,slots={pieceId|false x10},defenders={ {species,level,specialization} }}, slotTypes, pieces={ {id,slot,hp,damage,effect,unlocked,needs} }, vault={coins,cap,ratePerHour}, shield={untilTime,paidLeftToday,capSeconds}, trophies, season=SeasonView, revenge={ {userId,expires,attackId} }, attacksLeft, freeRerollsLeft, lootToday, lootCap, offer=Offer?, attack={attackId,expires}?}`
- Slot types: 1 `gate`, 2–6 `wall`, 7–10 `trap`. Lanes: slot 1→2, 2–3→1, 4→2, 5–6→3, 7→1, 8→2, 9→3, 10→2. Defender i guards lane i. `needs` = `starter`, `win:N`, `creatures:N`.
- `Offer = {offerId, bot, userId?, name, trophies, snapshot, revenge, expires}`
- `RaidResult = {attackId, stars 0-3, destruction 0-100, loot, trophies, events, bot, saved, forfeit?}`. `saved=false` means the loot/trophies are waiting on a profile save: show "saving…", not a failure.
- Abandoning, disconnecting or letting an attack expire after `Raid_Start` is a **0★ loss** (−12 trophies; `attack_expired` on a late submit). Warn before leaving an attack. Revenge attacks give the defender no counter-revenge; 3 revenges/day; 10 friendly raids/day.
- Replay `events` (≤60, `t` in seconds 0–20): `enter{a,lane}`, `trap{a,slot,amount}`, `move{a,lane}`, `ability{a,lane}`, `break{a,slot,gate?}`, `defender_down{a,lane,species}`, `attacker_down{a,lane}`, `end{stars,destruction}`. `a` = attacker index in the submitted `creatures` list.
- `LogEntry = {id, attacker, name, at, stars, destruction, loot, trophies, revenge, events}`
- `SeasonView = {season, trophies, tier, endsAt, history={ {season,trophies,tier} }, tiers}`; tiers `bronze` 0, `silver` 200, `gold` 500, `crystal` 1000, `astral` 1600.
- `Gallery = {seasons, guardians={id}, summit, titles, equipped, badges, friendlyWins, friendlyPlayed, streak}`

## Profile fields (readable in the existing `state` event)

`profile.schema` is now **3**. New subtree `profile.v1` (`mountain/shared/V1Schema.luau`): `processed`, `passes`, `tokens{raidReroll,shield}`, `eggTickets`, `cosmetics`, `titles`, `badges`, `title`, `boosts{production,xp}`, `daily{day,streak,lastLogin,loginClaimed,quests,rerolls,week,weekly,weeklyRerolls,claimed}`, `raid{day,attacks,loot,rerolls,practice,friendlyWins,friendlyPlayed}`, `applied`, `seasons`, `seasonSeen`. Prefer the views above; treat the raw subtree as read-only.

## Requests for HUD chat

1. `UIPresentation.quest` checks `profile.schema==2`; schema 3 profiles fall to the legacy branch. Please change to `profile.schema>=2` (one token).
2. Player-XP (Glassbloom D1): if it needs new profile fields, add them as schema 4 after `V1Schema.migrate` (Profiles.load chain: `RunRules.migrate` → `V1Schema.migrate` → yours), or put them under their own namespaced table. `Profiles.valid` now accepts schema 1/2/3.
3. Coin purchases (D7) must not assign `MarketplaceService.ProcessReceipt`; `V1Boot` owns it. Creature sources: raids accept only creatures with no `source` (legacy) or `source='play'` (`OutpostRules.eligible`). New creature-creating code should stamp `source='play'` for earned creatures and `source='robux'` for Robux eggs (D8); egg-ticket redemptions are excluded until reviewed. Please enforce the battle-team rule server-side the same way.
4. Daily/quests UI: wire to `Daily_*` actions and the `daily` event. Hard streak is LOCKED; show that a missed UTC day resets it, and the reset time (`resetAt`).
5. Display copy: only ids are provided for quests, pieces, titles, badges, tiers, cosmetics. Names and art are yours (design values must come from the HUD's own references).
6. The legacy `ChallengeDefense` / `RegisterDefense` actions still work. Replacing them with `Raid_Friendly` is PROPOSED; hide them once the friendly raid is wired.
7. Shop: every item is `unavailable` until products exist (`checkoutEnabled=false`, ids 0). Show odds + pity before any paid random item once one is added.
