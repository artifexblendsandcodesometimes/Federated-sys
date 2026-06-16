# setup_cuda.ps1 — FusionNet NVIDIA CUDA setup for Windows
# Requires: NVIDIA driver >= 560 for CUDA 12.8
# Compatible: RTX 50xx (Blackwell), RTX 40xx (Ada), RTX 30xx (Ampere)
#
# Usage (run from repo root in PowerShell):
#   .\scripts\setup_cuda.ps1
#
# If you get an execution policy error, run first:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  FusionNet — NVIDIA CUDA Setup (Windows)         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# ── 1. Check Python is available ─────────────────────────────────────────────
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python not found. Install Python 3.10+ from https://python.org and add it to PATH."
    exit 1
}
$pyVersion = python --version
Write-Host "`nPython : $pyVersion" -ForegroundColor Green

# ── 2. Upgrade pip ────────────────────────────────────────────────────────────
Write-Host "`nUpgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# ── 3. Install PyTorch cu128 (CUDA 12.8) ─────────────────────────────────────
# First stable wheel set supporting Blackwell (sm_100) via cu128.
Write-Host "`nInstalling PyTorch cu128 (CUDA 12.8)..." -ForegroundColor Yellow
pip install torch==2.11.0+cu128 torchvision==0.26.0+cu128 torchaudio==2.11.0+cu128 `
    --index-url https://download.pytorch.org/whl/cu128

# ── 4. Install remaining project dependencies ─────────────────────────────────
Write-Host "`nInstalling project dependencies..." -ForegroundColor Yellow
pip install -r "$PSScriptRoot\..\requirements.txt"

# ── 5. Install fusionnet-client dependencies ──────────────────────────────────
Write-Host "`nInstalling fusionnet-client dependencies..." -ForegroundColor Yellow
pip install -r "$PSScriptRoot\..\fusionnet-client\requirements.txt"

# ── 6. Verify environment ─────────────────────────────────────────────────────
Write-Host "`n--------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Environment Verification" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

python -c @"
import os, sys
# CUDA DLLs on Windows require System32 in search path
if sys.platform == 'win32':
    os.add_dll_directory(r'C:\Windows\System32')
import torch
print(f'PyTorch  : {torch.__version__}')
print(f'CUDA     : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    p = torch.cuda.get_device_properties(0)
    print(f'GPU      : {p.name} ({p.total_memory / 1024**3:.1f} GB)')
    print(f'CUDA ver : {torch.version.cuda}')
else:
    print('WARNING  : No CUDA GPU detected. Check your NVIDIA driver (>= 560 required).')
"@

Write-Host "`n[OK] Setup complete. Run the client with:" -ForegroundColor Green
Write-Host "     cd fusionnet-client" -ForegroundColor White
Write-Host "     python main.py --client-id 0 --num-clients 4" -ForegroundColor White
