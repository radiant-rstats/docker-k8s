#!/bin/bash
# Sync Docker-based student container system to sc2 server
# Run this script from the docker-k8s repository root

set -e

# Configuration
SC2_HOST="sc2"
SC2_USER="vnijs"
REMOTE_BASE_DIR="/home/vnijs/docker-k8s"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "k8s/docker/start-container.sh" ]; then
    error "Please run this script from the docker-k8s repository root"
    error "Current directory: $(pwd)"
    exit 1
fi

log "Starting sync to sc2 server..."

# Test SSH connection
log "Testing SSH connection to $SC2_HOST..."
if ! ssh -o ConnectTimeout=10 "$SC2_USER@$SC2_HOST" "echo 'SSH connection successful'" >/dev/null 2>&1; then
    error "Cannot connect to $SC2_HOST. Please check:"
    error "1. SSH key is set up correctly"
    error "2. Host '$SC2_HOST' is in ~/.ssh/config"
    error "3. Server is accessible"
    exit 1
fi

log "SSH connection verified ✓"

# Create remote directory structure
log "Creating remote directory structure..."
ssh "$SC2_USER@$SC2_HOST" "mkdir -p $REMOTE_BASE_DIR/{k8s/docker,files}" || {
    error "Failed to create remote directories"
    exit 1
}

# Sync the Docker deployment scripts
log "Syncing Docker deployment scripts..."
rsync -avz --delete \
    --exclude='.claude/' \
    --exclude='CLAUDE.md' \
    --exclude='*.log' \
    --exclude='.git/' \
    k8s/docker/ \
    "$SC2_USER@$SC2_HOST:$REMOTE_BASE_DIR/k8s/docker/" || {
    error "Failed to sync Docker scripts"
    exit 1
}

# Sync the container build files
log "Syncing container build files..."
rsync -avz --delete \
    --exclude='.git/' \
    files/ \
    "$SC2_USER@$SC2_HOST:$REMOTE_BASE_DIR/files/" || {
    error "Failed to sync container files"
    exit 1
}

# Make scripts executable on remote
log "Setting script permissions..."
ssh "$SC2_USER@$SC2_HOST" "
    chmod +x $REMOTE_BASE_DIR/k8s/docker/*.sh
    chmod +x $REMOTE_BASE_DIR/files/*.sh
" || {
    error "Failed to set script permissions"
    exit 1
}

# Verify critical files exist
log "Verifying critical files were synced..."
CRITICAL_FILES=(
    "k8s/docker/start-container.sh"
    "k8s/docker/config.env"
    "k8s/docker/generate-port.sh"
    "files/install-sshd.sh"
    "files/sshd/sshd_config"
)

MISSING_FILES=()
for file in "${CRITICAL_FILES[@]}"; do
    if ! ssh "$SC2_USER@$SC2_HOST" "test -f $REMOTE_BASE_DIR/$file" 2>/dev/null; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    error "Critical files missing on remote server:"
    for file in "${MISSING_FILES[@]}"; do
        error "  - $file"
    done
    exit 1
fi

log "All critical files verified ✓"

# Show next steps
log ""
log "🎉 Sync completed successfully!"
log ""
log "Next steps on sc2 server:"
log "1. SSH to sc2: ssh $SC2_HOST"
log "2. Navigate to: cd $REMOTE_BASE_DIR"
log "3. Review config: nano k8s/docker/config.env"
log "4. Test with your user: ./k8s/docker/start-container.sh"
log "5. Set up SSH ProxyCommand for students"
log ""
log "Important files synced:"
log "  📁 Deployment scripts: $REMOTE_BASE_DIR/k8s/docker/"
log "  📁 Container build files: $REMOTE_BASE_DIR/files/"
log "  📋 Main script: $REMOTE_BASE_DIR/k8s/docker/start-container.sh"
log "  ⚙️  Configuration: $REMOTE_BASE_DIR/k8s/docker/config.env"
log ""
warn "Remember to:"
warn "  - Update config.env with sc2-specific settings"
warn "  - Ensure Docker is installed and running on sc2"
warn "  - Test container creation before rolling out to students"

log "Sync script completed successfully!"