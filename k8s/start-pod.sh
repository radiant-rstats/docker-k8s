#!/bin/bash
# Get user information
export USER=$(whoami)
export USER_UID=$(id -u)
export USER_GID=$(id -g)

# Function to get pod status
check_pod_status() {
    POD_STATUS=$(microk8s kubectl get pods -l user=$USER -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    POD_NAME=$(microk8s kubectl get pods -l user=$USER -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    echo $POD_STATUS
}

# Check if pod already exists and is running
POD_STATUS=$(check_pod_status)
if [ "$POD_STATUS" = "Running" ]; then
    echo "Pod already running for user $USER"
else
    # If pod exists but is not running, delete it
    if [ ! -z "$POD_STATUS" ]; then
        echo "Cleaning up existing pod in $POD_STATUS state..."
        microk8s kubectl delete pod -l user=$USER
        microk8s kubectl delete svc rsm-msba-ssh-$USER
        sleep 5
    fi

    # Create temporary yaml with substituted values
    envsubst < k8s-config.yaml > "$USER-k8s-config.yaml"
    # Apply the configuration
    microk8s kubectl apply -f "$USER-k8s-config.yaml"
    # Wait for pod to be ready
    echo "Waiting for pod to be ready..."
    while [[ $(microk8s kubectl get pods -l user=$USER -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
        echo "Waiting for pod..." && sleep 1;
    done
    rm "$USER-k8s-config.yaml"
fi

# Get pod name and service details (whether new or existing)
POD_NAME=$(microk8s kubectl get pods -l user=$USER -o jsonpath="{.items[0].metadata.name}")
NODE_IP=$(microk8s kubectl get nodes -o wide | grep -v NAME | awk '{print $6}')
NODE_PORT=$(microk8s kubectl get svc rsm-msba-ssh-$USER -o jsonpath='{.spec.ports[0].nodePort}')

# Set up SSH config
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi
if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
fi

if [ ! -d ~/.rsm-msba ]; then
    mkdir -p ~/.rsm-msba
    chmod -R 755 ~/.rsm-msba
    chmod g+s ~/.rsm-msba    # This sets the setgid bit
fi

# if [ ! -d ~/postgresql ]; then
#     mkdir -p ~/postgresql
#     chown -R 999:999 ~/postgresql
#     chmod 700 ~/postgresql
# fi

# Check if SSH key exists, if not create one
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
fi

# Add or update SSH config
if grep -q "Host k8s-pod" ~/.ssh/config; then
    sed -i "/Host k8s-pod/,/Port/c\Host k8s-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT\n    RequestTTY yes\n    RemoteCommand /bin/zsh -l" ~/.ssh/config
else
    echo -e "\nHost k8s-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT\n    RequestTTY yes\n    RemoteCommand /bin/zsh -l" >> ~/.ssh/config
fi

echo "Pod '$POD_NAME' is running and ready for SSH connection"
echo "You can connect to your pod using: ssh k8s-pod"
echo "NodePort: $NODE_PORT"
echo "Node IP: $NODE_IP"