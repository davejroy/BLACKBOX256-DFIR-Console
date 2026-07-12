<#
Download-BLACKBOX256-Tools.ps1
Downloads all recommended DFIR tools into BLACKBOX256_USB\Tools.
#>

$root = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB\Tools"
Write-Host "Downloading DFIR tools to: $root"

function Ensure-Folder($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
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
    "Timeline",
    "Logs",
    "Browser",
    "Hashing",
    "Misc"
)

foreach ($f in $folders) {
    Ensure-Folder (Join-Path $root $f)
}

# -------------------------------
# Download Helper
# -------------------------------
function Download($url, $dest) {
    Write-Host "Downloading: $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Host "Saved: $dest"
    }
    catch {
        Write-Host "FAILED: $url"
    }
}

# -------------------------------
# WinPmem (Memory Acquisition)
# -------------------------------
Download `
  "https://github.com/Velocidex/WinPmem/releases/latest/download/winpmem_mini_x64.exe" `
  "$root\Memory\winpmem.exe"

# -------------------------------
# Volatility 3
# -------------------------------
Download `
  "https://github.com/volatilityfoundation/volatility3/archive/refs/heads/master.zip" `
  "$root\Memory\volatility\volatility3.zip"

# -------------------------------
# Volatility 2
# -------------------------------
Download `
  "https://github.com/volatilityfoundation/volatility/archive/refs/heads/master.zip" `
  "$root\Memory\volatility\volatility2.zip"

# -------------------------------
# FTK Imager CLI (manual download required)
# -------------------------------
Write-Host "FTK Imager CLI must be downloaded manually from Exterro:"
Write-Host "https://www.exterro.com/ftk-imager"

# -------------------------------
# EZTools (Eric Zimmerman)
# -------------------------------
Download `
  "https://ericzimmerman.github.io/eztools.zip" `
  "$root\EZTools\eztools.zip"

# -------------------------------
# Sysinternals Suite
# -------------------------------
Download `
  "https://download.sysinternals.com/files/SysinternalsSuite.zip" `
  "$root\Sysinternals\SysinternalsSuite.zip"

# -------------------------------
# Chainsaw (Event Log Hunting)
# -------------------------------
Download `
  "https://github.com/countercept/chainsaw/releases/latest/download/chainsaw.zip" `
  "$root\Logs\chainsaw.zip"

# -------------------------------
# Plaso / log2timeline
# -------------------------------
Download `
  "https://github.com/log2timeline/plaso/releases/latest/download/plaso.zip" `
  "$root\Timeline\plaso.zip"

# -------------------------------
# Hindsight (Browser Forensics)
# -------------------------------
Download `
  "https://github.com/obsidianforensics/hindsight/archive/refs/heads/master.zip" `
  "$root\Browser\hindsight.zip"

# -------------------------------
# Unfurl (URL Analysis)
# -------------------------------
Download `
  "https://github.com/obsidianforensics/unfurl/archive/refs/heads/master.zip" `
  "$root\Browser\unfurl.zip"

# -------------------------------
# Hashdeep
# -------------------------------
Download `
  "https://github.com/jessek/hashdeep/archive/refs/heads/master.zip" `
  "$root\Hashing\hashdeep.zip"

# -------------------------------
# CyberChef (Portable)
# -------------------------------
Download `
  "https://gchq.github.io/CyberChef/CyberChef_v10.8.2.html" `
  "$root\Misc\cyberchef.html"

# -------------------------------
# YARA
# -------------------------------
Download `
  "https://github.com/VirusTotal/yara/releases/latest/download/yara.zip" `
  "$root\Misc\yara.zip"

Write-Host ""
Write-Host "All downloads complete (except FTK Imager CLI)."
Write-Host "Extract ZIPs manually or add auto-extraction logic."
