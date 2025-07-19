#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CraftDeck Minecraft Mod Build Script

.DESCRIPTION
    Build script for CraftDeck Minecraft Mod with support for multiple mod loaders.

.PARAMETER Platform
    Target platform: all, fabric, forge, or quilt (default: all)

.PARAMETER Clean
    Perform clean build

.PARAMETER RunClient
    Start development client after build

.PARAMETER DetailedLog
    Show detailed build logs

.EXAMPLE
    .\Build-Mod.ps1
    .\Build-Mod.ps1 -Platform fabric -Clean
    .\Build-Mod.ps1 -Platform forge -RunClient
    .\Build-Mod.ps1 -Platform all -DetailedLog

#>

[CmdletBinding()]
param(
    [ValidateSet("all", "fabric", "forge", "quilt")]
    [string]$Platform = "all",

    [switch]$Clean,

    [switch]$RunClient,

    [switch]$DetailedLog
)

# Script configuration
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$modDir = Join-Path $projectRoot "craftdeck-mod"

Write-Host "🔨 CraftDeck Minecraft Mod Build" -ForegroundColor Cyan
Write-Host "=================================`n" -ForegroundColor Cyan

Write-Host "Project Directory: $modDir" -ForegroundColor Gray
Write-Host "Target Platform: $Platform" -ForegroundColor Gray
if ($Clean) { Write-Host "Clean Build: Yes" -ForegroundColor Gray }
if ($RunClient) { Write-Host "Run Client: Yes" -ForegroundColor Gray }
if ($DetailedLog) { Write-Host "Detailed Log: Yes" -ForegroundColor Gray }
Write-Host ""

# Validate environment
function Test-BuildEnvironment {
    Write-Host "🔍 Validating build environment..." -ForegroundColor Cyan

    $issues = @()

    # Check Java
    try {
        $javaVersion = java -version 2>&1 | Select-Object -First 1
        Write-Host "   ✅ Java: $javaVersion" -ForegroundColor Gray
    } catch {
        $issues += "❌ Java not found (required for Minecraft mod build)"
    }

    # Check mod directory
    if (-not (Test-Path $modDir)) {
        $issues += "❌ Minecraft Mod directory not found: $modDir"
    } else {
        Write-Host "   ✅ Mod directory found" -ForegroundColor Gray
    }

    # Check build.gradle
    $buildGradle = Join-Path $modDir "build.gradle"
    if (-not (Test-Path $buildGradle)) {
        $issues += "❌ build.gradle not found"
    } else {
        Write-Host "   ✅ Gradle build file found" -ForegroundColor Gray
    }

    if ($issues.Count -gt 0) {
        Write-Host "`nBuild environment issues:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  $issue" -ForegroundColor Red
        }
        return $false
    }

    Write-Host "✅ Build environment validated" -ForegroundColor Green
    return $true
}

# Clean build artifacts
function Invoke-Clean {
    Write-Host "🧹 Cleaning mod build artifacts..." -ForegroundColor Cyan

    try {
        Write-Host "   Running Gradle clean..." -ForegroundColor Gray
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            & .\gradlew.bat clean
        } else {
            & ./gradlew clean
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Clean operation failed"
        }

        Write-Host "✅ Clean completed" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Clean failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Run development client
function Start-DevClient {
    Write-Host "🎮 Starting development client ($Platform)..." -ForegroundColor Cyan

    $runTask = switch ($Platform) {
        "fabric" { ":fabric:runClient" }
        "forge" { ":forge:runClient" }
        "quilt" { ":quilt:runClient" }
        default { ":fabric:runClient" }
    }

    try {
        Write-Host "   Gradle task: $runTask" -ForegroundColor Gray
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            & .\gradlew.bat $runTask
        } else {
            & ./gradlew $runTask
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Development client failed to start"
        }

        Write-Host "✅ Development client started successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Development client failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Build mod
function Build-Mod {
    Write-Host "🔨 Building Minecraft mod ($Platform)..." -ForegroundColor Cyan

    $buildTask = switch ($Platform) {
        "all" { "build" }
        "fabric" { ":fabric:build" }
        "forge" { ":forge:build" }
        "quilt" { ":quilt:build" }
    }

    try {
        Write-Host "   Gradle task: $buildTask" -ForegroundColor Gray

        $gradleArgs = @($buildTask)
        if ($DetailedLog) {
            $gradleArgs += "--info"
        }

        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            & .\gradlew.bat $gradleArgs
        } else {
            & ./gradlew $gradleArgs
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Build operation failed"
        }

        Write-Host "✅ Build completed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Show build information
function Show-BuildInfo {
    Write-Host "📊 Build Information:" -ForegroundColor Cyan

    $platforms = @()
    if ($Platform -eq "all") {
        $platforms = @("fabric", "forge", "quilt")
    } else {
        $platforms = @($Platform)
    }

    foreach ($platform in $platforms) {
        $buildDir = "$platform\build\libs"
        if (Test-Path $buildDir) {
            $jars = Get-ChildItem -Path $buildDir -Filter "*.jar" -Exclude "*-sources.jar"
            if ($jars) {
                Write-Host "   $platform`:" -ForegroundColor Yellow
                foreach ($jar in $jars) {
                    $size = [math]::Round($jar.Length / 1KB, 1)
                    Write-Host "     - $($jar.Name) ($size KB)" -ForegroundColor Gray
                }
            }
        }
    }
}

# Main execution
function Main {
    $startTime = Get-Date

    # Validate environment
    if (-not (Test-BuildEnvironment)) {
        exit 1
    }

    $success = $true

    try {
        Push-Location $modDir

        # Clean if requested
        if ($Clean) {
            $success = Invoke-Clean
            if (-not $success) {
                exit 1
            }
        }

        # Run client or build
        if ($RunClient) {
            $success = Start-DevClient
        } else {
            $success = Build-Mod
            if ($success) {
                Show-BuildInfo
            }
        }

        $duration = (Get-Date) - $startTime
        Write-Host ""
        Write-Host "⏱️  Build time: $($duration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Gray

        if ($success) {
            Write-Host "🎉 Mod build completed successfully!" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "💥 Mod build failed!" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "❌ Build error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Execute main function
Main

# Wait for user input before closing
Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
Read-Host