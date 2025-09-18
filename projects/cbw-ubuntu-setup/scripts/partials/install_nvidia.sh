#!/usr/bin/env bash
set -euo pipefail

# NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && \
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
curl -fsSL https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update -y
apt-get install -y nvidia-container-toolkit

nvidia-ctk runtime configure --runtime=docker || true
systemctl restart docker

# CUDA Toolkit + cuDNN (from NVIDIA apt repo)
# Add CUDA repo
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/$(. /etc/os-release; echo $ID)$(. /etc/os-release; echo $VERSION_ID | tr -d .)/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
dpkg -i /tmp/cuda-keyring.deb || true
apt-get update -y
apt-get install -y cuda-toolkit-12-4 || true

# cuDNN (versioned packages; may require license acceptance)
apt-get install -y libcudnn9 libcudnn9-dev || true

# DCGM (GPU metrics for Prometheus)
apt-get install -y datacenter-gpu-manager || true

echo "[✓] NVIDIA container runtime, CUDA toolkit 12.x, cuDNN installed (where available)."
