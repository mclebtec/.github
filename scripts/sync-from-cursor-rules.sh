#!/usr/bin/env bash
# Sync reusable lint configs from sibling cursor-rules into mclebtec/.github/config/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

resolve_cursor_rules() {
  local candidate
  for candidate in \
    "${GITHUB_ROOT}/../cursor-rules" \
    "${CURSOR_RULES_ROOT:-}"; do
    [[ -n "${candidate}" && -d "${candidate}/config/markdown" ]] || continue
    echo "$(cd "${candidate}" && pwd)"
    return 0
  done
  echo "cursor-rules not found — set CURSOR_RULES_ROOT or clone ../cursor-rules" >&2
  return 1
}

RULES_ROOT="$(resolve_cursor_rules)"

for name in markdown shell terraform; do
  rsync -a --delete "${RULES_ROOT}/config/${name}/" "${GITHUB_ROOT}/config/${name}/"
  echo "Synced config/${name}/"
done

echo "Done. Commit and push mclebtec/.github."
