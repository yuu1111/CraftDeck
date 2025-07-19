#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CraftDeck Complete Build System

.DESCRIPTION
    Comprehensive build script for CraftDeck project (Minecraft Mod + StreamDeck Plugin).
    Supports parallel building and component selection.

.PARAMETER Component
    Component to build: all, mod, or plugin (default: all)

.PARAMETER Configuration
    Build configuration: Debug or Release (default: Release)

.PARAMETER ModPlatform
    Mod platform: all, fabric, forge, or quilt (default: all)

.PARAMETER Clean
    Perform clean build

.PARAMETER Deploy
    Automatically deploy plugin to StreamDeck

.PARAMETER DetailedLog
    Show detailed build logs

.PARAMETER NoParallel
    Disable parallel building

.EXAMPLE
    .\Build-All.ps1
    .\Build-All.ps1 -Component mod -ModPlatform fabric
    .\Build-All.ps1 -Component plugin -Configuration Debug -Deploy
    .\Build-All.ps1 -Clean -DetailedLog

#>

[CmdletBinding()]
param(
    [ValidateSet("all", "mod", "plugin")]
    [string]$Component = "all",

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [ValidateSet("all", "fabric", "forge", "quilt")]
    [string]$ModPlatform = "all",

    [switch]$Clean,

    [switch]$Deploy,

    [switch]$DetailedLog,

    [switch]$NoParallel
)

# Script configuration
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$projectRoot = Split-Path -Parent $scriptDir

Write-Host @"
 ██████╗██████╗  █████╗ ███████╗████████╗██████╗ ███████╗ ██████╗██╗  ██╗
██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝██║ ██╔╝
██║     ██████╔╝███████║█████╗     ██║   ██║  ██║█████╗  ██║     █████╔╝
██║     ██╔══██╗██╔══██║██╔══╝     ██║   ██║  ██║██╔══╝  ██║     ██╔═██╗
╚██████╗██║  ██║██║  ██║██║        ██║   ██████╔╝███████╗╚██████╗██║  ██╗
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝   ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝
"@ -ForegroundColor Cyan

Write-Host "`n🔨 CraftDeck Integrated Build System" -ForegroundColor Yellow
Write-Host "===================================`n" -ForegroundColor Yellow

Write-Host "Component: $Component" -ForegroundColor Gray
Write-Host "Configuration: $Configuration" -ForegroundColor Gray
Write-Host "Mod Platform: $ModPlatform" -ForegroundColor Gray
if ($Clean) { Write-Host "Clean Build: Yes" -ForegroundColor Gray }
if ($Deploy) { Write-Host "Auto Deploy: Yes" -ForegroundColor Gray }
if ($DetailedLog) { Write-Host "Detailed Log: Yes" -ForegroundColor Gray }
if ($NoParallel) { Write-Host "Parallel Build: No" -ForegroundColor Gray } else { Write-Host "Parallel Build: Yes" -ForegroundColor Gray }
Write-Host ""

# Build results tracking
$buildResults = @{
    MinecraftMod = $null
    StreamDeckPlugin = $null
}

# Build Minecraft Mod
function Build-MinecraftMod {
    Write-Host "━━━ 🎮 Minecraft Mod Build ━━━" -ForegroundColor Magenta

    $modScript = Join-Path $scriptDir "Build-Mod.ps1"

    if (-not (Test-Path $modScript)) {
        $buildResults.MinecraftMod = "❌ Script not found: Build-Mod.ps1"
        return $false
    }

    $modArgs = @{
        Platform = $ModPlatform
        Clean = $Clean
        DetailedLog = $DetailedLog
    }

    try {
        $modParams = @()
        $modParams += "-Platform", $ModPlatform
        if ($Clean) { $modParams += "-Clean" }
        if ($DetailedLog) { $modParams += "-DetailedLog" }

        & $modScript @modParams

        if ($LASTEXITCODE -eq 0) {
            $buildResults.MinecraftMod = "✅ Success"
            return $true
        } else {
            $buildResults.MinecraftMod = "❌ Failed (exit code: $LASTEXITCODE)"
            return $false
        }
    } catch {
        $buildResults.MinecraftMod = "❌ Failed: $($_.Exception.Message)"
        return $false
    }
}

# Build StreamDeck Plugin
function Build-StreamDeckPlugin {
    Write-Host "━━━ 🎛️ StreamDeck Plugin Build ━━━" -ForegroundColor Magenta

    $pluginScript = Join-Path $scriptDir "Build-Plugin.ps1"

    if (-not (Test-Path $pluginScript)) {
        $buildResults.StreamDeckPlugin = "❌ Script not found: Build-Plugin.ps1"
        return $false
    }

    try {
        $pluginParams = @()
        $pluginParams += "-Configuration", $Configuration
        if ($Clean) { $pluginParams += "-Clean" }
        if ($Deploy) { $pluginParams += "-Deploy" }
        if ($DetailedLog) { $pluginParams += "-DetailedLog" }

        & $pluginScript @pluginParams

        if ($LASTEXITCODE -eq 0) {
            $buildResults.StreamDeckPlugin = "✅ Success"
            return $true
        } else {
            $buildResults.StreamDeckPlugin = "❌ Failed (exit code: $LASTEXITCODE)"
            return $false
        }
    } catch {
        $buildResults.StreamDeckPlugin = "❌ Failed: $($_.Exception.Message)"
        return $false
    }
}

# Parallel build execution
function Start-ParallelBuild {
    Write-Host "🚀 Starting parallel build..." -ForegroundColor Yellow

    $modJob = Start-Job -ScriptBlock {
        param($ScriptPath, $ModPlatform, $Clean, $DetailedLog)

        $params = @("-Platform", $ModPlatform)
        if ($Clean) { $params += "-Clean" }
        if ($DetailedLog) { $params += "-DetailedLog" }

        & $ScriptPath @params
        return $LASTEXITCODE
    } -ArgumentList (Join-Path $scriptDir "Build-Mod.ps1"), $ModPlatform, $Clean, $DetailedLog

    $pluginJob = Start-Job -ScriptBlock {
        param($ScriptPath, $Configuration, $Clean, $Deploy, $DetailedLog)

        $params = @("-Configuration", $Configuration)
        if ($Clean) { $params += "-Clean" }
        if ($Deploy) { $params += "-Deploy" }
        if ($DetailedLog) { $params += "-DetailedLog" }

        & $ScriptPath @params
        return $LASTEXITCODE
    } -ArgumentList (Join-Path $scriptDir "Build-Plugin.ps1"), $Configuration, $Clean, $Deploy, $DetailedLog

    # Wait for completion
    Write-Host "   Waiting for builds to complete..." -ForegroundColor Gray
    $jobs = @($modJob, $pluginJob)
    $completedJobs = $jobs | Wait-Job

    # Process results
    foreach ($job in $completedJobs) {
        $result = Receive-Job $job
        if ($job.Id -eq $modJob.Id) {
            if ($job.State -eq "Completed" -and $result -eq 0) {
                $buildResults.MinecraftMod = "✅ Success"
            } else {
                $buildResults.MinecraftMod = "❌ Failed"
            }
        } elseif ($job.Id -eq $pluginJob.Id) {
            if ($job.State -eq "Completed" -and $result -eq 0) {
                $buildResults.StreamDeckPlugin = "✅ Success"
            } else {
                $buildResults.StreamDeckPlugin = "❌ Failed"
            }
        }
    }

    # Cleanup
    $jobs | Remove-Job -Force

    $success = ($buildResults.MinecraftMod -like "*Success*") -and ($buildResults.StreamDeckPlugin -like "*Success*")
    return $success
}

# Show build artifacts
function Show-BuildArtifacts {
    Write-Host "📦 Build Artifacts:" -ForegroundColor Yellow

    if ($Component -eq "all" -or $Component -eq "mod") {
        Write-Host "   Minecraft Mod:" -ForegroundColor Gray
        $platforms = if ($ModPlatform -eq "all") { @("fabric", "forge", "quilt") } else { @($ModPlatform) }

        foreach ($platform in $platforms) {
            $libsDir = Join-Path $projectRoot "craftdeck-mod\$platform\build\libs"
            if (Test-Path $libsDir) {
                Write-Host "     - $platform`: $libsDir" -ForegroundColor DarkGray
            }
        }
    }

    if ($Component -eq "all" -or $Component -eq "plugin") {
        Write-Host "   StreamDeck Plugin:" -ForegroundColor Gray
        $pluginBin = Join-Path $projectRoot "craftdeck-plugin\bin\$Configuration\net6.0"
        if (Test-Path $pluginBin) {
            Write-Host "     - Plugin: $pluginBin" -ForegroundColor DarkGray
        }
    }
}

# Main execution
function Main {
    $startTime = Get-Date
    $success = $true

    try {
        switch ($Component) {
            "mod" {
                $success = Build-MinecraftMod
            }
            "plugin" {
                $success = Build-StreamDeckPlugin
            }
            "all" {
                if ($NoParallel) {
                    # Sequential execution
                    Write-Host "🔄 Sequential build mode" -ForegroundColor Yellow
                    $modSuccess = Build-MinecraftMod
                    $pluginSuccess = Build-StreamDeckPlugin
                    $success = $modSuccess -and $pluginSuccess
                } else {
                    # Parallel execution
                    $success = Start-ParallelBuild
                }
            }
        }
    } catch {
        Write-Host "❌ Build system error: $($_.Exception.Message)" -ForegroundColor Red
        $success = $false
    }

    # Build results summary
    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Host "`n━━━ 📊 Build Results Summary ━━━" -ForegroundColor Cyan
    Write-Host "Total build time: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray

    if ($Component -eq "all" -or $Component -eq "mod") {
        Write-Host "Minecraft Mod: $($buildResults.MinecraftMod)" -ForegroundColor White
    }

    if ($Component -eq "all" -or $Component -eq "plugin") {
        Write-Host "StreamDeck Plugin: $($buildResults.StreamDeckPlugin)" -ForegroundColor White
    }

    if ($success) {
        Write-Host "`n🎉 All builds completed successfully!" -ForegroundColor Green
        Show-BuildArtifacts
        exit 0
    } else {
        Write-Host "`n💥 Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Execute main function
Main

# Wait for user input before closing
Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
Read-Host