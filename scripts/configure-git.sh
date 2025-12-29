#!/bin/bash
# Configure Git user settings for GitHub Actions

set -e

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
echo "✓ Git configured for GitHub Actions"

