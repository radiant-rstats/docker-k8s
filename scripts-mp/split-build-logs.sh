#!/bin/bash

# Script to split multi-platform build logs by platform
# Usage: split-build-logs.sh <input-log-file> <output-directory>

INPUT_LOG="$1"
OUTPUT_DIR="${2:-build-logs}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

if [ -z "$INPUT_LOG" ] || [ ! -f "$INPUT_LOG" ]; then
    echo "Usage: $0 <input-log-file> [output-directory]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Initialize variables
current_platform=""
amd64_file="$OUTPUT_DIR/build-amd64_${TIMESTAMP}.log"
arm64_file="$OUTPUT_DIR/build-arm64_${TIMESTAMP}.log"
general_file="$OUTPUT_DIR/build-general_${TIMESTAMP}.log"

# Create empty files
> "$amd64_file"
> "$arm64_file"
> "$general_file"

echo "Splitting multi-platform build log..."
echo "Input: $INPUT_LOG"
echo "Output directory: $OUTPUT_DIR"

# Process the log file line by line
while IFS= read -r line; do
    # Check if this line indicates a platform-specific build step
    if [[ "$line" =~ \[linux/amd64.*\] ]] || [[ "$line" =~ "linux/amd64" ]]; then
        current_platform="amd64"
        echo "$line" >> "$amd64_file"
    elif [[ "$line" =~ \[linux/arm64.*\] ]] || [[ "$line" =~ "linux/arm64" ]]; then
        current_platform="arm64"
        echo "$line" >> "$arm64_file"
    elif [[ "$line" =~ ^#[0-9]+ ]] && [[ "$current_platform" != "" ]]; then
        # This is a build step line, write to appropriate platform file
        if [ "$current_platform" = "amd64" ]; then
            echo "$line" >> "$amd64_file"
        elif [ "$current_platform" = "arm64" ]; then
            echo "$line" >> "$arm64_file"
        fi
    else
        # General log line or we don't know the platform yet
        echo "$line" >> "$general_file"
        
        # Also append to platform-specific logs if we're in a platform context
        if [ "$current_platform" = "amd64" ]; then
            echo "$line" >> "$amd64_file"
        elif [ "$current_platform" = "arm64" ]; then
            echo "$line" >> "$arm64_file"
        fi
    fi
done < "$INPUT_LOG"

echo "Log splitting complete!"
echo "Created files:"
echo "  - AMD64 logs: $amd64_file"
echo "  - ARM64 logs: $arm64_file"  
echo "  - General logs: $general_file"

# Show file sizes
echo ""
echo "File sizes:"
ls -lh "$amd64_file" "$arm64_file" "$general_file" | awk '{print "  - " $9 ": " $5}'