# =============================================================================
#  generate-api-key.ps1
#  Generates a cryptographically secure API key and appends it to API_KEYS
#  in the .env file at the repository root.
#
#  Usage:  .\scripts\generate-api-key.ps1
# =============================================================================
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvFile  = Join-Path $RepoRoot ".env"

# ── Ensure .env exists ────────────────────────────────────────────────────────
if (-not (Test-Path $EnvFile)) {
    Write-Error "ERROR: .env file not found at $EnvFile`nCopy .env.example to .env and fill in your values first."
    exit 1
}

# ── Generate 32 random bytes → 64-character hex key ──────────────────────────
$bytes  = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
$NewKey = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""

$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($NewKey))
$NewHash = ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""

# ── Prompt for a human-readable label ────────────────────────────────────────
$Label = Read-Host "Enter a label for this key (e.g. angular-prod, postman-dev)"
if ([string]::IsNullOrWhiteSpace($Label)) { $Label = "unlabelled" }
Write-Host ""

# ── Append the key to API_KEYS in .env ────────────────────────────────────────
$Content     = Get-Content $EnvFile -Raw
$CurrentLine = ($Content -split "`n" | Where-Object { $_ -match '^API_KEYS=' }) | Select-Object -First 1
$Current     = if ($CurrentLine) { $CurrentLine -replace '^API_KEYS=', '' } else { "" }
$Current     = $Current.Trim()

if ([string]::IsNullOrEmpty($Current)) {
    $NewLine = "API_KEYS=$NewHash"
} else {
    $NewLine = "API_KEYS=$Current,$NewHash"
}

# Replace the API_KEYS line in the file
if ($Content -match 'API_KEYS=') {
    $Content = $Content -replace 'API_KEYS=.*', $NewLine
} else {
    $Content = $Content.TrimEnd() + "`nAPI_KEYS=$NewHash`n"
}
Set-Content -Path $EnvFile -Value $Content -NoNewline

# Count total keys
$AllKeys = @(($NewLine -replace '^API_KEYS=', '') -split ',' | Where-Object { $_ -ne '' })
$Total   = $AllKeys.Count

# ── Print the new key (ONCE — copy it immediately) ───────────────────────────
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  New API key generated for: $Label"                          -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Key: $NewKey"                                               -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  COPY THIS KEY NOW -- it will not be shown again."
Write-Host "  API_KEYS now contains $Total key(s)."
Write-Host "  Restart: docker compose restart newsfeed-server"
Write-Host "============================================================" -ForegroundColor Cyan
