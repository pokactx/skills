#!/usr/bin/env bash
# smell-detector scanner.
#
# Usage:
#   detect.sh <repo-root> <pattern> [exclude-path ...]
#
# Scans source files under <repo-root> for <pattern> (a basic regex, passed to
# ripgrep) and prints matches as:
#   <file:line> — <pattern>
# Matches whose file path is inside any <exclude-path> (the approved-scope
# paths) are filtered out so only out-of-scope occurrences are reported.
#
# Prints "none" when there are no matches. Exits 0 on success, non-zero on
# usage errors.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: detect.sh <repo-root> <pattern> [exclude-path ...]" >&2
  exit 2
fi

repo_root="$1"
pattern="$2"
shift 2
excludes=("$@")

if ! command -v rg >/dev/null 2>&1; then
  echo "detect: ripgrep (rg) is required but not found" >&2
  exit 3
fi

# Restrict to likely source files; skip common noise.
rg_args=(--no-heading --line-number --with-filename)
rg_args+=(--glob '!.git/**' --glob '!node_modules/**' --glob '!dist/**' --glob '!build/**' --glob '!vendor/**' --glob '!*.lock' --glob '!*.min.*')

# Normalize excludes to absolute paths for prefix-matching.
norm_excludes=()
for ex in "${excludes[@]:-}"; do
  [[ -z "$ex" ]] && continue
  if [[ "$ex" != /* ]]; then
    ex="${repo_root%/}/${ex}"
  fi
  norm_excludes+=("$ex")
done

raw=""
raw=$(rg "${rg_args[@]}" -- "$pattern" "$repo_root" 2>/dev/null || true)

emit=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  file="${line%%:*}"
  abs_file="$file"
  [[ "$abs_file" != /* ]] && abs_file="${repo_root%/}/${file}"
  skipped=0
  for ex in "${norm_excludes[@]:-}"; do
    [[ -z "$ex" ]] && continue
    if [[ "$abs_file" == "$ex" || "$abs_file" == "$ex"/* ]]; then
      skipped=1
      break
    fi
  done
  [[ "$skipped" -eq 1 ]] && continue
  rest="${line#*:}"
  lineno="${rest%%:*}"
  printf '%s:%s — %s\n' "$file" "$lineno" "$pattern"
  emit=1
done <<< "$raw"

if [[ -z "${emit:-}" ]]; then
  echo "none"
fi
