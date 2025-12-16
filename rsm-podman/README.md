# Multi-Platform Docker Build Setup

This folder contains a unified approach to building Docker images that work on both ARM64 (Apple Silicon) and AMD64 (Intel) architectures using a single Dockerfile.

## Overview

Instead of maintaining separate Dockerfiles for ARM and Intel, this approach uses Docker's multi-platform build capabilities to create a single image that works on both architectures.

## Key Features

- **Single Dockerfile**: One source of truth for both architectures
- **Platform Detection**: Automatically detects target platform and sets appropriate configurations
- **Local Building**: Optimized for building on Mac Studio with Docker Desktop
- **Multi-Platform Push**: Pushes to Docker Hub with multi-platform manifest

## Architecture Differences Handled

The unified Dockerfile automatically handles these platform-specific differences:

1. **Base Images**: Uses platform-appropriate base image SHAs
2. **Java Paths**:
   - ARM64: `/usr/lib/jvm/java-17-openjdk-arm64/`
   - AMD64: `/usr/lib/jvm/java-17-openjdk-amd64/`
3. **Binary Downloads**: Downloads correct pgweb binary for each platform
4. **Image Names**: Sets appropriate `IMAGE_NAME` environment variable

## Files

```
scripts-mp/
│   ├── build-multiplatform.sh   # Main build script
│   ├── test-build.sh            # Local test build (no push)
│   ├── test-auth.sh             # Authentication test
│   ├── validate-setup.sh        # Pre-build validation
rsm-msba-k8s/
├── Dockerfile                    # Unified multi-platform Dockerfile
└── README.md                    # This file
```

## Prerequisites

1. **Docker Desktop** with buildx support (latest version recommended)
2. **Docker Hub Account** for pushing images
3. **Sufficient Resources**:
   - 16GB+ RAM recommended
   - 20GB+ free disk space
   - Good cooling (long build process)

## Quick Start

### 1. Validate Setup

Before building, run the validation script to check your environment:

```bash
cd scripts-mp
./validate-setup.sh
```

This will check:

- Docker Desktop is running
- buildx is available
- Required files are present
- Docker Hub authentication
- Available disk space

### 2. Test Authentication

Test your Docker Hub authentication (recommended):

```bash
./scripts/test-auth.sh
```

This verifies your authentication works before starting the long build process.

### 3. Set Up Authentication

Choose one of these methods (no interactive login required):

**Option A: Docker Access Token (Recommended)**

```bash
export DOCKER_TOKEN=your_docker_hub_token
```

**Option B: Username/Password**

```bash
export DOCKER_USERNAME=your_username
export DOCKER_PASSWORD=your_password
```

**Option C: One-time manual login**

```bash
docker login
```

### 4. Build and Push

```bash
cd scripts-mp
./build-multiplatform.sh [version]
```

Examples:

```bash
# Build with 'latest' tag
./build-multiplatform.sh

# Build with specific version
./build-multiplatform.sh v2.0.0

# Build with date-based version
./build-multiplatform.sh 2025-01-19
```

## Build Process

The build script will:

1. Create a multi-platform builder if needed
2. Bootstrap the builder environment
3. Build for both `linux/amd64` and `linux/arm64` platforms simultaneously
4. Push both images and create a multi-platform manifest
5. Display build timing and manifest information

## Expected Build Time

- **Mac Studio M1/M2**: 30-45 minutes
- **Intel Mac**: 45-60 minutes
- **Depends on**: Network speed, Docker layer caching, system load

## Usage After Build

Once built and pushed, users can pull and run the image on any supported platform:

```bash
# Docker automatically selects the right platform
docker pull radiant-rstats/rsm-msba-k8s:latest
docker run -it radiant-rstats/rsm-msba-k8s:latest

# Explicitly specify platform if needed
docker pull --platform linux/amd64 radiant-rstats/rsm-msba-k8s:latest
docker pull --platform linux/arm64 radiant-rstats/rsm-msba-k8s:latest
```

## Troubleshooting

### Build Fails with "platform not supported"

Enable experimental features in Docker Desktop settings.

### Out of Disk Space

The build creates large intermediate layers. Clean up Docker:

```bash
docker system prune -a
docker buildx prune -a
```

### Build Takes Too Long

- Ensure Docker Desktop has sufficient resources allocated
- Close other resource-intensive applications
- Consider building during off-peak hours for better network performance

### Authentication Issues

Make sure you're logged into Docker Hub:

```bash
docker logout
docker login
```

## Migration from Existing Setup

This setup is designed to complement, not replace, your existing ARM and Intel Dockerfiles. The original files in `rsm-msba-k8s-arm/` and `rsm-msba-k8s-intel/` remain untouched.

### Benefits of Migration

1. **Maintenance**: Single file to maintain instead of two
2. **Consistency**: Eliminates drift between ARM/Intel versions
3. **Efficiency**: Single build process, better caching
4. **User Experience**: Users get correct image automatically

### Testing the New Approach

You can test the new multi-platform image alongside your existing ones:

```bash
# Test ARM image (on Apple Silicon)
docker run --platform linux/arm64 radiant-rstats/rsm-msba-k8s:latest

# Test Intel image (on Intel Mac or with emulation)
docker run --platform linux/amd64 radiant-rstats/rsm-msba-k8s:latest
```

## Performance Notes

- **Apple Silicon**: Native ARM64 performance
- **Intel Macs**: Native AMD64 performance
- **Cross-platform**: Docker handles emulation when needed
- **Cloud Deployment**: Works on both ARM and Intel cloud instances

## Next Steps

1. Test the build process with the validation script
2. Run a test build with a version tag
3. Validate both platform images work correctly
4. Consider migrating your CI/CD to use this unified approach
5. Eventually retire the separate ARM/Intel Dockerfiles (when ready)
