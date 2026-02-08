#!/bin/bash
# Build and deploy Maven packages and Docker images for master with auto-generated version

set -e

if [ -z "${NEW_VERSION}" ]; then
  echo "::error::NEW_VERSION not set, cannot build"
  exit 1
fi

if [ -z "${REPO_URL}" ]; then
  echo "::error::REPO_URL not set, cannot deploy"
  exit 1
fi

# Ensure Docker is authenticated before building
if [ -n "${DOCKER_REGISTRY}" ]; then
  echo "Authenticating Docker for registry: ${DOCKER_REGISTRY}"
  gcloud auth configure-docker "${DOCKER_REGISTRY}" --quiet
  
  # Get token and login explicitly
  INITIAL_TOKEN=$(gcloud auth print-access-token)
  if [ -z "$INITIAL_TOKEN" ]; then
    echo "::error::Failed to get access token for Docker login"
    exit 1
  fi
  
  # Use printf to avoid adding extra newline, and verify login succeeds
  printf '%s' "${INITIAL_TOKEN}" | docker login -u oauth2accesstoken --password-stdin "${DOCKER_REGISTRY}" || {
    echo "::error::Docker login failed"
    exit 1
  }
  echo "✓ Docker authenticated"
fi

# Set the new version in all POM files
echo "Setting version to ${NEW_VERSION} in all POM files..."
mvn versions:set -DnewVersion=${NEW_VERSION} -DprocessAllModules -DgenerateBackupPoms=false

# Build and deploy Maven packages and Docker images with the new version
echo "Building and publishing Docker images to ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}"
echo "Deploying Maven packages to repository: ${REPO_URL}"
echo "Using server ID: artifact-registry"

# Refresh access token and update settings.xml before deployment
# Tokens can expire, so refresh right before deployment
ACCESS_TOKEN=$(gcloud auth print-access-token)
if [ -z "$ACCESS_TOKEN" ]; then
  echo "::error::Failed to get access token for deployment"
  exit 1
fi

# Export access token as environment variable for Spring Boot Maven plugin
# The plugin expects GCP_ACCESS_TOKEN for publish.registry.password
export GCP_ACCESS_TOKEN="${ACCESS_TOKEN}"

# Refresh Docker authentication with fresh token right before Maven build
# The Spring Boot Maven plugin needs fresh Docker credentials
if [ -n "${DOCKER_REGISTRY}" ]; then
  echo "Refreshing Docker authentication with fresh token..."
  # Use printf to avoid adding extra newline, and verify login succeeds
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

# Override any skip configuration in the POM using system properties
# These properties override plugin configuration in pom.xml
mvn clean deploy \
  -DskipTests \
  -Dmaven.javadoc.skip=true \
  -Dmaven.deploy.skip=false \
  -Ddeploy.skip=false \
  -Dmaven.deploy.plugin.skip=false \
  -Dorg.apache.maven.plugins.maven-deploy-plugin.skip=false \
  -DskipImage=false \
  -DaltDeploymentRepository=artifact-registry::default::${REPO_URL}

echo "✓ Maven packages and Docker images published successfully with version ${NEW_VERSION}"

