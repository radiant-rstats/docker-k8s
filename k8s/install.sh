# install microk8s
sudo snap install microk8s --classic --channel=1.32

microk8s start

microk8s kubectl get nodes
microk8s kubectl get services

# uninstall microk8s
microk8s stop

sudo snap remove microk8s

sudo rm -rf /var/snap/microk8s
sudo rm -rf /root/.kube
sudo rm -rf /home/$USER/.kube
sudo rm -rf ~/.microk8s

sudo rm -rf /var/snap/microk8s/common/var/lib/kubelet/*

snap connections | grep microk8s