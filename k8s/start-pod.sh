#!/bin/bash
# Get user information
export USER=$(whoami)
export USER_UID=$(id -u)
export USER_GID=$(id -g)
export INTEL_VERSION="1.1.0"
export GPU_VERSION="1.1.0"

APP="rsm-msba"
CALC="$1"  # Use $1 if provided, empty string if not
APP=${APP}${CALC}

# Calculate deterministic port based on username
calculate_port() {
    local username=$1
    # Generate a number between 0-2767 from username (to stay in valid NodePort range)
    local hash_num=$(echo "$username" | md5sum | tr -d [a-z] | cut -c1-4)
    local port=$((30000 + (hash_num % 2767)))
    echo $port
}

# Calculate the fixed port for this user
export NODE_PORT=$(calculate_port "${USER}-${APP}")

# Function to get pod status
check_pod_status() {
    local POD_TYPE=$1  # Accept pod type as parameter (e.g., "rsm-msba-gpu" or "rsm-msba")
    # Get status of pods that start with the pod type and have the user label
    POD_STATUS=$(microk8s kubectl get pods -l user=$USER,app=$POD_TYPE -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    POD_NAME=$(microk8s kubectl get pods -l user=$USER,app=$POD_TYPE -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    echo $POD_STATUS
}

# Check if pod already exists and is running
POD_STATUS=$(check_pod_status "$APP")
if [ "$POD_STATUS" = "Running" ]; then
    echo "Pod already running for user $USER"
elif [ "$POD_STATUS" = "ContainerCreating" ]; then
    echo "Pod is being created for user $USER. This could take a few minutes"
    while [[ $(microk8s kubectl get pods -l user=$USER,app=$APP -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
        echo "Waiting for pod creation to complete ..." && sleep 1;
    done
else
    # If pod exists but is not running, delete it
    if [ ! -z "$POD_STATUS" ]; then
        echo "Cleaning up existing pod in $POD_STATUS state..."
        microk8s kubectl delete deployment ${APP}-$USER
        microk8s kubectl delete svc ${APP}-ssh-$USER
        sleep 5
    fi

    # Create temporary yaml with substituted values
    touch "/opt/k8s/tmp/$USER-k8s-$APP-config.yaml"
    envsubst < /opt/k8s/bin/k8s-$APP-config.yaml > "/opt/k8s/tmp/$USER-k8s-$APP-config.yaml"

    # Apply the configuration
    microk8s kubectl apply -f "/opt/k8s/tmp/$USER-k8s-$APP-config.yaml"

    # Wait for pod to be ready
    echo "Waiting for pod ..."
    while [[ $(microk8s kubectl get pods -l user=$USER,app=$APP -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
        echo "Waiting for pod ..." && sleep 1;
    done
    rm "/opt/k8s/tmp/$USER-k8s-$APP-config.yaml"
fi

# Get pod name and service details
POD_NAME=$(microk8s kubectl get pods -l user=$USER,app=$APP -o jsonpath="{.items[0].metadata.name}")
NODE_IP=$(microk8s kubectl get nodes -o wide | grep -v NAME | awk '{print $6}')

# Set up SSH directories and permissions
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi
# if [ ! -f ~/.ssh/config ]; then
#     touch ~/.ssh/config
#     chmod 600 ~/.ssh/config
# fi
if [ ! -d ~/.rsm-msba ]; then
    mkdir -p ~/.rsm-msba
    chmod -R 755 ~/.rsm-msba
    chmod g+s ~/.rsm-msba
fi

# Check if the test key pair exists
if [ ! -f ~/.ssh/k8s_pod_key ]; then
    echo "Generating new SSH key pair to test pod access..."
    ssh-keygen -t rsa -f ~/.ssh/k8s_pod_key -N ""
    chmod 600 ~/.ssh/k8s_pod_key
fi

# Create authorized_keys if it doesn't exist
if [ ! -f ~/.ssh/authorized_keys ]; then
    echo "Creating authorized_keys file..."
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Check if the public key is already in authorized_keys
if ! grep -q "$(cat ~/.ssh/k8s_pod_key.pub)" ~/.ssh/authorized_keys; then
    echo "Adding public key to authorized_keys to test pod access..."
    cat ~/.ssh/k8s_pod_key.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Create ssh config if it doesn't exist
if [ ! -f ~/.ssh/config ]; then
    echo "Creating config file..."
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
fi

# Add or update SSH config
if ! grep -q "Host k8s-$APP-pod" ~/.ssh/config; then
    echo -e "\nHost k8s-$APP-pod\n    HostName localhost\n    User jovyan\n    Port $NODE_PORT\n    IdentityFile ~/.ssh/k8s_pod_key\n    StrictHostKeyChecking accept-new\n" >> ~/.ssh/config
fi

echo "Pod '$POD_NAME' is running and ready for SSH connection"
echo "Your dedicated NodePort is: $NODE_PORT"
echo "Node IP: $NODE_IP"

# output ssh connection information
echo -e "\nAdd connection settings to ~/.ssh/config:\n"
echo "Host $APP"
echo "    User jovyan"
echo "    Port $NODE_PORT"
echo "    ProxyCommand ssh $USER@$NODE_IP \"zsh -c '/opt/k8s/bin/start-pod.sh $CALC >/dev/null 2>&1 && sleep 3 && nc localhost %p'\""
echo "    StrictHostKeyChecking accept-new"
