# Multi-Platform Docker Build Deployment Guide

This guide walks you through building and deploying multi-platform (AMD64 and ARM64) Docker images for rsm-msba-k8s.

## Prerequisites

1. Docker Desktop installed and running
2. Docker Hub account with push access to `vnijs/rsm-msba-k8s`
3. Docker buildx available (included in Docker Desktop)

## Quick Start

### Using Make (Recommended)

The simplest way to build and deploy is using the provided Makefile:

```bash
# use for MS macos building
security -v unlock-keychain ~/Library/Keychains/login.keychain-db
```

```bash
# View all available commands
make help

# Build and push multi-platform image (version: latest)
#make build

# Build and push with a specific version
make build VERSION="2.2.0"

# Test build locally without pushing
make test
```

## Step-by-Step Deployment

### 1. Check Your Environment

Verify Docker is running and buildx is available:

```bash
make status
```

Or manually:

```bash
docker info
docker buildx version
```

### 2. Login to Docker Hub

Set your Docker Hub token as an environment variable:

```bash
export DOCKER_TOKEN=your_docker_hub_access_token
```

Then login:

```bash
make login
```

Or login manually:

```bash
docker login
```

### 3. Test Authentication

Verify you have push permissions:

```bash
make test-auth
```

### 4. Setup Multi-Platform Builder

Create and configure the buildx builder:

```bash
make setup-builder
```

This creates a builder instance that can build for multiple platforms simultaneously.

### 5. Build and Push

#### Option A: Using Make

Build and push the multi-platform image:

```bash
# With default version (latest)
make build

# With specific version
make build VERSION="2.2.0"
```

This will:

- Build for both `linux/amd64` and `linux/arm64`
- Tag as both `vnijs/rsm-msba-k8s:VERSION` and `vnijs/rsm-msba-k8s:latest`
- Push to Docker Hub
- Create detailed build logs in `build-logs/`

#### Option B: Using the Shell Script

```bash
# Build and push latest
./scripts-mp/build-multiplatform.sh

# Build and push specific version
./scripts-mp/build-multiplatform.sh v1.5.0

# Test build locally without pushing
./scripts-mp/build-multiplatform.sh --test
```

#### Option C: Manual Docker Buildx

```bash
# Setup builder
docker buildx create --name multiplatform-builder --driver docker-container --use
docker buildx inspect --bootstrap

# Build and push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag vnijs/rsm-msba-k8s:latest \
  --tag vnijs/rsm-msba-k8s:v1.5.0 \
  --build-arg DOCKERHUB_VERSION=v1.5.0 \
  --push \
  --progress=plain \
  -f rsm-msba-k8s/Dockerfile \
  .
```

### 6. Verify the Build

Inspect the multi-platform manifest:

```bash
make inspect VERSION=v1.5.0
```

Or manually:

```bash
docker buildx imagetools inspect vnijs/rsm-msba-k8s:v1.5.0
```

You should see both `linux/amd64` and `linux/arm64` platforms listed.

## Testing Locally

Before pushing to Docker Hub, test the build locally:

```bash
# Build test image for your current platform
make test

# Run the test image
docker run --rm -it vnijs/rsm-msba-k8s:test-build /bin/bash
```

## Build Without Cache

If you need a completely fresh build:

```bash
make build-no-cache VERSION=v1.5.0
```

## Build Logs

All builds create detailed logs in the `build-logs/` directory:

- `multiplatform-build_YYYYMMDD_HHMMSS.log` - Combined build log
- `build-amd64_YYYYMMDD_HHMMSS.log` - AMD64-specific logs
- `build-arm64_YYYYMMDD_HHMMSS.log` - ARM64-specific logs
- `test-build_YYYYMMDD_HHMMSS.log` - Test build logs

## Common Tasks

### Build a New Release

```bash
# Set version
VERSION=v1.6.0

# Login if needed
make login

# Build and push
make build VERSION=$VERSION

# Verify
make inspect VERSION=$VERSION
```

### Clean Up

```bash
# Remove test images and logs
make clean

# Remove buildx builder
make clean-builder

# Remove only logs
make clean-logs
```

## Troubleshooting

### Authentication Issues

If you see authentication errors:

1. Verify your Docker Hub token:

   ```bash
   echo $DOCKER_TOKEN
   ```

2. Login again:

   ```bash
   make login
   ```

3. Test authentication:
   ```bash
   make test-auth
   ```

### Build Failures

1. Check the build logs in `build-logs/`
2. Try building without cache:
   ```bash
   make build-no-cache
   ```
3. Test locally first:
   ```bash
   make test
   ```

### Platform-Specific Issues

To build for a specific platform only:

```bash
# AMD64 only
docker buildx build \
  --platform linux/amd64 \
  --tag vnijs/rsm-msba-k8s:amd64-test \
  --load \
  -f rsm-msba-k8s/Dockerfile \
  .

# ARM64 only
docker buildx build \
  --platform linux/arm64 \
  --tag vnijs/rsm-msba-k8s:arm64-test \
  --load \
  -f rsm-msba-k8s/Dockerfile \
  .
```

## Performance Notes

- Multi-platform builds take 30-60 minutes
- Test builds (single platform) take 15-30 minutes
- Builds use Docker layer caching when possible
- Use `--no-cache` for completely fresh builds

## Environment Variables

- `DOCKER_TOKEN` - Docker Hub access token (recommended)
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password (alternative to token)
- `VERSION` - Image version tag (default: latest)

## Additional Resources

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform Images Guide](https://docs.docker.com/build/building/multi-platform/)
- Build scripts: `scripts-mp/`
- Main Dockerfile: `rsm-msba-k8s/Dockerfile`
