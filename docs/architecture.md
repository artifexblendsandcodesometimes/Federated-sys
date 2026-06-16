# FusionNet Architecture

This document will contain the high-level system architecture and component breakdown for the FusionNet federated learning system.

## Hardware Abstraction Layer

FusionNet uses a dynamic hardware detection framework (`hardware_utils.py`) to seamlessly support heterogeneous edge devices.

When a node joins the federated network, the framework analyzes the local system:
1. **GPU Check**: It checks `torch.cuda.is_available()` to determine if an AMD ROCm or NVIDIA CUDA device is present.
2. **RAM Check**: It evaluates available system RAM (via `psutil`) or VRAM.
3. **Dynamic Scaling**: Based on the hardware tier, it returns an optimal configuration mapping:
   - **High-End GPU**: `device='cuda'`, Float16/Int4, large batch sizes, AFLoRA rank 64.
   - **Low-End GPU**: `device='cuda'`, Int4, small batch sizes, AFLoRA rank 4-8.
   - **CPU-Only**: `device='cpu'`, Float32/Int8, batch size 1, AFLoRA rank 2.

### 4. Communication Layer
FusionNet serializes the `A` matrices of the AFLoRA adapters into highly efficient **Base64** strings to dramatically reduce JSON payload sizes when communicating over HTTP/WebSockets with the coordinator.

This fallback ensures that even basic PCs without dedicated graphics hardware can participate in the global model updates.
