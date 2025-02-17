# checking if nvidia-smi works
docker run --gpus all nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04 nvidia-smi

# checking if nvidia-smi works
docker run --gpus all vnijs/rsm-msba-k8s-gpu:1.1.0 nvidia-smi

# checking if pytorch can find gpus
docker run --gpus all -v $(pwd)/files/python/test/test-cuda.py:/test-cuda.py vnijs/rsm-msba-k8s-gpu:1.1.0 python /test-cuda.py

