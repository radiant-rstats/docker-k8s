cd ~/gh/docker-k8s/
k8s/start-pod.sh
k8s/start-pod.sh "-gpu"
cat ~/.ssh/config
clear

# check issues on sc0 vs sc2 - big differences on 2/19
# may be related to nvidia setup on sc0
# if deactivating helps on sc0 then we can try to fix nvidia on sc0
microk8s kubectl get pods -A --sort-by=.metadata.creationTimestamp
microk8s kubectl logs -n kube-system calico-node-glj4l -c calico-node --tail=100

microk8s kubectl get ippool default-ipv4-ippool -o yaml
microk8s kubectl get felixconfiguration default -o yaml

microk8s kubectl get pod
microk8s kubectl get services
microk8s inspect

microk8s kubectl get svc -A | grep 30673
microk8s kubectl get svc -A | grep 30976

microk8s kubectl delete all --all -n default
microk8s kubectl delete deployment rsm-msba-vnijs
microk8s kubectl delete service rsm-msba-ssh-vnijs

microk8s kubectl delete deployment rsm-msba-gpu-vnijs
microk8s kubectl delete service rsm-msba-gpu-ssh-vnijs

microk8s kubectl get pod -o json | jq '.items[].metadata.finalizers'

pod_name=$(microk8s kubectl get pods -o jsonpath='{.items[0].metadata.name}')
microk8s kubectl describe pod $pod_name
echo $pod_name

microk8s kubectl logs $pod_name
microk8s kubectl describe pod $pod_name

microk8s kubectl exec -it $pod_name -- openssl version
microk8s kubectl exec -it $pod_name -- ls -la /home/jovyan
microk8s kubectl exec -it $pod_name -- su jovyan -c /bin/zsh

# can you connect to the pod using ssh?
ssh -vvv k8s-rsm-msba-pod
ssh k8s-rsm-msba-pod

ssh -vvv k8s-rsm-msba-gpu-pod
ssh k8s-rsm-msba-gpu-pod

# Stop microk8s
microk8s stop

# Start microk8s
microk8s start
sudo /snap/bin/microk8s reset

# list all microk8s enabled add-ons
microk8s add-ons list
microk8s enable hostpath-storage
microk8s enable nvidia

microk8s kubectl get pods -A --sort-by=.metadata.creationTimestamp




# Verify status
microk8s status
