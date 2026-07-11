<#
Imaging.psm1
Disk imaging module.
Requires:
  - PowerShell 7.x (Full Mode)
Preferred drive sizes:
  - F: ≥ 10 GB (logs/metadata)
  - G: ≥ target disk size (image storage)
#>

function Invoke-ForensicImaging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$DriveStatus,
        [Parameter(Mandatory)][string]$EvidenceRoot,
        [Parameter(Mandatory)][string]$ImageRoot
    )

    if ($Global:CompatibilityMode) {
        Write-Log "ForensicImaging skipped: requires PowerShell 7." "WARN"
        return
    }

    if (-not $DriveStatus["F"]) {
        Write-Log "ForensicImaging skipped: F: (evidence) missing." "WARN"
        return
    }

    if (-not $DriveStatus["G"]) {
        Write-Log "Forensic