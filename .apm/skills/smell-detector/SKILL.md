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

Turn a review finding into a reusable, deterministic detector. After a clean review, the forge-loop orchestrator calls this skill once to scan the whole repository for root-cause patterns fixed during Phase 4 — including occurrences outside the approved scope — and lists them as residual risks for the plan's `Risks` field. Matches are warnings, not blockers: the goal is to grow detectors as assets, not to block delivery.

## When to use

- forge-loop has just received `No findings` from the `reviewer`.
- The plan's `Fixed root causes` section has at least one entry with a search pattern.
- Run this skill once, before dispatching the `verifier`/`deliverer`.

## When not to use

- Before the first review pass.
- When `Fixed root causes` is empty (first implement pass reached `No findings` with no prior findings). Skip smell-detector, emit `Smell matches (outside approved scope)\n- none`, and proceed to Phase 5.
- As a blocking gate. This skill never blocks delivery; it surfaces risks.

## Input

Read search patterns from the plan's `Fixed root causes` section (accumulated during Phase 4). Each entry has a stable `root-cause-id`, a one-line description, and a `pattern:` token or regex. Do not derive patterns from the final `No findings` review output — that output has no root-cause descriptions.

## How it works

1. If `Fixed root causes` is empty, skip scanning and emit `none`.
2. For each pattern in `Fixed root causes`, run `scripts/detect.sh` with the pattern, repo root, and approved-scope exclude paths.
3. Emit the matches as `Smell matches (outside approved scope)`.

## Script invocation

Prerequisite: `ripgrep` (`rg`) must be on PATH.

Run from the repository root. Pass approved-scope paths as trailing exclude arguments (directories or files inside the approved scope):

```bash
.apm/skills/smell-detector/scripts/detect.sh "$REPO_ROOT" "$PATTERN" src/auth/ src/auth/session.go
# prints: <file:line — pattern> per match, or "none"
```

Repeat for each pattern in `Fixed root causes`. The script is the source of truth — do not eyeball matches.

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
