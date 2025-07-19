#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CraftDeck StreamDeck Plugin Build Script

.DESCRIPTION
    Build script for CraftDeck StreamDeck Plugin with deployment and publishing options.

.PARAMETER Configuration
    Build configuration: Debug or Release (default: Release)

.PARAMETER Clean
    Perform clean build

.PARAMETER Deploy
    Automatically deploy to StreamDeck

.PARAMETER Publish
    Publish as self-contained executable

.PARAMETER DetailedLog
    Show detailed build logs

.EXAMPLE
    .\Build-Plugin.ps1
    .\Build-Plugin.ps1 -Configuration Debug -Clean
    .\Build-Plugin.ps1 -Publish -Deploy
    .\Build-Plugin.ps1 -Configuration Release -DetailedLog

#>

[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [switch]$Clean,

    [switch]$Deploy,

    [switch]$Publish,

    [switch]$DetailedLog
)

# Script configuration
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$pluginDir = Join-Path $projectRoot "craftdeck-plugin"
$pluginProject = Join-Path $pluginDir "CraftDeck.StreamDeckPlugin.csproj"

Write-Host "🔨 CraftDeck StreamDeck Plugin Build" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

Write-Host "Project Directory: $pluginDir" -ForegroundColor Gray
Write-Host "Build Configuration: $Configuration" -ForegroundColor Gray
if ($Clean) { Write-Host "Clean Build: Yes" -ForegroundColor Gray }
if ($Publish) { Write-Host "Publish Mode: Yes" -ForegroundColor Gray }
if ($Deploy) { Write-Host "Auto Deploy: Yes" -ForegroundColor Gray }
Write-Host ""

# Validate environment
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

    # Check plugin directory
    if (-not (Test-Path $pluginDir)) {
        $issues += "❌ Plugin directory not found: $pluginDir"
    } else {
        Write-Host "   ✅ Plugin directory found" -ForegroundColor Gray
    }

    # Check project file
    if (-not (Test-Path $pluginProject)) {
        $issues += "❌ Plugin project file not found: $pluginProject"
    } else {
        Write-Host "   ✅ Plugin project file found" -ForegroundColor Gray
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
    Write-Host "🧹 Cleaning plugin build artifacts..." -ForegroundColor Cyan

    try {
        Push-Location $pluginDir

        $cleanArgs = @("clean", $pluginProject, "-c", $Configuration)
        if ($DetailedLog) {
            $cleanArgs += "-v", "detailed"
        }

        & dotnet $cleanArgs

        if ($LASTEXITCODE -ne 0) {
            throw "Clean operation failed"
        }

        # Remove additional directories
        $cleanDirs = @("bin", "obj", "publish")
        foreach ($dir in $cleanDirs) {
            $fullPath = Join-Path $pluginDir $dir
            if (Test-Path $fullPath) {
                Remove-Item -Recurse -Force -Path $fullPath
                Write-Host "   Removed: $dir" -ForegroundColor Gray
            }
        }

        Write-Host "✅ Clean completed" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Clean failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Build or publish plugin
function Build-Plugin {
    Write-Host "🔨 Building StreamDeck Plugin..." -ForegroundColor Cyan

    try {
        Push-Location $pluginDir

        if ($Publish) {
            Write-Host "   Publishing self-contained executable..." -ForegroundColor Gray

            $publishArgs = @(
                "publish",
                $pluginProject,
                "-c", $Configuration,
                "--self-contained",
                "-r", "win-x64",
                "-o", "publish"
            )

            if ($DetailedLog) {
                $publishArgs += "-v", "detailed"
            }

            & dotnet $publishArgs

            if ($LASTEXITCODE -ne 0) {
                throw "Publish operation failed"
            }

            Write-Host "   Publish output: $pluginDir\publish" -ForegroundColor Gray
        } else {
            Write-Host "   Building plugin..." -ForegroundColor Gray

            $buildArgs = @("build", $pluginProject, "-c", $Configuration)
            if ($DetailedLog) {
                $buildArgs += "-v", "detailed"
            }

            & dotnet $buildArgs

            if ($LASTEXITCODE -ne 0) {
                throw "Build operation failed"
            }
        }

        Write-Host "✅ Build completed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Deploy to StreamDeck
function Deploy-ToStreamDeck {
    Write-Host "🚀 Deploying to StreamDeck..." -ForegroundColor Cyan

    $registerScript = Join-Path $pluginDir "RegisterPluginAndStartStreamDeck.ps1"
    if (Test-Path $registerScript) {
        Write-Host "   Executing registration script..." -ForegroundColor Gray

        try {
            & powershell -ExecutionPolicy Unrestricted -File $registerScript

            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Successfully deployed to StreamDeck" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠️  StreamDeck registration completed with warnings" -ForegroundColor Yellow
                return $true
            }
        } catch {
            Write-Host "❌ StreamDeck deployment failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "⚠️  Registration script not found: $registerScript" -ForegroundColor Yellow
        return $false
    }
}

# Show build information
function Show-BuildInfo {
    Write-Host "📊 Build Information:" -ForegroundColor Cyan

    $outputDir = if ($Publish) { "publish" } else { "bin\$Configuration\net6.0\win-x64" }
    $outputPath = Join-Path $pluginDir $outputDir

    if ($Publish) {
        $exePath = Join-Path $outputPath "CraftDeck.StreamDeckPlugin.exe"
        if (Test-Path $exePath) {
            $fileInfo = Get-Item $exePath
            Write-Host "   Executable: $($fileInfo.Name)" -ForegroundColor Gray
            Write-Host "   Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
            Write-Host "   Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        }
    } else {
        # Check for executable first (self-contained), then DLL
        $exePath = Join-Path $outputPath "CraftDeck.StreamDeckPlugin.exe"
        $dllPath = Join-Path $outputPath "CraftDeck.StreamDeckPlugin.dll"

        if (Test-Path $exePath) {
            $fileInfo = Get-Item $exePath
            Write-Host "   Runtime: win-x64" -ForegroundColor Gray
            Write-Host "     - $($fileInfo.Name) ($([math]::Round($fileInfo.Length / 1MB, 1)) MB)" -ForegroundColor Gray
        } elseif (Test-Path $dllPath) {
            $fileInfo = Get-Item $dllPath
            Write-Host "   Assembly: $($fileInfo.Name)" -ForegroundColor Gray
            Write-Host "   Size: $([math]::Round($fileInfo.Length / 1KB, 1)) KB" -ForegroundColor Gray
            Write-Host "   Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        }

    }

    # Verify required files
    $requiredFiles = @(
        "manifest.json",
        "appsettings.json",
        "images\pluginIcon.png",
        "images\pluginIcon@2x.png",
        "property_inspector\property_inspector.html"
    )

    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $outputPath $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }

    if ($missingFiles.Count -gt 0) {
        Write-Host "`n⚠️  Missing required files:" -ForegroundColor Yellow
        $missingFiles | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
    } else {
        Write-Host "`n✅ All required files present" -ForegroundColor Green
    }
}

# Main execution
function Main {
    $startTime = Get-Date

    # Validate environment
    if (-not (Test-BuildEnvironment)) {
        Read-Host
        exit 1
    }

    $success = $true

    # Clean if requested
    if ($Clean) {
        $success = Invoke-Clean
        if (-not $success) {
            Read-Host
            exit 1
        }
    }

    # Build/publish
    $success = Build-Plugin
    if (-not $success) {
        Read-Host
        exit 1
    }

    # Show build information
    Show-BuildInfo

    # Deploy if requested
    if ($Deploy) {
        $deploySuccess = Deploy-ToStreamDeck
        if (-not $deploySuccess) {
            Write-Host "⚠️  Build succeeded but deployment failed" -ForegroundColor Yellow
        }
    }

    $duration = (Get-Date) - $startTime
    Write-Host ""
    Write-Host "⏱️  Build time: $($duration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Gray

    if ($success) {
        Write-Host "🎉 Plugin build completed successfully!" -ForegroundColor Green
        Read-Host
        exit 0
    } else {
        Write-Host "💥 Plugin build failed!" -ForegroundColor Red
        Read-Host
        exit 1
    }
}

# Execute main function
Main

# Wait for user input before closing
Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
Read-Host