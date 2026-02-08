#!/bin/bash
# Build and publish all Helm charts found in opt/helm directories
# This script:
# 1. Finds all Helm charts in opt/helm directories
# 2. Updates Helm dependencies (for parent common charts)
# 3. Packages charts as .tgz files
# 4. Pushes charts to GCP Artifact Registry
# 5. Optionally creates GitHub releases

set -euo pipefail

# Configuration - use environment variables from GitHub Actions
DOCKER_REGISTRY="${DOCKER_REGISTRY:-fake-registry.pkg.dev}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-fake-project/fake-repo}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-fake-project}"
CHART_VERSION="${CHART_VERSION:-0.1.0}"
APP_VERSION="${APP_VERSION:-${NEW_VERSION:-1.0.0}}"
PUSH_CHARTS="${PUSH_CHARTS:-true}"
CREATE_RELEASES="${CREATE_RELEASES:-false}"
HELM_SUFFIX="${HELM_SUFFIX:-helm}"

# Helm registry uses Docker registry for OCI charts
HELM_REGISTRY="${DOCKER_REGISTRY}"
PROJECT_ID="${GCP_PROJECT_ID}"
REPO_NAME="${DOCKER_REPOSITORY}"

# Full OCI registry URL for Helm charts
HELM_REPO_URL="${HELM_REGISTRY}/${PROJECT_ID}/${REPO_NAME}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Authenticate Helm to OCI registry
authenticate_helm() {
    print_info "Authenticating to GCP Artifact Registry..."
    if command -v gcloud &> /dev/null; then
        gcloud auth configure-docker "${HELM_REGISTRY}" --quiet || {
            print_warn "Failed to configure Docker authentication"
            return 1
        }
        gcloud auth print-access-token | helm registry login "${HELM_REGISTRY}" \
            --username oauth2accesstoken \
            --password-stdin || {
            print_warn "Failed to authenticate Helm to OCI registry"
            return 1
        }
        print_info "Helm authentication successful"
        return 0
    else
        print_error "gcloud CLI not found. Cannot authenticate to OCI registry."
        return 1
    fi
}

# Update Helm dependencies for a chart
update_chart_dependencies() {
    local chart_dir="$1"
    print_info "Updating dependencies for chart: ${chart_dir}"
    
    if [ ! -f "${chart_dir}/Chart.yaml" ]; then
        print_error "Chart.yaml not found in ${chart_dir}"
        return 1
    fi
    
    helm dependency update "${chart_dir}" || {
        print_error "Failed to update dependencies for ${chart_dir}"
        return 1
    }
    
    print_info "Dependencies updated successfully"
    return 0
}

# Package a Helm chart
package_chart() {
    local chart_dir="$1"
    local chart_name="$2"
    local chart_version="$3"
    local app_version="$4"
    
    print_info "Packaging chart: ${chart_name} (version: ${chart_version}, app: ${app_version})"
    
    # Update Chart.yaml versions if needed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i.bak "s/^version:.*/version: ${chart_version}/" "${chart_dir}/Chart.yaml"
        sed -i.bak "s/^appVersion:.*/appVersion: \"${app_version}\"/" "${chart_dir}/Chart.yaml"
        rm -f "${chart_dir}/Chart.yaml.bak"
    else
        sed -i "s/^version:.*/version: ${chart_version}/" "${chart_dir}/Chart.yaml"
        sed -i "s/^appVersion:.*/appVersion: \"${app_version}\"/" "${chart_dir}/Chart.yaml"
    fi
    
    # Package the chart
    helm package "${chart_dir}" --version "${chart_version}" --app-version "${app_version}" || {
        print_error "Failed to package chart: ${chart_name}"
        return 1
    }
    
    local chart_file="${chart_name}-${chart_version}.tgz"
    if [ ! -f "${chart_file}" ]; then
        print_error "Chart package not found: ${chart_file}"
        return 1
    fi
    
    print_info "Chart packaged: ${chart_file}"
    echo "${chart_file}"
}

# Push chart to OCI registry
push_chart() {
    local chart_file="$1"
    local helm_chart_name="$2"
    
    print_info "Pushing ${chart_file} to ${HELM_REPO_URL} as ${helm_chart_name}..."
    
    helm push "${chart_file}" "oci://${HELM_REPO_URL}/${helm_chart_name}" || {
        print_error "Failed to push chart: ${chart_file}"
        return 1
    }
    
    print_info "Successfully pushed ${helm_chart_name}:${CHART_VERSION}"
    echo "oci://${HELM_REPO_URL}/${helm_chart_name}:${CHART_VERSION}"
}

# Create GitHub release (optional)
create_github_release() {
    local chart_name="$1"
    local chart_file="$2"
    local chart_url="$3"
    
    if [ "${CREATE_RELEASES}" != "true" ]; then
        return 0
    fi
    
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        print_warn "GITHUB_TOKEN not set, skipping GitHub release creation"
        return 0
    fi
    
    print_info "Creating GitHub release for ${chart_name}..."
    
    # Extract repo owner and name from git remote
    local repo_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [ -z "${repo_url}" ]; then
        print_warn "Could not determine GitHub repository, skipping release"
        return 0
    fi
    
    # Create release using GitHub CLI or API
    if command -v gh &> /dev/null; then
        gh release create "helm-${chart_name}-${CHART_VERSION}" \
            "${chart_file}" \
            --title "Helm Chart ${chart_name} v${CHART_VERSION}" \
            --notes "Helm chart ${chart_name} version ${CHART_VERSION}

Chart URL: ${chart_url}
App Version: ${APP_VERSION}" || {
            print_warn "Failed to create GitHub release"
        }
    else
        print_warn "GitHub CLI (gh) not found, skipping release creation"
    fi
}

# Main function to process a Helm chart
process_chart() {
    local chart_dir="$1"
    local chart_name=$(basename "${chart_dir}")
    local helm_chart_name="${chart_name}-${HELM_SUFFIX}"
    
    print_section "Processing Chart: ${chart_name}"
    
    # Update dependencies
    if ! update_chart_dependencies "${chart_dir}"; then
        print_error "Skipping chart due to dependency update failure"
        return 1
    fi
    
    # Package chart
    local chart_file
    chart_file=$(package_chart "${chart_dir}" "${chart_name}" "${CHART_VERSION}" "${APP_VERSION}")
    if [ $? -ne 0 ]; then
        print_error "Skipping chart due to packaging failure"
        return 1
    fi
    
    # Push chart if enabled
    local chart_url=""
    if [ "${PUSH_CHARTS}" = "true" ]; then
        chart_url=$(push_chart "${chart_file}" "${helm_chart_name}")
        if [ $? -ne 0 ]; then
            print_error "Failed to push chart, but keeping .tgz file"
        fi
    else
        print_info "Skipping push (set PUSH_CHARTS=true to enable)"
    fi
    
    # Create GitHub release if enabled
    if [ -n "${chart_url}" ]; then
        create_github_release "${chart_name}" "${chart_file}" "${chart_url}"
    fi
    
    print_info "Completed processing: ${chart_name}"
    return 0
}

# Find all Helm charts
find_helm_charts() {
    local repo_root="${1:-.}"
    find "${repo_root}" -type f -path "*/opt/helm/*/Chart.yaml" | while read -r chart_yaml; do
        dirname "${chart_yaml}"
    done
}

# Main execution
main() {
    print_section "Helm Chart Build and Publish"
    print_info "Registry: ${HELM_REPO_URL}"
    print_info "Chart Version: ${CHART_VERSION}"
    print_info "App Version: ${APP_VERSION}"
    print_info "Push Charts: ${PUSH_CHARTS}"
    print_info "Create Releases: ${CREATE_RELEASES}"
    
    # Authenticate if pushing
    if [ "${PUSH_CHARTS}" = "true" ]; then
        if ! authenticate_helm; then
            print_error "Authentication failed. Cannot push charts."
            exit 1
        fi
    fi
    
    # Find and process all charts
    local repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    local charts_found=0
    local charts_success=0
    local charts_failed=0
    
    print_section "Finding Helm Charts"
    
    while IFS= read -r chart_dir; do
        if [ -z "${chart_dir}" ]; then
            continue
        fi
        
        charts_found=$((charts_found + 1))
        print_info "Found chart: ${chart_dir}"
    done < <(find_helm_charts "${repo_root}")
    
    if [ ${charts_found} -eq 0 ]; then
        print_warn "No Helm charts found in opt/helm directories"
        exit 0
    fi
    
    print_info "Found ${charts_found} Helm chart(s)"
    
    print_section "Processing Charts"
    
    while IFS= read -r chart_dir; do
        if [ -z "${chart_dir}" ]; then
            continue
        fi
        
        if process_chart "${chart_dir}"; then
            charts_success=$((charts_success + 1))
        else
            charts_failed=$((charts_failed + 1))
        fi
    done < <(find_helm_charts "${repo_root}")
    
    # Summary
    print_section "Summary"
    print_info "Total charts found: ${charts_found}"
    print_info "Successfully processed: ${charts_success}"
    if [ ${charts_failed} -gt 0 ]; then
        print_error "Failed: ${charts_failed}"
        exit 1
    fi
    
    print_info "All charts processed successfully!"
}

# Run main function
main "$@"
