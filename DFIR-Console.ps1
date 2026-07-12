<#
.SYNOPSIS
    BLACKBOX256 DFIR Console Loader

.DESCRIPTION
    Entry point for BLACKBOX256-DFIR-Console:
      - First-run environment validation
      - Sysinternals auto-download
      - Tool integrity dashboard (CLI + GUI)
      - DFIR profile selector (manual + tag-based)
      - Profile-aware post-release smoke test
      - JSON/HTML integrity export
      - DFIR Release Manifest JSON
      - Forensic report template
#>

# --- Global paths ---
$ScriptRoot      = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ModulesRoot     = Join-Path $ScriptRoot "Modules"
$ToolsRoot       = Join-Path $ScriptRoot "Tools"
$SysinternalsMod = Join-Path $ModulesRoot "Sysinternals\Get-Sysinternals.ps1"

#--- Load Case engine ----
$CaseEngineMod = Join-Path $ModulesRoot "CaseEngine\CaseEngine.ps1"
if (Test-Path $CaseEngineMod) {
    . $CaseEngineMod
} else {
    Write-Warning "CaseEngine module not found: $CaseEngineMod"
}

# --- Load Sysinternals auto-download ---
if (Test-Path $SysinternalsMod) {
    Import-Module $SysinternalsMod -Force
    $Global:SysinternalsPath = Get-SysinternalsSuite
} else {
    Write-Warning "Sysinternals module not found: $SysinternalsMod"
}

# Default DFIR profile
if (-not $Global:DfirProfile) { $Global:DfirProfile = "Generic Triage" }
if (-not $Global:DfirTools)   { $Global:DfirTools   = @("Plaso","Chainsaw","Sysinternals Suite") }

# ==========================
#  First-Run Environment Validator
# ==========================
function Invoke-EnvironmentValidator {
    Write-Host "=== Environment Validator ==="

    $issues = @()

    # PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "PowerShell 7+ is recommended. Current: $($PSVersionTable.PSVersion)"
    }

    # Required folders
    foreach ($path in @($ModulesRoot, $ToolsRoot)) {
        if (-not (Test-Path $path)) {
            $issues += "Missing required directory: $path"
        }
    }

    # Sysinternals presence
    if (-not (Test-Path $Global:SysinternalsPath)) {
        $issues += "Sysinternals Suite not present at: $Global:SysinternalsPath"
    }

    if ($issues.Count -eq 0) {
        Write-Host "[+] Environment OK" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[!] Environment issues detected:" -ForegroundColor Yellow
        $issues | ForEach-Object { Write-Host " - $_" }
        return $false
    }
}

# ==========================
#  Tool Integrity Dashboard (CLI)
# ==========================
function Show-ToolIntegrityDashboard {
    Write-Host "=== Tool Integrity Dashboard (CLI) ==="

    $tools = Get-ToolIntegrityData

    foreach ($tool in $tools) {
        $color = if ($tool.Status -eq "OK") { "Green" } else { "Red" }
        Write-Host ("{0,-20} {1,-8} {2}" -f $tool.Name, $tool.Status, $tool.Path) -ForegroundColor $color
    }
}

# ==========================
#  Tool Integrity Data (shared)
# ==========================
function Get-ToolIntegrityData {
    $tools = @(
        @{ Name = "Sysinternals Suite"; Path = $Global:SysinternalsPath },
        @{ Name = "Plaso";              Path = Join-Path $ToolsRoot "Plaso" },
        @{ Name = "Chainsaw";           Path = Join-Path $ToolsRoot "Chainsaw" },
        @{ Name = "EZTools";            Path = Join-Path $ToolsRoot "EZTools" },
        @{ Name = "Volatility";         Path = Join-Path $ToolsRoot "Volatility" },
        @{ Name = "YARA";               Path = Join-Path $ToolsRoot "YARA" }
    )

    $data = @()

    foreach ($tool in $tools) {
        $exists = Test-Path $tool.Path
        $data += [PSCustomObject]@{
            Name   = $tool.Name
            Path   = $tool.Path
            Status = if ($exists) { "OK" } else { "MISSING" }
        }
    }

    return $data
}

# ==========================
#  Tool Integrity Export (JSON/HTML)
# ==========================
function Export-ToolIntegrityJson {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\tool-integrity.json"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $data = Get-ToolIntegrityData
    $data | ConvertTo-Json -Depth 3 | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Tool integrity JSON exported to: $OutputPath"
}

function Export-ToolIntegrityHtml {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\tool-integrity.html"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $data = Get-ToolIntegrityData

    $html = @"
<html>
<head>
    <title>BLACKBOX256 Tool Integrity Dashboard</title>
    <style>
        body { font-family: Segoe UI, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; }
        th { background-color: #f0f0f0; }
        .ok { color: green; }
        .missing { color: red; }
    </style>
</head>
<body>
<h1>BLACKBOX256 Tool Integrity Dashboard</h1>
<p>DFIR Profile: $Global:DfirProfile</p>
<table>
<tr><th>Name</th><th>Status</th><th>Path</th></tr>
"@

    foreach ($item in $data) {
        $cls = if ($item.Status -eq "OK") { "ok" } else { "missing" }
        $html += "<tr><td>$($item.Name)</td><td class='$cls'>$($item.Status)</td><td>$($item.Path)</td></tr>`n"
    }

    $html += @"
</table>
</body>
</html>
"@

    $html | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Tool integrity HTML exported to: $OutputPath"
}

# ==========================
#  DFIR Profile Selector (manual)
# ==========================
function Select-DfirProfile {
    Write-Host "=== DFIR Profile Selector ==="
    Write-Host "1) Ransomware Incident"
    Write-Host "2) Insider Data Theft"
    Write-Host "3) Web Server Compromise"
    Write-Host "4) Generic Triage"

    $choice = Read-Host "Select profile"

    switch ($choice) {
        "1" {
            $Global:DfirProfile = "Ransomware"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Volatility", "YARA", "Sysinternals Suite")
        }
        "2" {
            $Global:DfirProfile = "Insider Theft"
            $Global:DfirTools = @("Plaso", "Browser Forensics", "EZTools", "YARA")
        }
        "3" {
            $Global:DfirProfile = "Web Compromise"
            $Global:DfirTools = @("Plaso", "Log Parsers", "YARA", "Sysinternals Suite")
        }
        "4" {
            $Global:DfirProfile = "Generic Triage"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Sysinternals Suite")
        }
        default {
            Write-Host "Invalid selection, defaulting to Generic Triage."
            $Global:DfirProfile = "Generic Triage"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Sysinternals Suite")
        }
    }

    Write-Host "[+] Active DFIR profile: $Global:DfirProfile"
    Write-Host "[+] Tools in profile: $($Global:DfirTools -join ', ')"
}

# ==========================
#  DFIR Profile Selector (from tag)
# ==========================
function Select-DfirProfileFromTag {
    param([string]$TagName)

    if ($TagName -match "ransomware") {
        $Global:DfirProfile = "Ransomware"
        $Global:DfirTools = @("Plaso","Chainsaw","Volatility","YARA","Sysinternals Suite")
    }
    elseif ($TagName -match "insider") {
        $Global:DfirProfile = "Insider Theft"
        $Global:DfirTools = @("Plaso","Browser Forensics","EZTools","YARA")
    }
    elseif ($TagName -match "web") {
        $Global:DfirProfile = "Web Compromise"
        $Global:DfirTools = @("Plaso","Log Parsers","YARA","Sysinternals Suite")
    }
    else {
        $Global:DfirProfile = "Generic Triage"
        $Global:DfirTools = @("Plaso","Chainsaw","Sysinternals Suite")
    }

    Write-Host "[+] Auto-selected DFIR profile from tag '$TagName': $Global:DfirProfile"
    Write-Host "[+] Tools: $($Global:DfirTools -join ', ')"
}

# ==========================
#  DFIR Release Manifest JSON
# ==========================
function Export-ReleaseManifestJson {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\release-manifest.json",
        [string]$TagName    = "unknown"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $versionFile = Join-Path $ScriptRoot "VERSION"
    $version     = if (Test-Path $versionFile) { Get-Content $versionFile } else { "unknown" }

    $tools = Get-ToolIntegrityData

    $manifest = [PSCustomObject]@{
        Project      = "BLACKBOX256-DFIR-Console"
        Version      = $version
        Tag          = $TagName
        DfirProfile  = $Global:DfirProfile
        Tools        = $tools
        GeneratedAt  = (Get-Date).ToString("o")
    }

    $manifest | ConvertTo-Json -Depth 5 | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Release manifest JSON exported to: $OutputPath"
}

# ==========================
#  Forensic Report Template
# ==========================
function New-ForensicReportTemplate {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\forensic-report-template.md",
        [string]$TagName    = "unknown"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $versionFile = Join-Path $ScriptRoot "VERSION"
    $version     = if (Test-Path $versionFile) { Get-Content $versionFile } else { "unknown" }

    $content = @"
# BLACKBOX256 DFIR Report

- Project: BLACKBOX256-DFIR-Console
- Version: $version
- Tag: $TagName
- DFIR Profile: $Global:DfirProfile
- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Incident Summary

## 2. Scope and Assets

## 3. Tools Used

$(($Global:DfirTools -join ", "))

## 4. Timeline

## 5. Findings

## 6. Recommendations

"@

    $content | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Forensic report template exported to: $OutputPath"
}

# ==========================
#  Post-Release Smoke Test (profile-aware)
# ==========================
function Invoke-PostReleaseSmokeTest {
    param([string]$ReleaseRoot = $ScriptRoot)

    Write-Host "=== Post-Release Smoke Test ==="

    $checks = @(
        @{ Name = "DFIR-Console.ps1"; Path = Join-Path $ReleaseRoot "DFIR-Console.ps1" },
        @{ Name = "Modules";          Path = Join-Path $ReleaseRoot "Modules" },
        @{ Name = "Tools";            Path = Join-Path $ReleaseRoot "Tools" },
        @{ Name = "VERSION";          Path = Join-Path $ReleaseRoot "VERSION" }
    )

    $failed = @()

    foreach ($check in $checks) {
        if (Test-Path $check.Path) {
            Write-Host "[+] $($check.Name) present" -ForegroundColor Green
        } else {
            Write-Host "[!] $($check.Name) missing: $($check.Path)" -ForegroundColor Red
            $failed += $check.Name
        }
    }

    Write-Host "[+] Checking DFIR profile tools: $Global:DfirProfile"

    foreach ($tool in $Global:DfirTools) {
        $path = switch ($tool) {
            "Sysinternals Suite" { $Global:SysinternalsPath }
            "Plaso"              { Join-Path $ToolsRoot "Plaso" }
            "Chainsaw"           { Join-Path $ToolsRoot "Chainsaw" }
            "EZTools"            { Join-Path $ToolsRoot "EZTools" }
            "Volatility"         { Join-Path $ToolsRoot "Volatility" }
            "YARA"               { Join-Path $ToolsRoot "YARA" }
            "Browser Forensics"  { Join-Path $ToolsRoot "BrowserForensics" }
            "Log Parsers"        { Join-Path $ToolsRoot "LogParsers" }
            default              { Join-Path $ToolsRoot $tool }
        }

        if (Test-Path $path) {
            Write-Host "[+] $tool present at $path" -ForegroundColor Green
        } else {
            Write-Host "[!] $tool missing at $path" -ForegroundColor Red
            $failed += $tool
        }
    }

    if ($failed.Count -eq 0) {
        Write-Host "[+] Smoke test PASSED" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[!] Smoke test FAILED. Missing: $($failed -join ', ')" -ForegroundColor Red
        return $false
    }
}

# ==========================
#  GUI Interface (WPF)
# ==========================
function Start-GuiInterface {
    Add-Type -AssemblyName PresentationFramework

    $window = New-Object Windows.Window
    $window.Title = "BLACKBOX256 DFIR Console"
    $window.Width = 800
    $window.Height = 600

    $grid = New-Object Windows.Controls.Grid
    $window.Content = $grid

    # Buttons
    $btnEnv = New-Object Windows.Controls.Button
    $btnEnv.Content = "Environment Validator"
    $btnEnv.Margin = "10,10,10,0"
    $btnEnv.Height = 40

    $btnTools = New-Object Windows.Controls.Button
    $btnTools.Content = "Tool Integrity Dashboard"
    $btnTools.Margin = "10,60,10,0"
    $btnTools.Height = 40

    $btnSmoke = New-Object Windows.Controls.Button
    $btnSmoke.Content = "Post-Release Smoke Test"
    $btnSmoke.Margin = "10,110,10,0"
    $btnSmoke.Height = 40

    $btnProfile = New-Object Windows.Controls.Button
    $btnProfile.Content = "DFIR Profile Selector"
    $btnProfile.Margin = "10,160,10,0"
    $btnProfile.Height = 40

    $output = New-Object Windows.Controls.TextBox
    $output.Margin = "10,210,10,10"
    $output.VerticalScrollBarVisibility = "Auto"
    $output.HorizontalScrollBarVisibility = "Auto"
    $output.AcceptsReturn = $true
    $output.IsReadOnly = $true

    $grid.Children.Add($btnEnv)
    $grid.Children.Add($btnTools)
    $grid.Children.Add($btnSmoke)
    $grid.Children.Add($btnProfile)
    $grid.Children.Add($output)

    # Wire up events
    $btnEnv.Add_Click({
        $result = Invoke-EnvironmentValidator
        $output.AppendText("Environment Validator: $result`r`n")
    })

    $btnTools.Add_Click({
        $output.AppendText("Tool Integrity Dashboard:`r`n")
        $tools = Get-ToolIntegrityData
        foreach ($tool in $tools) {
            $output.AppendText((" - {0}: {1}`r`n" -f $tool.Name, $tool.Status))
        }
    })

    $btnSmoke.Add_Click({
        $result = Invoke-PostReleaseSmokeTest -ReleaseRoot $ScriptRoot
        $output.AppendText("Smoke Test: $result`r`n")
    })

    $btnProfile.Add_Click({
        Select-DfirProfile
        $output.AppendText("DFIR Profile: $Global:DfirProfile`r`n")
    })

    $window.ShowDialog() | Out-Null
}

# ==========================
#  CLI Interface
# ==========================
function Start-CliInterface {
    Write-Host "=== BLACKBOX256 DFIR Console (CLI) ==="
    Write-Host "1) Environment Validator"
    Write-Host "2) Tool Integrity Dashboard"
    Write-Host "3) Post-Release Smoke Test"
    Write-Host "4) DFIR Profile Selector"
    Write-Host "5) Export Integrity (JSON/HTML)"
    Write-Host "6) Export Release Manifest"
    Write-Host "7) Generate Forensic Report Template"
    Write-Host "8) New DFIR Case"
    Write-Host "9) Evidence Intake (for case)"
    Write-Host "10) Run Profile Modules (for case)"
    Write-Host "11) Build Timeline (for case)"
    Write-Host "12) Validate Chain-of-Custody"
    Write-Host "Q) Quit"

    while ($true) {
        $choice = Read-Host "Select option"
        switch ($choice) {
            "1" { Invoke-EnvironmentValidator | Out-Null }
            "2" { Show-ToolIntegrityDashboard }
            "3" { Invoke-PostReleaseSmokeTest -ReleaseRoot $ScriptRoot | Out-Null }
            "4" { Select-DfirProfile }
            "5" {
                Export-ToolIntegrityJson
                Export-ToolIntegrityHtml
            }
            "6" { Export-ReleaseManifestJson -TagName "manual-cli" }
            "7" { New-ForensicReportTemplate -TagName "manual-cli" }
            "8" {
                $casePath = New-DfirCase
                Write-Host "Active case path: $casePath"
            }
            "9" {
                $casePath = Read-Host "Case path"
                Invoke-EvidenceIntake -CasePath $casePath
            }
            "10" {
                $casePath = Read-Host "Case path"
                Invoke-ProfileModuleRunner -CasePath $casePath
            }
            "11" {
                $casePath = Read-Host "Case path"
                Build-Timeline -CasePath $casePath
            }
            "12" {
                $casePath = Read-Host "Case path"
                Validate-ChainOfCustody -CasePath $casePath
            }   
            "Q" { break }
            "q" { break }
            default { Write-Host "Invalid selection." }
        }
    }
}

# ==========================
#  Mode Selection
# ==========================
Write-Host "=== BLACKBOX256 DFIR Console Loader ==="
Write-Host "Select interface mode:"
Write-Host "1) Text CLI"
Write-Host "2) GUI"

$mode = Read-Host "Enter choice (1/2)"

switch ($mode) {
    "1" { Start-CliInterface }
    "2" { Start-GuiInterface }
    default {
        Write-Host "Invalid choice, defaulting to CLI."
        Start-CliInterface
    }
}
<#
.SYNOPSIS
    BLACKBOX256 DFIR Console Loader

.DESCRIPTION
    Entry point for BLACKBOX256-DFIR-Console:
      - First-run environment validation
      - Sysinternals auto-download
      - Tool integrity dashboard (CLI + GUI)
      - DFIR profile selector (manual + tag-based)
      - Profile-aware post-release smoke test
      - JSON/HTML integrity export
      - DFIR Release Manifest JSON
      - Forensic report template
#>

# --- Global paths ---
$ScriptRoot      = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ModulesRoot     = Join-Path $ScriptRoot "Modules"
$ToolsRoot       = Join-Path $ScriptRoot "Tools"
$SysinternalsMod = Join-Path $ModulesRoot "Sysinternals\Get-Sysinternals.ps1"

# --- Load Sysinternals auto-download ---
if (Test-Path $SysinternalsMod) {
    Import-Module $SysinternalsMod -Force
    $Global:SysinternalsPath = Get-SysinternalsSuite
} else {
    Write-Warning "Sysinternals module not found: $SysinternalsMod"
}

# Default DFIR profile
if (-not $Global:DfirProfile) { $Global:DfirProfile = "Generic Triage" }
if (-not $Global:DfirTools)   { $Global:DfirTools   = @("Plaso","Chainsaw","Sysinternals Suite") }

# ==========================
#  First-Run Environment Validator
# ==========================
function Invoke-EnvironmentValidator {
    Write-Host "=== Environment Validator ==="

    $issues = @()

    # PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "PowerShell 7+ is recommended. Current: $($PSVersionTable.PSVersion)"
    }

    # Required folders
    foreach ($path in @($ModulesRoot, $ToolsRoot)) {
        if (-not (Test-Path $path)) {
            $issues += "Missing required directory: $path"
        }
    }

    # Sysinternals presence
    if (-not (Test-Path $Global:SysinternalsPath)) {
        $issues += "Sysinternals Suite not present at: $Global:SysinternalsPath"
    }

    if ($issues.Count -eq 0) {
        Write-Host "[+] Environment OK" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[!] Environment issues detected:" -ForegroundColor Yellow
        $issues | ForEach-Object { Write-Host " - $_" }
        return $false
    }
}

# ==========================
#  Tool Integrity Dashboard (CLI)
# ==========================
function Show-ToolIntegrityDashboard {
    Write-Host "=== Tool Integrity Dashboard (CLI) ==="

    $tools = Get-ToolIntegrityData

    foreach ($tool in $tools) {
        $color = if ($tool.Status -eq "OK") { "Green" } else { "Red" }
        Write-Host ("{0,-20} {1,-8} {2}" -f $tool.Name, $tool.Status, $tool.Path) -ForegroundColor $color
    }
}

# ==========================
#  Tool Integrity Data (shared)
# ==========================
function Get-ToolIntegrityData {
    $tools = @(
        @{ Name = "Sysinternals Suite"; Path = $Global:SysinternalsPath },
        @{ Name = "Plaso";              Path = Join-Path $ToolsRoot "Plaso" },
        @{ Name = "Chainsaw";           Path = Join-Path $ToolsRoot "Chainsaw" },
        @{ Name = "EZTools";            Path = Join-Path $ToolsRoot "EZTools" },
        @{ Name = "Volatility";         Path = Join-Path $ToolsRoot "Volatility" },
        @{ Name = "YARA";               Path = Join-Path $ToolsRoot "YARA" }
    )

    $data = @()

    foreach ($tool in $tools) {
        $exists = Test-Path $tool.Path
        $data += [PSCustomObject]@{
            Name   = $tool.Name
            Path   = $tool.Path
            Status = if ($exists) { "OK" } else { "MISSING" }
        }
    }

    return $data
}

# ==========================
#  Tool Integrity Export (JSON/HTML)
# ==========================
function Export-ToolIntegrityJson {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\tool-integrity.json"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $data = Get-ToolIntegrityData
    $data | ConvertTo-Json -Depth 3 | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Tool integrity JSON exported to: $OutputPath"
}

function Export-ToolIntegrityHtml {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\tool-integrity.html"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $data = Get-ToolIntegrityData

    $html = @"
<html>
<head>
    <title>BLACKBOX256 Tool Integrity Dashboard</title>
    <style>
        body { font-family: Segoe UI, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; }
        th { background-color: #f0f0f0; }
        .ok { color: green; }
        .missing { color: red; }
    </style>
</head>
<body>
<h1>BLACKBOX256 Tool Integrity Dashboard</h1>
<p>DFIR Profile: $Global:DfirProfile</p>
<table>
<tr><th>Name</th><th>Status</th><th>Path</th></tr>
"@

    foreach ($item in $data) {
        $cls = if ($item.Status -eq "OK") { "ok" } else { "missing" }
        $html += "<tr><td>$($item.Name)</td><td class='$cls'>$($item.Status)</td><td>$($item.Path)</td></tr>`n"
    }

    $html += @"
</table>
</body>
</html>
"@

    $html | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Tool integrity HTML exported to: $OutputPath"
}

# ==========================
#  DFIR Profile Selector (manual)
# ==========================
function Select-DfirProfile {
    Write-Host "=== DFIR Profile Selector ==="
    Write-Host "1) Ransomware Incident"
    Write-Host "2) Insider Data Theft"
    Write-Host "3) Web Server Compromise"
    Write-Host "4) Generic Triage"

    $choice = Read-Host "Select profile"

    switch ($choice) {
        "1" {
            $Global:DfirProfile = "Ransomware"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Volatility", "YARA", "Sysinternals Suite")
        }
        "2" {
            $Global:DfirProfile = "Insider Theft"
            $Global:DfirTools = @("Plaso", "Browser Forensics", "EZTools", "YARA")
        }
        "3" {
            $Global:DfirProfile = "Web Compromise"
            $Global:DfirTools = @("Plaso", "Log Parsers", "YARA", "Sysinternals Suite")
        }
        "4" {
            $Global:DfirProfile = "Generic Triage"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Sysinternals Suite")
        }
        default {
            Write-Host "Invalid selection, defaulting to Generic Triage."
            $Global:DfirProfile = "Generic Triage"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Sysinternals Suite")
        }
    }

    Write-Host "[+] Active DFIR profile: $Global:DfirProfile"
    Write-Host "[+] Tools in profile: $($Global:DfirTools -join ', ')"
}

# ==========================
#  DFIR Profile Selector (from tag)
# ==========================
function Select-DfirProfileFromTag {
    param([string]$TagName)

    if ($TagName -match "ransomware") {
        $Global:DfirProfile = "Ransomware"
        $Global:DfirTools = @("Plaso","Chainsaw","Volatility","YARA","Sysinternals Suite")
    }
    elseif ($TagName -match "insider") {
        $Global:DfirProfile = "Insider Theft"
        $Global:DfirTools = @("Plaso","Browser Forensics","EZTools","YARA")
    }
    elseif ($TagName -match "web") {
        $Global:DfirProfile = "Web Compromise"
        $Global:DfirTools = @("Plaso","Log Parsers","YARA","Sysinternals Suite")
    }
    else {
        $Global:DfirProfile = "Generic Triage"
        $Global:DfirTools = @("Plaso","Chainsaw","Sysinternals Suite")
    }

    Write-Host "[+] Auto-selected DFIR profile from tag '$TagName': $Global:DfirProfile"
    Write-Host "[+] Tools: $($Global:DfirTools -join ', ')"
}

# ==========================
#  DFIR Release Manifest JSON
# ==========================
function Export-ReleaseManifestJson {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\release-manifest.json",
        [string]$TagName    = "unknown"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $versionFile = Join-Path $ScriptRoot "VERSION"
    $version     = if (Test-Path $versionFile) { Get-Content $versionFile } else { "unknown" }

    $tools = Get-ToolIntegrityData

    $manifest = [PSCustomObject]@{
        Project      = "BLACKBOX256-DFIR-Console"
        Version      = $version
        Tag          = $TagName
        DfirProfile  = $Global:DfirProfile
        Tools        = $tools
        GeneratedAt  = (Get-Date).ToString("o")
    }

    $manifest | ConvertTo-Json -Depth 5 | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Release manifest JSON exported to: $OutputPath"
}

# ==========================
#  Forensic Report Template
# ==========================
function New-ForensicReportTemplate {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\forensic-report-template.md",
        [string]$TagName    = "unknown"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $versionFile = Join-Path $ScriptRoot "VERSION"
    $version     = if (Test-Path $versionFile) { Get-Content $versionFile } else { "unknown" }

    $content = @"
# BLACKBOX256 DFIR Report

- Project: BLACKBOX256-DFIR-Console
- Version: $version
- Tag: $TagName
- DFIR Profile: $Global:DfirProfile
- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Incident Summary

## 2. Scope and Assets

## 3. Tools Used

$(($Global:DfirTools -join ", "))

## 4. Timeline

## 5. Findings

## 6. Recommendations

"@

    $content | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Forensic report template exported to: $OutputPath"
}

# ==========================
#  Post-Release Smoke Test (profile-aware)
# ==========================
function Invoke-PostReleaseSmokeTest {
    param([string]$ReleaseRoot = $ScriptRoot)

    Write-Host "=== Post-Release Smoke Test ==="

    $checks = @(
        @{ Name = "DFIR-Console.ps1"; Path = Join-Path $ReleaseRoot "DFIR-Console.ps1" },
        @{ Name = "Modules";          Path = Join-Path $ReleaseRoot "Modules" },
        @{ Name = "Tools";            Path = Join-Path $ReleaseRoot "Tools" },
        @{ Name = "VERSION";          Path = Join-Path $ReleaseRoot "VERSION" }
    )

    $failed = @()

    foreach ($check in $checks) {
        if (Test-Path $check.Path) {
            Write-Host "[+] $($check.Name) present" -ForegroundColor Green
        } else {
            Write-Host "[!] $($check.Name) missing: $($check.Path)" -ForegroundColor Red
            $failed += $check.Name
        }
    }

    Write-Host "[+] Checking DFIR profile tools: $Global:DfirProfile"

    foreach ($tool in $Global:DfirTools) {
        $path = switch ($tool) {
            "Sysinternals Suite" { $Global:SysinternalsPath }
            "Plaso"              { Join-Path $ToolsRoot "Plaso" }
            "Chainsaw"           { Join-Path $ToolsRoot "Chainsaw" }
            "EZTools"            { Join-Path $ToolsRoot "EZTools" }
            "Volatility"         { Join-Path $ToolsRoot "Volatility" }
            "YARA"               { Join-Path $ToolsRoot "YARA" }
            "Browser Forensics"  { Join-Path $ToolsRoot "BrowserForensics" }
            "Log Parsers"        { Join-Path $ToolsRoot "LogParsers" }
            default              { Join-Path $ToolsRoot $tool }
        }

        if (Test-Path $path) {
            Write-Host "[+] $tool present at $path" -ForegroundColor Green
        } else {
            Write-Host "[!] $tool missing at $path" -ForegroundColor Red
            $failed += $tool
        }
    }

    if ($failed.Count -eq 0) {
        Write-Host "[+] Smoke test PASSED" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[!] Smoke test FAILED. Missing: $($failed -join ', ')" -ForegroundColor Red
        return $false
    }
}

# ==========================
#  GUI Interface (WPF)
# ==========================
function Start-GuiInterface {
    Add-Type -AssemblyName PresentationFramework

    $window = New-Object Windows.Window
    $window.Title = "BLACKBOX256 DFIR Console"
    $window.Width = 800
    $window.Height = 600

    $grid = New-Object Windows.Controls.Grid
    $window.Content = $grid

    # Buttons
    $btnEnv = New-Object Windows.Controls.Button
    $btnEnv.Content = "Environment Validator"
    $btnEnv.Margin = "10,10,10,0"
    $btnEnv.Height = 40

    $btnTools = New-Object Windows.Controls.Button
    $btnTools.Content = "Tool Integrity Dashboard"
    $btnTools.Margin = "10,60,10,0"
    $btnTools.Height = 40

    $btnSmoke = New-Object Windows.Controls.Button
    $btnSmoke.Content = "Post-Release Smoke Test"
    $btnSmoke.Margin = "10,110,10,0"
    $btnSmoke.Height = 40

    $btnProfile = New-Object Windows.Controls.Button
    $btnProfile.Content = "DFIR Profile Selector"
    $btnProfile.Margin = "10,160,10,0"
    $btnProfile.Height = 40

    $output = New-Object Windows.Controls.TextBox
    $output.Margin = "10,210,10,10"
    $output.VerticalScrollBarVisibility = "Auto"
    $output.HorizontalScrollBarVisibility = "Auto"
    $output.AcceptsReturn = $true
    $output.IsReadOnly = $true

    $grid.Children.Add($btnEnv)
    $grid.Children.Add($btnTools)
    $grid.Children.Add($btnSmoke)
    $grid.Children.Add($btnProfile)
    $grid.Children.Add($output)

    # Wire up events
    $btnEnv.Add_Click({
        $result = Invoke-EnvironmentValidator
        $output.AppendText("Environment Validator: $result`r`n")
    })

    $btnTools.Add_Click({
        $output.AppendText("Tool Integrity Dashboard:`r`n")
        $tools = Get-ToolIntegrityData
        foreach ($tool in $tools) {
            $output.AppendText((" - {0}: {1}`r`n" -f $tool.Name, $tool.Status))
        }
    })

    $btnSmoke.Add_Click({
        $result = Invoke-PostReleaseSmokeTest -ReleaseRoot $ScriptRoot
        $output.AppendText("Smoke Test: $result`r`n")
    })

    $btnProfile.Add_Click({
        Select-DfirProfile
        $output.AppendText("DFIR Profile: $Global:DfirProfile`r`n")
    })

    $window.ShowDialog() | Out-Null
}

# ==========================
#  CLI Interface
# ==========================
function Start-CliInterface {
    Write-Host "=== BLACKBOX256 DFIR Console (CLI) ==="
    Write-Host "1) Environment Validator"
    Write-Host "2) Tool Integrity Dashboard"
    Write-Host "3) Post-Release Smoke Test"
    Write-Host "4) DFIR Profile Selector"
    Write-Host "5) Export Integrity (JSON/HTML)"
    Write-Host "6) Export Release Manifest"
    Write-Host "7) Generate Forensic Report Template"
    Write-Host "Q) Quit"

    while ($true) {
        $choice = Read-Host "Select option"
        switch ($choice) {
            "1" { Invoke-EnvironmentValidator | Out-Null }
            "2" { Show-ToolIntegrityDashboard }
            "3" { Invoke-PostReleaseSmokeTest -ReleaseRoot $ScriptRoot | Out-Null }
            "4" { Select-DfirProfile }
            "5" {
                Export-ToolIntegrityJson
                Export-ToolIntegrityHtml
            }
            "6" { Export-ReleaseManifestJson -TagName "manual-cli" }
            "7" { New-ForensicReportTemplate -TagName "manual-cli" }
            "Q" { break }
            "q" { break }
            default { Write-Host "Invalid selection." }
        }
    }
}

# ==========================
#  Mode Selection
# ==========================
Write-Host "=== BLACKBOX256 DFIR Console Loader ==="
Write-Host "Select interface mode:"
Write-Host "1) Text CLI"
Write-Host "2) GUI"

$mode = Read-Host "Enter choice (1/2)"

switch ($mode) {
    "1" { Start-CliInterface }
    "2" { Start-GuiInterface }
    default {
        Write-Host "Invalid choice, defaulting to CLI."
        Start-CliInterface
    }
}
<#
.SYNOPSIS
    BLACKBOX256 DFIR Console Loader

.DESCRIPTION
    Entry point for BLACKBOX256-DFIR-Console:
      - First-run environment validation
      - Sysinternals auto-download
      - Tool integrity dashboard (CLI + GUI)
      - DFIR profile selector (manual + tag-based)
      - Profile-aware post-release smoke test
      - JSON/HTML integrity export
      - DFIR Release Manifest JSON
      - Forensic report template
#>

# --- Global paths ---
$ScriptRoot      = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ModulesRoot     = Join-Path $ScriptRoot "Modules"
$ToolsRoot       = Join-Path $ScriptRoot "Tools"
$SysinternalsMod = Join-Path $ModulesRoot "Sysinternals\Get-Sysinternals.ps1"

# --- Load Sysinternals auto-download ---
if (Test-Path $SysinternalsMod) {
    Import-Module $SysinternalsMod -Force
    $Global:SysinternalsPath = Get-SysinternalsSuite
} else {
    Write-Warning "Sysinternals module not found: $SysinternalsMod"
}

# Default DFIR profile
if (-not $Global:DfirProfile) { $Global:DfirProfile = "Generic Triage" }
if (-not $Global:DfirTools)   { $Global:DfirTools   = @("Plaso","Chainsaw","Sysinternals Suite") }

# ==========================
#  First-Run Environment Validator
# ==========================
function Invoke-EnvironmentValidator {
    Write-Host "=== Environment Validator ==="

    $issues = @()

    # PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "PowerShell 7+ is recommended. Current: $($PSVersionTable.PSVersion)"
    }

    # Required folders
    foreach ($path in @($ModulesRoot, $ToolsRoot)) {
        if (-not (Test-Path $path)) {
            $issues += "Missing required directory: $path"
        }
    }

    # Sysinternals presence
    if (-not (Test-Path $Global:SysinternalsPath)) {
        $issues += "Sysinternals Suite not present at: $Global:SysinternalsPath"
    }

    if ($issues.Count -eq 0) {
        Write-Host "[+] Environment OK" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[!] Environment issues detected:" -ForegroundColor Yellow
        $issues | ForEach-Object { Write-Host " - $_" }
        return $false
    }
}

# ==========================
#  Tool Integrity Dashboard (CLI)
# ==========================
function Show-ToolIntegrityDashboard {
    Write-Host "=== Tool Integrity Dashboard (CLI) ==="

    $tools = Get-ToolIntegrityData

    foreach ($tool in $tools) {
        $color = if ($tool.Status -eq "OK") { "Green" } else { "Red" }
        Write-Host ("{0,-20} {1,-8} {2}" -f $tool.Name, $tool.Status, $tool.Path) -ForegroundColor $color
    }
}

# ==========================
#  Tool Integrity Data (shared)
# ==========================
function Get-ToolIntegrityData {
    $tools = @(
        @{ Name = "Sysinternals Suite"; Path = $Global:SysinternalsPath },
        @{ Name = "Plaso";              Path = Join-Path $ToolsRoot "Plaso" },
        @{ Name = "Chainsaw";           Path = Join-Path $ToolsRoot "Chainsaw" },
        @{ Name = "EZTools";            Path = Join-Path $ToolsRoot "EZTools" },
        @{ Name = "Volatility";         Path = Join-Path $ToolsRoot "Volatility" },
        @{ Name = "YARA";               Path = Join-Path $ToolsRoot "YARA" }
    )

    $data = @()

    foreach ($tool in $tools) {
        $exists = Test-Path $tool.Path
        $data += [PSCustomObject]@{
            Name   = $tool.Name
            Path   = $tool.Path
            Status = if ($exists) { "OK" } else { "MISSING" }
        }
    }

    return $data
}

# ==========================
#  Tool Integrity Export (JSON/HTML)
# ==========================
function Export-ToolIntegrityJson {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\tool-integrity.json"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $data = Get-ToolIntegrityData
    $data | ConvertTo-Json -Depth 3 | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Tool integrity JSON exported to: $OutputPath"
}

function Export-ToolIntegrityHtml {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\tool-integrity.html"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $data = Get-ToolIntegrityData

    $html = @"
<html>
<head>
    <title>BLACKBOX256 Tool Integrity Dashboard</title>
    <style>
        body { font-family: Segoe UI, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; }
        th { background-color: #f0f0f0; }
        .ok { color: green; }
        .missing { color: red; }
    </style>
</head>
<body>
<h1>BLACKBOX256 Tool Integrity Dashboard</h1>
<p>DFIR Profile: $Global:DfirProfile</p>
<table>
<tr><th>Name</th><th>Status</th><th>Path</th></tr>
"@

    foreach ($item in $data) {
        $cls = if ($item.Status -eq "OK") { "ok" } else { "missing" }
        $html += "<tr><td>$($item.Name)</td><td class='$cls'>$($item.Status)</td><td>$($item.Path)</td></tr>`n"
    }

    $html += @"
</table>
</body>
</html>
"@

    $html | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Tool integrity HTML exported to: $OutputPath"
}

# ==========================
#  DFIR Profile Selector (manual)
# ==========================
function Select-DfirProfile {
    Write-Host "=== DFIR Profile Selector ==="
    Write-Host "1) Ransomware Incident"
    Write-Host "2) Insider Data Theft"
    Write-Host "3) Web Server Compromise"
    Write-Host "4) Generic Triage"

    $choice = Read-Host "Select profile"

    switch ($choice) {
        "1" {
            $Global:DfirProfile = "Ransomware"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Volatility", "YARA", "Sysinternals Suite")
        }
        "2" {
            $Global:DfirProfile = "Insider Theft"
            $Global:DfirTools = @("Plaso", "Browser Forensics", "EZTools", "YARA")
        }
        "3" {
            $Global:DfirProfile = "Web Compromise"
            $Global:DfirTools = @("Plaso", "Log Parsers", "YARA", "Sysinternals Suite")
        }
        "4" {
            $Global:DfirProfile = "Generic Triage"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Sysinternals Suite")
        }
        default {
            Write-Host "Invalid selection, defaulting to Generic Triage."
            $Global:DfirProfile = "Generic Triage"
            $Global:DfirTools = @("Plaso", "Chainsaw", "Sysinternals Suite")
        }
    }

    Write-Host "[+] Active DFIR profile: $Global:DfirProfile"
    Write-Host "[+] Tools in profile: $($Global:DfirTools -join ', ')"
}

# ==========================
#  DFIR Profile Selector (from tag)
# ==========================
function Select-DfirProfileFromTag {
    param([string]$TagName)

    if ($TagName -match "ransomware") {
        $Global:DfirProfile = "Ransomware"
        $Global:DfirTools = @("Plaso","Chainsaw","Volatility","YARA","Sysinternals Suite")
    }
    elseif ($TagName -match "insider") {
        $Global:DfirProfile = "Insider Theft"
        $Global:DfirTools = @("Plaso","Browser Forensics","EZTools","YARA")
    }
    elseif ($TagName -match "web") {
        $Global:DfirProfile = "Web Compromise"
        $Global:DfirTools = @("Plaso","Log Parsers","YARA","Sysinternals Suite")
    }
    else {
        $Global:DfirProfile = "Generic Triage"
        $Global:DfirTools = @("Plaso","Chainsaw","Sysinternals Suite")
    }

    Write-Host "[+] Auto-selected DFIR profile from tag '$TagName': $Global:DfirProfile"
    Write-Host "[+] Tools: $($Global:DfirTools -join ', ')"
}

# ==========================
#  DFIR Release Manifest JSON
# ==========================
function Export-ReleaseManifestJson {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\release-manifest.json",
        [string]$TagName    = "unknown"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $versionFile = Join-Path $ScriptRoot "VERSION"
    $version     = if (Test-Path $versionFile) { Get-Content $versionFile } else { "unknown" }

    $tools = Get-ToolIntegrityData

    $manifest = [PSCustomObject]@{
        Project      = "BLACKBOX256-DFIR-Console"
        Version      = $version
        Tag          = $TagName
        DfirProfile  = $Global:DfirProfile
        Tools        = $tools
        GeneratedAt  = (Get-Date).ToString("o")
    }

    $manifest | ConvertTo-Json -Depth 5 | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Release manifest JSON exported to: $OutputPath"
}

# ==========================
#  Forensic Report Template
# ==========================
function New-ForensicReportTemplate {
    param(
        [string]$OutputPath = "$ScriptRoot\dist\forensic-report-template.md",
        [string]$TagName    = "unknown"
    )

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path $OutputPath) | Out-Null
    }

    $versionFile = Join-Path $ScriptRoot "VERSION"
    $version     = if (Test-Path $versionFile) { Get-Content $versionFile } else { "unknown" }

    $content = @"
# BLACKBOX256 DFIR Report

- Project: BLACKBOX256-DFIR-Console
- Version: $version
- Tag: $TagName
- DFIR Profile: $Global:DfirProfile
- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Incident Summary

## 2. Scope and Assets

## 3. Tools Used

$(($Global:DfirTools -join ", "))

## 4. Timeline

## 5. Findings

## 6. Recommendations

"@

    $content | Out-File $OutputPath -Encoding UTF8
    Write-Host "[+] Forensic report template exported to: $OutputPath"
}

# ==========================
#  Post-Release Smoke Test (profile-aware)
# ==========================
function Invoke-PostReleaseSmokeTest {
    param([string]$ReleaseRoot = $ScriptRoot)

    Write-Host "=== Post-Release Smoke Test ==="

    $checks = @(
        @{ Name = "DFIR-Console.ps1"; Path = Join-Path $ReleaseRoot "DFIR-Console.ps1" },
        @{ Name = "Modules";          Path = Join-Path $ReleaseRoot "Modules" },
        @{ Name = "Tools";            Path = Join-Path $ReleaseRoot "Tools" },
        @{ Name = "VERSION";          Path = Join-Path $ReleaseRoot "VERSION" }
    )

    $failed = @()

    foreach ($check in $checks) {
        if (Test-Path $check.Path) {
            Write-Host "[+] $($check.Name) present" -ForegroundColor Green
        } else {
            Write-Host "[!] $($check.Name) missing: $($check.Path)" -ForegroundColor Red
            $failed += $check.Name
        }
    }

    Write-Host "[+] Checking DFIR profile tools: $Global:DfirProfile"

    foreach ($tool in $Global:DfirTools) {
        $path = switch ($tool) {
            "Sysinternals Suite" { $Global:SysinternalsPath }
            "Plaso"              { Join-Path $ToolsRoot "Plaso" }
            "Chainsaw"           { Join-Path $ToolsRoot "Chainsaw" }
            "EZTools"            { Join-Path $ToolsRoot "EZTools" }
            "Volatility"         { Join-Path $ToolsRoot "Volatility" }
            "YARA"               { Join-Path $ToolsRoot "YARA" }
            "Browser Forensics"  { Join-Path $ToolsRoot "BrowserForensics" }
            "Log Parsers"        { Join-Path $ToolsRoot "LogParsers" }
            default              { Join-Path $ToolsRoot $tool }
        }

        if (Test-Path $path) {
            Write-Host "[+] $tool present at $path" -ForegroundColor Green
        } else {
            Write-Host "[!] $tool missing at $path" -ForegroundColor Red
            $failed += $tool
        }
    }

    if ($failed.Count -eq 0) {
        Write-Host "[+] Smoke test PASSED" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[!] Smoke test FAILED. Missing: $($failed -join ', ')" -ForegroundColor Red
        return $false
    }
}

# ==========================
#  GUI Interface (WPF)
# ==========================
function Start-GuiInterface {
    Add-Type -AssemblyName PresentationFramework

    $window = New-Object Windows.Window
    $window.Title = "BLACKBOX256 DFIR Console"
    $window.Width = 800
    $window.Height = 600

    $grid = New-Object Windows.Controls.Grid
    $window.Content = $grid

    # Buttons
    $btnEnv = New-Object Windows.Controls.Button
    $btnEnv.Content = "Environment Validator"
    $btnEnv.Margin = "10,10,10,0"
    $btnEnv.Height = 40

    $btnTools = New-Object Windows.Controls.Button
    $btnTools.Content = "Tool Integrity Dashboard"
    $btnTools.Margin = "10,60,10,0"
    $btnTools.Height = 40

    $btnSmoke = New-Object Windows.Controls.Button
    $btnSmoke.Content = "Post-Release Smoke Test"
    $btnSmoke.Margin = "10,110,10,0"
    $btnSmoke.Height = 40

    $btnProfile = New-Object Windows.Controls.Button
    $btnProfile.Content = "DFIR Profile Selector"
    $btnProfile.Margin = "10,160,10,0"
    $btnProfile.Height = 40

    $output = New-Object Windows.Controls.TextBox
    $output.Margin = "10,210,10,10"
    $output.VerticalScrollBarVisibility = "Auto"
    $output.HorizontalScrollBarVisibility = "Auto"
    $output.AcceptsReturn = $true
    $output.IsReadOnly = $true

    $grid.Children.Add($btnEnv)
    $grid.Children.Add($btnTools)
    $grid.Children.Add($btnSmoke)
    $grid.Children.Add($btnProfile)
    $grid.Children.Add($output)

    # Wire up events
    $btnEnv.Add_Click({
        $result = Invoke-EnvironmentValidator
        $output.AppendText("Environment Validator: $result`r`n")
    })

    $btnTools.Add_Click({
        $output.AppendText("Tool Integrity Dashboard:`r`n")
        $tools = Get-ToolIntegrityData
        foreach ($tool in $tools) {
            $output.AppendText((" - {0}: {1}`r`n" -f $tool.Name, $tool.Status))
        }
    })

    $btnSmoke.Add_Click({
        $result = Invoke-PostReleaseSmokeTest -ReleaseRoot $ScriptRoot
        $output.AppendText("Smoke Test: $result`r`n")
    })

    $btnProfile.Add_Click({
        Select-DfirProfile
        $output.AppendText("DFIR Profile: $Global:DfirProfile`r`n")
    })

    $window.ShowDialog() | Out-Null
}

# ==========================
#  CLI Interface
# ==========================
function Start-CliInterface {
    Write-Host "=== BLACKBOX256 DFIR Console (CLI) ==="
    Write-Host "1) Environment Validator"
    Write-Host "2) Tool Integrity Dashboard"
    Write-Host "3) Post-Release Smoke Test"
    Write-Host "4) DFIR Profile Selector"
    Write-Host "5) Export Integrity (JSON/HTML)"
    Write-Host "6) Export Release Manifest"
    Write-Host "7) Generate Forensic Report Template"
    Write-Host "Q) Quit"

    while ($true) {
        $choice = Read-Host "Select option"
        switch ($choice) {
            "1" { Invoke-EnvironmentValidator | Out-Null }
            "2" { Show-ToolIntegrityDashboard }
            "3" { Invoke-PostReleaseSmokeTest -ReleaseRoot $ScriptRoot | Out-Null }
            "4" { Select-DfirProfile }
            "5" {
                Export-ToolIntegrityJson
                Export-ToolIntegrityHtml
            }
            "6" { Export-ReleaseManifestJson -TagName "manual-cli" }
            "7" { New-ForensicReportTemplate -TagName "manual-cli" }
            "Q" { break }
            "q" { break }
            default { Write-Host "Invalid selection." }
        }
    }
}

# ==========================
#  Mode Selection
# ==========================
Write-Host "=== BLACKBOX256 DFIR Console Loader ==="
Write-Host "Select interface mode:"
Write-Host "1) Text CLI"
Write-Host "2) GUI"

$mode = Read-Host "Enter choice (1/2)"

switch ($mode) {
    "1" { Start-CliInterface }
    "2" { Start-GuiInterface }
    default {
        Write-Host "Invalid choice, defaulting to CLI."
        Start-CliInterface
    }
}
