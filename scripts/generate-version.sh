#!/bin/bash
# Generate next version based on latest git tag
# Outputs NEW_VERSION to GITHUB_ENV for use in subsequent steps

set -e

echo "Generating new version for master release..."

# Get the latest tag to determine next version
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "${LATEST_TAG}" ]; then
  # No tags exist, start with 1.0.0
  NEW_VERSION="1.0.0"
  echo "No existing tags found, starting with version: ${NEW_VERSION}"
else
  # Extract version from tag (remove 'v' prefix if present)
  LATEST_VERSION=$(echo "${LATEST_TAG}" | sed 's/^v//')
  echo "Latest version: ${LATEST_VERSION}"
  
  # Increment patch version (e.g., 1.0.0 -> 1.0.1)
  IFS='.' read -ra VERSION_PARTS <<< "${LATEST_VERSION}"
  MAJOR=${VERSION_PARTS[0]:-1}
  MINOR=${VERSION_PARTS[1]:-0}
  PATCH=${VERSION_PARTS[2]:-0}
  
  # Increment patch version
  PATCH=$((PATCH + 1))
  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  echo "New version: ${NEW_VERSION}"
fi

# Store version for use in next step
echo "NEW_VERSION=${NEW_VERSION}" >> $GITHUB_ENV
echo "version=${NEW_VERSION}" >> $GITHUB_OUTPUT

echo "✓ Generated version: ${NEW_VERSION}"

