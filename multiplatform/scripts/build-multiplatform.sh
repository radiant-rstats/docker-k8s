#!/bin/bash

# Multi-platform Docker build script for Mac Studio
# This script builds and pushes multi-platform Docker images locally

set -e

# Configuration
IMAGE_NAME="radiant-rstats/rsm-msba-k8s"
VERSION="${1:-latest}"
PLATFORMS="linux/amd64,linux/arm64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Docker authentication function (based on build-images.sh)
docker_login() {
    echo "Checking Docker Hub authentication..."

    if [ -n "$DOCKER_PASSWORD" ] && [ -n "$DOCKER_USERNAME" ]; then
        print_status "Logging in to Docker Hub using environment variables..."
        if echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin; then
            print_status "Successfully authenticated with username/password"
            return 0
        else
            print_error "Failed to authenticate with username/password"
            return 1
        fi
    elif [ -n "$DOCKER_TOKEN" ]; then
        print_status "Logging in to Docker Hub using access token..."
        if echo "$DOCKER_TOKEN" | docker login --username "${DOCKER_USERNAME:-$(whoami)}" --password-stdin; then
            print_status "Successfully authenticated with access token"
            return 0
        else
            print_error "Failed to authenticate with access token"
            return 1
        fi
    else
        # Test if already authenticated by trying to access user info
        print_status "Testing existing Docker authentication..."
        if docker info 2>/dev/null | grep -q "Username:"; then
            username=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
            print_status "Already authenticated as: $username"

            # Double-check by trying to search (this requires auth)
            if docker search --limit 1 hello-world &>/dev/null; then
                print_status "Authentication confirmed - can access Docker Hub"
                return 0
            else
                print_warning "Authentication appears stale - re-authentication needed"
            fi
        fi

        print_error "Docker Hub authentication required but no credentials provided."
        print_error "Please set one of the following:"
        print_error "1. DOCKER_USERNAME and DOCKER_PASSWORD environment variables"
        print_error "2. DOCKER_TOKEN environment variable with your access token"
        print_error ""
        print_error "Example:"
        print_error "  export DOCKER_TOKEN=your_docker_hub_token"
        print_error "  ./scripts/build-multiplatform.sh"
        print_error ""
        print_error "Or run 'docker login' manually first"
        return 1
    fi
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check if buildx is available
if ! docker buildx version > /dev/null 2>&1; then
    print_error "Docker buildx is not available. Please update Docker Desktop."
    exit 1
fi

# Test Docker Hub authentication BEFORE starting build
print_status "Verifying Docker Hub authentication..."
if ! docker_login; then
    print_error "Docker Hub authentication failed. Build aborted."
    print_warning "Set DOCKER_TOKEN environment variable or run 'docker login' manually"
    exit 1
fi
print_status "Docker Hub authentication verified ✓"

print_status "Starting multi-platform build for $IMAGE_NAME:$VERSION"
print_status "Platforms: $PLATFORMS"

# Create a new builder instance if it doesn't exist
BUILDER_NAME="multiplatform-builder"
if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
    print_status "Creating new buildx builder: $BUILDER_NAME"
    docker buildx create --name "$BUILDER_NAME" --driver docker-container --use
else
    print_status "Using existing buildx builder: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

# Bootstrap the builder (this may take a moment)
print_status "Bootstrapping builder..."
docker buildx inspect --bootstrap

# Build context check
if [ ! -f "../files/init-apt.sh" ]; then
    print_error "Build context issue: files directory not found relative to multiplatform folder"
    print_warning "Make sure you're running this script from the multiplatform directory"
    print_warning "And that the files directory exists in the parent directory"
    exit 1
fi

# Start the build
print_status "Building multi-platform image..."
print_warning "This is a large image and may take 30-60 minutes to build"

# Build command with timing
start_time=$(date +%s)

docker buildx build \
    --platform "$PLATFORMS" \
    --tag "$IMAGE_NAME:$VERSION" \
    --tag "$IMAGE_NAME:latest" \
    --build-arg DOCKERHUB_VERSION="$VERSION" \
    --no-cache \
    --push \
    --progress=plain \
    -f Dockerfile \
    ..

build_status=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $build_status -eq 0 ]; then
    print_status "Build completed successfully!"
    print_status "Build duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
    print_status "Image pushed to: $IMAGE_NAME:$VERSION"
    print_status "Image pushed to: $IMAGE_NAME:latest"

    # Show image details
    print_status "Inspecting multi-platform manifest..."
    docker buildx imagetools inspect "$IMAGE_NAME:$VERSION"
else
    print_error "Build failed with exit code $build_status"
    exit $build_status
fi

print_status "Multi-platform build process completed!"
print_status "You can now run: docker run --platform linux/amd64 $IMAGE_NAME:$VERSION"
print_status "Or: docker run --platform linux/arm64 $IMAGE_NAME:$VERSION"
