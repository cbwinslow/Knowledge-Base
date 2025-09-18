#!/usr/bin/env python3
import sys, onnxruntime as ort
print("ONNX Runtime:", ort.__version__)
print("Providers:", ort.get_available_providers())
if "CUDAExecutionProvider" not in ort.get_available_providers():
    print("[FAIL] CUDAExecutionProvider not available — GPU not active.")
    sys.exit(2)
print("[OK] CUDAExecutionProvider is available.")
