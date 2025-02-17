# install microk8s
sudo snap install microk8s --classic --channel=1.32

# setup to work for anyone in the microk8s group
sudo usermod -a -G microk8s $USER

microk8s start

microk8s kubectl get nodes
microk8s kubectl get services

# move scripts to shared directory
sudo rm -rf /opt/k8s
sudo mkdir -p /opt/k8s/
sudo chmod -R 777 /opt/k8s/ 
sudo mkdir -p /opt/k8s/bin
sudo chmod -R 755 /opt/k8s/bin 
sudo cp k8s/start-pod.sh /opt/k8s/bin
sudo cp k8s/k8s-config.yaml /opt/k8s/bin
ls -la /opt/k8s/bin

# uninstall microk8s
microk8s stop

sudo snap remove microk8s

sudo rm -rf /var/snap/microk8s
sudo rm -rf /root/.kube
sudo rm -rf /home/$USER/.kube
sudo rm -rf ~/.microk8s

sudo rm -rf /var/snap/microk8s/common/var/lib/kubelet/*

snap connections | grep microk8s