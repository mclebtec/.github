#!/bin/bash
# Configure Docker authentication for GCP Artifact Registry

set -e

if [ -z "${DOCKER_REGISTRY}" ]; then
  echo "::error::DOCKER_REGISTRY not set"
  exit 1
fi

echo "Configuring Docker authentication for image publishing..."
gcloud auth configure-docker "${DOCKER_REGISTRY}" --quiet

# Also do explicit docker login with access token for Spring Boot Maven plugin
# The Spring Boot plugin sometimes doesn't use the credential helper properly
echo "Performing explicit Docker login..."
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin "${DOCKER_REGISTRY}"

echo "✓ Docker authenticated for registry: ${DOCKER_REGISTRY}"

