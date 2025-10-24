# install microk8s
sudo snap install microk8s --classic --channel=1.32

# Create the group
sudo groupadd microk8s

# Add desired users to the group (replace username with actual usernames)
sudo su
sudo usermod -a -G microk8s $USER
exit
groups

# setup to work for anyone in the microk8s group
sudo usermod -a -G microk8s $USER

# Change ownership of the configuration files
sudo chgrp -R microk8s /var/snap/microk8s/current/credentials
sudo chmod -R g+rX /var/snap/microk8s/current/credentials

# Create a symbolic link to kubectl
sudo ln -s /snap/bin/microk8s.kubectl /usr/local/bin/kubectl

# Set proper permissions
sudo chmod g+rx /usr/local/bin/kubectl

sudo tee /etc/profile.d/microk8s.sh << 'EOF'
export KUBECONFIG=$KUBECONFIG:/opt/k8s/microk8s/config
EOF

sudo tee /etc/profile.d/microk8s.sh << 'EOF'
export KUBECONFIG=/opt/k8s/microk8s/config
EOF

# check that you have nvidia
nvidia-smi

# enable addon
microk8s enable hostpath-storage
microk8s enable nvidia
microk8s enable gpu

# now you should be able to start microk8s
microk8s start

# move scripts to shared directory
sudo rm -rf /opt/k8s/tmp
sudo rm -rf /opt/k8s/bin
sudo mkdir -p /opt/k8s/tmp
sudo chmod -R 777 /opt/k8s/tmp
sudo mkdir -p /opt/k8s/bin
cd ~/gh/docker-k8s
sudo cp k8s/start-pod.sh /opt/k8s/bin
sudo cp k8s/k8s-rsm-msba-config.yaml /opt/k8s/bin
sudo cp k8s/k8s-rsm-msba-gpu-config.yaml /opt/k8s/bin
sudo chmod -R 755 /opt/k8s/bin

# Create the microk8s-specific directory
sudo mkdir -p /opt/k8s/microk8s
sudo chown root:microk8s /opt/k8s/microk8s
sudo chmod 775 /opt/k8s/microk8s

# Generate and store the microk8s config
microk8s config > /opt/k8s/microk8s/config
sudo chown root:microk8s /opt/k8s/microk8s/config
sudo chmod 660 /opt/k8s/microk8s/config

# check if k8s is running
microk8s kubectl get nodes
microk8s kubectl get services

#######################################################
# uninstall microk8s
#######################################################
microk8s stop

sudo snap remove microk8s

sudo rm -rf /var/snap/microk8s
sudo rm -rf /root/.kube
sudo rm -rf /home/$USER/.kube
sudo rm -rf ~/.microk8s

sudo rm -rf /var/snap/microk8s/common/var/lib/kubelet/*

snap connections | grep microk8s