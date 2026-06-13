#!/usr/bin/env bash
# CI lint bundle — mirrors cursor-rules/config/markdown (public mclebtec/.github).

set -euo pipefail

PRETTIER_VERSION="3.5.3"
MODE="apply"
BUNDLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for arg in "$@"; do
  case "${arg}" in
    --check) MODE="check" ;;
    -h | --help)
      echo "Usage: format-markdown.sh [--check]"
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 1
      ;;
  esac
done

if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "Run from a consumer git repository." >&2
  exit 1
fi

CONFIG="${BUNDLE_ROOT}/config/markdown/prettier.config.mjs"
IGNORE="${BUNDLE_ROOT}/config/markdown/.prettierignore"

if [[ ! -f "${CONFIG}" ]]; then
  echo "Missing ${CONFIG}" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "npx not found — install Node.js" >&2
  exit 1
fi

cd "${ROOT}"
PRETTIER=(npx --yes "prettier@${PRETTIER_VERSION}" --config "${CONFIG}" --ignore-path "${IGNORE}")

if [[ "${MODE}" == "check" ]]; then
  echo "Checking Markdown formatting (Prettier) in ${ROOT}..."
  "${PRETTIER[@]}" --check "**/*.md"
  echo "All Markdown files are formatted."
  exit 0
fi

echo "Formatting Markdown (Prettier) in ${ROOT}..."
"${PRETTIER[@]}" --write "**/*.md"
echo "Markdown formatting complete."
