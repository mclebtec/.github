#!/bin/bash
# Configure Docker authentication for GCP Artifact Registry

set -e

if [ -z "${DOCKER_REGISTRY}" ]; then
  echo "::error::DOCKER_REGISTRY not set"
  exit 1
fi

echo "Configuring Docker authentication for image publishing..."
gcloud auth configure-docker "${DOCKER_REGISTRY}" --quiet
echo "✓ Docker authenticated for registry: ${DOCKER_REGISTRY}"

