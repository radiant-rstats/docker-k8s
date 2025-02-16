
#!/bin/bash
set -e  # Exit on error
set -x  # Print commands as they're executed

cd ~/gh/docker-k8s/causalml

# Create logs directory
mkdir -p logs
mkdir -p wheels

# Build with logging
docker build -t causalml-wheel-builder . 2>&1 | tee logs/build.log

# Create temporary container
container_id=$(docker create causalml-wheel-builder)
echo "Created container: ${container_id}"

# List contents of relevant directories in container
echo "Checking wheel location in container..."
docker exec ${container_id} find /build -name "*.whl" 2>&1 | tee logs/wheel-locations.log

# Copy wheels with verbose output
echo "Copying wheels..."
docker cp ${container_id}:/build/dist/. ./wheels/ 2>&1 | tee logs/copy.log

# List copied wheels
echo "Wheels in local directory:"
ls -la ./wheels/

# Cleanup
docker rm ${container_id}
echo "Build complete. Check logs/ directory for build details"

cd ~/gh/docker-k8s/