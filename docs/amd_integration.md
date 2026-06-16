# AMD Hardware Integration

This document outlines how FusionNet leverages AMD hardware:
- **ROCm and PyTorch**: Native support for high-performance AFLoRA fine-tuning on MI300X and consumer GPUs.
- **bitsandbytes for 4-bit Quantization**: Utilizing the new ROCm 6.0 support in HuggingFace `bitsandbytes` to load models in `nf4` precision with double quantization.
- **Opacus & Custom Fallback for DP-SGD**: Wrapping the training loop with `opacus` to provide mathematically sound Differential Privacy. A custom DP-SGD fallback is included for cases where Opacus hooks fail on dynamically quantized 4-bit modules, ensuring robust execution on ROCm backends.
- **RCCL for Secure Aggregation**: (Planned) Using RCCL backend in distributed PyTorch for efficient cross-device tensor averaging.
