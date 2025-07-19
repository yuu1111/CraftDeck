# CraftDeck Release Script
# This script prepares a release of both the Minecraft mod and StreamDeck plugin

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$OutputDir = ".\release",

    [Parameter(Mandatory=$false)]
    [switch]$CreateZip = $false,

    [Parameter(Mandatory=$false)]
    [switch]$SkipTests = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== CraftDeck Release Script ===" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Yellow
Write-Host "Output Directory: $OutputDir" -ForegroundColor Yellow

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Create output directory
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Create subdirectories
$MinecraftModDir = Join-Path $OutputDir "minecraft-mod"
$StreamDeckPluginDir = Join-Path $OutputDir "streamdeck-plugin"
New-Item -ItemType Directory -Path $MinecraftModDir -Force | Out-Null
New-Item -ItemType Directory -Path $StreamDeckPluginDir -Force | Out-Null

# Function to update version in manifest.json
function Update-ManifestVersion {
    param($ManifestPath, $NewVersion)

    if (Test-Path $ManifestPath) {
        $manifest = Get-Content $ManifestPath | ConvertFrom-Json
        $manifest.Version = $NewVersion
        $manifest | ConvertTo-Json -Depth 10 | Set-Content $ManifestPath -Encoding UTF8
        Write-Host "Updated manifest version to $NewVersion" -ForegroundColor Green
    } else {
        Write-Warning "Manifest file not found: $ManifestPath"
    }
}

try {
    # Update StreamDeck plugin manifest version
    $ManifestPath = Join-Path $ProjectRoot "craftdeck-plugin\manifest.json"
    Update-ManifestVersion -ManifestPath $ManifestPath -NewVersion $Version

    # Build Minecraft Mod
    Write-Host "`n=== Building Minecraft Mod ===" -ForegroundColor Cyan
    Set-Location (Join-Path $ProjectRoot "craftdeck-mod")

    # Clean and build
    .\gradlew.bat clean
    if ($LASTEXITCODE -ne 0) { throw "Gradle clean failed" }

    .\gradlew.bat build
    if ($LASTEXITCODE -ne 0) { throw "Gradle build failed" }

    # Run tests (unless skipped)
    if (-not $SkipTests) {
        Write-Host "Running tests..." -ForegroundColor Yellow
        .\gradlew.bat test
        if ($LASTEXITCODE -ne 0) { throw "Tests failed" }
    }

    # Copy Minecraft mod JARs
    $ModBuildDirs = @("common\build\libs", "fabric\build\libs", "forge\build\libs", "quilt\build\libs")
    foreach ($buildDir in $ModBuildDirs) {
        $sourcePath = Join-Path (Get-Location) $buildDir
        if (Test-Path $sourcePath) {
            Get-ChildItem $sourcePath -Filter "*.jar" | Where-Object { -not $_.Name.Contains("sources") -and -not $_.Name.Contains("dev") } | ForEach-Object {
                Copy-Item $_.FullName $MinecraftModDir
                Write-Host "Copied: $($_.Name)" -ForegroundColor Green
            }
        }
    }

    # Build StreamDeck Plugin
    Write-Host "`n=== Building StreamDeck Plugin ===" -ForegroundColor Cyan
    Set-Location $ProjectRoot

    # Restore and build
    dotnet restore CraftDeckSolution.sln
    if ($LASTEXITCODE -ne 0) { throw "Dotnet restore failed" }

    dotnet build CraftDeckSolution.sln -c Release
    if ($LASTEXITCODE -ne 0) { throw "Dotnet build failed" }

    # Publish StreamDeck plugin
    $PublishDir = Join-Path $ProjectRoot "temp-publish"
    dotnet publish craftdeck-plugin\CraftDeck.StreamDeckPlugin.csproj -c Release --self-contained -r win-x64 -o $PublishDir
    if ($LASTEXITCODE -ne 0) { throw "Dotnet publish failed" }

    # Create .streamDeckPlugin package
    Write-Host "Creating .streamDeckPlugin package..." -ForegroundColor Yellow
    $PluginPackageDir = Join-Path $ProjectRoot "temp-plugin-package"
    New-Item -ItemType Directory -Path $PluginPackageDir -Force | Out-Null

    # Copy published binaries
    Copy-Item "$PublishDir\*" $PluginPackageDir -Recurse -Force

    # Copy plugin assets
    Copy-Item "craftdeck-plugin\manifest.json" $PluginPackageDir -Force
    Copy-Item "craftdeck-plugin\images" $PluginPackageDir -Recurse -Force
    Copy-Item "craftdeck-plugin\property_inspector" $PluginPackageDir -Recurse -Force
    Copy-Item "craftdeck-plugin\en.json" $PluginPackageDir -Force
    Copy-Item "craftdeck-plugin\ja.json" $PluginPackageDir -Force

    # Create .streamDeckPlugin file
    $PluginFileName = "CraftDeck-v$Version.streamDeckPlugin"
    $PluginFilePath = Join-Path $StreamDeckPluginDir $PluginFileName

    # Use PowerShell compression
    Compress-Archive -Path "$PluginPackageDir\*" -DestinationPath $PluginFilePath -Force
    Write-Host "Created: $PluginFileName" -ForegroundColor Green

    # Clean up temporary directories
    Remove-Item $PublishDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $PluginPackageDir -Recurse -Force -ErrorAction SilentlyContinue

    # Create release notes
    Write-Host "`n=== Creating Release Notes ===" -ForegroundColor Cyan
    $ReleaseNotesPath = Join-Path $OutputDir "RELEASE_NOTES.md"
    $ReleaseNotes = @"
# CraftDeck v$Version Release Notes

## Installation Instructions

### Minecraft Mod
1. Choose the appropriate JAR file for your mod loader:
   - **Fabric**: CraftDeck-fabric-$Version.jar
   - **Forge**: CraftDeck-forge-$Version.jar
   - **Quilt**: CraftDeck-quilt-$Version.jar
2. Place the JAR file in your Minecraft mods folder
3. Start Minecraft with the mod loader

### StreamDeck Plugin
1. Double-click `$PluginFileName` to install
2. The plugin will be automatically registered with StreamDeck software
3. Restart StreamDeck software if necessary

## Requirements
- **Minecraft**: 1.20.1+
- **Java**: 17+
- **StreamDeck Software**: Latest version
- **Mod Loaders**: Fabric, Forge, or Quilt compatible versions

## What's New in v$Version
- [Add your release notes here]

## Files in This Release
### Minecraft Mod
"@

    Get-ChildItem $MinecraftModDir -Filter "*.jar" | ForEach-Object {
        $ReleaseNotes += "`n- $($_.Name)"
    }

    $ReleaseNotes += "`n`n### StreamDeck Plugin`n- $PluginFileName"

    $ReleaseNotes | Set-Content $ReleaseNotesPath -Encoding UTF8
    Write-Host "Created release notes: RELEASE_NOTES.md" -ForegroundColor Green

    # Create ZIP if requested
    if ($CreateZip) {
        Write-Host "`n=== Creating Release ZIP ===" -ForegroundColor Cyan
        $ZipPath = Join-Path (Split-Path $OutputDir -Parent) "CraftDeck-v$Version-Release.zip"
        Compress-Archive -Path "$OutputDir\*" -DestinationPath $ZipPath -Force
        Write-Host "Created release ZIP: $ZipPath" -ForegroundColor Green
    }

    # Summary
    Write-Host "`n=== Release Complete ===" -ForegroundColor Green
    Write-Host "Version: $Version" -ForegroundColor Yellow
    Write-Host "Output Directory: $OutputDir" -ForegroundColor Yellow
    Write-Host "`nMinecraft Mod JARs:" -ForegroundColor Cyan
    Get-ChildItem $MinecraftModDir -Filter "*.jar" | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor White
    }
    Write-Host "`nStreamDeck Plugin:" -ForegroundColor Cyan
    Write-Host "  - $PluginFileName" -ForegroundColor White

    Write-Host "`nRelease is ready for distribution!" -ForegroundColor Green

} catch {
    Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $ProjectRoot
}