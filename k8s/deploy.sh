# cd ~/gh/docker-k8s/k8s
k8s/start-pod.sh
clear

# newgrp microk8s

microk8s kubectl get pod
microk8s kubectl get services

# microk8s kubectl delete all --all -n default
microk8s kubectl delete deployment rsm-msba-vnijs
microk8s kubectl delete service rsm-msba-ssh-vnijs

pod_name=$(microk8s kubectl get pods -o jsonpath='{.items[0].metadata.name}')
echo $pod_name

microk8s kubectl logs $pod_name
microk8s kubectl describe pod $pod_name

microk8s kubectl exec -it $pod_name -- openssl version
microk8s kubectl exec -it $pod_name -- ls -la /home/jovyan
microk8s kubectl exec -it $pod_nam -- su jovyan -c /bin/zsh

# can you connect to the pod using ssh?
ssh -vvv k8s-pod
ssh k8s-pod

# Stop microk8s
microk8s stop

# Start microk8s
microk8s start

# Verify status
microk8s status
