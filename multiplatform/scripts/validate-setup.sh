#!/bin/bash

# Test script to validate multi-platform build setup
# Run this before attempting the full build

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "🔍 Multi-platform Docker Build Setup Validation"
echo "================================================"

# Check Docker Desktop
print_info "Checking Docker Desktop..."
if docker info > /dev/null 2>&1; then
    print_status "Docker is running"
    docker_version=$(docker --version)
    print_info "  $docker_version"
else
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check buildx
print_info "Checking Docker buildx..."
if docker buildx version > /dev/null 2>&1; then
    print_status "Docker buildx is available"
    buildx_version=$(docker buildx version)
    print_info "  $buildx_version"
else
    print_error "Docker buildx is not available. Please update Docker Desktop."
    exit 1
fi

# Check available platforms
print_info "Checking available platforms..."
available_platforms=$(docker buildx ls | grep "docker" | awk '{print $3}')
print_info "  Available platforms: $available_platforms"

if echo "$available_platforms" | grep -q "linux/amd64" && echo "$available_platforms" | grep -q "linux/arm64"; then
    print_status "Both linux/amd64 and linux/arm64 platforms are available"
else
    print_warning "Not all required platforms are available. You may need to enable experimental features in Docker Desktop."
fi

# Check build context
print_info "Checking build context..."
if [ -f "../files/init-apt.sh" ]; then
    print_status "Build context is correct (files directory found)"
else
    print_error "Build context issue: files directory not found"
    print_info "  Current directory: $(pwd)"
    print_info "  Expected: files directory should be at ../files/"
    exit 1
fi

# Check required files
print_info "Checking required files..."
required_files=(
    "../files/init-apt.sh"
    "../files/postgres/postgresql.conf"
    "../files/postgres/pg_hba.conf"
    "../files/postgres/install-postgres.sh"
    "../files/conda/condarc"
    "../files/install-sshd.sh"
    "../files/install-quarto.sh"
    "../files/install-uv.sh"
    "../files/install-radiant.sh"
    "../files/install-hadoop.sh"
    "../files/scalable_analytics/core-site.xml"
    "../files/scalable_analytics/hdfs-site.xml"
    "../files/scalable_analytics/init-dfs.sh"
    "../files/scalable_analytics/start-dfs.sh"
    "../files/scalable_analytics/stop-dfs.sh"
    "../files/install-ohmyzsh.sh"
    "../files/start-container.sh"
    "../files/sshd/sshd_config"
    "../files/install-gh.sh"
    "../files/zsh/zshrc"
    "../files/zsh/p10k.zsh"
    "../files/zsh/usethis"
    "../files/zsh/interactive-usethis.sh"
    "../files/zsh/github.sh"
    "../files/zsh/scripts/radiant.sh"
    "../files/zsh/setup.sh"
    "../files/zsh/menu.sh"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    print_status "All required files are present"
else
    print_error "Missing ${#missing_files[@]} required files"
    exit 1
fi

# Check launch scripts
print_info "Checking platform-specific launch scripts..."
if [ -f "../launch-rsm-msba-k8s-arm.sh" ]; then
    print_status "ARM launch script found"
else
    print_error "ARM launch script not found: ../launch-rsm-msba-k8s-arm.sh"
fi

if [ -f "../launch-rsm-msba-k8s-intel.sh" ]; then
    print_status "Intel launch script found"
else
    print_error "Intel launch script not found: ../launch-rsm-msba-k8s-intel.sh"
fi

# Check disk space (rough estimate)
print_info "Checking available disk space..."
available_gb=$(df -g . | awk 'NR==2 {print $4}')
if [ "$available_gb" -gt 20 ]; then
    print_status "Sufficient disk space available (~${available_gb}GB free)"
else
    print_warning "Low disk space (~${available_gb}GB free). Large Docker builds may require 15-20GB."
fi

# Check Docker Hub authentication
print_info "Checking Docker Hub authentication..."
if docker info | grep -q "Username:"; then
    username=$(docker info | grep "Username:" | awk '{print $2}')
    print_status "Logged into Docker Hub as: $username"
else
    print_warning "Not logged into Docker Hub. Run 'docker login' before pushing images."
fi

echo ""
echo "🎯 Validation Summary"
echo "===================="
print_status "Setup validation completed successfully!"
print_info "You can now run the build script:"
print_info "  cd /Users/vnijs/gh/docker-k8s/multiplatform"
print_info "  ./scripts/build-multiplatform.sh [version]"
print_warning "Note: This is a large image build that may take 30-60 minutes"
print_warning "Ensure your Mac Studio has adequate cooling and power"
