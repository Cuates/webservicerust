# =============================================================================
#  revoke-api-key.ps1
#  Lists existing API keys (masked) and removes the selected one from
#  API_KEYS in the .env file at the repository root.
#
#  Usage:  .\scripts\revoke-api-key.ps1
# =============================================================================
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvFile  = Join-Path $RepoRoot ".env"

# ── Ensure .env exists ────────────────────────────────────────────────────────
if (-not (Test-Path $EnvFile)) {
    Write-Error "ERROR: .env file not found at $EnvFile"
    exit 1
}

# ── Read current API_KEYS ─────────────────────────────────────────────────────
$Content     = Get-Content $EnvFile -Raw
$CurrentLine = ($Content -split "`n" | Where-Object { $_ -match '^API_KEYS=' }) | Select-Object -First 1
$Current     = if ($CurrentLine) { $CurrentLine -replace '^API_KEYS=', '' } else { "" }
$Current     = $Current.Trim()

$Keys = @($Current -split ',' | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() })

if ($Keys.Count -eq 0) {
    Write-Host "No API keys found in $EnvFile. Nothing to revoke."
    exit 0
}

# ── Display masked keys (first 6 chars only) ──────────────────────────────────
Write-Host ""
Write-Host "Current API keys:" -ForegroundColor Cyan
Write-Host ("─" * 37) -ForegroundColor DarkGray
for ($i = 0; $i -lt $Keys.Count; $i++) {
    $masked = $Keys[$i].Substring(0, [Math]::Min(6, $Keys[$i].Length)) + "..."
    Write-Host ("  {0}. {1}" -f ($i + 1), $masked)
}
Write-Host ("─" * 37) -ForegroundColor DarkGray
Write-Host ""

$ChoiceStr = Read-Host "Enter the number of the key to revoke (or 0 to cancel)"
$Choice    = [int]$ChoiceStr

if ($Choice -eq 0) {
    Write-Host "Cancelled."
    exit 0
}

if ($Choice -lt 1 -or $Choice -gt $Keys.Count) {
    Write-Error "Invalid selection."
    exit 1
}

$RevokeIdx = $Choice - 1
$RevokedKey = $Keys[$RevokeIdx]
$Masked     = $RevokedKey.Substring(0, [Math]::Min(6, $RevokedKey.Length)) + "..."

# ── Remove the selected key ───────────────────────────────────────────────────
$Remaining = @($Keys | Where-Object { $_ -ne $RevokedKey })
$NewValue  = $Remaining -join ','
$NewLine   = "API_KEYS=$NewValue"

if ($Content -match 'API_KEYS=') {
    $Content = $Content -replace 'API_KEYS=.*', $NewLine
} else {
    $Content = $Content.TrimEnd() + "`nAPI_KEYS=$NewValue`n"
}
Set-Content -Path $EnvFile -Value $Content -NoNewline

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Key revoked: $Masked"
Write-Host "  API_KEYS now contains $($Remaining.Count) key(s)."
Write-Host "  Restart: docker compose restart newsfeed-server"
Write-Host "============================================================" -ForegroundColor Cyan
