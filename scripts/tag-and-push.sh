#!/bin/bash
# Create and push git tag with the specified version

set -e

if [ -z "${NEW_VERSION}" ]; then
  echo "::error::NEW_VERSION not set, cannot create tag"
  exit 1
fi

echo "Creating git tag: v${NEW_VERSION}"
git tag -a "v${NEW_VERSION}" -m "Release version ${NEW_VERSION}"
git push origin "v${NEW_VERSION}"
echo "✓ Git tag v${NEW_VERSION} created and pushed"

# Optional: Commit the version change back to master
# Uncomment the following lines if you want to commit POM version changes
# git add -A
# git commit -m "Bump version to ${NEW_VERSION}" || echo "No changes to commit"
# git push origin master

