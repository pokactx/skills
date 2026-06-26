# Forge Loop — Templates

Verbatim blocks the agent emits during the forge-loop workflow. Localize the fixed labels (`Findings`, `Plan context`, etc.) to the conversation language; keep the option markers `A)`/`B)`/`C)` and the priority markers `P0`/`P1`/`P2`/`P3` verbatim.

## Investigation block

Emit this whole block before the first clarifying question and re-emit it after every answer. Do not omit it even when there is no ambiguity; if no question is needed, write `Next clarifying question: none` and replace the entire `Next clarifying question` section (its `As-Is`/`What this resolves`/`Why the user must choose`/`Impact on the plan`/options/`Recommendation`/`Choose one` lines) with that single `none` line, then proceed to Phase 3. On re-emit, replace unchanged `Plan context` and `Findings` lines with `unchanged` instead of repeating prior content; always show the current `Open ambiguities` and the next question in full.

```text
Findings
- Code:
- Documentation:
- Tests:
- Existing plans:
- Local instructions:

Plan context
- Goal under planning:
- As-Is:
- Decided so far:
- Constraints to preserve:
- Undecided:

Open ambiguities
1. ...
2. ...
3. ...

Next clarifying question
Q1. ...

As-Is:
...

What this resolves:
Open ambiguity #...

Why the user must choose:
...

Impact on the plan:
...

A) ...
B) ...
C) ...

Recommendation:
...

Choose one of A, B, or C.
```

## Plan template

Write the plan where the repository expects persistent implementation plans. With no convention, use `docs/plans/plan_YYYYMMDDHHMMSS_<short-slug>.md` (append a kebab-case slug from the goal to avoid same-second collisions) and create directories as needed.

```md
# Plan

## Goal

## Current findings

## Decisions

## Resolved open questions

## Scope

## Steps

## Validation

## Risks
```

`Resolved open questions` maps every former `Open ambiguities` item to a settled decision. `Decisions` records any explicit user choices that shape delivery, including an opt-out of opening a PR (state the target branch and that a PR was intentionally skipped).

`Validation` lists the verification the `verifier` sub-agent will run (tests, type check, linter, build) and is the field the verifier cross-checks against its results. `Risks` records residual risks discovered during the loop, including: verification gaps the `verifier` marked `unavailable` with a recorded alternative, and out-of-scope recurrence matches surfaced by the `smell-detector` skill.

The review prompt, review output contract, and severity definitions (`P0`/`P1`/`P2`/`P3`) live in the `reviewer` sub-agent's contract (`.apm/agents/reviewer.agent.md`), not in this file. The verify and deliver output contracts live in the `verifier` and `deliverer` sub-agent contracts (`.apm/agents/verifier.agent.md`, `.apm/agents/deliverer.agent.md`).
