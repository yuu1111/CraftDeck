#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CraftDeck StreamDeck Plugin Deployment Script

.DESCRIPTION
    Builds and deploys the CraftDeck StreamDeck Plugin.
    Automatically handles building, testing, and deployment to StreamDeck.

.PARAMETER Configuration
    Build configuration: Debug or Release (default: Release)

.PARAMETER SkipStreamDeckRestart
    Skip restarting StreamDeck application after plugin deployment

.PARAMETER SkipTests
    Skip running tests before deployment

.EXAMPLE
    .\Deploy-Plugin.ps1
    .\Deploy-Plugin.ps1 -Configuration Debug
    .\Deploy-Plugin.ps1 -SkipStreamDeckRestart
    .\Deploy-Plugin.ps1 -SkipTests

#>

[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [switch]$SkipStreamDeckRestart,

    [switch]$SkipTests
)

# Script configuration
$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $PSScriptRoot
$pluginPath = Join-Path $scriptRoot "craftdeck-plugin"

# Platform detection
function Get-Platform {
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        return "Windows"
    } elseif ($IsMacOS) {
        return "macOS"
    } elseif ($IsLinux) {
        return "Linux"
    } else {
        throw "Unsupported platform"
    }
}

# Get StreamDeck configuration
function Get-StreamDeckConfig {
    $platform = Get-Platform

    switch ($platform) {
        "Windows" {
            return @{
                Runtime = "win-x64"
                StreamDeckExe = "$($env:ProgramFiles)\Elgato\StreamDeck\StreamDeck.exe"
                PluginsDir = "$($env:APPDATA)\Elgato\StreamDeck\Plugins"
                ProcessName = "StreamDeck"
            }
        }
        "macOS" {
            return @{
                Runtime = "osx-x64"
                StreamDeckExe = "/Applications/Stream Deck.app"
                PluginsDir = "$HOME/Library/Application Support/com.elgato.StreamDeck/Plugins"
                ProcessName = "Stream Deck"
            }
        }
        "Linux" {
            return @{
                Runtime = "linux-x64"
                StreamDeckExe = "/usr/bin/streamdeck"
                PluginsDir = "$HOME/.local/share/StreamDeck/Plugins"
                ProcessName = "streamdeck"
            }
        }
        default {
            throw "Unsupported platform: $platform"
        }
    }
}

# Build StreamDeck Plugin
function Build-StreamDeckPlugin {
    param([hashtable]$Config)

    Write-Host "🔨 Building StreamDeck Plugin..." -ForegroundColor Cyan

    if (-not (Test-Path $pluginPath)) {
        Write-Host "❌ Plugin directory not found: $pluginPath" -ForegroundColor Red
        return $false
    }

    try {
        Push-Location $pluginPath

        Write-Host "   Configuration: $Configuration" -ForegroundColor Gray
        Write-Host "   Runtime: $($Config.Runtime)" -ForegroundColor Gray

        # Build and publish
        dotnet build -c $Configuration
        dotnet publish -c $Configuration -r $($Config.Runtime) --self-contained

        # Copy localization files
        $publishDir = "bin\$Configuration\net6.0\$($Config.Runtime)\publish"
        Copy-Item "en.json" $publishDir -Force
        Copy-Item "ja.json" $publishDir -Force

        Write-Host "✅ StreamDeck Plugin built successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ StreamDeck Plugin build failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Deploy StreamDeck Plugin
function Deploy-StreamDeckPlugin {
    param([hashtable]$Config)

    Write-Host "📦 Deploying StreamDeck Plugin..." -ForegroundColor Cyan

    $publishDir = Join-Path $pluginPath "bin\$Configuration\net6.0\$($Config.Runtime)\publish"
    $manifestFile = Join-Path $publishDir "manifest.json"

    if (-not (Test-Path $publishDir)) {
        Write-Host "❌ Publish directory not found: $publishDir" -ForegroundColor Red
        return $false
    }

    if (-not (Test-Path $manifestFile)) {
        Write-Host "❌ Manifest file not found: $manifestFile" -ForegroundColor Red
        return $false
    }

    try {
        # Get plugin UUID from manifest
        $manifest = Get-Content $manifestFile | ConvertFrom-Json
        $pluginID = $manifest.UUID
        $destDir = Join-Path $Config.PluginsDir "$pluginID.sdPlugin"

        Write-Host "   Plugin UUID: $pluginID" -ForegroundColor Gray
        Write-Host "   Target: $destDir" -ForegroundColor Gray

        # Stop StreamDeck processes
        Stop-StreamDeckProcesses -Config $Config

        # Remove existing plugin
        if (Test-Path $destDir) {
            Write-Host "   Removing existing plugin..." -ForegroundColor Gray
            Remove-Item -Recurse -Force -Path $destDir -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }

        # Deploy new plugin
        Write-Host "   Copying plugin files..." -ForegroundColor Gray
        Copy-Item -Path $publishDir -Destination $destDir -Recurse -Force

        Write-Host "✅ StreamDeck Plugin deployed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ StreamDeck Plugin deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Stop StreamDeck processes
function Stop-StreamDeckProcesses {
    param([hashtable]$Config)

    Write-Host "   Stopping StreamDeck processes..." -ForegroundColor Gray

    $processesToStop = @($Config.ProcessName, "CraftDeck.StreamDeckPlugin")

    foreach ($processName in $processesToStop) {
        try {
            Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        } catch {
            # Ignore errors
        }
    }

    Start-Sleep -Seconds 2
}

# Start StreamDeck
function Start-StreamDeck {
    param([hashtable]$Config)

    if ($SkipStreamDeckRestart) {
        Write-Host "⏭️  Skipping StreamDeck restart" -ForegroundColor Yellow
        return
    }

    Write-Host "🚀 Starting StreamDeck..." -ForegroundColor Cyan

    try {
        if (Test-Path $Config.StreamDeckExe) {
            if ($Config.Runtime -eq "osx-x64") {
                Start-Process "open" -ArgumentList $Config.StreamDeckExe -NoNewWindow
            } else {
                Start-Process $Config.StreamDeckExe -NoNewWindow
            }
            Write-Host "✅ StreamDeck started" -ForegroundColor Green
        } else {
            Write-Host "⚠️  StreamDeck not found. Please start manually." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Failed to start StreamDeck. Please start manually." -ForegroundColor Yellow
    }
}

# Run tests
function Invoke-Tests {
    if ($SkipTests) {
        Write-Host "⏭️  Skipping tests" -ForegroundColor Yellow
        return $true
    }

    Write-Host "🧪 Running tests..." -ForegroundColor Cyan

    try {
        Push-Location $pluginPath
        dotnet test --configuration $Configuration --no-build
        Write-Host "✅ Tests passed" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Tests failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Main execution
function Main {
    Write-Host "🎮 CraftDeck StreamDeck Plugin Deployment" -ForegroundColor Magenta
    Write-Host "=========================================`n" -ForegroundColor Magenta

    $platform = Get-Platform
    $config = Get-StreamDeckConfig

    Write-Host "Platform: $platform" -ForegroundColor Gray
    Write-Host "Configuration: $Configuration`n" -ForegroundColor Gray

    $success = $true

    # Build and deploy plugin
    $success = Build-StreamDeckPlugin -Config $config
    if ($success) { $success = Invoke-Tests }
    if ($success) { $success = Deploy-StreamDeckPlugin -Config $config }
    if ($success) { Start-StreamDeck -Config $config }

    Write-Host ""
    if ($success) {
        Write-Host "🎉 Plugin deployment completed successfully!" -ForegroundColor Green

        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "1. Open StreamDeck application" -ForegroundColor Gray
        Write-Host "2. Add CraftDeck actions to your Stream Deck" -ForegroundColor Gray
        Write-Host "3. Configure WebSocket connection (default: ws://localhost:8080)" -ForegroundColor Gray

        Read-Host
        exit 0
    } else {
        Write-Host "💥 Plugin deployment failed!" -ForegroundColor Red
        Read-Host
        exit 1
    }
}

# Execute main function
Main

# Wait for user input before closing
Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
Read-Host