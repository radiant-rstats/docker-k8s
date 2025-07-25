#!/bin/bash

# Simple build wrapper that handles logging and opens logs in VS Code
VERSION="${1:-latest}"

# Fixed log file names (no timestamps)
MAIN_LOG="build-logs/build-main.log"
ARM_LOG="build-logs/build-arm64.log"
AMD_LOG="build-logs/build-amd64.log"

# Create build-logs directory
mkdir -p build-logs

# Clear previous logs
> "$MAIN_LOG"
> "$ARM_LOG" 
> "$AMD_LOG"

echo "Starting multi-platform build for version: $VERSION"
echo "Logs:"
echo "  Main: $MAIN_LOG"
echo "  ARM64: $ARM_LOG"
echo "  AMD64: $AMD_LOG"
echo ""

# Open logs in VS Code if available
if command -v code > /dev/null 2>&1; then
    code "$MAIN_LOG" "$ARM_LOG" "$AMD_LOG"
    echo "Opened log files in VS Code"
fi

# Start the build and stream output
./scripts-mp/build-multiplatform.sh "$VERSION" 2>&1 | tee "$MAIN_LOG" | while IFS= read -r line; do
    echo "$line"
    
    # Split logs by platform
    if [[ "$line" =~ arm64 ]]; then
        echo "$line" >> "$ARM_LOG"
    fi
    if [[ "$line" =~ amd64 ]]; then
        echo "$line" >> "$AMD_LOG"
    fi
done

echo ""
echo "Build completed!"
echo "Logs saved to:"
echo "  $MAIN_LOG"
echo "  $ARM_LOG"
echo "  $AMD_LOG"