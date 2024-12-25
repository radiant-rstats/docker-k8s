./start-pod.sh

microk8s kubectl get pod
microk8s kubectl get services

microk8s kubectl delete deployment rsm-msba-vnijs
microk8s kubectl delete service rsm-msba-ssh-vnijs

pod_name=$(microk8s kubectl get pods -o jsonpath='{.items[0].metadata.name}')
echo $pod_name

microk8s kubectl logs $pod_name
microk8s kubectl describe pod $pod_name

microk8s kubectl exec -it $pod_name -- openssl version
microk8s kubectl exec -it $pod_name -- ls -la /home/jovyan
microk8s kubectl exec -it $pod_name -- /bin/bash -c "cd /home/jovyan && su jovyan && exec /bin/bash"

