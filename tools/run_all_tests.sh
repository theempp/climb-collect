#!/bin/bash
# run_all_tests.sh : every mountain/tests suite (Luau + run_*.py). Prints one line per suite and a summary.
cd "$(dirname "$0")/.."
L="C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe"; pass=0; fail=0
for f in mountain/tests/*.luau; do
 case $(basename $f) in combat_raids.luau|raid_events.luau|run_persistence.luau) continue;; esac  # bodies loaded by run_*.py
 out=$("$L" "$f" 2>&1); rc=$?
 if [ $rc -eq 0 ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
 echo "$([ $rc -eq 0 ] && echo PASS || echo FAIL) $(basename $f) | $(echo "$out" | tail -1 | cut -c1-90)"
done
for f in mountain/tests/run_*.py; do
 out=$(python "$f" 2>&1); rc=$?
 if [ $rc -eq 0 ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
 echo "$([ $rc -eq 0 ] && echo PASS || echo FAIL) $(basename $f) | $(echo "$out" | tail -1 | cut -c1-90)"
done
echo "SUITES pass=$pass fail=$fail"
