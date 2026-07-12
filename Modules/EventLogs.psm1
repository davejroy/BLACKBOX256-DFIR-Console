<#
EventLogs.psm1
Exports Windows event logs.
Compatible with:
  - PowerShell 5.1 (Limited Mode)
  - PowerShell 7.x (Full Mode)
Preferred drive size:
  - F: ≥ 5 GB
#>

function Invoke-EventLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$DriveStatus,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    if (-not $DriveStatus["F"]) {
        Write-Log "EventLogs skipped: F: (evidence) missing." "WARN"
        return
    }

    if (-not (Check-FreeSpace -DrivePath $EvidenceRoot -RequiredGB 5)) {
        Write-Log "EventLogs skipped: insufficient space on F:." "WARN"
        return
    }

    $outDir = Join-Path $EvidenceRoot "EventLogs"
    Ensure-Directory $outDir

    Write-Log "EventLogs started."

    $logs = @("System","Security","Application")

    foreach ($log in $logs) {
        try {
            $target = Join-Path $outDir "$log.evtx"
            wevtutil epl $log $target
            Write-Log "Exported $log log to $target"
        }
        catch {
            Write-Log "EventLogs error exporting $log: $($_.Exception.Message)" "ERROR"
        }
    }

    Write-Log "EventLogs completed."
}

Export-ModuleMember -Function Invoke-EventLogs
