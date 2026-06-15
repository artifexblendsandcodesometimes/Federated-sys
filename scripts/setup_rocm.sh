#!/bin/bash
set -e

echo "Setting up ROCm environment for FusionNet..."

# System dependencies (Assuming Ubuntu 22.04)
# sudo apt update
# sudo apt install -y wget gnupg2

# Install PyTorch with ROCm 6.0 support
echo "Installing PyTorch for ROCm 6.0..."
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.0

# Install other requirements
pip install -r ../requirements.txt

echo "Setup complete. Verifying environment..."
python -c "import torch; print(f'PyTorch ROCm available: {torch.cuda.is_available()}')"
