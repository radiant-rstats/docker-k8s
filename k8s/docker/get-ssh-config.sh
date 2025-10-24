#!/bin/bash
# Generate SSH config snippet for a student to connect to their container
# Students run this after initial SSH setup to get their VS Code configuration

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

usage() {
    echo "Generate SSH configuration for VS Code Remote-SSH"
    echo ""
    echo "Usage: $0 [--gpu]"
    echo "  --gpu:  Generate config for GPU container (optional)"
    echo ""
    echo "This will generate an SSH config snippet that you should add to your"
    echo "local ~/.ssh/config file (on your laptop/desktop, not on the server)."
    exit 1
}

# Parse arguments
USE_GPU=false
for arg in "$@"; do
    case $arg in
        --gpu|-gpu)
            USE_GPU=true
            ;;
        --help|-h)
            usage
            ;;
    esac
done

# Get current user info
USERNAME=$(whoami)

# Determine container type and name
if [ "$USE_GPU" = true ]; then
    CONTAINER_TYPE="GPU"
    HOST_ALIAS="rsm-msba-gpu"
    PORT_FLAG="--gpu"
else
    CONTAINER_TYPE="regular"
    HOST_ALIAS="rsm-msba"
    PORT_FLAG=""
fi

# Calculate port for this user
PORT=$(${SCRIPT_DIR}/generate-port.sh "$USERNAME" $PORT_FLAG 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate port for user $USERNAME" >&2
    exit 1
fi

# Generate SSH config
echo "=========================================="
echo "SSH Configuration for VS Code Remote-SSH"
echo "=========================================="
echo ""
echo "User:      $USERNAME"
echo "Type:      $CONTAINER_TYPE container"
echo "Port:      $PORT"
echo "Server:    $SERVER_HOSTNAME"
echo ""
echo "----------------------------------------"
echo "Copy the configuration below and add it to your LOCAL ~/.ssh/config file"
echo "(on your laptop/desktop, NOT on the server)"
echo "----------------------------------------"
echo ""

cat << EOF
Host $HOST_ALIAS
    HostName $SERVER_HOSTNAME
    User $USERNAME
    ProxyCommand ssh %r@%h "$SCRIPT_DIR/start-container.sh $PORT_FLAG && nc localhost $PORT"
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking accept-new
EOF

echo ""
echo "----------------------------------------"
echo "Usage Instructions:"
echo "----------------------------------------"
echo "1. Copy the configuration above"
echo "2. Open your LOCAL ~/.ssh/config file (on your laptop)"
echo "   - Windows: C:\\Users\\YourName\\.ssh\\config"
echo "   - Mac/Linux: ~/.ssh/config"
echo "3. Paste the configuration at the end of the file"
echo "4. Save the file"
echo "5. In VS Code:"
echo "   - Install 'Remote - SSH' extension if not already installed"
echo "   - Click the green button in bottom-left corner"
echo "   - Select 'Connect to Host'"
echo "   - Choose '$HOST_ALIAS' from the list"
echo "   - Wait for connection (first time may take 30-60 seconds)"
echo ""
echo "Notes:"
echo "- Your home directory (/home/$USERNAME) will be automatically mounted"
echo "- The container will start automatically when you connect"
echo "- The container stops after 24 hours of idle time (work is saved in your home directory)"
echo "- To reconnect after idle timeout, just connect again - container will restart"
echo ""
echo "Need help? Contact your system administrator"
echo "=========================================="
