#!/usr/bin/env bash
set -euo pipefail

# Resolve version and inject Helm values placeholders
# Usage: DOCKER_REGISTRY=... DOCKER_REPOSITORY=... IMAGE_TAG=... ./scripts/inject-helm-values.sh
# Optional: HELM_DATA_VERSION, HELM_PRESENTATION_VERSION (default 0.1.3)

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
HELM_DATA_VERSION="${HELM_DATA_VERSION:-0.1.3}"
HELM_PRESENTATION_VERSION="${HELM_PRESENTATION_VERSION:-0.1.3}"

for f in $(find . -path '*/opt/helm/*' -type f \( -name 'values.yaml' -o -name 'Chart.yaml' \)); do
  sed -i "s|PLACEHOLDER_DOCKER_REGISTRY|${DOCKER_REGISTRY}|g" "$f"
  sed -i "s|PLACEHOLDER_DOCKER_REPOSITORY|${DOCKER_REPOSITORY}|g" "$f"
  sed -i "s|PLACEHOLDER_IMAGE_TAG|${IMAGE_TAG}|g" "$f"
  sed -i "s|HELM_DOCKER_REGISTRY|${HELM_DOCKER_REGISTRY}|g" "$f"
  sed -i "s|HELM_DOCKER_REPOSITORY|${HELM_DOCKER_REPOSITORY}|g" "$f"
  sed -i "s|HELM_IMAGE_TAG|${HELM_IMAGE_TAG}|g" "$f"
  sed -i "s|HELM_DATA_VERSION|${HELM_DATA_VERSION}|g" "$f"
  sed -i "s|HELM_PRESENTATION_VERSION|${HELM_PRESENTATION_VERSION}|g" "$f"
done

# Inject helm-dependencies.yaml and sync to Chart.yaml if it exists
DEPS_FILE="helm-dependencies.yaml"
if [ -f "$DEPS_FILE" ]; then
  sed -i "s|HELM_DATA_VERSION|${HELM_DATA_VERSION}|g" "$DEPS_FILE"
  sed -i "s|HELM_PRESENTATION_VERSION|${HELM_PRESENTATION_VERSION}|g" "$DEPS_FILE"

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