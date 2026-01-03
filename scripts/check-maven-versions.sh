#!/bin/bash
# Check existing versions of a Maven artifact in GCP Artifact Registry
# Usage: check-maven-versions.sh <groupId> <artifactId> [repository] [location] [project]

set -e

GROUP_ID="${1}"
ARTIFACT_ID="${2}"
MAVEN_REPOSITORY="${3:-${MAVEN_REPOSITORY_VAR}}"
MAVEN_LOCATION="${4:-${MAVEN_LOCATION_VAR:-us-central1}}"
GCP_PROJECT="${5:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$GROUP_ID" ] || [ -z "$ARTIFACT_ID" ]; then
  echo "Usage: $0 <groupId> <artifactId> [repository] [location] [project]"
  exit 1
fi

if [ -z "$GCP_PROJECT" ] || [ -z "$MAVEN_REPOSITORY" ]; then
  echo "Error: GCP_PROJECT and MAVEN_REPOSITORY must be set or provided as arguments"
  exit 1
fi

# Extract just the repository name (remove any project prefix if present)
MAVEN_REPOSITORY=$(echo "${MAVEN_REPOSITORY}" | sed 's|^[^/]*/||')

echo "Checking versions for ${GROUP_ID}:${ARTIFACT_ID} in repository ${MAVEN_REPOSITORY}..."

# List all versions of the artifact from Artifact Registry
# Convert groupId to path (com.example -> com/example)
GROUP_PATH=$(echo "${GROUP_ID}" | tr '.' '/')

# Use gcloud to list packages - Maven packages are stored as:
# projects/{project}/locations/{location}/repositories/{repo}/packages/{groupId}/{artifactId}/{version}
PACKAGE_PATTERN="${GROUP_PATH}/${ARTIFACT_ID}"

# List all packages and filter for our groupId/artifactId, then extract versions
VERSIONS=$(gcloud artifacts packages list \
  --repository="${MAVEN_REPOSITORY}" \
  --location="${MAVEN_LOCATION}" \
  --project="${GCP_PROJECT}" \
  --format="value(name)" 2>/dev/null | \
  grep -E "/${PACKAGE_PATTERN}/" | \
  sed -E "s|.*/${ARTIFACT_ID}/([^/]+)$|\1|" | \
  grep -v "^$" | \
  sort -V 2>/dev/null || echo "") || true

if [ -z "$VERSIONS" ]; then
  echo "No versions found in registry"
  echo ""
  exit 0
fi

echo "Found versions in registry:"
echo "$VERSIONS" | while read -r version; do
  echo "  - ${version}"
done

# Get the latest version (highest version number)
LATEST_VERSION=$(echo "$VERSIONS" | tail -1)
echo ""
echo "Latest version in registry: ${LATEST_VERSION}"

# Output the latest version for use in other scripts
echo "${LATEST_VERSION}"

