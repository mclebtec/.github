#!/bin/bash
# Create a GitHub Release with links to artifacts in GCP Artifact Registry

set -e

if [ -z "${NEW_VERSION}" ]; then
  echo "::error::NEW_VERSION not set, cannot create release"
  exit 1
fi

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "::error::GITHUB_TOKEN not set, cannot create release"
  exit 1
fi

if [ -z "${GITHUB_REPOSITORY}" ]; then
  echo "::error::GITHUB_REPOSITORY not set"
  exit 1
fi

REPO_OWNER=$(echo "${GITHUB_REPOSITORY}" | cut -d'/' -f1)
REPO_NAME=$(echo "${GITHUB_REPOSITORY}" | cut -d'/' -f2)
TAG_NAME="v${NEW_VERSION}"

# Build release notes with artifact registry links
# Using a here-doc style approach that jq will handle correctly
RELEASE_NOTES_FILE=$(mktemp)
cat > "${RELEASE_NOTES_FILE}" <<EOF
## Release ${NEW_VERSION}

EOF

# Add Maven repository link if available
if [ -n "${REPO_URL}" ]; then
  cat >> "${RELEASE_NOTES_FILE}" <<EOF
### Maven Artifacts
Maven packages are available in GCP Artifact Registry:
- Repository: \`${REPO_URL}\`

EOF
  
  # Extract repository name from URL for a more readable link
  if echo "${REPO_URL}" | grep -q "artifactregistry.googleapis.com"; then
    REGION=$(echo "${REPO_URL}" | sed -n 's|.*//\([^.]*\)\.artifactregistry\.googleapis\.com.*|\1|p')
    REPO_PATH=$(echo "${REPO_URL}" | sed -n 's|.*maven/\([^/]*\)/.*|\1|p')
    cat >> "${RELEASE_NOTES_FILE}" <<EOF
View in [GCP Artifact Registry](https://console.cloud.google.com/artifacts/maven/${REGION}/${REPO_PATH})

EOF
  fi
fi

# Add Docker image link if available
if [ -n "${DOCKER_REGISTRY}" ] && [ -n "${DOCKER_REPOSITORY}" ]; then
  IMAGE_TAG="${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}:${NEW_VERSION}"
  cat >> "${RELEASE_NOTES_FILE}" <<EOF
### Docker Images
Docker images are available in GCP Artifact Registry:
- Image: \`${IMAGE_TAG}\`
- Pull command: \`docker pull ${IMAGE_TAG}\`

EOF
  
  # Extract registry info for console link
  if echo "${DOCKER_REGISTRY}" | grep -q "\.pkg\.dev"; then
    REGION=$(echo "${DOCKER_REGISTRY}" | sed -n 's|.*//\([^.]*\)\.pkg\.dev.*|\1|p')
    REPO_PATH=$(echo "${DOCKER_REGISTRY}" | sed -n 's|.*pkg\.dev/\([^/]*\)/\([^/]*\)/.*|\1/\2|p')
    REPO_NAME_ONLY=$(echo "${DOCKER_REGISTRY}" | sed -n 's|.*pkg\.dev/[^/]*/[^/]*/\([^/]*\)|\1|p')
    cat >> "${RELEASE_NOTES_FILE}" <<EOF
View in [GCP Artifact Registry](https://console.cloud.google.com/artifacts/docker/${REGION}/${REPO_PATH}/${REPO_NAME_ONLY})

EOF
  fi
fi

# Read the release notes content
RELEASE_NOTES=$(cat "${RELEASE_NOTES_FILE}")
rm -f "${RELEASE_NOTES_FILE}"

# Create the release using GitHub API
echo "Creating GitHub Release for tag ${TAG_NAME}..."

# Use jq to properly format JSON (available in GitHub Actions runners)
JSON_PAYLOAD=$(jq -n \
  --arg tag "${TAG_NAME}" \
  --arg name "Release ${NEW_VERSION}" \
  --arg body "${RELEASE_NOTES}" \
  '{tag_name: $tag, name: $name, body: $body, draft: false, prerelease: false}')

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases" \
  -d "${JSON_PAYLOAD}")

HTTP_CODE=$(echo "${RESPONSE}" | tail -n1)
BODY=$(echo "${RESPONSE}" | sed '$d')

if [ "${HTTP_CODE}" -eq 201 ]; then
  RELEASE_URL=$(echo "${BODY}" | grep -o '"html_url":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "✓ GitHub Release created successfully"
  echo "Release URL: ${RELEASE_URL}"
else
  echo "::error::Failed to create GitHub Release. HTTP ${HTTP_CODE}"
  echo "${BODY}"
  exit 1
fi

