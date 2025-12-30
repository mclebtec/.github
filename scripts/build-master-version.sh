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

# Set the new version in all POM files
echo "Setting version to ${NEW_VERSION} in all POM files..."
mvn versions:set -DnewVersion=${NEW_VERSION} -DprocessAllModules -DgenerateBackupPoms=false

# Build and deploy Maven packages and Docker images with the new version
echo "Building and publishing Docker images to ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}"

# mvn clean deploy -Pdocker-build -DskipTests -Dmaven.javadoc.skip=true -Ddocker.publish=true \
#   -DaltDeploymentRepository=artifact-registry::default::${REPO_URL}

mvn clean deploy -Pdocker-build -DskipTests -Dmaven.javadoc.skip=true \
  -DaltDeploymentRepository=artifact-registry::default::${REPO_URL}  

echo "✓ Maven packages and Docker images published successfully with version ${NEW_VERSION}"

