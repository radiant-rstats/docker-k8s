#!/bin/bash

IMAGE_VERSION=2.1.0
IMAGE_USERNAME=vnijs
UPLOAD="NO"
# UPLOAD="YES"

# Docker authentication function
docker_login() {
  echo "Checking Docker Hub authentication..."

  if [ -n "$DOCKER_PASSWORD" ] && [ -n "$DOCKER_USERNAME" ]; then
    echo "Logging in to Docker Hub using environment variables..."
    if echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin; then
      echo "Successfully authenticated with username/password"
      return 0
    else
      echo "Failed to authenticate with username/password"
      return 1
    fi
  elif [ -n "$DOCKER_TOKEN" ]; then
    echo "Logging in to Docker Hub using access token..."
    if echo "$DOCKER_TOKEN" | docker login --username "$IMAGE_USERNAME" --password-stdin; then
      echo "Successfully authenticated with access token"
      return 0
    else
      echo "Failed to authenticate with access token"
      return 1
    fi
  else
    # Test if already authenticated by trying to access user info
    echo "Testing existing Docker authentication..."
    if docker info 2>/dev/null | grep -q "Username:"; then
      username=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
      echo "Already authenticated as: $username"

      # Double-check by trying to search (this requires auth)
      if docker search --limit 1 hello-world &>/dev/null; then
        echo "Authentication confirmed - can access Docker Hub"
        return 0
      else
        echo "Authentication appears stale - re-authentication needed"
      fi
    fi

    echo "Docker Hub authentication required."
    echo "Please choose one of the following options:"
    echo "1. Run 'docker login' manually"
    echo "2. Set DOCKER_USERNAME and DOCKER_PASSWORD environment variables"
    echo "3. Set DOCKER_TOKEN environment variable with your access token"
    echo ""
    echo "For option 1, run: docker login"
    echo "Then re-run this script."
    return 1
  fi
}

if [ "$(uname -m)" = "arm64" ]; then
  ARCH="linux/arm64"
else
  ARCH="linux/amd64"
fi

build () {
  {
    if [[ "$1" == "NO" ]]; then
      # build without cache
      docker buildx build -f "${LABEL}/Dockerfile" \
        --progress=plain \
        --load \
        --platform ${ARCH} \
        --build-arg IMAGE_VERSION="${IMAGE_VERSION}" \
        --no-cache \
        --tag $IMAGE_USERNAME/${LABEL}:latest \
        --tag $IMAGE_USERNAME/${LABEL}:$IMAGE_VERSION .
    else
      # build with cache
      docker buildx build -f "${LABEL}/Dockerfile" \
        --progress=plain \
        --load \
        --platform ${ARCH} \
        --build-arg IMAGE_VERSION="${IMAGE_VERSION}" \
        --tag $IMAGE_USERNAME/${LABEL}:latest \
        --tag $IMAGE_USERNAME/${LABEL}:$IMAGE_VERSION .
    fi
  } || {
    echo "-----------------------------------------------------------------------"
    echo "Docker build for ${LABEL} was not successful"
    echo "-----------------------------------------------------------------------"
    sleep 3s
    exit 1
  }
  if [ "${UPLOAD}" == "YES" ] && [ "${LABEL}" != "connectorx" ]; then
    echo "Preparing to upload ${LABEL} to Docker Hub..."

    # Ensure Docker is available
    if ! docker info &>/dev/null; then
      echo "ERROR: Docker not available"
      exit 1
    fi

    # Ensure authentication BEFORE attempting push
    if ! docker_login; then
      echo "ERROR: Docker Hub authentication failed"
      echo "Please run 'docker login' manually and try again"
      exit 1
    fi

    echo "Tagging and pushing ${LABEL}..."

    # Tag the images
    if ! docker tag $IMAGE_USERNAME/${LABEL}:latest $IMAGE_USERNAME/${LABEL}:${IMAGE_VERSION}; then
      echo "ERROR: Failed to tag image"
      exit 1
    fi

    # Push versioned image
    echo "Pushing ${LABEL}:${IMAGE_VERSION}..."
    if ! docker push $IMAGE_USERNAME/${LABEL}:${IMAGE_VERSION}; then
      echo "ERROR: Failed to push versioned image"
      exit 1
    fi

    # Push latest image
    echo "Pushing ${LABEL}:latest..."
    if ! docker push $IMAGE_USERNAME/${LABEL}:latest; then
      echo "ERROR: Failed to push latest image"
      exit 1
    fi

    echo "Successfully pushed ${LABEL} images to Docker Hub"
  fi
}

# what os is being used
ostype=`uname`
if [[ "$ostype" == "Darwin" ]]; then
  sed_fun () {
    sed -i '' -e $1 $2
  }
else
  sed_fun () {
    sed -i $1 $2
  }
fi

if [ "$(uname -m)" = "arm64" ]; then

  # LABEL=connectorx
  # build
  # exit

  LABEL=rsm-msba-k8s
  build
else
  # if [[ $(hostname -I) == *"132.249.225.85"* ]]; then
  #   LABEL=rsm-msba-k8s-gpu
  #   echo $LABEL
  #   build
  # else
    LABEL=rsm-msba-k8s
    echo $LABEL
    build
  # fi
fi

# run script using to ensure it keeps running on a server even if the connection goes down
# nohup ./scripts/build-images.sh > build.log &; tail -f build.log
