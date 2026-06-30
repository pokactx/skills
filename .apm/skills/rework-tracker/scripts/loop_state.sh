#!/usr/bin/env bash
# rework-tracker state machine.
#
# Usage:
#   loop_state.sh <state-file> <root-cause-id> <result>
#
# result is one of: compliant | incomplete | invalid
#
# Appends a pass to the state file and prints exactly one token:
#   continue   — under the threshold (3 consecutive failures for the same root cause)
#   stop       — three consecutive incomplete/invalid for the same root cause
#
# Exit code 0 on continue, 0 on stop (the caller distinguishes by token),
# non-zero on usage errors.

set -euo pipefail

THRESHOLD=3

if [[ $# -ne 3 ]]; then
  echo "usage: loop_state.sh <state-file> <root-cause-id> <result>" >&2
  exit 2
fi

state_file="$1"
rcid="$2"
result="$3"

case "$result" in
  compliant|incomplete|invalid) ;;
  *)
    echo "loop_state: invalid result '$result' (expected compliant|incomplete|invalid)" >&2
    exit 2
    ;;
esac

mkdir -p "$(dirname "$state_file")"
touch "$state_file"

# Count consecutive trailing incomplete/invalid lines for this root cause.
# A compliant line or a different root-cause-id breaks the streak.
streak=0
last_rcid=""
while IFS=$'\t' read -r id attempt res ts; do
  [[ -z "${id:-}" ]] && continue
  if [[ "$id" == "$rcid" && "$res" != "compliant" ]]; then
    streak=$((streak + 1))
  else
    streak=0
  fi
  last_rcid="$id"
done < "$state_file"

# Compute this pass's attempt number for the root cause.
attempt=$(awk -F '\t' -v rcid="$rcid" '$1 == rcid { n = $2 } END { print n + 1 }' "$state_file" 2>/dev/null || true)
[[ -z "${attempt:-}" ]] && attempt=1

ts=$(date +%Y-%m-%dT%H:%M:%S%z)
printf '%s\t%s\t%s\t%s\n' "$rcid" "$attempt" "$result" "$ts" >> "$state_file"

# This pass's effect on the streak: a compliant pass resets, a failure extends.
if [[ "$result" == "compliant" ]]; then
  streak=0
else
  streak=$((streak + 1))
fi

if (( streak >= THRESHOLD )); then
  echo "stop"
else
  echo "continue"
fi
