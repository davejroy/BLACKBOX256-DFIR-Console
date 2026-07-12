<#
Bump-Version.ps1
Semantic version bump: major / minor / patch
Updates VERSION, commits, tags, pushes.
#>

param(
    [Parameter(Mandatory)][ValidateSet("major","minor","patch")]
    [string]$Type
)

$projectRoot = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB"
Set-Location $projectRoot

$versionFile = Join-Path $projectRoot "VERSION"

if (-not (Test-Path $versionFile)) {
    Write-Host "VERSION file not found. Creating 0.1.0."
    "0.1.0" | Set-Content $versionFile
}

$current = Get-Content $versionFile | Select-Object -First 1
$parts   = $current.Split('.')

[int]$major = $parts[0]
[int]$minor = $parts[1]
[int]$patch = $parts[2]

switch ($Type) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
    }
    "minor" {
        $minor++
        $patch = 0
    }
    "patch" {
        $patch++
    }
}

$newVersion = "$major.$minor.$patch"
$tag        = "v$newVersion"

Write-Host "Bumping version: $current -> $newVersion"

$newVersion | Set-Content $versionFile

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Skipping commit/tag."
    exit 0
}

git add VERSION
git commit -m "Bump version to $newVersion"
git tag $tag
git push
git push origin $tag

Write-Host "Version bump complete:"
Write-Host "  VERSION: $newVersion"
Write-Host "  Tag:     $tag"
