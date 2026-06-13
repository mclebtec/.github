#!/usr/bin/env bash
# Format/check shell scripts with shfmt (-i 2 -ci -bn -sr).

set -euo pipefail

SHFMT_VERSION="3.10.0"
SHFMT_FLAGS=(-i 2 -ci -bn -sr)
MODE="apply"

for arg in "$@"; do
  case "${arg}" in
    --check) MODE="check" ;;
    -h | --help)
      echo "Usage: format-shell.sh [--check]"
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

ensure_shfmt() {
  if command -v shfmt >/dev/null 2>&1; then
    SHFMT_BIN="$(command -v shfmt)"
    return 0
  fi
  local cache="${HOME}/.cache/primecare-shfmt"
  local bin="${cache}/shfmt"
  if [[ -x "${bin}" ]]; then
    SHFMT_BIN="${bin}"
    return 0
  fi
  local os arch asset
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "${arch}" in
    x86_64) arch="amd64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)
      echo "Unsupported arch: ${arch}" >&2
      exit 1
      ;;
  esac
  asset="shfmt_v${SHFMT_VERSION}_${os}_${arch}"
  mkdir -p "${cache}"
  echo "Downloading shfmt ${SHFMT_VERSION}..."
  curl -fsSL "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/${asset}" -o "${bin}"
  chmod +x "${bin}"
  SHFMT_BIN="${bin}"
}

SHFMT_BIN=""
ensure_shfmt

SHELL_DIRS=()
for rel in scripts tools .github/scripts primecare-infra/scripts primecare-mock-domain/scripts; do
  [[ -d "${ROOT}/${rel}" ]] && SHELL_DIRS+=("${ROOT}/${rel}")
done

if [[ ${#SHELL_DIRS[@]} -eq 0 ]]; then
  echo "No shell script directories found."
  exit 0
fi

SHELL_FILES=()
while IFS= read -r file; do
  [[ -n "${file}" ]] && SHELL_FILES+=("${file}")
done < <(
  find "${SHELL_DIRS[@]}" -type f -name '*.sh' \
    ! -path '*/ios/*' \
    ! -name 'flutter_export_environment.sh' 2>/dev/null | sort
)

if [[ ${#SHELL_FILES[@]} -eq 0 ]]; then
  echo "No shell scripts found to format."
  exit 0
fi

if [[ "${MODE}" == "check" ]]; then
  echo "Checking shell formatting (shfmt) on ${#SHELL_FILES[@]} files..."
  "${SHFMT_BIN}" "${SHFMT_FLAGS[@]}" -l -d "${SHELL_FILES[@]}"
  echo "All shell scripts are formatted."
  exit 0
fi

echo "Formatting shell scripts (shfmt, ${#SHELL_FILES[@]} files)..."
"${SHFMT_BIN}" "${SHFMT_FLAGS[@]}" -w "${SHELL_FILES[@]}"
"${SHFMT_BIN}" "${SHFMT_FLAGS[@]}" -l -d "${SHELL_FILES[@]}"
echo "Shell formatting complete."
