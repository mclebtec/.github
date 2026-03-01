#!/usr/bin/env bash
set -euo pipefail

# Resolve version and inject Helm values placeholders
# Usage: DOCKER_REGISTRY=... DOCKER_REPOSITORY=... IMAGE_TAG=... ./scripts/inject-helm-values.sh

IMAGE_TAG="${IMAGE_TAG:-}"
if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null || echo "1.0.0")
fi

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "NEW_VERSION=${IMAGE_TAG}" >> "$GITHUB_ENV"
fi

for f in $(find . -path '*/opt/helm/*' -type f \( -name 'values.yaml' -o -name 'Chart.yaml' \)); do
  sed -i "s|PLACEHOLDER_DOCKER_REGISTRY|${DOCKER_REGISTRY}|g" "$f"
  sed -i "s|PLACEHOLDER_DOCKER_REPOSITORY|${DOCKER_REPOSITORY}|g" "$f"
  sed -i "s|PLACEHOLDER_IMAGE_TAG|${IMAGE_TAG}|g" "$f"
done