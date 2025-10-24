#!/bin/bash
# Stop a student's Docker container
# Can be run by the student or by admin

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

usage() {
    echo "Usage: $0 [username] [--gpu]"
    echo "  username: Student userid (optional, defaults to current user)"
    echo "  --gpu:    Stop GPU container instead of regular (optional)"
    echo ""
    echo "Examples:"
    echo "  $0              # Stop your own container"
    echo "  $0 --gpu        # Stop your own GPU container"
    echo "  $0 aaa111       # Admin: stop aaa111's container"
    exit 1
}

# Parse arguments
TARGET_USER=$(whoami)
USE_GPU=false

for arg in "$@"; do
    case $arg in
        --gpu|-gpu)
            USE_GPU=true
            ;;
        --help|-h)
            usage
            ;;
        *)
            # Assume it's a username
            TARGET_USER="$arg"
            ;;
    esac
done

# Determine container name
if [ "$USE_GPU" = true ]; then
    CONTAINER_NAME="${CONTAINER_PREFIX_GPU}-${TARGET_USER}"
else
    CONTAINER_NAME="${CONTAINER_PREFIX}-${TARGET_USER}"
fi

# Check if running as admin or as the target user
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "$TARGET_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    echo "Error: You can only stop your own container (or run as root)" >&2
    exit 1
fi

# Check if container exists
if ! docker ps -a -q -f name="^${CONTAINER_NAME}$" | grep -q .; then
    echo "Container $CONTAINER_NAME does not exist"
    exit 0
fi

# Get container status
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)

if [ "$CONTAINER_STATUS" = "running" ]; then
    echo "Stopping container $CONTAINER_NAME..."
    docker stop "$CONTAINER_NAME"
    echo "Container stopped"
elif [ "$CONTAINER_STATUS" = "exited" ]; then
    echo "Container $CONTAINER_NAME is already stopped"
else
    echo "Container $CONTAINER_NAME is in state: $CONTAINER_STATUS"
fi

# Optionally remove the container (uncomment if you want to remove instead of just stop)
# docker rm "$CONTAINER_NAME"
