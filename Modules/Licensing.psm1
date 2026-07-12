<#
Licensing.psm1
Collects OS licensing information.
Compatible with:
  - PowerShell 5.1 (Limited Mode)
  - PowerShell 7.x (Full Mode)
Preferred drive size:
  - F: ≥ 1 GB
#>

function Invoke-LicensingSuite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$DriveStatus,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    if (-not $DriveStatus["F"]) {
        Write-Log "LicensingSuite skipped: F: (evidence) missing." "WARN"
        return
    }

    if (-not (Check-FreeSpace -DrivePath $EvidenceRoot -RequiredGB 1)) {
        Write-Log "LicensingSuite skipped: insufficient space on F:." "WARN"
        return
    }

    $outDir = Join-Path $EvidenceRoot "Licensing"
    Ensure-Directory $outDir

    Write-Log "LicensingSuite started."

    try {
        slmgr /dli | Out-File (Join-Path $outDir "slmgr_dli.txt")
        slmgr /xpr | Out-File (Join-Path $outDir "slmgr_xpr.txt")
    }
    catch {
        Write-Log "LicensingSuite error: $($_.Exception.Message)" "ERROR"
    }

    Write-Log "LicensingSuite completed."
}

Export-ModuleMember -Function Invoke-LicensingSuite
