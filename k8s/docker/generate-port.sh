#!/bin/bash
# Generate deterministic port number from username
# Handles edge cases where multiple userids might have same numeric suffix

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

usage() {
    echo "Usage: $0 <username> [--gpu]"
    echo "  username: Student userid (e.g., aaa111, bbb222)"
    echo "  --gpu:    Use GPU port range (optional)"
    exit 1
}

# Parse arguments
USERNAME="$1"
USE_GPU=false

if [ -z "$USERNAME" ]; then
    usage
fi

if [ "$2" = "--gpu" ]; then
    USE_GPU=true
fi

# Extract numeric portion from username
# Supports formats: aaa111, abc123, john456, etc.
NUMERIC_PART=$(echo "$USERNAME" | grep -o '[0-9]\+$')

if [ -z "$NUMERIC_PART" ]; then
    # Fallback: if no trailing numbers, use hash-based port (silent - this is normal)
    HASH=$(echo -n "$USERNAME" | md5sum | cut -c1-8)
    if [ "$USE_GPU" = true ]; then
        PORT=$((PORT_BASE_GPU + (0x$HASH % 5000)))
    else
        PORT=$((PORT_BASE + (0x$HASH % 5000)))
    fi
else
    # Standard case: use numeric suffix
    if [ "$USE_GPU" = true ]; then
        PORT=$((PORT_BASE_GPU + NUMERIC_PART))
    else
        PORT=$((PORT_BASE + NUMERIC_PART))
    fi
fi

# Validate port is in acceptable range
if [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then
    echo "Error: Calculated port $PORT is out of valid range (1024-65535)" >&2
    exit 1
fi

# Check for port conflicts with existing containers
# This is a safety check in case of hash collisions or unusual usernames
EXISTING_CONTAINER=$(docker ps -a --format '{{.Names}} {{.Ports}}' | grep ":$PORT->" | awk '{print $1}')
if [ -n "$EXISTING_CONTAINER" ]; then
    # Port is in use - check if it's this user's container
    if [[ "$EXISTING_CONTAINER" == "${CONTAINER_PREFIX}-${USERNAME}" ]] || \
       [[ "$EXISTING_CONTAINER" == "${CONTAINER_PREFIX_GPU}-${USERNAME}" ]]; then
        # Same user, same port - this is fine
        :
    else
        # Different user has this port - collision detected
        echo "Warning: Port $PORT already in use by $EXISTING_CONTAINER" >&2
        # Try next available port
        for i in {1..100}; do
            NEW_PORT=$((PORT + i))
            if [ "$NEW_PORT" -gt "$PORT_MAX" ]; then
                echo "Error: No available ports found" >&2
                exit 1
            fi
            CONFLICT=$(docker ps -a --format '{{.Ports}}' | grep -c ":$NEW_PORT->")
            if [ "$CONFLICT" -eq 0 ]; then
                PORT=$NEW_PORT
                echo "Using alternative port: $PORT" >&2
                break
            fi
        done
    fi
fi

echo "$PORT"
