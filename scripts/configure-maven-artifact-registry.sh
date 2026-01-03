#!/bin/bash
# Configure Maven settings.xml for GCP Artifact Registry
# Outputs repository-url to GITHUB_OUTPUT

set -e

mkdir -p ~/.m2

# Get GCP project from gcloud config (set during authentication)
GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
MAVEN_REPOSITORY="${MAVEN_REPOSITORY_VAR}"
# Default location to us-central1 (can be overridden by setting MAVEN_LOCATION_VAR)
MAVEN_LOCATION="${MAVEN_LOCATION_VAR:-us-central1}"

# Extract just the repository name (remove any project prefix if present)
# Repository name should be just the repository, not project/repository
MAVEN_REPOSITORY=$(echo "${MAVEN_REPOSITORY}" | sed 's|^[^/]*/||')

if [ -z "$GCP_PROJECT" ] || [ -z "$MAVEN_REPOSITORY" ]; then
  echo "Error: GCP_PROJECT and MAVEN_REPOSITORY must be set"
  exit 1
fi

echo "Using GCP Project: ${GCP_PROJECT}"
echo "Using Maven Repository: ${MAVEN_REPOSITORY}"
echo "Using Location: ${MAVEN_LOCATION}"

# Generate Maven settings using gcloud and extract only XML content
# gcloud outputs XML plus instructions, so we extract only the <settings>...</settings> block
TEMP_SETTINGS=$(mktemp)
if ! gcloud artifacts print-settings mvn \
  --project=${GCP_PROJECT} \
  --repository=${MAVEN_REPOSITORY} \
  --location=${MAVEN_LOCATION} 2>&1 | \
  sed -n '/^<settings/,/^<\/settings>/p' > ${TEMP_SETTINGS}; then
  echo "::error::Failed to configure Maven for Artifact Registry"
  echo "::error::Service account needs 'Artifact Registry Writer' role (roles/artifactregistry.writer)"
  SERVICE_ACCOUNT=$(gcloud config get-value account 2>/dev/null || echo "unknown")
  echo "::error::Current service account: ${SERVICE_ACCOUNT}"
  echo "::error::Grant permission with:"
  echo "::error::  gcloud artifacts repositories add-iam-policy-binding ${MAVEN_REPOSITORY} \\"
  echo "::error::    --location=${MAVEN_LOCATION} \\"
  echo "::error::    --member=serviceAccount:${SERVICE_ACCOUNT} \\"
  echo "::error::    --role=roles/artifactregistry.writer"
  rm -f ${TEMP_SETTINGS}
  exit 1
fi

# Update server ID to 'artifact-registry' to match build scripts
# This ensures the server ID in -DaltDeploymentRepository matches settings.xml
# Replace the server ID (typically the repository name) with 'artifact-registry'
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS uses BSD sed (requires empty string after -i)
  sed -i '' 's/\(<id>\)[^<]*\(<\/id>\)/\1artifact-registry\2/' ${TEMP_SETTINGS}
else
  # Linux uses GNU sed
  sed -i 's/\(<id>\)[^<]*\(<\/id>\)/\1artifact-registry\2/' ${TEMP_SETTINGS}
fi
mv ${TEMP_SETTINGS} ~/.m2/settings.xml

# Construct repository URL: https://{location}-maven.pkg.dev/{project}/{repository}
REPO_URL="https://${MAVEN_LOCATION}-maven.pkg.dev/${GCP_PROJECT}/${MAVEN_REPOSITORY}"
echo "repository-url=${REPO_URL}" >> $GITHUB_OUTPUT
echo "✓ Maven repository URL: ${REPO_URL}"
echo "✓ Maven settings.xml configured successfully"

