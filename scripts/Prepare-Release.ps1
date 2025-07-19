# CraftDeck Release Preparation Script
# This script helps prepare for a new release by updating version numbers and creating changelog entries

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$ReleaseNotes = "",

    [Parameter(Mandatory=$false)]
    [switch]$CreateTag = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== CraftDeck Release Preparation ===" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Yellow
Write-Host "Dry Run: $DryRun" -ForegroundColor Yellow

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Validate version format (semantic versioning)
if ($Version -notmatch '^\d+\.\d+\.\d+(-\w+)?$') {
    Write-Host "Error: Version must follow semantic versioning (e.g., 1.0.0 or 1.0.0-beta)" -ForegroundColor Red
    exit 1
}

# Function to update version in files
function Update-FileVersion {
    param($FilePath, $Pattern, $Replacement, $Description)

    if (Test-Path $FilePath) {
        if (-not $DryRun) {
            (Get-Content $FilePath) -replace $Pattern, $Replacement | Set-Content $FilePath -Encoding UTF8
        }
        Write-Host "✓ Updated $Description in $FilePath" -ForegroundColor Green
    } else {
        Write-Warning "File not found: $FilePath"
    }
}

# Function to update JSON version
function Update-JsonVersion {
    param($JsonPath, $PropertyName, $NewVersion, $Description)

    if (Test-Path $JsonPath) {
        if (-not $DryRun) {
            $json = Get-Content $JsonPath | ConvertFrom-Json
            $json.$PropertyName = $NewVersion
            $json | ConvertTo-Json -Depth 10 | Set-Content $JsonPath -Encoding UTF8
        }
        Write-Host "✓ Updated $Description in $JsonPath" -ForegroundColor Green
    } else {
        Write-Warning "File not found: $JsonPath"
    }
}

try {
    Set-Location $ProjectRoot

    Write-Host "`n=== Updating Version Numbers ===" -ForegroundColor Cyan

    # Update StreamDeck plugin manifest
    $ManifestPath = "craftdeck-plugin\manifest.json"
    Update-JsonVersion -JsonPath $ManifestPath -PropertyName "Version" -NewVersion $Version -Description "StreamDeck plugin version"

    # Update Gradle version in mod
    $GradlePropertiesPath = "craftdeck-mod\gradle.properties"
    Update-FileVersion -FilePath $GradlePropertiesPath -Pattern 'mod_version\s*=\s*.*' -Replacement "mod_version=$Version" -Description "Minecraft mod version"

    # Update README versions
    $ReadmePath = "README.md"
    Update-FileVersion -FilePath $ReadmePath -Pattern 'Version:\s*v[\d\.-]+' -Replacement "Version: v$Version" -Description "README version"

    $ReadmeJpPath = "README-JP.md"
    Update-FileVersion -FilePath $ReadmeJpPath -Pattern 'バージョン:\s*v[\d\.-]+' -Replacement "バージョン: v$Version" -Description "README-JP version"

    # Update CHANGELOG.md
    Write-Host "`n=== Updating Changelog ===" -ForegroundColor Cyan
    $ChangelogPath = "CHANGELOG.md"

    if (-not (Test-Path $ChangelogPath)) {
        Write-Host "Creating CHANGELOG.md..." -ForegroundColor Yellow
        if (-not $DryRun) {
            @"
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [$Version] - $(Get-Date -Format 'yyyy-MM-dd')

### Added
- Initial release of CraftDeck
- Minecraft mod with WebSocket server for game data collection
- StreamDeck plugin for displaying Minecraft information
- Real-time communication between Minecraft and StreamDeck
- Support for Fabric, Forge, and Quilt mod loaders
- Multi-language support (English, Japanese)

### Changed
- N/A

### Fixed
- N/A

### Removed
- N/A
"@ | Set-Content $ChangelogPath -Encoding UTF8
        }
        Write-Host "✓ Created initial CHANGELOG.md" -ForegroundColor Green
    } else {
        # Add new version entry to existing changelog
        if (-not $DryRun) {
            $changelogContent = Get-Content $ChangelogPath
            $newEntry = @"

## [$Version] - $(Get-Date -Format 'yyyy-MM-dd')

### Added
$ReleaseNotes

### Changed
- [Add any changes here]

### Fixed
- [Add any fixes here]

### Removed
- [Add any removals here]
"@

            # Find the line with [Unreleased] and add the new entry after it
            $updatedContent = @()
            $unreleasedFound = $false

            foreach ($line in $changelogContent) {
                $updatedContent += $line
                if ($line -match '## \[Unreleased\]' -and -not $unreleasedFound) {
                    $updatedContent += $newEntry
                    $unreleasedFound = $true
                }
            }

            $updatedContent | Set-Content $ChangelogPath -Encoding UTF8
        }
        Write-Host "✓ Added v$Version entry to CHANGELOG.md" -ForegroundColor Green
    }

    # Show git status
    Write-Host "`n=== Git Status ===" -ForegroundColor Cyan
    git status --porcelain

    if (-not $DryRun) {
        # Commit changes
        Write-Host "`n=== Committing Changes ===" -ForegroundColor Cyan
        git add .
        git commit -m "Prepare release v$Version

- Update version numbers to $Version
- Update CHANGELOG.md with new release entry
- Prepare for v$Version release

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Changes committed successfully" -ForegroundColor Green

            # Create tag if requested
            if ($CreateTag) {
                Write-Host "`n=== Creating Git Tag ===" -ForegroundColor Cyan
                git tag -a "v$Version" -m "Release v$Version"
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Created tag v$Version" -ForegroundColor Green
                    Write-Host "  Use 'git push origin v$Version' to push the tag" -ForegroundColor Yellow
                } else {
                    Write-Warning "Failed to create git tag"
                }
            }
        } else {
            Write-Warning "Failed to commit changes"
        }
    }

    Write-Host "`n=== Next Steps ===" -ForegroundColor Green
    Write-Host "1. Review the changes made" -ForegroundColor White
    Write-Host "2. Test the build: .\scripts\Release-CraftDeck.ps1 -Version $Version" -ForegroundColor White
    Write-Host "3. Push changes: git push origin main" -ForegroundColor White
    if ($CreateTag) {
        Write-Host "4. Push tag: git push origin v$Version" -ForegroundColor White
    }
    Write-Host "5. Create GitHub release with the built artifacts" -ForegroundColor White

    if ($DryRun) {
        Write-Host "`nNote: This was a dry run. No files were actually modified." -ForegroundColor Yellow
    }

} catch {
    Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $ProjectRoot
}

# Wait for user input before closing
Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
Read-Host