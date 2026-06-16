# setup_env.ps1 — FusionNet Python virtual environment setup (Windows)
# Creates a venv, upgrades pip, and installs all dependencies.
# Run this ONCE before any other script.
#
# Usage (run from repo root in PowerShell):
#   .\scripts\setup_env.ps1             # CPU-only (any machine)
#   .\scripts\setup_env.ps1 -Backend cuda  # NVIDIA GPU (CUDA 12.8)
#   .\scripts\setup_env.ps1 -Backend rocm  # AMD GPU (ROCm via WSL2)
#
# If you get an execution policy error, run first:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

param(
    [ValidateSet("cpu", "cuda", "rocm")]
    [string]$Backend = "cpu"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  FusionNet — Environment Setup (Windows)         " -ForegroundColor Cyan
Write-Host "  Backend: $($Backend.ToUpper())                  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$repoRoot = Split-Path -Parent $PSScriptRoot
$venvPath = Join-Path $repoRoot "venv"

# ── 1. Check Python ───────────────────────────────────────────────────────────
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error @"
Python 3.10+ not found.
Download from: https://www.python.org/downloads/
Make sure to check 'Add Python to PATH' during installation.
"@
    exit 1
}
$pyVer = python --version
Write-Host "`n[1/5] Python found: $pyVer" -ForegroundColor Green

# ── 2. Create virtual environment ─────────────────────────────────────────────
if (Test-Path $venvPath) {
    Write-Host "`n[2/5] venv already exists at: $venvPath (skipping creation)" -ForegroundColor Yellow
} else {
    Write-Host "`n[2/5] Creating virtual environment at: $venvPath" -ForegroundColor Yellow
    python -m venv $venvPath
    Write-Host "      venv created." -ForegroundColor Green
}

# ── 3. Activate venv ──────────────────────────────────────────────────────────
$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
Write-Host "`n[3/5] Activating venv..." -ForegroundColor Yellow
& $activateScript
Write-Host "      venv active." -ForegroundColor Green

# ── 4. Upgrade pip + install PyTorch backend ──────────────────────────────────
Write-Host "`n[4/5] Installing PyTorch ($($Backend.ToUpper()) build)..." -ForegroundColor Yellow
python -m pip install --upgrade pip

switch ($Backend) {
    "cuda" {
        # CUDA 12.8 — RTX 30xx/40xx/50xx (driver >= 560)
        pip install torch==2.11.0+cu128 torchvision==0.26.0+cu128 torchaudio==2.11.0+cu128 `
            --index-url https://download.pytorch.org/whl/cu128
    }
    "rocm" {
        # PyTorch ROCm wheels are Linux-only.
        # On Windows, install CPU wheel. For GPU, use WSL2 + setup_rocm.sh.
        Write-Host "  NOTE: PyTorch ROCm wheels are Linux-only." -ForegroundColor Yellow
        Write-Host "  Installing CPU build. For AMD GPU acceleration use WSL2." -ForegroundColor Yellow
        pip install torch torchvision torchaudio
    }
    default {
        # Plain CPU build — works on any Windows PC
        pip install torch torchvision torchaudio
    }
}

# ── 5. Install project dependencies ──────────────────────────────────────────
Write-Host "`n[5/5] Installing FusionNet dependencies..." -ForegroundColor Yellow
pip install -r (Join-Path $repoRoot "requirements.txt")
pip install -r (Join-Path $repoRoot "fusionnet-client\requirements.txt")

# ── Verification ──────────────────────────────────────────────────────────────
Write-Host "`n--------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Verification" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

python -c @"
import sys, torch
is_rocm = getattr(torch.version, 'hip', None) is not None
backend = 'ROCm' if is_rocm else ('CUDA' if torch.cuda.is_available() else 'CPU')
print(f'Python   : {sys.version.split()[0]}')
print(f'PyTorch  : {torch.__version__}')
print(f'Backend  : {backend}')
if torch.cuda.is_available():
    p = torch.cuda.get_device_properties(0)
    print(f'GPU      : {p.name} ({p.total_memory/1024**3:.1f} GB)')
else:
    import psutil
    ram = psutil.virtual_memory().total / 1024**3
    print(f'RAM      : {ram:.1f} GB (CPU mode)')
"@

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "  Setup complete! Next steps:" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Activate venv in future sessions:" -ForegroundColor White
Write-Host "    .\venv\Scripts\Activate.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Run the client node:" -ForegroundColor White
Write-Host "    cd fusionnet-client" -ForegroundColor Cyan
Write-Host "    python main.py --client-id 0 --num-clients 4" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Launch a full FL round:" -ForegroundColor White
Write-Host "    .\scripts\launch_fl_round.ps1 -NumClients 4" -ForegroundColor Cyan
