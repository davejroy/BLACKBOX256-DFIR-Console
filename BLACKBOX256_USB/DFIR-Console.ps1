<#
DFIR-Console.ps1
BLACKBOX256 DFIR Console (Modular, Version-Aware, PowerShell 5.1–7.6.3 Compatible)
Author: David (Vardryn/Tyvant DFIR Labs)
#>

# ============================================================
# PowerShell Version Detection + Compatibility Mode
# ============================================================

$major = $PSVersionTable.PSVersion.Major
$minor = $PSVersionTable.PSVersion.Minor

Write-Host ""
Write-Host "Detected PowerShell version: $major.$minor"
Write-Host ""

# -------------------------------------------
# Reject anything older than 5.1
# -------------------------------------------
if ($major -lt 5 -or ($major -eq 5 -and $minor -lt 1)) {
    Write-Host "ERROR: BLACKBOX256 requires at least PowerShell 5.1."
    Write-Host "Your version is deprecated and cannot run this DFIR console."
    exit
}

# -------------------------------------------
# PowerShell 5.1 → Limited Mode
# -------------------------------------------
if ($major -eq 5) {

    Write-Host "==============================================================="
    Write-Host "  LIMITED MODE: Running BLACKBOX256 under PowerShell 5.1"
    Write-Host "==============================================================="
    Write-Host ""
    Write-Host "Your PowerShell version is legacy and missing modern features."
    Write-Host ""
    Write-Host "Available modules:"
    Write-Host "  ✔ System Info"
    Write-Host "  ✔ Event Logs"
    Write-Host "  ✔ Registry Persistence"
    Write-Host "  ✔ Remote Access"
    Write-Host "  ✔ Licensing"
    Write-Host ""
    Write-Host "Unavailable modules:"
    Write-Host "  ✖ Memory Capture (requires PS7)"
    Write-Host "  ✖ Forensic Imaging (requires PS7)"
    Write-Host "  ✖ Advanced triage features"
    Write-Host ""
    Write-Host "PowerShell 7 is strongly recommended for:"
    Write-Host "  - Full DFIR capability"
    Write-Host "  - Better stability"
    Write-Host "  - Modern module support"
    Write-Host "  - Improved performance"
    Write-Host ""

    $upgrade = Read-Host "Upgrade to PowerShell 7 now? (Y/N)"

    if ($upgrade -eq "Y") {
        Write-Host "Installing PowerShell 7 via Winget..."
        try {
            winget install Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
            Write-Host "PowerShell 7 installed. Relaunching..."
            & "C:\Program Files\PowerShell\7\pwsh.exe" -File $PSCommandPath
            exit
        } catch {
            Write-Host "Automatic installation failed. Continuing in limited mode."
        }
    }

    # Enable compatibility mode
    $Global:CompatibilityMode = $true
}

# -------------------------------------------
# PowerShell 7+ → Full Mode
# -------------------------------------------
if ($major -ge 7) {
    Write-Host "==============================================================="
    Write-Host "  FULL MODE: Running BLACKBOX256 under PowerShell 7.x"
    Write-Host "==============================================================="
    Write-Host ""
    $Global:CompatibilityMode = $false
}

# ============================================================
# Global Configuration
# ============================================================

$Global:ToolRoot      = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB"
$Global:EvidenceRoot  = "F:\BLACKBOX-EVIDENCE"
$Global:ImageRoot     = "G:\FORENSIC-IMAGES"

$Global:DriveStatus = @{
    "E" = $false
    "F" = $false
    "G" = $false
}

$Global:LogFile = Join-Path $Global:EvidenceRoot "BLACKBOX256_DFIR_Console.log"

# ============================================================
# Module Imports
# ============================================================

Import-Module (Join-Path $Global:ToolRoot "Modules\Utils.psm1")          -Force
Import-Module (Join-Path $Global:ToolRoot "Modules\SystemInfo.psm1")     -Force
Import-Module (Join-Path $Global:ToolRoot "Modules\EventLogs.psm1")      -Force
Import-Module (Join-Path $Global:ToolRoot "Modules\Registry.psm1")       -Force
Import-Module (Join-Path $Global:ToolRoot "Modules\RemoteAccess.psm1")   -Force
Import-Module (Join-Path $Global:ToolRoot "Modules\Licensing.psm1")      -Force
Import-Module (Join-Path $Global:ToolRoot "Modules\MemoryCapture.psm1")  -Force
Import-Module (Join-Path $Global:ToolRoot "Modules\Imaging.psm1")        -Force

# ============================================================
# Startup: Drive Checks, Experience Level, Incident Context
# ============================================================

Ensure-Directory (Split-Path $Global:LogFile -Parent)
Write-Log "BLACKBOX256 DFIR Console started."

Check-DriveAvailability -DriveStatus $Global:DriveStatus

$experience = Select-ExperienceLevel
$context    = Collect-IncidentContext

# ============================================================
# Menus
# ============================================================

function Show-MainMenu {
    Write-Host ""
    Write-Host "=== BLACKBOX256 DFIR Main Menu ==="
    Write-Host "  1. Primary Modules"
    Write-Host "  2. Secondary Modules"
    Write-Host "  3. Advanced Modules (PS7 only)"
    Write-Host "  4. Run ALL Modules"
    Write-Host "  5. Exit"
    Read-Host "Select option (1-5)"
}

function Show-PrimaryMenu {
    Write-Host ""
    Write-Host "Primary Modules:"
    Write-Host "  1. System & OS Info (preferred F: ≥ 1 GB)"
    Write-Host "  2. Event Logs (preferred F: ≥ 5 GB)"
    Write-Host "  3. Registry Persistence (preferred F: ≥ 1 GB)"
    Write-Host "  4. Run ALL"
    Read-Host "Select option (1-4)"
}

function Show-SecondaryMenu {
    Write-Host ""
    Write-Host "Secondary Modules:"
    Write-Host "  1. Remote Access Suite (preferred F: ≥ 1 GB)"
    Write-Host "  2. Licensing Suite (preferred F: ≥ 1 GB)"
    Write-Host "  3. Run ALL"
    Read-Host "Select option (1-3)"
}

function Show-AdvancedMenu {
    Write-Host ""
    Write-Host "Advanced DFIR Modules (PowerShell 7 required):"
    Write-Host "  1. Memory Capture (preferred F: ≥ 128 GB)"
    Write-Host "  2. Forensic Imaging (preferred F: ≥ 10 GB, G: ≥ target disk size)"
    Write-Host "  3. Run ALL"
    Read-Host "Select option (1-3)"
}

# ============================================================
# Orchestration
# ============================================================

function Run-PrimaryModules {
    param([string]$choice)

    switch ($choice) {
        "1" { Invoke-SystemInfo          -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot }
        "2" { Invoke-EventLogs           -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot }
        "3" { Invoke-RegistryPersistence -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot }
        "4" {
            Invoke-SystemInfo          -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot
            Invoke-EventLogs           -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot
            Invoke-RegistryPersistence -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot
        }
    }
}

function Run-SecondaryModules {
    param([string]$choice)

    switch ($choice) {
        "1" { Invoke-RemoteAccessSuite -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot }
        "2" { Invoke-LicensingSuite    -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot }
        "3" {
            Invoke-RemoteAccessSuite -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot
            Invoke-LicensingSuite    -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot
        }
    }
}

function Run-AdvancedModules {
    param([string]$choice)

    if ($Global:CompatibilityMode) {
        Write-Host ""
        Write-Host "Advanced modules require PowerShell 7."
        Write-Host "Please upgrade to unlock Memory Capture and Forensic Imaging."
        Write-Host ""
        return
    }

    switch ($choice) {
        "1" { Invoke-MemoryCapture   -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot -Context $context }
        "2" { Invoke-ForensicImaging -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot -ImageRoot $Global:ImageRoot }
        "3" {
            Invoke-MemoryCapture   -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot -Context $context
            Invoke-ForensicImaging -DriveStatus $Global:DriveStatus -EvidenceRoot $Global:EvidenceRoot -ImageRoot $Global:ImageRoot
        }
    }
}

function Start-DFIRConsole {

    while ($true) {
        $mainChoice = Show-MainMenu

        switch ($mainChoice) {
            "1" {
                $p = Show-PrimaryMenu
                Run-PrimaryModules -choice $p
            }
            "2" {
                $s = Show-SecondaryMenu
                Run-SecondaryModules -choice $s
            }
            "3" {
                $a = Show-AdvancedMenu
                Run-AdvancedModules -choice $a
            }
            "4" {
                Run-PrimaryModules   -choice "4"
                Run-SecondaryModules -choice "3"
                Run-AdvancedModules  -choice "3"
            }
            "5" {
                Write-Log "DFIR Console exiting."
                break
            }
            default {
                Write-Host "Invalid choice."
            }
        }
    }
}

# ============================================================
# Start Console
# ============================================================

Start-DFIRConsole
