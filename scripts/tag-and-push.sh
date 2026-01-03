#!/bin/bash
# Create and push git tag with the specified version

set -e

if [ -z "${NEW_VERSION}" ]; then
  echo "::error::NEW_VERSION not set, cannot create tag"
  exit 1
fi

# Configure git authentication for GitHub Actions
# GITHUB_TOKEN is automatically available in GitHub Actions
if [ -z "${GITHUB_TOKEN}" ]; then
  echo "::error::GITHUB_TOKEN not set, cannot push tag"
  exit 1
fi

# Get the repository URL and configure it with the token for authentication
REMOTE_URL=$(git remote get-url origin)
# Handle HTTPS URLs (standard in GitHub Actions)
# Insert token after https:// to authenticate
if echo "${REMOTE_URL}" | grep -q "^https://"; then
  # Remove any existing authentication, then add token
  CLEAN_URL=$(echo "${REMOTE_URL}" | sed "s|https://[^@]*@|https://|")
  AUTH_URL="https://${GITHUB_TOKEN}@${CLEAN_URL#https://}"
else
  echo "::warning::Remote URL is not HTTPS format, attempting to use as-is"
  AUTH_URL="${REMOTE_URL}"
fi

# Store original URL and set authenticated URL
ORIGINAL_URL="${REMOTE_URL}"
git remote set-url origin "${AUTH_URL}"

echo "Creating git tag: v${NEW_VERSION}"
git tag -a "v${NEW_VERSION}" -m "Release version ${NEW_VERSION}"
git push origin "v${NEW_VERSION}"
echo "✓ Git tag v${NEW_VERSION} created and pushed"

# Restore original remote URL (remove token from URL for security)
git remote set-url origin "${ORIGINAL_URL}"

# Optional: Commit the version change back to master
# Uncomment the following lines if you want to commit POM version changes
# git add -A
# git commit -m "Bump version to ${NEW_VERSION}" || echo "No changes to commit"
# git push origin master

