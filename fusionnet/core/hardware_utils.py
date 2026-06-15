import os
import sys
import torch
import psutil

# On Windows, PyTorch cu128 DLLs require System32 in the search path.
# This must be done before torch.cuda is accessed.
if sys.platform == "win32":
    os.add_dll_directory(r"C:\Windows\System32")


def detect_hardware():
    """
    Detects the optimal hardware profile for the local node.
    Returns a configuration dict with device, batch_size, and lora_rank.
    """
    config = {}
    print(f"PyTorch Version: {torch.__version__}")
    print(f"CUDA Available: {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        config['device'] = 'cuda'
        props = torch.cuda.get_device_properties(0)
        vram_gb = props.total_memory / (1024 ** 3)
        print(f"GPU: {props.name} ({vram_gb:.1f} GB VRAM)")

        if vram_gb >= 24:
            # High-end GPU (e.g. RTX 4090, A100)
            config['batch_size'] = 16
            config['lora_rank'] = 16
            config['contribution_weight'] = 2.0
        elif vram_gb >= 16:
            # Mid-range GPU (e.g. RTX 4080, 3090)
            config['batch_size'] = 4
            config['lora_rank'] = 8
            config['contribution_weight'] = 1.0
        elif vram_gb >= 7.5:
            # Consumer GPU (e.g. RTX 5060 Laptop 8 GB, RTX 3070)
            config['batch_size'] = 2
            config['lora_rank'] = 4
            config['contribution_weight'] = 0.75
        else:
            # Low VRAM GPU (e.g. Steam Deck, older mobile GPUs)
            config['batch_size'] = 1
            config['lora_rank'] = 2
            config['contribution_weight'] = 0.5
    else:
        # CPU Fallback
        config['device'] = 'cpu'
        sys_ram_gb = psutil.virtual_memory().total / (1024 ** 3)
        config['batch_size'] = 1
        config['lora_rank'] = 2
        config['contribution_weight'] = 0.1
        print(f"Warning: No GPU detected. Falling back to CPU with {sys_ram_gb:.1f} GB RAM. Training will be slow.")

    return config


if __name__ == "__main__":
    cfg = detect_hardware()
    print(f"Hardware config: {cfg}")
