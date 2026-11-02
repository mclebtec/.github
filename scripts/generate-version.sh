#!/bin/bash
# Generate next version based on latest git tag
# Outputs NEW_VERSION to GITHUB_ENV for use in subsequent steps
#
# Also skips versions already present in Artifact Registry (immutable releases).
# That covers the case where Maven/Docker deploy succeeded but tag-and-push failed
# (AR 400 on redeploy of the same semver).

set -e

echo "Generating new version for master release..."

# Checkout often omits tags; fetch so we do not redeploy an immutable release (AR 400).
git fetch --tags --force origin 2>/dev/null || git fetch --tags --force 2>/dev/null || true

# Highest v* tag globally (not only tags reachable from HEAD).
LATEST_TAG=$(git tag -l 'v*' --sort=-v:refname 2>/dev/null | head -1 || true)

if [ -z "${LATEST_TAG}" ]; then
  NEW_VERSION="1.0.0"
  echo "No existing git tags found, starting with version: ${NEW_VERSION}"
else
  echo "Latest git tag: ${LATEST_TAG}"
  LATEST_VERSION=$(echo "${LATEST_TAG}" | sed 's/^v//')
  echo "Latest version: ${LATEST_VERSION}"

  IFS='.' read -ra VERSION_PARTS <<<"${LATEST_VERSION}"
  MAJOR=${VERSION_PARTS[0]:-1}
  MINOR=${VERSION_PARTS[1]:-0}
  PATCH=${VERSION_PARTS[2]:-0}

  PATCH=$((PATCH + 1))
  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  echo "Candidate version from tags: ${NEW_VERSION}"
fi

maven_ar_has_version() {
  local version="$1"
  if ! command -v gcloud >/dev/null 2>&1; then
    return 1
  fi

  local gcp_project
  gcp_project=$(gcloud config get-value project 2>/dev/null || true)
  local maven_repo="${MAVEN_REPOSITORY_VAR:-${MAVEN_REPOSITORY:-}}"
  # Allow "project/repo" or bare repo id.
  maven_repo=$(echo "${maven_repo}" | sed 's|^[^/]*/||')
  local maven_loc="${MAVEN_LOCATION_VAR:-${MAVEN_LOCATION:-}}"
  if [ -z "${maven_loc}" ] && [ -n "${REPO_URL:-}" ]; then
    maven_loc=$(echo "${REPO_URL}" | sed -n 's|https://\([^.]*\)-maven\.pkg\.dev/.*|\1|p')
  fi
  maven_loc="${maven_loc:-africa-south1}"

  # Parent POM coordinates for primecare-domain (override via MAVEN_AR_PACKAGE).
  local package="${MAVEN_AR_PACKAGE:-com.mclebtec.primecare:primecare-domain}"

  if [ -z "${gcp_project}" ] || [ -z "${maven_repo}" ]; then
    return 1
  fi

  gcloud artifacts versions list \
    --package="${package}" \
    --repository="${maven_repo}" \
    --location="${maven_loc}" \
    --project="${gcp_project}" \
    --format='value(name)' 2>/dev/null |
    grep -qE "/${version//./\\.}$"
}

# Bump until the version is free in git tags and Artifact Registry.
MAX_BUMPS=50
bumps=0
while [ "${bumps}" -lt "${MAX_BUMPS}" ]; do
  if git rev-parse "v${NEW_VERSION}" >/dev/null 2>&1; then
    echo "Git tag v${NEW_VERSION} already exists; bumping patch"
  elif maven_ar_has_version "${NEW_VERSION}"; then
    echo "Maven AR already has ${NEW_VERSION}; bumping patch (avoids deploy 400)"
  else
    break
  fi
  IFS='.' read -ra VERSION_PARTS <<<"${NEW_VERSION}"
  MAJOR=${VERSION_PARTS[0]:-1}
  MINOR=${VERSION_PARTS[1]:-0}
  PATCH=${VERSION_PARTS[2]:-0}
  PATCH=$((PATCH + 1))
  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  bumps=$((bumps + 1))
done

if [ "${bumps}" -ge "${MAX_BUMPS}" ]; then
  echo "::error::Could not find a free Maven version after ${MAX_BUMPS} bumps"
  exit 1
fi

export NEW_VERSION
echo "NEW_VERSION=${NEW_VERSION}" >>$GITHUB_ENV
echo "version=${NEW_VERSION}" >>$GITHUB_OUTPUT

echo "✓ Generated version: ${NEW_VERSION}"
