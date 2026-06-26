---
name: rework-tracker
description: >-
  Track consecutive failed rework passes against the same root cause in the
  forge-loop Phase 4 loop and trip a safety valve after three in a row. Called
  by the forge-loop orchestrator on every rework pass. Deterministic: counts
  attempts in a state file via a script, not by LLM reasoning.
---

# Rework Tracker

Make the forge-loop safety valve deterministic. The orchestrator calls this skill on every rework pass; the skill counts consecutive failed passes against the same root cause in a state file and returns `continue` or `stop`. After three consecutive failures against the same root cause, return `stop` so the orchestrator halts auto-looping and reports the blocker to the user.

## When to use

- The forge-loop orchestrator is about to re-dispatch the `implementer` after a non-clean review or an invalid/incomplete implement pass.
- Call this skill before each re-dispatch to decide `continue` vs `stop`.

## When not to use

- Outside the forge-loop Phase 4 loop.
- On the first implement pass (no rework yet).

## State file

One file per plan, next to the plan:

```
docs/plans/loop_<plan-slug>.md
```

`<plan-slug>` is the same slug used in the plan filename. Each line is one rework pass, tab-separated:

```
<root-cause-id>\t<attempt>\t<result>\t<timestamp>
```

- `root-cause-id`: short stable identifier for the root cause (a kebab-case label the orchestrator derives from the finding, e.g. `nil-user-token`). The same root cause keeps the same id across passes.
- `attempt`: 1-based index for this root cause (resets when the root cause changes or a pass succeeds).
- `result`: `compliant` | `incomplete` | `invalid` (per the implementer's last output).
- `timestamp`: ISO 8601 local time.

Example state file:

```text
nil-user-token	1	incomplete	2026-06-26T11:34:09+09:00
nil-user-token	2	invalid	2026-06-26T11:36:42+09:00
nil-user-token	3	incomplete	2026-06-26T11:39:05+09:00
```

## API

The orchestrator passes:

- the state file path,
- the `root-cause-id` for this rework,
- the implementer's last `result` (`compliant` | `incomplete` | `invalid`).

The skill runs the script and returns exactly one of:

- `continue` — under the threshold, proceed with the rework dispatch.
- `stop` — three consecutive `incomplete`/`invalid` against the same root cause; halt and report to the user with the last attempts summarized.

## Determinism

Counting and threshold comparison are done by `scripts/loop_state.sh`. Do not count by eye or by memory. The script is the source of truth for the safety valve.

## Reset rules

- A `compliant` result resets the attempt counter for that root cause.
- A different `root-cause-id` starts a new counter.
- The state file persists across the loop so the count is auditable.
