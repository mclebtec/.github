#!/bin/bash
# Generate next version based on existing versions in Maven registry and git tags
# Checks both registry and git tags to determine the next version
# Outputs NEW_VERSION to GITHUB_ENV for use in subsequent steps

set -e

echo "Generating new version for master release..."

# Get groupId and artifactId from POM
GROUP_ID=$(mvn help:evaluate -Dexpression=project.groupId -q -DforceStdout 2>/dev/null || echo "")
ARTIFACT_ID=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout 2>/dev/null || echo "")

if [ -z "$GROUP_ID" ] || [ -z "$ARTIFACT_ID" ]; then
  echo "::warning::Could not extract groupId/artifactId from POM, falling back to git tags only"
  GROUP_ID=""
  ARTIFACT_ID=""
fi

# Get latest version from Maven registry if available
REGISTRY_VERSION=""
if [ -n "$GROUP_ID" ] && [ -n "$ARTIFACT_ID" ] && [ -n "${MAVEN_REPOSITORY_VAR}" ]; then
  echo "Checking existing versions in Maven registry..."
  REGISTRY_VERSION=$(bash .github/scripts/check-maven-versions.sh \
    "${GROUP_ID}" \
    "${ARTIFACT_ID}" \
    "${MAVEN_REPOSITORY_VAR}" \
    "${MAVEN_LOCATION_VAR:-us-central1}" 2>/dev/null | tail -1) || REGISTRY_VERSION=""
  
  if [ -n "$REGISTRY_VERSION" ] && [ "$REGISTRY_VERSION" != "No versions found in registry" ]; then
    echo "Latest version in registry: ${REGISTRY_VERSION}"
  else
    echo "No versions found in registry"
    REGISTRY_VERSION=""
  fi
fi

# Get the latest tag to determine next version
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
TAG_VERSION=""
if [ -n "${LATEST_TAG}" ]; then
  TAG_VERSION=$(echo "${LATEST_TAG}" | sed 's/^v//')
  echo "Latest version from git tag: ${TAG_VERSION}"
fi

# Determine which version to use as base (prefer registry over tag)
if [ -n "$REGISTRY_VERSION" ]; then
  LATEST_VERSION="$REGISTRY_VERSION"
  echo "Using registry version as base: ${LATEST_VERSION}"
elif [ -n "$TAG_VERSION" ]; then
  LATEST_VERSION="$TAG_VERSION"
  echo "Using git tag version as base: ${LATEST_VERSION}"
else
  # No versions found anywhere, start with 1.0.0
  NEW_VERSION="1.0.0"
  echo "No existing versions found, starting with version: ${NEW_VERSION}"
  export NEW_VERSION
  echo "NEW_VERSION=${NEW_VERSION}" >> $GITHUB_ENV
  echo "version=${NEW_VERSION}" >> $GITHUB_OUTPUT
  echo "✓ Generated version: ${NEW_VERSION}"
  exit 0
fi

# Increment patch version (e.g., 1.0.0 -> 1.0.1)
# Handle version format: MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-SUFFIX
BASE_VERSION=$(echo "${LATEST_VERSION}" | sed 's/-.*$//')
IFS='.' read -ra VERSION_PARTS <<< "${BASE_VERSION}"
MAJOR=${VERSION_PARTS[0]:-1}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# Increment patch version
PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

echo "Incremented version: ${LATEST_VERSION} -> ${NEW_VERSION}"

# Store version for use in next step and current shell session
export NEW_VERSION
echo "NEW_VERSION=${NEW_VERSION}" >> $GITHUB_ENV
echo "version=${NEW_VERSION}" >> $GITHUB_OUTPUT

echo "✓ Generated version: ${NEW_VERSION}"

