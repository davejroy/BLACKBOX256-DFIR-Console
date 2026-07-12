<#
Build-BLACKBOX256-EXE.ps1
Creates a self-extracting EXE that deploys BLACKBOX256_USB and launches DFIR-Console.ps1.

Requirements:
  - Windows (IEXPRESS is built-in)
#>

param(
    [string]$SourceRoot = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB",
    [string]$ExeOutput  = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_Setup.exe"
)

Write-Host "Building EXE from: $SourceRoot"
Write-Host "Output EXE: $ExeOutput"
Write-Host ""

if (-not (Test-Path $SourceRoot)) {
    Write-Host "Source folder not found: $SourceRoot"
    exit 1
}

# 1. Create a temporary SED file for IEXPRESS
$sedPath = Join-Path $env:TEMP "BLACKBOX256_iexpress.sed"
$workingDir = Split-Path $ExeOutput -Parent

# 2. Zip the BLACKBOX256_USB folder
$zipPath = Join-Path $workingDir "BLACKBOX256_USB.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($SourceRoot, $zipPath)

Write-Host "Created ZIP: $zipPath"

# 3. Create a small launcher batch that:
#    - extracts ZIP
#    - runs DFIR-Console.ps1 via pwsh
$launcherBat = Join-Path $workingDir "BLACKBOX256_Launcher.bat"
@"
@echo off
setlocal
set EXTRACT_DIR=%TEMP%\BLACKBOX256_USB
if exist "%EXTRACT_DIR%" rd /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%"
powershell -NoLogo -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%~dp0BLACKBOX256_USB.zip', '%EXTRACT_DIR%')"
pwsh -ExecutionPolicy Bypass -File "%EXTRACT_DIR%\DFIR-Console.ps1"
endlocal
"@ | Set-Content -Path $launcherBat -Encoding ASCII

Write-Host "Created launcher: $launcherBat"

# 4. Build SED file for IEXPRESS
@"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvSize=0
RebootMode=I
InstallPrompt=
DisplayLicense=
FinishMessage=BLACKBOX256 DFIR Platform has been extracted and launched.
TargetName=$ExeOutput
FriendlyName=BLACKBOX256 DFIR Platform
AppLaunched=$launcherBat
PostInstallCmd=
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$workingDir
[SourceFiles0]
$file1=$zipPath
$file2=$launcherBat
[Strings]
file1=BLACKBOX256_USB.zip
file2=BLACKBOX256_Launcher.bat
"@ | Set-Content -Path $sedPath -Encoding ASCII

Write-Host "Created SED: $sedPath"

# 5. Run IEXPRESS
Write-Host "Running IEXPRESS to build EXE..."
iexpress /N /Q /M $sedPath

if (Test-Path $ExeOutput) {
    Write-Host "EXE build complete: $ExeOutput"
} else {
    Write-Host "EXE build failed."
}
