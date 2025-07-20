#!/bin/bash

# Test build script - builds locally without pushing to registry
# Useful for testing the Dockerfile before doing a full build+push

set -e

# Configuration
IMAGE_NAME="rsm-msba-k8s-test"
VERSION="${1:-test}"
PLATFORMS="linux/amd64,linux/arm64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Starting LOCAL multi-platform build test"
print_status "Image: $IMAGE_NAME:$VERSION"
print_status "Platforms: $PLATFORMS"
print_warning "This will NOT push to any registry - local testing only"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Create a new builder instance if it doesn't exist
BUILDER_NAME="multiplatform-builder"
if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
    print_status "Creating new buildx builder: $BUILDER_NAME"
    docker buildx create --name "$BUILDER_NAME" --driver docker-container --use
else
    print_status "Using existing buildx builder: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

# Bootstrap the builder
print_status "Bootstrapping builder..."
docker buildx inspect --bootstrap

# Build context check
if [ ! -f "../files/init-apt.sh" ]; then
    print_error "Build context issue: files directory not found relative to multiplatform folder"
    exit 1
fi

# Start the build (without push)
print_status "Building multi-platform image (LOCAL ONLY)..."
print_warning "This may take 30-60 minutes..."

start_time=$(date +%s)

docker buildx build \
    --platform "$PLATFORMS" \
    --tag "$IMAGE_NAME:$VERSION" \
    --build-arg DOCKERHUB_VERSION="$VERSION" \
    --load \
    --progress=plain \
    -f Dockerfile \
    ..

build_status=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $build_status -eq 0 ]; then
    print_status "LOCAL build completed successfully!"
    print_status "Build duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
    print_status "Image available locally as: $IMAGE_NAME:$VERSION"

    # Show local images
    print_status "Local images:"
    docker images | grep "$IMAGE_NAME" || echo "No local images found (this is normal for multi-platform builds)"

    print_warning "Note: Multi-platform images can't be loaded locally in their full form"
    print_warning "To test individual platforms, build them separately:"
    print_status "  docker buildx build --platform linux/amd64 --tag $IMAGE_NAME:amd64 --load -f Dockerfile .."
    print_status "  docker buildx build --platform linux/arm64 --tag $IMAGE_NAME:arm64 --load -f Dockerfile .."
else
    print_error "Build failed with exit code $build_status"
    exit $build_status
fi

print_status "Local test build completed!"
print_status "If this succeeded, you can now run the full build with push:"
print_status "  ./scripts/build-multiplatform.sh $VERSION"
