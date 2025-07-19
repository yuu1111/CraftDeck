# Sync-DocsToWiki.ps1
# Pushes the wiki folder content to GitHub Wiki repository

param(
    [string]$WikiRepoUrl = "https://github.com/yuu1111/CraftDeck.wiki.git",
    [string]$WikiPath = "$PSScriptRoot\..\wiki"
)

Write-Host "CraftDeck Wiki Push Script" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# Check if wiki folder exists
if (-not (Test-Path $WikiPath)) {
    Write-Host "`nWiki folder not found at: $WikiPath" -ForegroundColor Red
    Write-Host "Please create the wiki folder and add wiki content first." -ForegroundColor Yellow
    exit 1
}

# Initialize wiki folder as git repo if needed
Push-Location $WikiPath

if (-not (Test-Path ".git")) {
    Write-Host "`nInitializing wiki as Git repository..." -ForegroundColor Yellow
    git init
    git remote add origin $WikiRepoUrl
}

# Check if remote wiki exists
Write-Host "`nChecking if GitHub Wiki is enabled..." -ForegroundColor Yellow
$wikiExists = $false
try {
    git ls-remote origin 2>&1 | Out-Null
    $wikiExists = $LASTEXITCODE -eq 0
} catch {
    $wikiExists = $false
}

if (-not $wikiExists) {
    Write-Host "GitHub Wiki not found!" -ForegroundColor Red
    Write-Host "`nTo enable the Wiki:" -ForegroundColor Yellow
    Write-Host "1. Go to https://github.com/yuu1111/CraftDeck/settings" -ForegroundColor White
    Write-Host "2. Scroll down to 'Features' section" -ForegroundColor White
    Write-Host "3. Check 'Wikis' checkbox" -ForegroundColor White
    Write-Host "4. Go to https://github.com/yuu1111/CraftDeck/wiki" -ForegroundColor White
    Write-Host "5. Click 'Create the first page'" -ForegroundColor White
    Write-Host "6. Save any content (can be deleted later)" -ForegroundColor White
    Write-Host "7. Run this script again" -ForegroundColor White
    Pop-Location
    exit 1
}

# Pull latest changes from wiki
Write-Host "`nPulling latest changes from GitHub Wiki..." -ForegroundColor Yellow
git pull origin master --allow-unrelated-histories 2>$null

# Check for local changes
$hasChanges = (git status --porcelain | Measure-Object).Count -gt 0

if ($hasChanges) {
    Write-Host "`nLocal changes detected:" -ForegroundColor Yellow
    git status --short

    # Commit and push changes
    Write-Host "`nCommitting changes..." -ForegroundColor Yellow
    git add .
    git commit -m "Update wiki content

Updated from main repository commit: $(git -C "$PSScriptRoot\.." rev-parse --short HEAD)"

    Write-Host "`nPushing to GitHub Wiki..." -ForegroundColor Yellow
    git push origin master

    Write-Host "`nWiki push completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nNo changes detected. Wiki is up to date." -ForegroundColor Green
}

Pop-Location

Write-Host "`nWiki URL: https://github.com/yuu1111/CraftDeck/wiki" -ForegroundColor Cyan

# Wait for user input before closing
Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
Read-Host