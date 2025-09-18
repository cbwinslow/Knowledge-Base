#!/usr/bin/env bash
set -euo pipefail
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' > /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update -y
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker || true
systemctl restart docker
# CUDA toolkit & cuDNN
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/$(. /etc/os-release; echo $ID)$(. /etc/os-release; echo $VERSION_ID | tr -d .)/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
dpkg -i /tmp/cuda-keyring.deb || true
apt-get update -y
apt-get install -y cuda-toolkit-12-4 || true
apt-get install -y libcudnn9 libcudnn9-dev || true
apt-get install -y datacenter-gpu-manager || true
echo "[✓] NVIDIA runtime + CUDA/cuDNN done."
