<#
Utils.psm1
Core utilities for BLACKBOX256 DFIR Platform.
Provides:
  - Logging
  - Directory creation
  - Drive free-space checks
  - Drive availability checks
  - Experience level selection
  - Incident context collection
#>

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [$Level] $Message"
    Write-Host $line

    try {
        if ($Global:LogFile) {
            $logDir = Split-Path $Global:LogFile -Parent
            if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
            Add-Content -Path $Global:LogFile -Value $line
        }
    } catch { }
}

function Ensure-Directory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $driveLetter = $Path.Substring(0,1)
    if (-not (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue)) {
        Write-Log "Drive ${driveLetter}: missing. Cannot create directory ${Path}." "WARN"
        return
    }

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Log "Created directory: ${Path}"
    }
}

function Check-FreeSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DrivePath,
        [Parameter(Mandatory)][int]$RequiredGB
    )

    $driveLetter = $DrivePath.Substring(0,1)
    $drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue

    if (-not $drive) {
        Write-Log "Drive ${driveLetter}: not found." "ERROR"
        return $false
    }

    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Log "Drive ${driveLetter}: free space ${freeGB} GB"

    if ($freeGB -lt $RequiredGB) {
        Write-Host "WARNING: Drive ${driveLetter}: has ${freeGB} GB free. Required: ${RequiredGB} GB."
        return $false
    }

    return $true
}

function Check-DriveAvailability {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$DriveStatus)

    Write-Host ""
    Write-Host "=== BLACKBOX256 Drive Availability Check ==="

    $requiredDrives = @{
        "E" = "BLACKBOX256 Tools (preferred ≥ 32 GB)"
        "F" = "BLACKBOX-EVIDENCE (preferred ≥ 128 GB)"
        "G" = "FORENSIC-IMAGES (preferred ≥ target disk size)"
    }

    foreach ($letter in $requiredDrives.Keys) {

        if (Get-PSDrive -Name $letter -ErrorAction SilentlyContinue) {
            Write-Host "Drive ${letter}: detected (${requiredDrives[$letter]})."
            Write-Log "Drive ${letter}: detected."
            $DriveStatus[$letter] = $true
        }
        else {
            Write-Host ""
            Write-Host "Drive ${letter}: (${requiredDrives[$letter]}) is NOT connected."
            Write-Log "Drive ${letter}: NOT detected." "WARN"

            $response = Read-Host "Connect drive ${letter}: now and press Enter, or type SKIP"

            if (Get-PSDrive -Name $letter -ErrorAction SilentlyContinue) {
                Write-Host "Drive ${letter}: detected after user action."
                Write-Log "Drive ${letter}: detected after prompt."
                $DriveStatus[$letter] = $true
            }
            else {
                Write-Host "Drive ${letter}: still missing. Modules requiring this drive will be skipped."
                Write-Log "Drive ${letter}: still missing after prompt." "WARN"
                $DriveStatus[$letter] = $false
            }
        }
    }

    Write-Host ""
    Write-Host "Drive check complete."
    Write-Host ""
}

function Select-ExperienceLevel {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "Select your experience level:"
    Write-Host "  1. Beginner"
    Write-Host "  2. Intermediate"
    Write-Host "  3. Advanced"

    $choice = Read-Host "Enter choice (1-3)"

    switch ($choice) {
        "1" { $level = "Beginner" }
        "2" { $level = "Intermediate" }
        "3" { $level = "Advanced" }
        default { $level = "Intermediate" }
    }

    Write-Log "Experience level selected: ${level}"
    return $level
}

function Collect-IncidentContext {
    [CmdletBinding()]
    param()

    $context = [ordered]@{}

    Write-Host ""
    Write-Host "Has this machine been rebooted since suspected compromise?"
    Write-Host "  1. No"
    Write-Host "  2. Yes, once"
    Write-Host "  3. Yes, multiple times"

    $rebootChoice = Read-Host "Enter choice (1-3)"

    switch ($rebootChoice) {
        "1" { $context.RebootStatus = "NoReboot" }
        "2" { $context.RebootStatus = "SingleReboot" }
        "3" { $context.RebootStatus = "MultipleReboots" }
        default { $context.RebootStatus = "Unknown" }
    }

    Write-Host ""
    Write-Host "Is this a high-value system? (Y/N)"
    $hv = Read-Host
    $context.HighValue = ($hv -eq "Y")

    Write-Host ""
    Write-Host "Suspected active malware? (Y/N)"
    $mal = Read-Host
    $context.SuspectedActiveMalware = ($mal -eq "Y")

    Write-Host ""
    Write-Host "Triage depth:"
    Write-Host "  1. Fast"
    Write-Host "  2. Deep"

    $depth = Read-Host "Enter choice (1-2)"
    $context.TriageDepth = if ($depth -eq "1") { "Fast" } else { "Deep" }

    Write-Log "Incident context collected."
    return $context
}

Export-ModuleMember -Function * -Alias *
<#
Utils.psm1
Core utilities for BLACKBOX256 DFIR Platform.
Provides:
  - Logging
  - Directory creation
  - Drive free-space checks
  - Drive availability checks
  - Experience level selection
  - Incident context collection
#>

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [$Level] $Message"
    Write-Host $line

    try {
        if ($Global:LogFile) {
            $logDir = Split-Path $Global:LogFile -Parent
            if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
            Add-Content -Path $Global:LogFile -Value $line
        }
    } catch { }
}

function Ensure-Directory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $driveLetter = $Path.Substring(0,1)
    if (-not (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue)) {
        Write-Log "Drive ${driveLetter}: missing. Cannot create directory ${Path}." "WARN"
        return
    }

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Log "Created directory: ${Path}"
    }
}

function Check-FreeSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DrivePath,
        [Parameter(Mandatory)][int]$RequiredGB
    )

    $driveLetter = $DrivePath.Substring(0,1)
    $drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue

    if (-not $drive) {
        Write-Log "Drive ${driveLetter}: not found." "ERROR"
        return $false
    }

    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Log "Drive ${driveLetter}: free space ${freeGB} GB"

    if ($freeGB -lt $RequiredGB) {
        Write-Host "WARNING: Drive ${driveLetter}: has ${freeGB} GB free. Required: ${RequiredGB} GB."
        return $false
    }

    return $true
}

function Check-DriveAvailability {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$DriveStatus)

    Write-Host ""
    Write-Host "=== BLACKBOX256 Drive Availability Check ==="

    $requiredDrives = @{
        "E" = "BLACKBOX256 Tools (preferred ≥ 32 GB)"
        "F" = "BLACKBOX-EVIDENCE (preferred ≥ 128 GB)"
        "G" = "FORENSIC-IMAGES (preferred ≥ target disk size)"
    }

    foreach ($letter in $requiredDrives.Keys) {

        if (Get-PSDrive -Name $letter -ErrorAction SilentlyContinue) {
            Write-Host "Drive ${letter}: detected (${requiredDrives[$letter]})."
            Write-Log "Drive ${letter}: detected."
            $DriveStatus[$letter] = $true
        }
        else {
            Write-Host ""
            Write-Host "Drive ${letter}: (${requiredDrives[$letter]}) is NOT connected."
            Write-Log "Drive ${letter}: NOT detected." "WARN"

            $response = Read-Host "Connect drive ${letter}: now and press Enter, or type SKIP"

            if (Get-PSDrive -Name $letter -ErrorAction SilentlyContinue) {
                Write-Host "Drive ${letter}: detected after user action."
                Write-Log "Drive ${letter}: detected after prompt."
                $DriveStatus[$letter] = $true
            }
            else {
                Write-Host "Drive ${letter}: still missing. Modules requiring this drive will be skipped."
                Write-Log "Drive ${letter}: still missing after prompt." "WARN"
                $DriveStatus[$letter] = $false
            }
        }
    }

    Write-Host ""
    Write-Host "Drive check complete."
    Write-Host ""
}

function Select-ExperienceLevel {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "Select your experience level:"
    Write-Host "  1. Beginner"
    Write-Host "  2. Intermediate"
    Write-Host "  3. Advanced"

    $choice = Read-Host "Enter choice (1-3)"

    switch ($choice) {
        "1" { $level = "Beginner" }
        "2" { $level = "Intermediate" }
        "3" { $level = "Advanced" }
        default { $level = "Intermediate" }
    }

    Write-Log "Experience level selected: ${level}"
    return $level
}

function Collect-IncidentContext {
    [CmdletBinding()]
    param()

    $context = [ordered]@{}

    Write-Host ""
    Write-Host "Has this machine been rebooted since suspected compromise?"
    Write-Host "  1. No"
    Write-Host "  2. Yes, once"
    Write-Host "  3. Yes, multiple times"

    $rebootChoice = Read-Host "Enter choice (1-3)"

    switch ($rebootChoice) {
        "1" { $context.RebootStatus = "NoReboot" }
        "2" { $context.RebootStatus = "SingleReboot" }
        "3" { $context.RebootStatus = "MultipleReboots" }
        default { $context.RebootStatus = "Unknown" }
    }

    Write-Host ""
    Write-Host "Is this a high-value system? (Y/N)"
    $hv = Read-Host
    $context.HighValue = ($hv -eq "Y")

    Write-Host ""
    Write-Host "Suspected active malware? (Y/N)"
    $mal = Read-Host
    $context.SuspectedActiveMalware = ($mal -eq "Y")

    Write-Host ""
    Write-Host "Triage depth:"
    Write-Host "  1. Fast"
    Write-Host "  2. Deep"

    $depth = Read-Host "Enter choice (1-2)"
    $context.TriageDepth = if ($depth -eq "1") { "Fast" } else { "Deep" }

    Write-Log "Incident context collected."
    return $context
}

Export-ModuleMember -Function * -Alias *
<#
Utils.psm1
Core utilities for BLACKBOX256 DFIR Platform.
Provides:
  - Logging
  - Directory creation
  - Drive free-space checks
  - Drive availability checks
  - Experience level selection
  - Incident context collection
#>

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [$Level] $Message"
    Write-Host $line

    try {
        if ($Global:LogFile) {
            $logDir = Split-Path $Global:LogFile -Parent
            if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
            Add-Content -Path $Global:LogFile -Value $line
        }
    } catch { }
}

function Ensure-Directory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $driveLetter = $Path.Substring(0,1)
    if (-not (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue)) {
        Write-Log "Drive ${driveLetter}: missing. Cannot create directory ${Path}." "WARN"
        return
    }

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Log "Created directory: ${Path}"
    }
}

function Check-FreeSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DrivePath,
        [Parameter(Mandatory)][int]$RequiredGB
    )

    $driveLetter = $DrivePath.Substring(0,1)
    $drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue

    if (-not $drive) {
        Write-Log "Drive ${driveLetter}: not found." "ERROR"
        return $false
    }

    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Log "Drive ${driveLetter}: free space ${freeGB} GB"

    if ($freeGB -lt $RequiredGB) {
        Write-Host "WARNING: Drive ${driveLetter}: has ${freeGB} GB free. Required: ${RequiredGB} GB."
        return $false
    }

    return $true
}

function Check-DriveAvailability {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$DriveStatus)

    Write-Host ""
    Write-Host "=== BLACKBOX256 Drive Availability Check ==="

    $requiredDrives = @{
        "E" = "BLACKBOX256 Tools (preferred ≥ 32 GB)"
        "F" = "BLACKBOX-EVIDENCE (preferred ≥ 128 GB)"
        "G" = "FORENSIC-IMAGES (preferred ≥ target disk size)"
    }

    foreach ($letter in $requiredDrives.Keys) {

        if (Get-PSDrive -Name $letter -ErrorAction SilentlyContinue) {
            Write-Host "Drive ${letter}: detected (${requiredDrives[$letter]})."
            Write-Log "Drive ${letter}: detected."
            $DriveStatus[$letter] = $true
        }
        else {
            Write-Host ""
            Write-Host "Drive ${letter}: (${requiredDrives[$letter]}) is NOT connected."
            Write-Log "Drive ${letter}: NOT detected." "WARN"

            $response = Read-Host "Connect drive ${letter}: now and press Enter, or type SKIP"

            if (Get-PSDrive -Name $letter -ErrorAction SilentlyContinue) {
                Write-Host "Drive ${letter}: detected after user action."
                Write-Log "Drive ${letter}: detected after prompt."
                $DriveStatus[$letter] = $true
            }
            else {
                Write-Host "Drive ${letter}: still missing. Modules requiring this drive will be skipped."
                Write-Log "Drive ${letter}: still missing after prompt." "WARN"
                $DriveStatus[$letter] = $false
            }
        }
    }

    Write-Host ""
    Write-Host "Drive check complete."
    Write-Host ""
}

function Select-ExperienceLevel {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "Select your experience level:"
    Write-Host "  1. Beginner"
    Write-Host "  2. Intermediate"
    Write-Host "  3. Advanced"

    $choice = Read-Host "Enter choice (1-3)"

    switch ($choice) {
        "1" { $level = "Beginner" }
        "2" { $level = "Intermediate" }
        "3" { $level = "Advanced" }
        default { $level = "Intermediate" }
    }

    Write-Log "Experience level selected: ${level}"
    return $level
}

function Collect-IncidentContext {
    [CmdletBinding()]
    param()

    $context = [ordered]@{}

    Write-Host ""
    Write-Host "Has this machine been rebooted since suspected compromise?"
    Write-Host "  1. No"
    Write-Host "  2. Yes, once"
    Write-Host "  3. Yes, multiple times"

    $rebootChoice = Read-Host "Enter choice (1-3)"

    switch ($rebootChoice) {
        "1" { $context.RebootStatus = "NoReboot" }
        "2" { $context.RebootStatus = "SingleReboot" }
        "3" { $context.RebootStatus = "MultipleReboots" }
        default { $context.RebootStatus = "Unknown" }
    }

    Write-Host ""
    Write-Host "Is this a high-value system? (Y/N)"
    $hv = Read-Host
    $context.HighValue = ($hv -eq "Y")

    Write-Host ""
    Write-Host "Suspected active malware? (Y/N)"
    $mal = Read-Host
    $context.SuspectedActiveMalware = ($mal -eq "Y")

    Write-Host ""
    Write-Host "Triage depth:"
    Write-Host "  1. Fast"
    Write-Host "  2. Deep"

    $depth = Read-Host "Enter choice (1-2)"
    $context.TriageDepth = if ($depth -eq "1") { "Fast" } else { "Deep" }

    Write-Log "Incident context collected."
    return $context
}

Export-ModuleMember -Function * -Alias *
