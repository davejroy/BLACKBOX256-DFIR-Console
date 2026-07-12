<#
Push-BLACKBOX256.ps1
Pushes all new BLACKBOX256 files to GitHub as version v1.0.1
Author: David
#>

param(
    [string]$RepoURL = "https://github.com/<YOUR_GITHUB_USERNAME>/BLACKBOX256.git",
    [string]$Tag     = "v1.0.1",
    [string]$Message = "Release $Tag - Full DFIR console + modules + tools integration"
)

Write-Host ""
Write-Host "=== BLACKBOX256 GitHub Push Script ==="
Write-Host "Repo: $RepoURL"
Write-Host "Tag:  $Tag"
Write-Host ""

# Ensure git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Git is not installed or not in PATH."
    exit 1
}

# Move to project root
$projectRoot = "C:\Users\davej\OneDrive\Documents\Dev\BLACKBOX256_USB"
Set-Location $projectRoot

# Initialize repo if needed
if (-not (Test-Path ".git")) {
    Write-Host "Initializing new Git repository..."
    git init
    git remote add origin $RepoURL
}

# Stage everything
Write-Host "Staging all files..."
git add .

# Commit
Write-Host "Committing changes..."
git commit -m $Message

# Push main branch
Write-Host "Pushing to GitHub..."
git branch -M main
git push -u origin main

# Create tag
Write-Host "Tagging release $Tag..."
git tag $Tag
git push origin $Tag

Write-Host ""
Write-Host "====================================================="
Write-Host "BLACKBOX256 successfully pushed to GitHub as $Tag"
Write-Host "====================================================="
Write-Host ""
