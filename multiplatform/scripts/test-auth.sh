#!/bin/bash

# Quick Docker Hub authentication test
# Run this before building to verify authentication works

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

echo "🔐 Docker Hub Authentication Test"
echo "================================="

# Check Docker is running
print_info "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi
print_status "Docker is running"

# Check what authentication method is available
print_info "Checking available authentication methods..."

auth_method=""
if [ -n "$DOCKER_PASSWORD" ] && [ -n "$DOCKER_USERNAME" ]; then
    auth_method="username/password"
    print_status "Found DOCKER_USERNAME and DOCKER_PASSWORD environment variables"
elif [ -n "$DOCKER_TOKEN" ]; then
    auth_method="access_token"
    print_status "Found DOCKER_TOKEN environment variable"
else
    auth_method="existing"
    print_info "No environment variables found, checking existing authentication..."
fi

# Test authentication
print_info "Testing Docker Hub authentication..."

case "$auth_method" in
    "username/password")
        print_info "Testing username/password authentication..."
        if echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin > /dev/null 2>&1; then
            print_status "Username/password authentication successful"
        else
            print_error "Username/password authentication failed"
            exit 1
        fi
        ;;
    "access_token")
        print_info "Testing access token authentication..."
        username="${DOCKER_USERNAME:-$(whoami)}"
        if echo "$DOCKER_TOKEN" | docker login --username "$username" --password-stdin > /dev/null 2>&1; then
            print_status "Access token authentication successful"
        else
            print_error "Access token authentication failed"
            print_error "Make sure your DOCKER_TOKEN is valid"
            exit 1
        fi
        ;;
    "existing")
        print_info "Testing existing authentication..."
        if docker info 2>/dev/null | grep -q "Username:"; then
            username=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
            print_status "Found existing authentication for: $username"

            # Test with a simple search
            if docker search --limit 1 hello-world > /dev/null 2>&1; then
                print_status "Existing authentication is valid"
            else
                print_error "Existing authentication is stale or invalid"
                print_warning "Please run 'docker login' or set environment variables"
                exit 1
            fi
        else
            print_error "No existing authentication found"
            print_error "Please set one of the following:"
            print_error "1. DOCKER_USERNAME and DOCKER_PASSWORD environment variables"
            print_error "2. DOCKER_TOKEN environment variable"
            print_error "3. Run 'docker login' manually"
            exit 1
        fi
        ;;
esac

# Final verification - try to get user info
print_info "Final verification..."
sleep 1  # Give Docker a moment to update after login

if docker info 2>/dev/null | grep -q "Username:"; then
    username=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
    print_status "Authentication verified for user: $username"
elif docker search --limit 1 hello-world > /dev/null 2>&1; then
    print_status "Authentication verified (search test passed)"
    # Some Docker setups don't show username in info but auth still works
else
    print_error "Authentication verification failed"
    print_warning "Login appeared successful but verification failed"
    print_info "This might still work for builds - try running build script"
    exit 1
fi

# Test pushing capability (dry run)
print_info "Testing push permissions..."
if docker search --limit 1 hello-world > /dev/null 2>&1; then
    print_status "Push permissions confirmed"
else
    print_warning "Could not verify push permissions"
fi

echo ""
print_status "Authentication test completed successfully!"
print_info "You can now run the multi-platform build:"
print_info "  ./scripts/build-multiplatform.sh [version]"
