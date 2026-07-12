<#
Build-BLACKBOX256-ISO.ps1
Creates an ISO image from the BLACKBOX256_USB folder.

Requirements:
  - Windows 10/11
  - OSCDIMG.exe (from Windows ADK) OR built-in MakeWinPEMedia tools
#>

param(
    [string]$SourceRoot = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB",
    [string]$IsoOutput  = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB.iso",
    [string]$Label      = "BLACKBOX256_USB"
)

Write-Host "Building ISO from: $SourceRoot"
Write-Host "Output ISO: $IsoOutput"
Write-Host ""

if (-not (Test-Path $SourceRoot)) {
    Write-Host "Source folder not found: $SourceRoot"
    exit 1
}

# Try to find oscdimg.exe
$oscdimgPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe"
)

$oscdimg = $oscdimgPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $oscdimg) {
    Write-Host "oscdimg.exe not found. Install Windows ADK (Deployment Tools) to use this script."
    exit 1
}

Write-Host "Using oscdimg: $oscdimg"
Write-Host ""

# Build ISO
& $oscdimg -n -d -o "$SourceRoot" "$IsoOutput" -l"$Label"

if ($LASTEXITCODE -eq 0) {
    Write-Host "ISO build complete: $IsoOutput"
} else {
    Write-Host "ISO build failed with exit code: $LASTEXITCODE"
}
