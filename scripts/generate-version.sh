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

# Parent POM Maven path under Artifact Registry (override via MAVEN_AR_GROUP_PATH / MAVEN_AR_ARTIFACT).
MAVEN_AR_GROUP_PATH="${MAVEN_AR_GROUP_PATH:-com/mclebtec/primecare}"
MAVEN_AR_ARTIFACT="${MAVEN_AR_ARTIFACT:-primecare-domain}"

maven_ar_has_version() {
  local version="$1"

  if ! command -v gcloud >/dev/null 2>&1; then
    echo "AR check skipped for ${version}: gcloud not available"
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "AR check skipped for ${version}: curl not available"
    return 1
  fi

  local repo_url="${REPO_URL:-}"
  if [ -z "${repo_url}" ]; then
    local maven_repo="${MAVEN_REPOSITORY_VAR:-${MAVEN_REPOSITORY:-}}"
    maven_repo=$(echo "${maven_repo}" | sed 's|^[^/]*/||')
    local maven_loc="${MAVEN_LOCATION_VAR:-${MAVEN_LOCATION:-}}"
    if [ -z "${maven_loc}" ]; then
      maven_loc="africa-south1"
    fi
    local gcp_project
    gcp_project=$(gcloud config get-value project 2>/dev/null || true)
    if [ -n "${gcp_project}" ] && [ -n "${maven_repo}" ]; then
      repo_url="https://${maven_loc}-maven.pkg.dev/${gcp_project}/${maven_repo}"
    fi
  fi
  repo_url="${repo_url%/}"

  if [ -z "${repo_url}" ]; then
    echo "AR check skipped for ${version}: REPO_URL / Maven repo not set"
    return 1
  fi

  local token
  token=$(gcloud auth print-access-token 2>/dev/null || true)
  if [ -z "${token}" ]; then
    echo "AR check skipped for ${version}: could not get access token"
    return 1
  fi

  # Probe the exact artifact Maven would overwrite (matches deploy 400 path).
  local pom_url="${repo_url}/${MAVEN_AR_GROUP_PATH}/${MAVEN_AR_ARTIFACT}/${version}/${MAVEN_AR_ARTIFACT}-${version}.pom"
  local code
  code=$(
    curl -sS -o /dev/null -w '%{http_code}' \
      -H "Authorization: Bearer ${token}" \
      "${pom_url}" 2>/dev/null || echo "000"
  )
  echo "AR probe ${pom_url} -> HTTP ${code}"
  if [ "${code}" = "200" ]; then
    return 0
  fi
  return 1
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
