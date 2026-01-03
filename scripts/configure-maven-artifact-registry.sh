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

# Verify authentication and get access token
ACCESS_TOKEN=$(gcloud auth print-access-token)
if [ -z "$ACCESS_TOKEN" ]; then
  echo "::error::Failed to get access token. Ensure authentication is configured."
  exit 1
fi

# Verify repository exists and we have access
if ! gcloud artifacts repositories describe ${MAVEN_REPOSITORY} \
  --project=${GCP_PROJECT} \
  --location=${MAVEN_LOCATION} > /dev/null 2>&1; then
  echo "::error::Repository ${MAVEN_REPOSITORY} not found or not accessible"
  echo "::error::Service account needs 'Artifact Registry Writer' role (roles/artifactregistry.writer)"
  SERVICE_ACCOUNT=$(gcloud config get-value account 2>/dev/null || echo "unknown")
  echo "::error::Current service account: ${SERVICE_ACCOUNT}"
  echo "::error::Grant permission with:"
  echo "::error::  gcloud artifacts repositories add-iam-policy-binding ${MAVEN_REPOSITORY} \\"
  echo "::error::    --location=${MAVEN_LOCATION} \\"
  echo "::error::    --member=serviceAccount:${SERVICE_ACCOUNT} \\"
  echo "::error::    --role=roles/artifactregistry.writer"
  exit 1
fi

# Create Maven settings.xml with OAuth token authentication
# This matches the pattern used in maven-deploy action for GitHub Actions compatibility
cat > ~/.m2/settings.xml <<EOF
<settings>
  <servers>
    <server>
      <id>artifact-registry</id>
      <username>oauth2accesstoken</username>
      <password>${ACCESS_TOKEN}</password>
      <configuration>
        <httpConfiguration>
          <get>
            <usePreemptive>true</usePreemptive>
          </get>
          <head>
            <usePreemptive>true</usePreemptive>
          </head>
          <put>
            <params>
              <property>
                <name>http.protocol.expect-continue</name>
                <value>false</value>
              </property>
            </params>
          </put>
        </httpConfiguration>
      </configuration>
    </server>
  </servers>
</settings>
EOF

# Construct repository URL: https://{location}-maven.pkg.dev/{project}/{repository}
REPO_URL="https://${MAVEN_LOCATION}-maven.pkg.dev/${GCP_PROJECT}/${MAVEN_REPOSITORY}"
echo "repository-url=${REPO_URL}" >> $GITHUB_OUTPUT
echo "✓ Maven repository URL: ${REPO_URL}"
echo "✓ Maven settings.xml configured successfully"

