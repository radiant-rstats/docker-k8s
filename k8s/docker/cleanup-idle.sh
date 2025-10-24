#!/bin/bash
# Cleanup script to stop containers that have been idle for more than 24 hours
# Run this via cron hourly: 0 * * * * /opt/docker-containers/cleanup-idle.sh

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"
CLEANUP_LOG="${LOG_DIR}/cleanup.log"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$CLEANUP_LOG"
}

log "Starting idle container cleanup"

# Get current timestamp
NOW=$(date +%s)

# Counter for stopped containers
STOPPED_COUNT=0

# Find all student containers (both regular and GPU)
CONTAINERS=$(docker ps --format '{{.Names}}' --filter "name=${CONTAINER_PREFIX}-" --filter "name=${CONTAINER_PREFIX_GPU}-")

for CONTAINER_NAME in $CONTAINERS; do
    # Get container start time
    START_TIME=$(docker inspect --format='{{.State.StartedAt}}' "$CONTAINER_NAME")
    START_TS=$(date -d "$START_TIME" +%s 2>/dev/null)

    if [ $? -ne 0 ]; then
        log "Warning: Could not parse start time for $CONTAINER_NAME"
        continue
    fi

    # Calculate idle time
    IDLE_TIME=$((NOW - START_TS))

    # Check if container has been running longer than idle timeout
    if [ $IDLE_TIME -gt $IDLE_TIMEOUT ]; then
        # Get username from container name
        USERNAME=${CONTAINER_NAME#${CONTAINER_PREFIX}-}
        USERNAME=${USERNAME#${CONTAINER_PREFIX_GPU}-}

        IDLE_HOURS=$((IDLE_TIME / 3600))

        log "Stopping idle container: $CONTAINER_NAME (idle for ${IDLE_HOURS}h)"

        # Stop the container
        docker stop "$CONTAINER_NAME" >> "$CLEANUP_LOG" 2>&1

        if [ $? -eq 0 ]; then
            STOPPED_COUNT=$((STOPPED_COUNT + 1))
            log "Successfully stopped $CONTAINER_NAME"
        else
            log "Error: Failed to stop $CONTAINER_NAME"
        fi
    fi
done

if [ $STOPPED_COUNT -eq 0 ]; then
    log "No idle containers found"
else
    log "Cleanup complete: stopped $STOPPED_COUNT container(s)"
fi

# Optional: Remove old log entries (keep last 30 days)
find "$LOG_DIR" -name "*.log" -type f -mtime +30 -delete 2>/dev/null

exit 0
