#!/bin/bash

DOCKERHUB_VERSION=1.3.0
DOCKERHUB_USERNAME=vnijs
UPLOAD="NO"
UPLOAD="YES"

# Docker authentication function
docker_login() {
  if [ -n "$DOCKER_PASSWORD" ] && [ -n "$DOCKER_USERNAME" ]; then
    echo "Logging in to Docker Hub using environment variables..."
    echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
  elif [ -n "$DOCKER_TOKEN" ]; then
    echo "Logging in to Docker Hub using access token..."
    echo "$DOCKER_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin
  else
    # Test if already authenticated
    if ! docker search --limit 1 hello-world &>/dev/null; then
      echo "Docker Hub authentication required."
      echo "Either:"
      echo "1. Run 'docker login' manually, or"
      echo "2. Set DOCKER_USERNAME and DOCKER_PASSWORD environment variables, or"
      echo "3. Set DOCKER_TOKEN environment variable with your access token"
      exit 1
    fi
    echo "Using existing Docker authentication..."
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
        --build-arg DOCKERHUB_VERSION="${DOCKERHUB_VERSION}" \
        --no-cache \
        --tag $DOCKERHUB_USERNAME/${LABEL}:latest \
        --tag $DOCKERHUB_USERNAME/${LABEL}:$DOCKERHUB_VERSION .
    else
      # build with cache
      docker buildx build -f "${LABEL}/Dockerfile" \
        --progress=plain \
        --load \
        --platform ${ARCH} \
        --build-arg DOCKERHUB_VERSION="${DOCKERHUB_VERSION}" \
        --tag $DOCKERHUB_USERNAME/${LABEL}:latest \
        --tag $DOCKERHUB_USERNAME/${LABEL}:$DOCKERHUB_VERSION .
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
      echo "Docker not available"
      exit 1
    fi

    # Ensure authentication
    docker_login

    echo "Tagging and pushing ${LABEL}..."
    docker tag $DOCKERHUB_USERNAME/${LABEL}:latest $DOCKERHUB_USERNAME/${LABEL}:${DOCKERHUB_VERSION}
    docker push $DOCKERHUB_USERNAME/${LABEL}:${DOCKERHUB_VERSION}
    docker push $DOCKERHUB_USERNAME/${LABEL}:latest

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

  LABEL=rsm-msba-k8s-arm
  build
else
  # if [[ $(hostname -I) == *"132.249.225.85"* ]]; then
  #   LABEL=rsm-msba-k8s-gpu
  #   echo $LABEL
  #   build
  # else
    LABEL=rsm-msba-k8s-intel
    echo $LABEL
    build
  # fi
fi

# run script using to ensure it keeps running on a server even if the connection goes down
# nohup ./scripts/build-images.sh > build.log &; tail -f build.log
