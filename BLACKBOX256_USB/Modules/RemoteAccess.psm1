<#
RemoteAccess.psm1
Collects remote access artifacts (RDP, VPN, remote tools).
Compatible with:
  - PowerShell 5.1 (Limited Mode)
  - PowerShell 7.x (Full Mode)
Preferred drive size:
  - F: ≥ 1 GB
#>

function Invoke-RemoteAccessSuite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$DriveStatus,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    if (-not $DriveStatus["F"]) {
        Write-Log "RemoteAccessSuite skipped: F: (evidence) missing." "WARN"
        return
    }

    if (-not (Check-FreeSpace -DrivePath $EvidenceRoot -RequiredGB 1)) {
        Write-Log "RemoteAccessSuite skipped: insufficient space on F:." "WARN"
        return
    }

    $outDir = Join-Path $EvidenceRoot "RemoteAccess"
    Ensure-Directory $outDir

    Write-Log "RemoteAccessSuite started."

    try {
        # RDP servers
        Get-ItemProperty "HKCU:\Software\Microsoft\Terminal Server Client\Servers\*" |
            Out-File (Join-Path $outDir "RDP_Servers.txt")

        # RDP MRU
        Get-ItemProperty "HKCU:\Software\Microsoft\Terminal Server Client\Default" |
            Out-File (Join-Path $outDir "RDP_MRU.txt")

        # Remote access services
        Get-Service | Where-Object {
            $_.Name -match "TeamViewer|AnyDesk|VNC|RDP|Remote"
        } | Out-File (Join-Path $outDir "RemoteServices.txt")
    }
    catch {
        Write-Log "RemoteAccessSuite error: $($_.Exception.Message)" "ERROR"
    }

    Write-Log "RemoteAccessSuite completed."
}

Export-ModuleMember -Function Invoke-RemoteAccessSuite
