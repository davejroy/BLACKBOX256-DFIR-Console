<#
Registry.psm1
Exports persistence-related registry keys.
Compatible with:
  - PowerShell 5.1 (Limited Mode)
  - PowerShell 7.x (Full Mode)
Preferred drive size:
  - F: ≥ 1 GB
#>

function Invoke-RegistryPersistence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$DriveStatus,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    if (-not $DriveStatus["F"]) {
        Write-Log "RegistryPersistence skipped: F: (evidence) missing." "WARN"
        return
    }

    if (-not (Check-FreeSpace -DrivePath $EvidenceRoot -RequiredGB 1)) {
        Write-Log "RegistryPersistence skipped: insufficient space on F:." "WARN"
        return
    }

    $outDir = Join-Path $EvidenceRoot "RegistryPersistence"
    Ensure-Directory $outDir

    Write-Log "RegistryPersistence started."

    $keys = @(
        "HKLM\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )

    foreach ($key in $keys) {
        try {
            $safeName = $key.Replace("\","_").Replace(":","")
            $target = Join-Path $outDir "$safeName.reg"
            reg export $key $target /y | Out-Null
            Write-Log "Exported registry key $key to $target"
        }
        catch {
            Write-Log "RegistryPersistence error exporting $key: $($_.Exception.Message)" "ERROR"
        }
    }

    Write-Log "RegistryPersistence completed."
}

Export-ModuleMember -Function Invoke-RegistryPersistence
