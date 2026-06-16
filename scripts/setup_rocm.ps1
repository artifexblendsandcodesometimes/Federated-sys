# setup_rocm.ps1 — FusionNet AMD ROCm setup for Windows
# ROCm on Windows is supported via HIP SDK (ROCm 5.7+ / HIP SDK 5.7+).
# Requires: AMD Radeon RX 6000 / RX 7000 series or newer, HIP SDK installed.
#
# HIP SDK for Windows: https://www.amd.com/en/developer/resources/rocm-hub/hip-sdk.html
#
# Usage (run from repo root in PowerShell):
#   .\scripts\setup_rocm.ps1
#
# If you get an execution policy error, run first:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "  FusionNet — AMD ROCm / HIP SDK Setup (Windows)  " -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

Write-Host @"

  NOTE: ROCm on Windows uses AMD's HIP SDK.
  Ensure you have installed:
    1. AMD Radeon Software (latest)
    2. AMD HIP SDK from:
       https://www.amd.com/en/developer/resources/rocm-hub/hip-sdk.html

  PyTorch ROCm wheels are Linux-only from pytorch.org.
  On Windows, we install the CUDA-compatible wheel and rely on
  the HIP SDK's CUDA compatibility layer (hipcc / HIPRT).

  For full ROCm support on Windows, WSL2 (Ubuntu 22.04) is recommended:
    wsl --install -d Ubuntu-22.04
  Then run scripts/setup_rocm.sh inside WSL2.

"@ -ForegroundColor Yellow

# ── 1. Check Python ───────────────────────────────────────────────────────────
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python not found. Install Python 3.10+ from https://python.org and add it to PATH."
    exit 1
}
$pyVersion = python --version
Write-Host "Python : $pyVersion" -ForegroundColor Green

# ── 2. Upgrade pip ────────────────────────────────────────────────────────────
Write-Host "`nUpgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# ── 3. Check for HIP SDK ──────────────────────────────────────────────────────
$hipPath = "C:\Program Files\AMD\ROCm"
$hipFound = Test-Path $hipPath
if ($hipFound) {
    Write-Host "HIP SDK detected at: $hipPath" -ForegroundColor Green
} else {
    Write-Host "HIP SDK not found at default path ($hipPath)." -ForegroundColor Yellow
    Write-Host "Proceeding with CPU-compatible install. GPU acceleration may not work." -ForegroundColor Yellow
}

# ── 4. Install PyTorch (CPU / CUDA fallback for Windows ROCm) ─────────────────
# PyTorch ROCm wheels are not published for Windows.
# We install the standard CPU wheel so all Python code runs.
# GPU training on Windows/AMD requires WSL2 + ROCm Linux install.
Write-Host "`nInstalling PyTorch (CPU build — ROCm wheels are Linux-only)..." -ForegroundColor Yellow
pip install torch torchvision torchaudio

# ── 5. Install remaining project dependencies ─────────────────────────────────
Write-Host "`nInstalling project dependencies..." -ForegroundColor Yellow
pip install -r "$PSScriptRoot\..\requirements.txt"

# ── 6. Install fusionnet-client dependencies ──────────────────────────────────
Write-Host "`nInstalling fusionnet-client dependencies..." -ForegroundColor Yellow
pip install -r "$PSScriptRoot\..\fusionnet-client\requirements.txt"

# ── 7. Verify ─────────────────────────────────────────────────────────────────
Write-Host "`n--------------------------------------------------" -ForegroundColor Magenta
Write-Host "  Environment Verification" -ForegroundColor Magenta
Write-Host "--------------------------------------------------" -ForegroundColor Magenta

python -c @"
import torch
is_rocm = getattr(torch.version, 'hip', None) is not None
print(f'PyTorch  : {torch.__version__}')
print(f'ROCm/HIP : {is_rocm}')
print(f'CUDA API : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    p = torch.cuda.get_device_properties(0)
    print(f'GPU      : {p.name} ({p.total_memory / 1024**3:.1f} GB)')
else:
    print('INFO     : Running on CPU. For AMD GPU on Windows use WSL2 + setup_rocm.sh')
"@

Write-Host "`n[OK] Setup complete." -ForegroundColor Green
Write-Host "" 
Write-Host "  For AMD GPU acceleration on Windows, use WSL2:" -ForegroundColor Cyan
Write-Host "    wsl --install -d Ubuntu-22.04" -ForegroundColor White
Write-Host "    # Then inside WSL2:" -ForegroundColor White
Write-Host "    bash scripts/setup_rocm.sh" -ForegroundColor White
Write-Host ""
Write-Host "  To run on CPU (works now):" -ForegroundColor Cyan
Write-Host "    cd fusionnet-client" -ForegroundColor White
Write-Host "    python main.py --client-id 0 --num-clients 4" -ForegroundColor White
