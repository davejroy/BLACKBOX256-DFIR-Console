<#
Build-Release.ps1
Packages BLACKBOX256_USB into a versioned ZIP + SHA256 hash.
Used by GitHub Actions and can be run locally.
#>

param(
    [Parameter(Mandatory)][string]$Tag
)

$projectRoot = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB"
$distRoot    = Join-Path $projectRoot "dist"

Write-Host "Building release for tag: $Tag"

if (-not (Test-Path $distRoot)) {
    New-Item -ItemType Directory -Path $distRoot | Out-Null
}

$zipName  = "BLACKBOX256_USB-$Tag.zip"
$zipPath  = Join-Path $distRoot $zipName
$hashPath = Join-Path $distRoot ("BLACKBOX256_USB-$Tag.sha256.txt")

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Write-Host "Creating ZIP: $zipPath"
Compress-Archive -Path "$projectRoot\*" -DestinationPath $zipPath -Force

Write-Host "Computing SHA256..."
$hash = Get-FileHash -Path $zipPath -Algorithm SHA256
"$($hash.Hash)  $zipName" | Set-Content $hashPath

Write-Host "Release build complete:"
Write-Host "  ZIP:   $zipPath"
Write-Host "  SHA256: $hashPath"
