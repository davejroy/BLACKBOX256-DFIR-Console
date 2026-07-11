<#
SystemInfo.psm1
Collects basic system and OS information.
Compatible with:
  - PowerShell 5.1 (Limited Mode)
  - PowerShell 7.x (Full Mode)
Preferred drive size:
  - F: ≥ 1 GB
#>

function Invoke-SystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$DriveStatus,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    if (-not $DriveStatus["F"]) {
        Write-Log "SystemInfo skipped: F: (evidence) missing." "WARN"
        return
    }

    if (-not (Check-FreeSpace -DrivePath $EvidenceRoot -RequiredGB 1)) {
        Write-Log "SystemInfo skipped: insufficient space on F:." "WARN"
        return
    }

    $outDir = Join-Path $EvidenceRoot "SystemInfo"
    Ensure-Directory $outDir

    Write-Log "SystemInfo started."

    try {
        Get-ComputerInfo | Out-File (Join-Path $outDir "ComputerInfo.txt")
        Get-WmiObject Win32_OperatingSystem | Out-File (Join-Path $outDir "OS_WMI.txt")
        Get-WmiObject Win32_ComputerSystem | Out-File (Join-Path $outDir "ComputerSystem_WMI.txt")
    }
    catch {
        Write-Log "SystemInfo error: $($_.Exception.Message)" "ERROR"
    }

    Write-Log "SystemInfo completed."
}

Export-ModuleMember -Function Invoke-SystemInfo
