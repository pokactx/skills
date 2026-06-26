---
name: smell-detector
description: >-
  Detect the same root-cause pattern as a review finding across the whole
  repository (including outside the approved scope) and list the matches as
  residual risks, not blockers. Called by the forge-loop orchestrator once
  after a clean review, before delivery. Deterministic: scans via a script,
  not by LLM reasoning. The starting point for turning review findings into
  reusable detectors.
---

# Smell Detector

Turn a review finding into a reusable, deterministic detector. After a clean review, the forge-loop orchestrator calls this skill once to scan the whole repository for the same root-cause pattern — including occurrences outside the approved scope — and lists them as residual risks for the next plan's `Risks` field. Matches are warnings, not blockers: the goal is to grow detectors as assets, not to block delivery.

## When to use

- forge-loop has just received `No findings` from the `reviewer`.
- Run this skill once, before dispatching the `verifier`/`deliverer`.

## When not to use

- Before the first review pass.
- As a blocking gate. This skill never blocks delivery; it surfaces risks.

## How it works

1. Derive a search pattern from the reviewer's root-cause description. Start simple: a token/regex that matches the offending construct (e.g. `issueToken(` called without a nil-guard, `fmt.Println` used for errors, `time.Sleep` in retry loops).
2. Run `scripts/detect.sh` with the pattern and the repo root. The script scans tracked source files and prints `file:line — pattern` matches, excluding the approved-scope paths the orchestrator passes in.
3. Emit the matches as `Smell matches (outside approved scope)`.

## Output

```text
Smell matches (outside approved scope)
- <file:line — pattern — suggested fix>, or "none"
```

If matches exist, the orchestrator records them in the plan's `Risks` (or surfaces them to the user) and proceeds to verify/deliver. They do not re-enter the Phase 4 loop.

## Growing detectors

The first version of a detector is a grep/regex pattern in `detect.sh`. When a pattern keeps recurring, promote it: add it as a named rule in the script with a stable id, and later consider an AST-based variant. Each promoted rule is an asset that survives model and agent changes.

## Determinism

Scanning is done by `scripts/detect.sh`. Do not eyeball matches. The script is the source of truth for what is reported.

## Severity stance

Matches are warnings, not blockers — the article's "lower the bar with a Warning-level severity." If a match turns out to be a real must-fix, the orchestrator can choose to open it as a new plan rather than expanding the current approved scope.
