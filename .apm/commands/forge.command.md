---
description: Run the forge-loop on a task — clarify, plan with approval, implement/review until clean, verify, then open a PR
argument-hint: <task, issue, or ticket to implement>
---
Use the forge-loop skill to take the following work from a clean start through to an opened PR: $ARGUMENTS

Follow the forge-loop phases exactly — do not shortcut to delivery:

1. Investigate the project context yourself (pre-approval; no sub-agents, no edits).
2. Clarify open ambiguities one question at a time until none material remains.
3. Write the plan to the repository's plan location and wait for my explicit approval.
4. After approval, loop implement/review (with rework-tracker as the safety valve) until review is clean and no P0/P1/P2 remain, then run smell-detector once when the plan's `Fixed root causes` section has entries (otherwise skip and proceed).
5. Verify, then deliver via the deliverer sub-agent — open a PR by default, or commit only if I opted out of a PR during planning.

The PR is the loop's terminal deliver step, not a separate action: let Phase 5 open it. Do not author PR creation logic here.
