#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CraftDeck StreamDeck Plugin Development & Deployment Script

.DESCRIPTION
    Unified PowerShell script for building, deploying, and debugging the CraftDeck StreamDeck plugin.
    Supports Windows, macOS, and Linux environments.

.PARAMETER Action
    The action to perform: Build, Deploy, Debug, Clean, or All

.PARAMETER Configuration
    Build configuration: Debug or Release (default: Debug)

.PARAMETER Platform
    Target platform: Auto, Windows, macOS, or Linux (default: Auto)

.PARAMETER SkipStreamDeckRestart
    Skip restarting StreamDeck application after deployment

.EXAMPLE
    .\CraftDeck.ps1 -Action Build
    .\CraftDeck.ps1 -Action Deploy -Configuration Release
    .\CraftDeck.ps1 -Action Debug
    .\CraftDeck.ps1 -Action All -Configuration Release

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Build", "Deploy", "Debug", "Clean", "All")]
    [string]$Action,

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",

    [ValidateSet("Auto", "Windows", "macOS", "Linux")]
    [string]$Platform = "Auto",

    [switch]$SkipStreamDeckRestart
)

# Script configuration
$ErrorActionPreference = "Stop"
$basePath = $PSScriptRoot

if ($basePath.Length -eq 0) {
    $basePath = $PWD.Path
}

# Platform detection
function Get-CurrentPlatform {
    if ($Platform -ne "Auto") {
        return $Platform
    }

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

# Platform-specific configuration
function Get-PlatformConfig {
    param([string]$DetectedPlatform)
    
    switch ($DetectedPlatform) {
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
            throw "Unsupported platform: $DetectedPlatform"
        }
    }
}

# Build the plugin
function Invoke-Build {
    param([hashtable]$Config)
    
    Write-Host "🔨 Building CraftDeck StreamDeck Plugin..." -ForegroundColor Cyan
    Write-Host "   Configuration: $Configuration" -ForegroundColor Gray
    Write-Host "   Platform: $($Config.Runtime)" -ForegroundColor Gray
    
    $buildArgs = @(
        "build"
        "-c", $Configuration
        "-r", $Config.Runtime
        "--self-contained"
    )
    
    try {
        dotnet @buildArgs
        Write-Host "✅ Build completed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Deploy the plugin
function Invoke-Deploy {
    param([hashtable]$Config)
    
    Write-Host "📦 Deploying CraftDeck Plugin..." -ForegroundColor Cyan
    
    # Load and parse manifest
    $binDir = "$basePath\bin\$Configuration\net6.0\$($Config.Runtime)"
    $manifestFile = "$binDir\manifest.json"
    
    if (-not (Test-Path $binDir)) {
        Write-Host "❌ Build output directory not found: $binDir" -ForegroundColor Red
        Write-Host "   Run build first with: .\CraftDeck.ps1 -Action Build" -ForegroundColor Yellow
        return $false
    }
    
    if (-not (Test-Path $manifestFile)) {
        Write-Host "❌ Manifest file not found: $manifestFile" -ForegroundColor Red
        return $false
    }
    
    try {
        $manifestContent = Get-Content $manifestFile | Out-String
        $json = ConvertFrom-Json $manifestContent
        $pluginID = $json.UUID
        $destDir = "$($Config.PluginsDir)\$pluginID.sdPlugin"
        
        Write-Host "   Plugin UUID: $pluginID" -ForegroundColor Gray
        Write-Host "   Target Directory: $destDir" -ForegroundColor Gray
        
        # Stop StreamDeck and plugin processes
        Stop-StreamDeckProcesses -Config $Config
        
        # Clean deployment directory
        if (Test-Path $destDir) {
            Write-Host "   Removing existing plugin directory..." -ForegroundColor Gray
            Remove-Item -Recurse -Force -Path $destDir
        }
        
        # Create plugin directory and copy files
        Write-Host "   Copying plugin files..." -ForegroundColor Gray
        New-Item -Type Directory -Path $destDir -Force | Out-Null
        Copy-Item -Path "$binDir\*" -Destination $destDir -Recurse -Force
        
        Write-Host "✅ Deployment completed successfully" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
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
            # Ignore errors when stopping processes
        }
    }
    
    Start-Sleep -Seconds 2
}

# Start StreamDeck application
function Start-StreamDeck {
    param([hashtable]$Config)
    
    if ($SkipStreamDeckRestart) {
        Write-Host "⏭️  Skipping StreamDeck restart" -ForegroundColor Yellow
        return
    }
    
    Write-Host "🚀 Starting StreamDeck application..." -ForegroundColor Cyan
    
    try {
        if (Test-Path $Config.StreamDeckExe) {
            if ($Config.Runtime -eq "osx-x64") {
                Start-Process "open" -ArgumentList $Config.StreamDeckExe -NoNewWindow
            } else {
                Start-Process $Config.StreamDeckExe -NoNewWindow
            }
            Write-Host "✅ StreamDeck started" -ForegroundColor Green
        } else {
            Write-Host "⚠️  StreamDeck executable not found: $($Config.StreamDeckExe)" -ForegroundColor Yellow
            Write-Host "   Please start StreamDeck manually" -ForegroundColor Gray
        }
    } catch {
        Write-Host "⚠️  Failed to start StreamDeck: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Please start StreamDeck manually" -ForegroundColor Gray
    }
}

# Debug the plugin
function Invoke-Debug {
    param([hashtable]$Config)
    
    Write-Host "🐛 Starting Debug Mode..." -ForegroundColor Cyan
    
    $pluginDir = "$($Config.PluginsDir)\com.craftdeck.plugin.sdPlugin"
    $pluginExe = "$pluginDir\CraftDeck.StreamDeckPlugin.exe"
    
    if (-not (Test-Path $pluginExe)) {
        Write-Host "❌ Plugin executable not found: $pluginExe" -ForegroundColor Red
        Write-Host "   Deploy the plugin first with: .\CraftDeck.ps1 -Action Deploy" -ForegroundColor Yellow
        return $false
    }
    
    try {
        Write-Host "   Plugin Directory: $pluginDir" -ForegroundColor Gray
        Write-Host "   Starting plugin with debugger break..." -ForegroundColor Gray
        
        Push-Location $pluginDir
        Start-Process $pluginExe -ArgumentList "-break" -NoNewWindow -Wait
        Pop-Location
        
        return $true
    } catch {
        Write-Host "❌ Debug failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Clean build artifacts
function Invoke-Clean {
    Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor Cyan
    
    $cleanDirs = @("bin", "obj", "publish")
    
    foreach ($dir in $cleanDirs) {
        $fullPath = "$basePath\$dir"
        if (Test-Path $fullPath) {
            Write-Host "   Removing: $fullPath" -ForegroundColor Gray
            Remove-Item -Recurse -Force -Path $fullPath
        }
    }
    
    try {
        dotnet clean
        Write-Host "✅ Clean completed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Clean failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
function Main {
    Write-Host "🎮 CraftDeck StreamDeck Plugin Script" -ForegroundColor Magenta
    Write-Host "=====================================`n" -ForegroundColor Magenta
    
    $detectedPlatform = Get-CurrentPlatform
    $config = Get-PlatformConfig -DetectedPlatform $detectedPlatform
    
    Write-Host "Platform: $detectedPlatform" -ForegroundColor Gray
    Write-Host "Action: $Action" -ForegroundColor Gray
    Write-Host ""
    
    $success = $true
    
    switch ($Action) {
        "Build" {
            $success = Invoke-Build -Config $config
        }
        "Deploy" {
            $success = Invoke-Deploy -Config $config
            if ($success) {
                Start-StreamDeck -Config $config
            }
        }
        "Debug" {
            $success = Invoke-Debug -Config $config
        }
        "Clean" {
            $success = Invoke-Clean
        }
        "All" {
            $success = Invoke-Clean
            if ($success) { $success = Invoke-Build -Config $config }
            if ($success) { $success = Invoke-Deploy -Config $config }
            if ($success) { Start-StreamDeck -Config $config }
        }
    }
    
    Write-Host ""
    if ($success) {
        Write-Host "🎉 Operation completed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "💥 Operation failed!" -ForegroundColor Red
        exit 1
    }
}

# Execute main function
Main