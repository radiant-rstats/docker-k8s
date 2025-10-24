#!/bin/bash
# Start or create a student's Docker container
# This script is called via SSH ProxyCommand when a student connects

set -e

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

# Parse arguments
USE_GPU=false
if [ "$1" = "--gpu" ] || [ "$1" = "-gpu" ]; then
    USE_GPU=true
fi

# Get current user info
USERNAME=$(whoami)
USER_UID=$(id -u)
USER_GID=$(id -g)
USER_HOME=$(eval echo "~$USERNAME")

# Determine container name and image
if [ "$USE_GPU" = true ]; then
    CONTAINER_NAME="${CONTAINER_PREFIX_GPU}-${USERNAME}"
    IMAGE="$DOCKER_IMAGE_GPU"
    PORT_FLAG="--gpu"
else
    CONTAINER_NAME="${CONTAINER_PREFIX}-${USERNAME}"
    IMAGE="$DOCKER_IMAGE"
    PORT_FLAG=""
fi

# Calculate port for this user
PORT=$(${SCRIPT_DIR}/generate-port.sh "$USERNAME" $PORT_FLAG)
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate port for user $USERNAME" >&2
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${USERNAME}.log"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Starting container for user $USERNAME (port $PORT)"

# Check if container exists
CONTAINER_EXISTS=$(docker ps -a -q -f name="^${CONTAINER_NAME}$")

if [ -n "$CONTAINER_EXISTS" ]; then
    # Container exists - check its status
    CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")

    if [ "$CONTAINER_STATUS" = "running" ]; then
        # Container is already running
        # Check if image has been updated
        CURRENT_IMAGE=$(docker inspect "$CONTAINER_NAME" --format='{{.Image}}')
        LATEST_IMAGE=$(docker inspect "$IMAGE" --format='{{.Id}}' 2>/dev/null || echo "")

        if [ -n "$LATEST_IMAGE" ] && [ "$CURRENT_IMAGE" != "$LATEST_IMAGE" ]; then
            log "Image updated - recreating container"
            docker stop "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
            docker rm "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
            CONTAINER_EXISTS=""
        else
            log "Container already running"
        fi
    elif [ "$CONTAINER_STATUS" = "exited" ] || [ "$CONTAINER_STATUS" = "created" ]; then
        # Container exists but is stopped
        log "Starting stopped container"
        docker start "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    else
        # Container in unexpected state - remove and recreate
        log "Container in state '$CONTAINER_STATUS' - recreating"
        docker rm -f "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
        CONTAINER_EXISTS=""
    fi
fi

# Create container if it doesn't exist
if [ -z "$CONTAINER_EXISTS" ]; then
    log "Creating new container"

    # Pull latest image if not present
    if ! docker image inspect "$IMAGE" &>/dev/null; then
        log "Pulling image $IMAGE"
        docker pull "$IMAGE" >> "$LOG_FILE" 2>&1
    fi

    # Build docker run command
    DOCKER_CMD="docker run -d \
        --name $CONTAINER_NAME \
        --hostname ${CONTAINER_NAME} \
        -p ${PORT}:22 \
        --memory=$MEMORY_LIMIT \
        --memory-reservation=$MEMORY_RESERVATION \
        --cpus=$CPU_LIMIT \
        -e TZ=$TZ \
        -e USER=$CONTAINER_USER \
        -e HOME=$CONTAINER_HOME \
        -e SHELL=$CONTAINER_SHELL \
        -e ZDOTDIR=$CONTAINER_ZDOTDIR \
        -e RSMBASE=$CONTAINER_RSMBASE \
        -e NB_UID=$USER_UID \
        -e NB_GID=$USER_GID \
        -e SKIP_PERMISSIONS=false \
        -v ${USER_HOME}:${CONTAINER_HOME} \
        --restart unless-stopped"

    # Add GPU support if requested
    if [ "$USE_GPU" = true ]; then
        DOCKER_CMD="$DOCKER_CMD --gpus all"
    fi

    DOCKER_CMD="$DOCKER_CMD $IMAGE"

    # Execute docker run
    eval $DOCKER_CMD >> "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        log "Error: Failed to create container"
        echo "Error: Failed to create container. Check log: $LOG_FILE" >&2
        exit 1
    fi

    log "Container created successfully"
fi

# Wait for SSH to be ready in the container
log "Waiting for SSH to be ready..."
TIMEOUT=$CONTAINER_START_TIMEOUT
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Check if sshd is running in container
    if docker exec "$CONTAINER_NAME" pgrep sshd > /dev/null 2>&1; then
        log "SSH is ready"
        exit 0
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

# Timeout reached
log "Error: Timeout waiting for SSH to be ready"
echo "Error: Container started but SSH not ready after ${TIMEOUT}s" >&2
echo "Check container logs: docker logs $CONTAINER_NAME" >&2
exit 1
