<#
.SYNOPSIS
    BLACKBOX256 DFIR Case Engine

.DESCRIPTION
    Handles:
      - Case initialization
      - Evidence intake (SHA256 + SHA512)
      - Chain-of-custody logging
      - Case manifest
      - Profile-aware module runner
      - Timeline builder (Phase 1)
      - CoC validation
#>

param()

# --- Global paths ---
$ScriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CasesRoot   = Join-Path $ScriptRoot "..\..\Cases"  # adjust if needed

if (-not (Test-Path $CasesRoot)) {
    New-Item -ItemType Directory -Path $CasesRoot | Out-Null
}

function New-DfirCase {
    param(
        [string]$CaseName,
        [string]$IncidentType,
        [string]$Analyst
    )

    if (-not $CaseName) {
        $CaseName = Read-Host "Case name (e.g., 2026-07-11-Ransomware-ACME)"
    }
    if (-not $IncidentType) {
        $IncidentType = $Global:DfirProfile
    }
    if (-not $Analyst) {
        $Analyst = Read-Host "Analyst name"
    }

    $casePath = Join-Path $CasesRoot $CaseName

    foreach ($sub in @("Evidence","Reports","Timeline","Tools","ChainOfCustody")) {
        $p = Join-Path $casePath $sub
        if (-not (Test-Path $p)) {
            New-Item -ItemType Directory -Path $p | Out-Null
        }
    }

    $manifest = [PSCustomObject]@{
        CaseName     = $CaseName
        IncidentType = $IncidentType
        Analyst      = $Analyst
        DfirProfile  = $Global:DfirProfile
        CreatedAt    = (Get-Date).ToString("o")
    }

    $manifestPath = Join-Path $casePath "Manifest.json"
    $manifest | ConvertTo-Json -Depth 5 | Out-File $manifestPath -Encoding UTF8

    Write-Host "[+] Case created at: $casePath"
    return $casePath
}

function Get-HashBundle {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Path not found: $Path"
    }

    $sha256 = Get-FileHash -Algorithm SHA256 -Path $Path
    $sha512 = Get-FileHash -Algorithm SHA512 -Path $Path

    return [PSCustomObject]@{
        Path   = $Path
        SHA256 = $sha256.Hash
        SHA512 = $sha512.Hash
    }
}

function Invoke-EvidenceIntake {
    param(
        [string]$CasePath
    )

    if (-not $CasePath) {
        throw "CasePath is required. Call New-DfirCase first."
    }

    $evidenceRoot = Join-Path $CasePath "Evidence"
    $cocRoot      = Join-Path $CasePath "ChainOfCustody"

    $intakeFile   = Join-Path $cocRoot "EvidenceIntake.json"
    $hashFile     = Join-Path $cocRoot "EvidenceHashes.json"

    $intake = @()
    $hashes = @()

    while ($true) {
        $src = Read-Host "Evidence source path (blank to finish)"
        if ([string]::IsNullOrWhiteSpace($src)) { break }

        if (-not (Test-Path $src)) {
            Write-Host "[!] Path not found: $src" -ForegroundColor Red
            continue
        }

        $name = Split-Path $src -Leaf
        $dest = Join-Path $evidenceRoot $name

        Copy-Item -Path $src -Destination $dest -Force

        $bundle = Get-HashBundle -Path $dest

        $entry = [PSCustomObject]@{
            EvidenceName   = $name
            SourcePath     = $src
            StoredPath     = $dest
            Timestamp      = (Get-Date).ToString("o")
            Analyst        = $env:USERNAME
            Hashes         = @{
                SHA256 = $bundle.SHA256
                SHA512 = $bundle.SHA512
            }
        }

        $intake += $entry
        $hashes += $bundle

        Write-Host "[+] Evidence ingested: $name"
        Write-Host "    SHA256: $($bundle.SHA256)"
        Write-Host "    SHA512: $($bundle.SHA512)"
    }

    if ($intake.Count -gt 0) {
        $intake | ConvertTo-Json -Depth 5 | Out-File $intakeFile -Encoding UTF8
        $hashes | ConvertTo-Json -Depth 5 | Out-File $hashFile -Encoding UTF8
        Write-Host "[+] Evidence intake logged to: $intakeFile"
        Write-Host "[+] Evidence hashes logged to: $hashFile"
    } else {
        Write-Host "[!] No evidence ingested."
    }
}

function Invoke-ProfileModuleRunner {
    param(
        [string]$CasePath
    )

    if (-not $CasePath) {
        throw "CasePath is required."
    }

    $toolsOutRoot = Join-Path $CasePath "Tools"
    if (-not (Test-Path $toolsOutRoot)) {
        New-Item -ItemType Directory -Path $toolsOutRoot | Out-Null
    }

    $execLogPath = Join-Path $CasePath "ChainOfCustody\ExecutionLog.json"
    $execLog = @()

    Write-Host "[+] Running profile modules for: $Global:DfirProfile"

    foreach ($tool in $Global:DfirTools) {
        $timestamp = (Get-Date).ToString("o")

        # Placeholder: integrate actual tool runners here
        $outFile = Join-Path $toolsOutRoot ("{0}-{1}.log" -f $tool, (Get-Date -Format "yyyyMMddHHmmss"))
        "Placeholder output for $tool" | Out-File $outFile -Encoding UTF8

        $hashBundle = Get-HashBundle -Path $outFile

        $entry = [PSCustomObject]@{
            Tool       = $tool
            OutputPath = $outFile
            Timestamp  = $timestamp
            Analyst    = $env:USERNAME
            Hashes     = @{
                SHA256 = $hashBundle.SHA256
                SHA512 = $hashBundle.SHA512
            }
        }

        $execLog += $entry

        Write-Host "[+] Ran tool: $tool"
        Write-Host "    Output: $outFile"
        Write-Host "    SHA256: $($hashBundle.SHA256)"
        Write-Host "    SHA512: $($hashBundle.SHA512)"
    }

    if ($execLog.Count -gt 0) {
        $execLog | ConvertTo-Json -Depth 5 | Out-File $execLogPath -Encoding UTF8
        Write-Host "[+] Execution log written to: $execLogPath"
    }
}

function Build-Timeline {
    param(
        [string]$CasePath
    )

    if (-not $CasePath) {
        throw "CasePath is required."
    }

    $timelineRoot = Join-Path $CasePath "Timeline"
    if (-not (Test-Path $timelineRoot)) {
        New-Item -ItemType Directory -Path $timelineRoot | Out-Null
    }

    $timelineJson = Join-Path $timelineRoot "timeline.json"

    # Phase 1: simple placeholder timeline
    $events = @(
        [PSCustomObject]@{
            Source    = "Placeholder"
            Timestamp = (Get-Date).ToString("o")
            Event     = "Timeline initialized for case."
        }
    )

    $events | ConvertTo-Json -Depth 5 | Out-File $timelineJson -Encoding UTF8
    Write-Host "[+] Timeline initialized at: $timelineJson"
}

function Validate-ChainOfCustody {
    param(
        [string]$CasePath
    )

    if (-not $CasePath) {
        throw "CasePath is required."
    }

    $cocRoot   = Join-Path $CasePath "ChainOfCustody"
    $hashFile  = Join-Path $cocRoot "EvidenceHashes.json"

    if (-not (Test-Path $hashFile)) {
        Write-Host "[!] No EvidenceHashes.json found for case." -ForegroundColor Yellow
        return
    }

    $stored = Get-Content $hashFile | ConvertFrom-Json
    $results = @()

    foreach ($item in $stored) {
        $path = $item.Path
        if (-not (Test-Path $path)) {
            $results += [PSCustomObject]@{
                Path    = $path
                Status  = "Missing"
                SHA256  = $null
                SHA512  = $null
                Match   = $false
            }
            continue
        }

        $current = Get-HashBundle -Path $path

        $match256 = ($current.SHA256 -eq $item.SHA256)
        $match512 = ($current.SHA512 -eq $item.SHA512)

        $results += [PSCustomObject]@{
            Path    = $path
            Status  = "Present"
            SHA256  = $current.SHA256
            SHA512  = $current.SHA512
            Match   = ($match256 -and $match512)
        }
    }

    $validationFile = Join-Path $cocRoot "CoC-Validation.json"
    $results | ConvertTo-Json -Depth 5 | Out-File $validationFile -Encoding UTF8

    Write-Host "[+] Chain-of-custody validation written to: $validationFile"
}
