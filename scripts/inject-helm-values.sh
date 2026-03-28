#!/usr/bin/env bash
set -euo pipefail

# Resolve version and inject Helm values placeholders
# Usage: DOCKER_REGISTRY=... DOCKER_REPOSITORY=... IMAGE_TAG=... ./scripts/inject-helm-values.sh
#
# mc-common-helm dependency versions (mc-data, mc-presentation, mc-gateway):
#   1) If HELM_DATA_VERSION / HELM_PRESENTATION_VERSION / HELM_GATEWAY_VERSION is non-empty, use it (CI override).
#   2) Else read helm.mc.*.version from root pom.xml (POM_FILE, default ./pom.xml).
#   3) Else last-resort defaults (0.1.3 / 0.1.3 / 0.1.4).
#
# Note: GitHub Actions often passes empty vars; ${VAR:-default} would ignore pom — we only default when unset/empty after pom lookup.

# Read a single <helm.mc.*.version> property from the aggregator pom.xml
read_helm_mc_property_from_pom() {
  local tag="$1"
  local pom="${POM_FILE:-./pom.xml}"
  local v=""
  if [ ! -f "$pom" ]; then
    printf '%s' ""
    return
  fi
  if command -v mvn >/dev/null 2>&1; then
    v=$(mvn -f "$pom" help:evaluate -Dexpression="${tag}" -q -DforceStdout 2>/dev/null | tail -1 | tr -d '\r\n') || true
  fi
  if [ -z "$v" ] || [ "$v" = "null" ]; then
    v=$(grep "<${tag}>" "$pom" 2>/dev/null | head -1 | sed -E 's/^[[:space:]]*<[^>]+>([^<]+)<\/[^>]+>.*/\1/' | tr -d '\r\n')
  fi
  printf '%s' "$v"
}

resolve_helm_mc_version() {
  local env_val="$1"
  local pom_tag="$2"
  local fallback="$3"
  if [ -n "${env_val:-}" ]; then
    printf '%s' "$env_val"
    return
  fi
  local from_pom
  from_pom=$(read_helm_mc_property_from_pom "$pom_tag")
  if [ -n "$from_pom" ]; then
    printf '%s' "$from_pom"
    return
  fi
  printf '%s' "$fallback"
}

IMAGE_TAG="${IMAGE_TAG:-}"
if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null || echo "1.0.0")
fi

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "NEW_VERSION=${IMAGE_TAG}" >> "$GITHUB_ENV"
fi

# Replace placeholders (support both PLACEHOLDER_ and HELM_ prefixes for backward compatibility)
DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-}"
HELM_DOCKER_REGISTRY="${HELM_DOCKER_REGISTRY:-$DOCKER_REGISTRY}"
HELM_DOCKER_REPOSITORY="${HELM_DOCKER_REPOSITORY:-$DOCKER_REPOSITORY}"
HELM_IMAGE_TAG="${HELM_IMAGE_TAG:-$IMAGE_TAG}"

HELM_DATA_VERSION=$(resolve_helm_mc_version "${HELM_DATA_VERSION:-}" helm.mc.data.version 0.x.x)
HELM_PRESENTATION_VERSION=$(resolve_helm_mc_version "${HELM_PRESENTATION_VERSION:-}" helm.mc.presentation.version 0.x.x)
HELM_GATEWAY_VERSION=$(resolve_helm_mc_version "${HELM_GATEWAY_VERSION:-}" helm.mc.gateway.version 0.x.x)

echo "Helm mc-common-helm dependency versions: mc-data=${HELM_DATA_VERSION} mc-presentation=${HELM_PRESENTATION_VERSION} mc-gateway=${HELM_GATEWAY_VERSION}"

for f in $(find . -path '*/opt/helm/*' -type f \( -name 'values.yaml' -o -name 'Chart.yaml' \)); do
  sed -i "s|PLACEHOLDER_DOCKER_REGISTRY|${DOCKER_REGISTRY}|g" "$f"
  sed -i "s|PLACEHOLDER_DOCKER_REPOSITORY|${DOCKER_REPOSITORY}|g" "$f"
  sed -i "s|PLACEHOLDER_IMAGE_TAG|${IMAGE_TAG}|g" "$f"
  sed -i "s|HELM_DOCKER_REGISTRY|${HELM_DOCKER_REGISTRY}|g" "$f"
  sed -i "s|HELM_DOCKER_REPOSITORY|${HELM_DOCKER_REPOSITORY}|g" "$f"
  sed -i "s|HELM_IMAGE_TAG|${HELM_IMAGE_TAG}|g" "$f"
  sed -i "s|HELM_MC_DATA_VERSION|${HELM_DATA_VERSION}|g" "$f"
  sed -i "s|HELM_MC_PRESENTATION_VERSION|${HELM_PRESENTATION_VERSION}|g" "$f"
  sed -i "s|HELM_MC_GATEWAY_VERSION|${HELM_GATEWAY_VERSION}|g" "$f"
done

# Inject helm-dependencies.yaml and sync to Chart.yaml if it exists
DEPS_FILE="helm-dependencies.yaml"
if [ -f "$DEPS_FILE" ]; then
  sed -i "s|HELM_DATA_VERSION|${HELM_DATA_VERSION}|g" "$DEPS_FILE"
  sed -i "s|HELM_PRESENTATION_VERSION|${HELM_PRESENTATION_VERSION}|g" "$DEPS_FILE"
  sed -i "s|HELM_MC_DATA_VERSION|${HELM_DATA_VERSION}|g" "$DEPS_FILE"
  sed -i "s|HELM_MC_PRESENTATION_VERSION|${HELM_PRESENTATION_VERSION}|g" "$DEPS_FILE"
  sed -i "s|HELM_MC_GATEWAY_VERSION|${HELM_GATEWAY_VERSION}|g" "$DEPS_FILE"

  # Sync dependency versions from helm-dependencies.yaml to all Chart.yaml files
  DATA_VERSION=$(grep '^  mc-data:' "$DEPS_FILE" | sed -E 's/.*["'\'']([^"'\'']+)["'\''].*/\1/' | head -1)
  PRESENTATION_VERSION=$(grep '^  mc-presentation:' "$DEPS_FILE" | sed -E 's/.*["'\'']([^"'\'']+)["'\''].*/\1/' | head -1)

  if [ -n "$DATA_VERSION" ] && [ -n "$PRESENTATION_VERSION" ]; then
    echo "Syncing helm dependencies: mc-data=$DATA_VERSION, mc-presentation=$PRESENTATION_VERSION"
    while IFS= read -r -d '' chart; do
      if grep -q 'name: mc-data' "$chart"; then
        sed -i.bak -E "s/^(    version: \")[^\"]+/\1$DATA_VERSION/" "$chart" 2>/dev/null && rm -f "${chart}.bak" || true
      fi
      if grep -q 'name: mc-presentation' "$chart"; then
        sed -i.bak -E "s/^(    version: \")[^\"]+/\1$PRESENTATION_VERSION/" "$chart" 2>/dev/null && rm -f "${chart}.bak" || true
      fi
    done < <(find . -name "Chart.yaml" -print0)
  fi
fi