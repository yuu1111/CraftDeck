#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CraftDeck Project Build Script

.DESCRIPTION
    Build script for CraftDeck components without deployment.
    Useful for development and CI/CD pipelines.

.PARAMETER Component
    Component to build: Mod, Plugin, or All (default: All)

.PARAMETER Configuration
    Build configuration: Debug or Release (default: Debug)

.PARAMETER Clean
    Clean build artifacts before building

.PARAMETER SkipTests
    Skip running tests after build

.EXAMPLE
    .\Build-CraftDeck.ps1
    .\Build-CraftDeck.ps1 -Component Plugin -Configuration Release
    .\Build-CraftDeck.ps1 -Clean
    .\Build-CraftDeck.ps1 -Component Mod -SkipTests

#>

[CmdletBinding()]
param(
    [ValidateSet("Mod", "Plugin", "All")]
    [string]$Component = "All",

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",

    [switch]$Clean,

    [switch]$SkipTests
)

# Script configuration
$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $PSScriptRoot
$modPath = Join-Path $scriptRoot "craftdeck-mod"
$pluginPath = Join-Path $scriptRoot "craftdeck-plugin"

# Clean build artifacts
function Invoke-Clean {
    param([string]$ProjectPath, [string]$ProjectType)

    Write-Host "🧹 Cleaning $ProjectType..." -ForegroundColor Cyan

    try {
        Push-Location $ProjectPath

        if ($ProjectType -eq "Mod") {
            if ($IsWindows) {
                .\gradlew.bat clean
            } else {
                ./gradlew clean
            }
        } else {
            dotnet clean

            $cleanDirs = @("bin", "obj", "publish")
            foreach ($dir in $cleanDirs) {
                $fullPath = Join-Path $ProjectPath $dir
                if (Test-Path $fullPath) {
                    Remove-Item -Recurse -Force -Path $fullPath
                }
            }
        }

        Write-Host "✅ $ProjectType cleaned" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ $ProjectType clean failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Build Minecraft Mod
function Build-MinecraftMod {
    Write-Host "🔨 Building Minecraft Mod..." -ForegroundColor Cyan

    if (-not (Test-Path $modPath)) {
        Write-Host "❌ Mod directory not found: $modPath" -ForegroundColor Red
        return $false
    }

    try {
        Push-Location $modPath

        if ($Clean) {
            Invoke-Clean -ProjectPath $modPath -ProjectType "Mod"
        }

        Write-Host "   Running Gradle build..." -ForegroundColor Gray
        if ($IsWindows) {
            .\gradlew.bat build
        } else {
            ./gradlew build
        }

        # Display build artifacts
        Show-ModBuildInfo

        Write-Host "✅ Minecraft Mod built successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Minecraft Mod build failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Build StreamDeck Plugin
function Build-StreamDeckPlugin {
    Write-Host "🔨 Building StreamDeck Plugin..." -ForegroundColor Cyan

    if (-not (Test-Path $pluginPath)) {
        Write-Host "❌ Plugin directory not found: $pluginPath" -ForegroundColor Red
        return $false
    }

    try {
        Push-Location $pluginPath

        if ($Clean) {
            Invoke-Clean -ProjectPath $pluginPath -ProjectType "Plugin"
        }

        Write-Host "   Configuration: $Configuration" -ForegroundColor Gray

        # Build solution
        dotnet build -c $Configuration

        # Run tests if not skipped
        if (-not $SkipTests) {
            Write-Host "   Running tests..." -ForegroundColor Gray
            dotnet test --configuration $Configuration --no-build
        }

        # Display build info
        Show-PluginBuildInfo

        Write-Host "✅ StreamDeck Plugin built successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ StreamDeck Plugin build failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Show mod build information
function Show-ModBuildInfo {
    Write-Host "📊 Build Information:" -ForegroundColor Cyan

    $platforms = @("common", "fabric", "forge", "quilt")

    foreach ($platform in $platforms) {
        $buildDir = Join-Path $modPath "$platform\build\libs"
        if (Test-Path $buildDir) {
            $jars = Get-ChildItem $buildDir -Filter "*.jar"
            Write-Host "   $platform`:" -ForegroundColor Yellow
            foreach ($jar in $jars) {
                $size = [math]::Round($jar.Length / 1KB, 1)
                Write-Host "     - $($jar.Name) ($size KB)" -ForegroundColor Gray
            }
        }
    }
}

# Show plugin build information
function Show-PluginBuildInfo {
    Write-Host "📊 Build Information:" -ForegroundColor Cyan

    $buildDir = Join-Path $pluginPath "bin\$Configuration\net6.0"
    if (Test-Path $buildDir) {
        $dll = Join-Path $buildDir "CraftDeck.StreamDeckPlugin.dll"
        if (Test-Path $dll) {
            $dllInfo = Get-Item $dll
            $size = [math]::Round($dllInfo.Length / 1KB, 1)
            Write-Host "   Assembly: CraftDeck.StreamDeckPlugin.dll ($size KB)" -ForegroundColor Gray
        }

        # Check for runtime-specific builds
        $runtimes = @("win-x64", "osx-x64", "linux-x64")
        foreach ($runtime in $runtimes) {
            $runtimeDir = Join-Path $buildDir $runtime
            if (Test-Path $runtimeDir) {
                Write-Host "   Runtime: $runtime" -ForegroundColor Yellow
                $exe = Get-ChildItem $runtimeDir -Filter "*.exe" | Select-Object -First 1
                if ($exe) {
                    $size = [math]::Round($exe.Length / 1MB, 1)
                    Write-Host "     - $($exe.Name) ($size MB)" -ForegroundColor Gray
                }
            }
        }
    }
}

# Validate build environment
function Test-BuildEnvironment {
    Write-Host "🔍 Validating build environment..." -ForegroundColor Cyan

    $issues = @()

    # Check .NET SDK
    try {
        $dotnetVersion = dotnet --version
        Write-Host "   ✅ .NET SDK: $dotnetVersion" -ForegroundColor Gray
    } catch {
        $issues += "❌ .NET SDK not found or not accessible"
    }

    # Check Java for Gradle
    try {
        $javaVersion = java -version 2>&1 | Select-Object -First 1
        Write-Host "   ✅ Java: $javaVersion" -ForegroundColor Gray
    } catch {
        $issues += "❌ Java not found (required for Minecraft mod build)"
    }

    # Check project files
    if (-not (Test-Path (Join-Path $modPath "build.gradle"))) {
        $issues += "❌ Mod build.gradle not found"
    } else {
        Write-Host "   ✅ Mod project files found" -ForegroundColor Gray
    }

    if (-not (Test-Path (Join-Path $pluginPath "CraftDeck.StreamDeckPlugin.csproj"))) {
        $issues += "❌ Plugin project file not found"
    } else {
        Write-Host "   ✅ Plugin project files found" -ForegroundColor Gray
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

# Main execution
function Main {
    Write-Host "🔨 CraftDeck Project Build" -ForegroundColor Magenta
    Write-Host "========================`n" -ForegroundColor Magenta

    Write-Host "Component: $Component" -ForegroundColor Gray
    Write-Host "Configuration: $Configuration" -ForegroundColor Gray
    if ($Clean) { Write-Host "Clean: Yes" -ForegroundColor Gray }
    if ($SkipTests) { Write-Host "Skip Tests: Yes" -ForegroundColor Gray }
    Write-Host ""

    # Validate environment
    if (-not (Test-BuildEnvironment)) {
        exit 1
    }

    $success = $true
    $startTime = Get-Date

    # Build components based on selection
    switch ($Component) {
        "Mod" {
            $success = Build-MinecraftMod
        }
        "Plugin" {
            $success = Build-StreamDeckPlugin
        }
        "All" {
            $success = Build-MinecraftMod
            if ($success) {
                $success = Build-StreamDeckPlugin
            }
        }
    }

    $duration = (Get-Date) - $startTime

    Write-Host ""
    Write-Host "⏱️  Build time: $($duration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Gray

    if ($success) {
        Write-Host "🎉 Build completed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "💥 Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Execute main function
Main