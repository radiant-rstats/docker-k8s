# test_gpu.py
import torch
import sys


def test_gpu():
    print("\n=== System Info ===")
    print(f"Python version: {sys.version}")

    print("\n=== PyTorch Info ===")
    print(f"PyTorch version: {torch.__version__}")
    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"CUDA version: {torch.version.cuda}")

    if torch.cuda.is_available():
        print("\n=== GPU Info ===")
        print(f"GPU count: {torch.cuda.device_count()}")
        print(f"Current device: {torch.cuda.get_device_name()}")

        print("\n=== GPU Test ===")
        try:
            x = torch.rand(3, 3).cuda()
            y = torch.rand(3, 3).cuda()
            z = torch.matmul(x, y)
            print("GPU computation successful:")
            print(z)
            return True
        except Exception as e:
            print(f"Error in GPU computation: {e}")
            return False
    else:
        print("\nCUDA is not available. Check if:")
        print("1. PyTorch is installed with CUDA support")
        print("2. NVIDIA drivers are properly installed")
        print("3. Container has access to GPU (--gpus all flag)")
        return False


test_gpu()
