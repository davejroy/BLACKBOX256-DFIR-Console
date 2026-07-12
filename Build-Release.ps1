<#
.SYNOPSIS
    Builds a release package for BLACKBOX256‑DFIR‑Console.

.DESCRIPTION
    This script:
      • Ensures Sysinternals Suite is downloaded dynamically
      • Builds a clean release ZIP and SHA256 checksum
      • Tags the release version automatically
      • Prepares artifacts for GitHub Actions or manual upload

.NOTES
    Author: David Roy
    Version: 1.0.2
    Date: July 2026
#>

Write-Host "=== Building BLACKBOX256‑DFIR‑Console Release ==="

# --- Environment setup ---
$RootPath   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DistPath   = Join-Path $RootPath "dist"
$VersionFile = Join-Path $RootPath "VERSION"
$Version     = Get-Content $VersionFile -ErrorAction Stop
$Tag         = "v$Version"

# --- Ensure output directory exists ---
if (-not (Test-Path $DistPath)) {
    New-Item -ItemType Directory -Path $DistPath | Out-Null
}

# --- Load Sysinternals auto‑download module ---
Import-Module "$RootPath\Modules\Sysinternals\Get-Sysinternals.ps1" -Force
$SysinternalsPath = Get-SysinternalsSuite
Write-Host "[+] Sysinternals Suite ready at: $SysinternalsPath"

# --- Define release contents ---
$ReleaseName = "BLACKBOX256_USB-$Tag"
$ZipPath     = Join-Path $DistPath "$ReleaseName.zip"
$ShaPath     = Join-Path $DistPath "$ReleaseName.sha256.txt"

# --- Clean previous artifacts ---
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
if (Test-Path $ShaPath) { Remove-Item $ShaPath -Force }

# --- Build ZIP ---
Write-Host "[+] Creating release ZIP..."
$ItemsToInclude = @(
    "$RootPath\DFIR-Console.ps1",
    "$RootPath\Modules",
    "$RootPath\Tools",
    "$RootPath\VERSION"
)

Compress-Archive -Path $ItemsToInclude -DestinationPath $ZipPath -Force
Write-Host "[+] ZIP created: $ZipPath"

# --- Generate SHA256 checksum ---
Write-Host "[+] Generating SHA256 checksum..."
$Hash = (Get-FileHash $ZipPath -Algorithm SHA256).Hash
$Hash | Out-File $ShaPath -Encoding ASCII
Write-Host "[+] SHA256 checksum written to: $ShaPath"

# --- Tag and commit (optional for CI/CD) ---
Write-Host "[+] Tagging release version..."
git tag -a $Tag -m "Release $Tag"
git push origin $Tag

# --- Summary ---
Write-Host ""
Write-Host "=== Release Build Complete ==="
Write-Host "Version:  $Version"
Write-Host "Tag:      $Tag"
Write-Host "ZIP:      $ZipPath"
Write-Host "SHA256:   $ShaPath"
Write-Host "================================"
