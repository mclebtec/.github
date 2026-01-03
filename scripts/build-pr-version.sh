#!/bin/bash
# Build and deploy Maven packages for pull requests with custom version
# Version format: BASE_VERSION-SNAPSHOT-BRANCH_NAME-COMMIT_HASH

set -e

# Extract version from POM
BASE_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
echo "Base version from POM: ${BASE_VERSION}"

# Extract and sanitize branch name
BRANCH_NAME=${GITHUB_HEAD_REF}
SANITIZED_BRANCH=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
echo "Branch name: $BRANCH_NAME -> $SANITIZED_BRANCH"

# Extract commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "Commit hash: ${COMMIT_HASH}"

# Ensure commit hash is not empty
if [ -z "$COMMIT_HASH" ]; then
  COMMIT_HASH=$(git rev-parse --short HEAD)
fi

# Remove -SNAPSHOT if present, then add branch name and commit hash
VERSION=$(echo "${BASE_VERSION}" | sed 's/-SNAPSHOT$//')-SNAPSHOT-${SANITIZED_BRANCH}-${COMMIT_HASH}
echo "Setting version to: ${VERSION}"

# Verify REPO_URL is set
if [ -z "${REPO_URL}" ]; then
  echo "::error::REPO_URL not set, cannot deploy"
  exit 1
fi

echo "Deploying to repository: ${REPO_URL}"
echo "Using server ID: artifact-registry"

# Refresh access token and update settings.xml before deployment
# Tokens can expire, so refresh right before deployment
ACCESS_TOKEN=$(gcloud auth print-access-token)
if [ -z "$ACCESS_TOKEN" ]; then
  echo "::error::Failed to get access token for deployment"
  exit 1
fi

# Update settings.xml with fresh token
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|<password>[^<]*</password>|<password>${ACCESS_TOKEN}</password>|" ~/.m2/settings.xml
else
  sed -i "s|<password>[^<]*</password>|<password>${ACCESS_TOKEN}</password>|" ~/.m2/settings.xml
fi

# Set version using versions:set plugin, then deploy
mvn versions:set -DnewVersion=${VERSION} -DprocessAllModules
mvn clean deploy -DskipTests -Dmaven.javadoc.skip=true \
  -DaltDeploymentRepository=artifact-registry::default::${REPO_URL}

echo "✓ Maven packages deployed successfully with version ${VERSION}"

