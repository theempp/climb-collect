# Hosted test plan — PhoneCandidate03

Build: PhoneCandidate02 + `[CC-SAVE]` log lines in `Profiles` (load OK/FAIL, save OK/FAIL with coins, creatures, error). Logs print only outside Studio. Experience: Climb & Collect – Phone Candidate (private, PlaceId 139426549461023). Testers: 2 phones. Setup per `phone-candidate-2026-10-26.md` owner checklist (Max Players 8, Private, collaborator).

Read logs: Developer Console (chat `/console`) > Server tab. Filter `CC-SAVE`.

## A. Persistence (1 phone)
1. Join. Log: `load OK <uid> coins N creatures M`. Note N, M.
2. Habitat assign > collect > bank. Note new coins/creatures.
3. Leave. Log: `save OK ... release true` with the same numbers. Wait 1 min, rejoin: load numbers match.
4. Leave mid-carry, rejoin: unsecured creature gone, secured kept.
5. All leave (server closes), new server, rejoin: values still match.
6. Pass: no `FAIL` lines and numbers match. Record any `err` text verbatim.

## B. Two players
1. Separate homes; cannot touch the other's production.
2. Visit: tap-inspect the other's home.
3. Bat theft: carrier + thief; knock loose, grab, secure. Log the outcome.
4. Leave/rejoin mid-theft: no duplicated or lost creature.

## C. Phone performance (budget in phone-candidate-2026-10-26.md)
Home, gate, mid-mountain, nest fight: FPS, memory, ping; join time; UI overlap screenshots.

## D. Eight players — later, after A–C pass.

## Record
Per phone: model, iOS, join time, FPS/memory/ping, every `FAIL` log line, bugs with the action before them.
