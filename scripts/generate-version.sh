#!/bin/bash
# Generate next version based on latest git tag
# Outputs NEW_VERSION to GITHUB_ENV for use in subsequent steps

set -e

echo "Generating new version for master release..."

# Checkout often omits tags; fetch so we do not redeploy an immutable release (AR 400).
git fetch --tags --force origin 2>/dev/null || git fetch --tags --force 2>/dev/null || true

# Highest v* tag globally (not only tags reachable from HEAD).
LATEST_TAG=$(git tag -l 'v*' --sort=-v:refname 2>/dev/null | head -1 || true)

if [ -z "${LATEST_TAG}" ]; then
  NEW_VERSION="1.0.0"
  echo "No existing tags found, starting with version: ${NEW_VERSION}"
else
  echo "Latest git tag: ${LATEST_TAG}"
  # Extract version from tag (remove 'v' prefix if present)
  LATEST_VERSION=$(echo "${LATEST_TAG}" | sed 's/^v//')
  echo "Latest version: ${LATEST_VERSION}"

  # Increment patch version (e.g., 1.0.0 -> 1.0.1)
  IFS='.' read -ra VERSION_PARTS <<< "${LATEST_VERSION}"
  MAJOR=${VERSION_PARTS[0]:-1}
  MINOR=${VERSION_PARTS[1]:-0}
  PATCH=${VERSION_PARTS[2]:-0}

  PATCH=$((PATCH + 1))
  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  echo "New version: ${NEW_VERSION}"
fi

# Fallback when deploy succeeded but tag-and-push failed (no git tag, version already in AR).
if [ "${NEW_VERSION}" = "1.0.0" ] && command -v gcloud >/dev/null 2>&1; then
  GCP_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
  MAVEN_REPO="${MAVEN_REPOSITORY_VAR:-${MAVEN_REPOSITORY:-}}"
  MAVEN_REPO=$(echo "${MAVEN_REPO}" | sed 's|^[^/]*/||')
  MAVEN_LOC="${MAVEN_LOCATION_VAR:-${MAVEN_LOCATION:-}}"
  if [ -z "${MAVEN_LOC}" ] && [ -n "${REPO_URL:-}" ]; then
    MAVEN_LOC=$(echo "${REPO_URL}" | sed -n 's|https://\([^.]*\)-maven\.pkg\.dev/.*|\1|p')
  fi
  MAVEN_LOC="${MAVEN_LOC:-us-central1}"
  if [ -n "${GCP_PROJECT}" ] && [ -n "${MAVEN_REPO}" ]; then
    if gcloud artifacts versions list \
      --package="com.mclebtec:primecare-domain" \
      --repository="${MAVEN_REPO}" \
      --location="${MAVEN_LOC}" \
      --project="${GCP_PROJECT}" \
      --format='value(name)' 2>/dev/null \
      | grep -qE '/1\.0\.0$'; then
      echo "Maven AR already has primecare-domain:1.0.0 (tag missing); bumping to 1.0.1"
      NEW_VERSION="1.0.1"
    fi
  fi
fi

export NEW_VERSION
echo "NEW_VERSION=${NEW_VERSION}" >> $GITHUB_ENV
echo "version=${NEW_VERSION}" >> $GITHUB_OUTPUT

echo "✓ Generated version: ${NEW_VERSION}"
