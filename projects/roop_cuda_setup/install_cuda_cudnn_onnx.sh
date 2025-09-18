#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date '+%F %T')] $*"; }
run(){ echo "> $*"; eval "$@"; }

check_hardware_compat(){
  log "Checking GPU hardware compatibility..."
  if ! command -v lspci >/dev/null; then run "apt-get install -y pciutils"; fi

  if lspci | grep -qi nvidia; then
    if command -v nvidia-smi >/dev/null; then
      local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
      local vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
      local driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)
      local supported_cuda=$(nvidia-smi | sed -n '1,4p' | sed -n 's/.*CUDA Version: *\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -n1)

      log "GPU: $gpu_name | VRAM: ${vram}MB | Driver: $driver | Supported CUDA: ${supported_cuda:-unknown}"

      if [[ "$vram" -lt 4096 ]]; then
        log "[WARN] GPU has <4GB VRAM. Some ONNX workloads may fail."
      fi
      if [[ -n "$supported_cuda" ]]; then
        local major=${supported_cuda%%.*}
        if (( major < 12 )); then
          log "[ERROR] Detected driver only supports CUDA $supported_cuda — too old for CUDA 12.x/cuDNN 9. Aborting."
          exit 1
        fi
      fi
    else
      log "[ERROR] nvidia-smi not available. Install NVIDIA drivers first."
      exit 1
    fi

    if command -v deviceQuery >/dev/null; then
      local cc=$(deviceQuery | grep 'CUDA Capability' | awk '{print $NF}')
      log "Compute capability: $cc"
      local major=${cc%%.*}
      if (( major < 6 )); then
        log "[ERROR] GPU compute capability $cc is too old for CUDA 12.x/cuDNN 9. Aborting."
        exit 1
      fi
    fi

    local ubu=$(lsb_release -rs | cut -d'.' -f1)
    case "$ubu" in
      20|22|24) log "Ubuntu $ubu supported.";;
      *) log "[WARN] Ubuntu $(lsb_release -ds) may not be officially supported by CUDA 12.x. Proceeding anyway.";;
    esac
  else
    log "[ERROR] No NVIDIA GPU detected. CUDA/cuDNN GPU installation not supported."
    exit 1
  fi
}

install_cuda(){ run "apt-get update -y && apt-get install -y nvidia-cuda-toolkit"; }
install_cudnn(){ run "apt-get install -y libcudnn9 libcudnn9-dev"; }
install_onnx(){ run "python3 -m pip install --upgrade onnxruntime-gpu==1.18.0"; }

main(){
  check_hardware_compat
  install_cuda
  install_cudnn
  install_onnx
  log "All done. Reboot recommended."
}
main "$@"
