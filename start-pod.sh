#!/bin/bash
# Get user information
export USER=$(whoami)
export USER_UID=$(id -u)
export USER_GID=$(id -g)

# Create temporary yaml with substituted values
envsubst < k8s-config.yaml > "$USER-k8s-config.yaml"
# Apply the configuration
microk8s kubectl apply -f "$USER-k8s-config.yaml"
# Wait for pod to be ready
echo "Waiting for pod to be ready..."
while [[ $(microk8s kubectl get pods -l user=$USER -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
    echo "Waiting for pod..." && sleep 1;
done
# Get pod name
POD_NAME=$(microk8s kubectl get pods -l user=$USER -o jsonpath="{.items[0].metadata.name}")
# Get service details
NODE_IP=$(microk8s kubectl get nodes -o wide | grep -v NAME | awk '{print $6}')
NODE_PORT=$(microk8s kubectl get svc rsm-msba-ssh-$USER -o jsonpath='{.spec.ports[0].nodePort}')
# Set up SSH config for the pod
# if .ssh does not exist, create it
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi
if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
fi
# Check if SSH key exists, if not create one
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
fi
# Add or update SSH config
if grep -q "Host k8s-pod" ~/.ssh/config; then
    # Update existing entry
    sed -i "/Host k8s-pod/,/Port/c\Host k8s-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT" ~/.ssh/config
else
    # Add new entry
    echo -e "\nHost k8s-pod\n    HostName $NODE_IP\n    User jovyan\n    Port $NODE_PORT" >> ~/.ssh/config
fi
# Clean up
rm  "$USER-k8s-config.yaml"
echo "You can connect to your pod using: ssh k8s-pod"