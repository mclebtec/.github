#!/bin/bash
# Build and deploy Maven packages and Docker images for pull requests.
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

# Ensure Docker is authenticated before building native images
if [ -n "${DOCKER_REGISTRY}" ]; then
  echo "Authenticating Docker for registry: ${DOCKER_REGISTRY}"
  gcloud auth configure-docker "${DOCKER_REGISTRY}" --quiet

  INITIAL_TOKEN=$(gcloud auth print-access-token)
  if [ -z "$INITIAL_TOKEN" ]; then
    echo "::error::Failed to get access token for Docker login"
    exit 1
  fi

  printf '%s' "${INITIAL_TOKEN}" | docker login -u oauth2accesstoken --password-stdin "${DOCKER_REGISTRY}" || {
    echo "::error::Docker login failed"
    exit 1
  }
  echo "✓ Docker authenticated"
fi

echo "Deploying to repository: ${REPO_URL}"
echo "Using server ID: artifact-registry"

# Refresh access token and update settings.xml before deployment
ACCESS_TOKEN=$(gcloud auth print-access-token)
if [ -z "$ACCESS_TOKEN" ]; then
  echo "::error::Failed to get access token for deployment"
  exit 1
fi

export GCP_ACCESS_TOKEN="${ACCESS_TOKEN}"

if [ -n "${DOCKER_REGISTRY}" ]; then
  echo "Refreshing Docker authentication with fresh token..."
  printf '%s' "${ACCESS_TOKEN}" | docker login -u oauth2accesstoken --password-stdin "${DOCKER_REGISTRY}" || {
    echo "::error::Docker login refresh failed"
    exit 1
  }
  echo "✓ Docker authentication refreshed"
fi

# Update settings.xml with fresh token
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|<password>[^<]*</password>|<password>${ACCESS_TOKEN}</password>|" ~/.m2/settings.xml
else
  sed -i "s|<password>[^<]*</password>|<password>${ACCESS_TOKEN}</password>|" ~/.m2/settings.xml
fi

# Set version using versions:set plugin, then deploy
mvn versions:set -DnewVersion=${VERSION} -DprocessAllModules

# Verify settings.xml exists and has correct configuration
if [ ! -f ~/.m2/settings.xml ]; then
  echo "::error::settings.xml not found. Maven configuration may be missing."
  exit 1
fi

echo "Verifying Maven settings.xml configuration..."
grep -q "artifact-registry" ~/.m2/settings.xml || {
  echo "::error::Server ID 'artifact-registry' not found in settings.xml"
  exit 1
}

echo "Deployment configuration:"
echo "  Repository URL: ${REPO_URL}"
echo "  Server ID: artifact-registry"
echo "  Docker registry: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}"
echo "  Layout: default"
echo "  Docker image: JVM (-DskipImage=false, spring-boot-maven-plugin)"

mvn clean deploy \
  -Dmaven.javadoc.skip=true \
  -Dmaven.deploy.skip=false \
  -Ddeploy.skip=false \
  -Dmaven.deploy.plugin.skip=false \
  -Dorg.apache.maven.plugins.maven-deploy-plugin.skip=false \
  -DskipImage=false \
  -DaltDeploymentRepository=artifact-registry::default::${REPO_URL}

echo "✓ Maven packages and Docker images published successfully with version ${VERSION}"
