#!/usr/bin/env bash
# Sync reusable lint configs from sibling cursor-rules into mclebtec/.github/config/
# Does NOT copy rules/, structure/, storage/, or anything with secrets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FORBIDDEN_PATHS=(
  ".env"
  "credentials.json"
  "*.pem"
  "*.p12"
  "id_rsa"
  "id_rsa.pub"
)

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

echo "Scanning cursor-rules for forbidden patterns before sync..."
if rg -l --glob '!*.md' -i 'BEGIN (RSA |OPENSSH |EC )PRIVATE|ghp_[a-zA-Z0-9]{20,}|sk_live_|xox[baprs]-' \
  "${RULES_ROOT}/config" 2>/dev/null; then
  echo "Abort: possible secret material under cursor-rules/config" >&2
  exit 1
fi

for name in markdown shell terraform; do
  rsync -a --delete \
    --exclude='README.md' \
    "${RULES_ROOT}/config/${name}/" "${GITHUB_ROOT}/config/${name}/"
  echo "Synced config/${name}/ (configs only, README preserved in .github)"
done

echo "Done. Review git diff — then commit and push mclebtec/.github."
