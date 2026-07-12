<#
Get-Tools.ps1
DFIR tool downloader + auto-extraction + versioning + portable Plaso installer.
#>

$root = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB\Tools"
Write-Host "Downloading DFIR tools to: $root"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36"

function Ensure-Folder($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

function Download($url, $dest) {
    Write-Host "Downloading: $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -Headers @{ "User-Agent" = $UA }
        Write-Host "Saved: $dest"
        return $true
    }
    catch {
        Write-Host "FAILED: $url"
        Write-Host "Error: $($_.Exception.Message)"
        return $false
    }
}

function Extract-ZipVersioned {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][string]$BaseName
    )

    if (-not (Test-Path $ZipPath)) {
        Write-Host "Zip not found: $ZipPath"
        return
    }

    Ensure-Folder $TargetRoot

    $dateTag   = (Get-Date).ToString("yyyyMMdd")
    $versioned = Join-Path $TargetRoot ("{0}-{1}" -f $BaseName, $dateTag)

    if (Test-Path $versioned) {
        Write-Host "Versioned folder already exists: $versioned"
        return
    }

    Write-Host "Extracting $ZipPath to $versioned"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $versioned)
    Write-Host "Extracted to: $versioned"
}

# -------------------------------
# Folder Setup
# -------------------------------
$folders = @(
    "Memory",
    "Memory\volatility",
    "Imaging",
    "EZTools",
    "Sysinternals",
    "Logs",
    "Timeline",
    "Browser",
    "Hashing",
    "Misc"
)

foreach ($f in $folders) {
    Ensure-Folder (Join-Path $root $f)
}

# -------------------------------
# WinPmem (Memory Acquisition)
# -------------------------------
$winpmemPath = "$root\Memory\winpmem.exe"
Download "https://github.com/Velocidex/WinPmem/releases/latest/download/winpmem_x64.exe" $winpmemPath

# -------------------------------
# Volatility 3
# -------------------------------
$vol3Zip = "$root\Memory\volatility\volatility3.zip"
if (Download "https://github.com/volatilityfoundation/volatility3/archive/refs/heads/master.zip" $vol3Zip) {
    Extract-ZipVersioned -ZipPath $vol3Zip -TargetRoot "$root\Memory\volatility" -BaseName "volatility3"
}

# -------------------------------
# Volatility 2
# -------------------------------
$vol2Zip = "$root\Memory\volatility\volatility2.zip"
if (Download "https://github.com/volatilityfoundation/volatility/archive/refs/heads/master.zip" $vol2Zip) {
    Extract-ZipVersioned -ZipPath $vol2Zip -TargetRoot "$root\Memory\volatility" -BaseName "volatility2"
}

# -------------------------------
# EZTools (Eric Zimmerman)
# -------------------------------
$ezTools = @(
    "RECmd.zip",
    "RegistryExplorer.zip",
    "ShellBagsExplorer.zip",
    "TimelineExplorer.zip",
    "LECmd.zip",
    "PECmd.zip",
    "SQLECmd.zip"
)

foreach ($tool in $ezTools) {
    $url = "https://f001.backblazeb2.com/file/EricZimmermanTools/$tool"
    $dest = "$root\EZTools\$tool"
    if (Download $url $dest) {
        Extract-ZipVersioned -ZipPath $dest -TargetRoot "$root\EZTools" -BaseName ($tool.Replace(".zip",""))
    }
}

# -------------------------------
# Sysinternals Suite
# -------------------------------
$sysZip = "$root\Sysinternals\SysinternalsSuite.zip"
if (Download "https://download.sysinternals.com/files/SysinternalsSuite.zip" $sysZip) {
    Extract-ZipVersioned -ZipPath $sysZip -TargetRoot "$root\Sysinternals" -BaseName "SysinternalsSuite"
}

# -------------------------------
# Chainsaw (Event Log Hunting)
# -------------------------------
$chainsawZip = "$root\Logs\chainsaw.zip"
if (Download "https://github.com/WithSecureLabs/chainsaw/releases/latest/download/chainsaw_windows.zip" $chainsawZip) {
    Extract-ZipVersioned -ZipPath $chainsawZip -TargetRoot "$root\Logs" -BaseName "chainsaw"
}

# -------------------------------
# Portable Plaso Installer (Python venv)
# -------------------------------
Write-Host ""
Write-Host "Installing portable Plaso..."

$pythonUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$pythonZip = "$root\Timeline\python-embed.zip"

if (Download $pythonUrl $pythonZip) {

    $dateTag = (Get-Date).ToString("yyyyMMdd")
    $venvRoot = "$root\Timeline\plaso-venv-$dateTag"
    Ensure-Folder $venvRoot

    Write-Host "Extracting portable Python..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($pythonZip, $venvRoot)

    Write-Host "Creating Plaso virtual environment..."
    $pythonExe = Join-Path $venvRoot "python.exe"

    & $pythonExe -m venv "$venvRoot\venv"

    Write-Host "Installing Plaso..."
    & "$venvRoot\venv\Scripts\pip.exe" install plaso

    Write-Host "Creating wrapper scripts..."
    @"
@echo off
"%~dp0plaso-venv-$dateTag\venv\Scripts\log2timeline.exe" %*
"@ | Set-Content "$root\Timeline\log2timeline.cmd"

    @"
@echo off
"%~dp0plaso-venv-$dateTag\venv\Scripts\psort.exe" %*
"@ | Set-Content "$root\Timeline\psort.cmd"

    @"
@echo off
"%~dp0plaso-venv-$dateTag\venv\Scripts\pinfo.exe" %*
"@ | Set-Content "$root\Timeline\pinfo.cmd"

    Write-Host "Plaso installed successfully."
}

# -------------------------------
# Browser Tools
# -------------------------------
$hindsightZip = "$root\Browser\hindsight.zip"
if (Download "https://github.com/obsidianforensics/hindsight/archive/refs/heads/master.zip" $hindsightZip) {
    Extract-ZipVersioned -ZipPath $hindsightZip -TargetRoot "$root\Browser" -BaseName "hindsight"
}

$unfurlZip = "$root\Browser\unfurl.zip"
if (Download "https://github.com/obsidianforensics/unfurl/archive/refs/heads/master.zip" $unfurlZip) {
    Extract-ZipVersioned -ZipPath $unfurlZip -TargetRoot "$root\Browser" -BaseName "unfurl"
}

# -------------------------------
# Hashdeep
# -------------------------------
$hashdeepZip = "$root\Hashing\hashdeep.zip"
if (Download "https://github.com/jessek/hashdeep/archive/refs/heads/master.zip" $hashdeepZip) {
    Extract-ZipVersioned -ZipPath $hashdeepZip -TargetRoot "$root\Hashing" -BaseName "hashdeep"
}

# -------------------------------
# CyberChef
# -------------------------------
$cyberchefHtml = "$root\Misc\cyberchef.html"
Download "https://gchq.github.io/CyberChef/CyberChef_v10.19.4.html" $cyberchefHtml

# -------------------------------
# YARA
# -------------------------------
$yaraZip = "$root\Misc\yara.zip"
if (Download "https://github.com/VirusTotal/yara/releases/latest/download/yara-4.5.1-win64.zip" $yaraZip) {
    Extract-ZipVersioned -ZipPath $yaraZip -TargetRoot "$root\Misc" -BaseName "yara"
}

Write-Host ""
Write-Host "Tool download + extraction + Plaso installation complete."
Write-Host "Versioned folders created under each tool category."
