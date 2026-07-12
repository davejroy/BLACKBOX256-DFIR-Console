<#
Timeline.psm1
Plaso timeline generation module for BLACKBOX256.
Requires:
  - PowerShell 7.x (recommended)
  - Portable Plaso venv installed via Get-Tools.ps1
#>

function Invoke-TimelineAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$DriveStatus,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    Write-Host ""
    Write-Host "=== Plaso Timeline Analysis ==="

    if (-not $DriveStatus["F"]) {
        Write-Log "TimelineAnalysis skipped: F: (evidence) missing." "WARN"
        return
    }

    # Locate Plaso venv
    $timelineRoot = Join-Path $Global:ToolRoot "Tools\Timeline"
    $venv = Get-ChildItem $timelineRoot -Directory | Where-Object { $_.Name -like "plaso-venv-*" } | Select-Object -First 1

    if (-not $venv) {
        Write-Host "Plaso venv not found. Run Get-Tools.ps1 first."
        Write-Log "TimelineAnalysis skipped: Plaso venv missing." "ERROR"
        return
    }

    $log2timeline = Join-Path $timelineRoot "log2timeline.cmd"
    $psort        = Join-Path $timelineRoot "psort.cmd"

    if (-not (Test-Path $log2timeline)) {
        Write-Host "log2timeline.cmd missing."
        Write-Log "TimelineAnalysis skipped: log2timeline wrapper missing." "ERROR"
        return
    }

    # Ask user what to timeline
    Write-Host ""
    Write-Host "Select timeline target:"
    Write-Host "  1. Entire live system (recommended)"
    Write-Host "  2. Specific folder"
    Write-Host "  3. Disk image (E01 or RAW)"
    $choice = Read-Host "Enter choice (1-3)"

    switch ($choice) {
        "1" {
            $target = "C:\"
        }
        "2" {
            $target = Read-Host "Enter folder path to timeline"
        }
        "3" {
            $target = Read-Host "Enter full path to disk image (E01 or RAW)"
        }
        default {
            Write-Host "Invalid choice. Defaulting to live system."
            $target = "C:\"
        }
    }

    # Output directory
    $outDir = Join-Path $EvidenceRoot "Timeline"
    Ensure-Directory $outDir

    $storageFile = Join-Path $outDir "plaso_storage.plaso"
    $timelineCsv = Join-Path $outDir "timeline.csv"

    Write-Log "TimelineAnalysis started. Target: $target"

    # Run log2timeline
    Write-Host ""
    Write-Host "Running log2timeline..."
    Write-Log "Running log2timeline on $target"

    & $log2timeline $storageFile $target

    Write-Host ""
    Write-Host "Running psort..."
    Write-Log "Running psort to generate CSV timeline"

    & $psort -o l2tcsv -w $timelineCsv $storageFile

    Write-Host ""
    Write-Host "Timeline complete."
    Write-Host "Output:"
    Write-Host "  Storage file: $storageFile"
    Write-Host "  CSV timeline: $timelineCsv"

    Write-Log "TimelineAnalysis completed."
}

Export-ModuleMember -Function Invoke-TimelineAnalysis
