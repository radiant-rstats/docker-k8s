#!/bin/bash

DOCKERHUB_VERSION=1.3.0
DOCKERHUB_USERNAME=vnijs
UPLOAD="NO"
UPLOAD="YES"

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
    docker login
    docker tag $USER/${LABEL}:latest $USER/${LABEL}:${DOCKERHUB_VERSION}
    docker push $USER/${LABEL}:${DOCKERHUB_VERSION}
    docker push $USER/${LABEL}:latest
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