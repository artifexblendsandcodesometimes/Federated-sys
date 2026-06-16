# launch_fl_round.ps1 — FusionNet Federated Learning Round Launcher (Windows)
# Simulates a multi-client federated learning round on a single Windows machine.
#
# Usage (run from repo root):
#   .\scripts\launch_fl_round.ps1
#   .\scripts\launch_fl_round.ps1 -NumClients 4 -FederationRounds 3
#
# Parameters:
#   -NumClients      : Number of simulated FL client nodes (default: 3)
#   -FederationRounds: Number of FL rounds to run per client (default: 1)

param(
    [int]$NumClients = 3,
    [int]$FederationRounds = 1
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  FusionNet — Federated Learning Round (Windows)  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Clients     : $NumClients" -ForegroundColor White
Write-Host "  FL Rounds   : $FederationRounds" -ForegroundColor White
Write-Host ""

# ── Resolve paths ─────────────────────────────────────────────────────────────
$repoRoot   = Split-Path -Parent $PSScriptRoot
$clientDir  = Join-Path $repoRoot "fusionnet-client"
$mainScript = Join-Path $clientDir "main.py"

if (-not (Test-Path $mainScript)) {
    Write-Error "Cannot find fusionnet-client\main.py at: $mainScript"
    exit 1
}

# ── Launch each client as a background job ────────────────────────────────────
$jobs = @()
for ($round = 1; $round -le $FederationRounds; $round++) {
    Write-Host "--- FL Round $round / $FederationRounds ---" -ForegroundColor Magenta

    for ($id = 0; $id -lt $NumClients; $id++) {
        Write-Host "  Spawning client $id / $NumClients ..." -ForegroundColor Yellow

        $job = Start-Job -ScriptBlock {
            param($clientDir, $mainScript, $clientId, $numClients, $round)
            Set-Location $clientDir
            $output = python $mainScript --client-id $clientId --num-clients $numClients 2>&1
            [PSCustomObject]@{
                ClientId = $clientId
                Round    = $round
                Output   = $output -join "`n"
            }
        } -ArgumentList $clientDir, $mainScript, $id, $NumClients, $round

        $jobs += $job
    }

    # ── Wait for all clients in this round to finish ──────────────────────────
    Write-Host "`n  Waiting for all $NumClients clients to finish round $round ..." -ForegroundColor Cyan
    $results = $jobs | Wait-Job | Receive-Job

    # ── Print per-client output ───────────────────────────────────────────────
    foreach ($result in $results) {
        Write-Host "`n  ========== Client $($result.ClientId) | Round $($result.Round) ==========" -ForegroundColor Green
        Write-Host $result.Output
    }

    # Clean up jobs before next round
    $jobs | Remove-Job -Force
    $jobs = @()

    Write-Host "`n  [Round $round complete]" -ForegroundColor Green
    Write-Host ""
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  All $FederationRounds FL round(s) finished!      " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  - Inspect adapter checkpoints in: fusionnet-client\checkpoints\" -ForegroundColor White
Write-Host "  - Run example_federated_round.py to simulate coordinator aggregation" -ForegroundColor White
Write-Host "  - See README.md for full deployment guide" -ForegroundColor White
