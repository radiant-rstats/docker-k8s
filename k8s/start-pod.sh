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

# Add or update SSH config
if grep -q "Host k8s-$APP-pod" ~/.ssh/config; then
    sed -i "/Host k8s-$APP-pod/,/RemoteCommand/c\Host k8s-$APP-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT\n    RequestTTY yes\n    StrictHostKeyChecking accept-new\n    RemoteCommand /bin/zsh -l" ~/.ssh/config
else
    echo -e "\nHost k8s-$APP-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT\n    RequestTTY yes\n    StrictHostKeyChecking accept-new\n    RemoteCommand /bin/zsh -l" >> ~/.ssh/config
fi

echo "Pod '$POD_NAME' is running and ready for SSH connection"
echo "Your dedicated NodePort is: $NODE_PORT"
echo "Node IP: $NODE_IP"

# output terminal connection information
echo -e "\nFor access from a terminal, use these settings in ~/.ssh/config:\n"
echo "Host $APP-terminal"
echo "    Host $NODE_IP"
echo "    User $USER"
echo "    Port $NODE_PORT"
echo "    RequestTTY yes"
echo "    RemoteCommand zsh -c '/opt/k8s/bin/start$CALC-pod.sh && sleep 3 && exec ssh -t jovyan@localhost -p $NODE_PORT /bin/zsh -l'"
echo "    StrictHostKeyChecking accept-new"
echo "    ServerAliveInterval 60"
echo "    ServerAliveCountMax 5"
echo "    ConnectTimeout 120"

# output VS Code connection information
echo -e "\nFor VS Code Remote-SSH connection, use these settings in ~/.ssh/config:\n"
echo "Host $APP-vscode"
echo "    User jovyan"
echo "    Port $NODE_PORT"
echo "    ProxyCommand ssh -t $USER@$NODE_IP \"zsh -c '/opt/k8s/bin/start$CALC-pod.sh >/dev/null 2>&1 && sleep 3 && nc localhost %p'\""
echo "    StrictHostKeyChecking accept-new"
echo "    ServerAliveInterval 60"
echo "    ServerAliveCountMax 5"
echo "    ConnectTimeout 120"
