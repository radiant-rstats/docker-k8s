#!/bin/bash
# Get user information
export USER=$(whoami)
export USER_UID=$(id -u)
export USER_GID=$(id -g)

# Calculate deterministic port based on username
calculate_port() {
    local username=$1
    # Generate a number between 0-2767 from username (to stay in valid NodePort range)
    local hash_num=$(echo "$username" | md5sum | tr -d [a-z] | cut -c1-4)
    local port=$((30000 + (hash_num % 2767)))
    echo $port
}

# Calculate the fixed port for this user
export NODE_PORT=$(calculate_port "${USER}-gpu")

# Function to get pod status
check_pod_status() {
    local POD_TYPE=$1  # Accept pod type as parameter (e.g., "gpu" or "msba")
    # Get status of pods that start with the pod type and have the user label
    POD_STATUS=$(microk8s kubectl get pods -l user=$USER,app=$POD_TYPE -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    POD_NAME=$(microk8s kubectl get pods -l user=$USER,app=$POD_TYPE -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    echo $POD_STATUS
}

# Check if pod already exists and is running
POD_STATUS=$(check_pod_status "rsm-msba-gpu")
if [ "$POD_STATUS" = "Running" ]; then
    echo "Pod already running for user $USER"
else
    # If pod exists but is not running, delete it
    if [ ! -z "$POD_STATUS" ]; then
        echo "Cleaning up existing pod in $POD_STATUS state..."
        microk8s kubectl delete pod -l user=$USER
        microk8s kubectl delete svc rsm-msba-ssh-gpu-$USER
        sleep 5
    fi

    # Create temporary yaml with substituted values
    touch "/opt/k8s/tmp/$USER-k8s-gpu-config.yaml"
    envsubst < /opt/k8s/bin/k8s-gpu-config.yaml > "/opt/k8s/tmp/$USER-k8s-gpu-config.yaml"

    # Apply the configuration
    microk8s kubectl apply -f "/opt/k8s/tmp/$USER-k8s-gpu-config.yaml"

    # Wait for pod to be ready
    echo "Waiting for pod to be ready..."
    while [[ $(microk8s kubectl get pods -l user=$USER -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
        echo "Waiting for pod..." && sleep 1;
    done
    rm "/opt/k8s/tmp/$USER-k8s-gpu-config.yaml"
fi

# Get pod name and service details
POD_NAME=$(microk8s kubectl get pods -l user=$USER -o jsonpath="{.items[0].metadata.name}")
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
if grep -q "Host k8s-gpu-pod" ~/.ssh/config; then
    sed -i "/Host k8s-gpu-pod/,/RemoteCommand/c\Host k8s-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT\n    RequestTTY yes\n    StrictHostKeyChecking accept-new\n    RemoteCommand /bin/zsh -l" ~/.ssh/config
else
    echo -e "\nHost k8s-gpu-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT\n    RequestTTY yes\n    StrictHostKeyChecking accept-new\n    RemoteCommand /bin/zsh -l" >> ~/.ssh/config
fi

echo "Pod '$POD_NAME' is running and ready for SSH connection"
echo "Your dedicated NodePort is: $NODE_PORT"
echo "Node IP: $NODE_IP"

# output terminal connection information
echo -e "\nFor access from a terminal, use these settings in ~/.ssh/config:\n"
echo "Host rsm-msba-gpu-terminal"
echo "    Host $NODE_IP"
echo "    User $USER"
echo "    Port $NODE_PORT"
echo "    RequestTTY yes"
echo "    RemoteCommand zsh -c '/opt/k8s/bin/start-gpu-pod.sh && sleep 3 && exec ssh -t jovyan@localhost -p $NODE_PORT /bin/zsh -l'"
echo "    StrictHostKeyChecking accept-new"

# output VS Code connection information
echo -e "\nFor VS Code Remote-SSH connection, use these settings in ~/.ssh/config:\n"
echo "Host rsm-msba-gpu-vscode"
echo "    User jovyan"
echo "    Port $NODE_PORT"
echo "    ProxyCommand ssh -t $USER@$NODE_IP \"zsh -c '/opt/k8s/bin/start-gpu-pod.sh >/dev/null 2>&1 && sleep 3 && nc localhost %p'\""
echo "    StrictHostKeyChecking accept-new"