#!/bin/bash

# Get CUDA_ARCH for your GPU from `nvidia-smi`
CUDA_ARCH=$(nvidia-smi --query-gpu=compute_cap --format=csv | sed -n '2 p' | tr -d '.')

pip install . --install-option="-DUSE_CUDA=ON" --install-option="-DRPU_CUDA_ARCHITECTURES="${CUDA_ARCH}"" --install-option="-DRPU_BLAS=OpenBLAS"

echo "IBM aihwkit:latest-cuda is built and insatlled successfully"