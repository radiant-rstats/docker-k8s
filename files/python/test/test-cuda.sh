
docker run --gpus all -v $(pwd)/files/python/test/test-cuda.py:/test-cuda.py vnijs/rsm-msba-k8s-gpu:1.1.0 python /test-cuda.py
