# Build-All.ps1
# CraftDeck 全体ビルドスクリプト（Minecraft Mod + StreamDeck Plugin）

param(
    [Parameter(HelpMessage="ビルドするコンポーネント (all, mod, plugin)")]
    [ValidateSet("all", "mod", "plugin")]
    [string]$Component = "all",

    [Parameter(HelpMessage="ビルド構成 (Debug, Release)")]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [Parameter(HelpMessage="Modのプラットフォーム (all, fabric, forge, quilt)")]
    [ValidateSet("all", "fabric", "forge", "quilt")]
    [string]$ModPlatform = "all",

    [Parameter(HelpMessage="クリーンビルドを実行")]
    [switch]$Clean,

    [Parameter(HelpMessage="StreamDeckに自動デプロイ")]
    [switch]$Deploy,

    [Parameter(HelpMessage="詳細ログを表示")]
    [switch]$DetailedLog,

    [Parameter(HelpMessage="並列ビルドを無効化")]
    [switch]$NoParallel
)

$ErrorActionPreference = "Stop"

# スクリプトディレクトリ
$ScriptDir = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host @"
 ██████╗██████╗  █████╗ ███████╗████████╗██████╗ ███████╗ ██████╗██╗  ██╗
██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝██║ ██╔╝
██║     ██████╔╝███████║█████╗     ██║   ██║  ██║█████╗  ██║     █████╔╝
██║     ██╔══██╗██╔══██║██╔══╝     ██║   ██║  ██║██╔══╝  ██║     ██╔═██╗
╚██████╗██║  ██║██║  ██║██║        ██║   ██████╔╝███████╗╚██████╗██║  ██╗
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝   ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝
"@ -ForegroundColor Cyan

Write-Host "`n=== CraftDeck 統合ビルドシステム ===" -ForegroundColor Yellow
Write-Host "コンポーネント: $Component" -ForegroundColor Gray
Write-Host "構成: $Configuration" -ForegroundColor Gray
Write-Host "Modプラットフォーム: $ModPlatform" -ForegroundColor Gray

# ビルド開始時刻
$StartTime = Get-Date

# ビルド結果を格納
$BuildResults = @{
    MinecraftMod = $null
    StreamDeckPlugin = $null
}

# Minecraft Mod ビルド関数
function Build-MinecraftMod {
    Write-Host "`n━━━ Minecraft Mod ビルド ━━━" -ForegroundColor Magenta

    $modScript = Join-Path $ScriptDir "Build-MinecraftMod.ps1"
    $modArgs = @{
        Platform = $ModPlatform
        Clean = $Clean
        DetailedLog = $DetailedLog
    }

    try {
        & $modScript @modArgs
        $BuildResults.MinecraftMod = "✅ 成功"
        return $true
    }
    catch {
        $BuildResults.MinecraftMod = "❌ 失敗: $_"
        return $false
    }
}

# StreamDeck Plugin ビルド関数
function Build-StreamDeckPlugin {
    Write-Host "`n━━━ StreamDeck Plugin ビルド ━━━" -ForegroundColor Magenta

    $pluginScript = Join-Path $ScriptDir "Build-StreamDeckPlugin.ps1"
    $pluginArgs = @{
        Configuration = $Configuration
        Clean = $Clean
        Deploy = $Deploy
        DetailedLog = $DetailedLog
    }

    try {
        & $pluginScript @pluginArgs
        $BuildResults.StreamDeckPlugin = "✅ 成功"
        return $true
    }
    catch {
        $BuildResults.StreamDeckPlugin = "❌ 失敗: $_"
        return $false
    }
}

# メインビルド処理
$Success = $true

try {
    switch ($Component) {
        "mod" {
            $Success = Build-MinecraftMod
        }
        "plugin" {
            $Success = Build-StreamDeckPlugin
        }
        "all" {
            if ($NoParallel) {
                # 順次実行
                $modSuccess = Build-MinecraftMod
                $pluginSuccess = Build-StreamDeckPlugin
                $Success = $modSuccess -and $pluginSuccess
            }
            else {
                # 並列実行
                Write-Host "`n並列ビルドを開始します..." -ForegroundColor Yellow

                $modJob = Start-Job -ScriptBlock {
                    param($ScriptDir, $ModPlatform, $Clean, $Verbose)
                    $modScript = Join-Path $ScriptDir "Build-MinecraftMod.ps1"
                    & $modScript -Platform $ModPlatform -Clean:$Clean -DetailedLog:$DetailedLog
                } -ArgumentList $ScriptDir, $ModPlatform, $Clean, $Verbose

                $pluginJob = Start-Job -ScriptBlock {
                    param($ScriptDir, $Configuration, $Clean, $Deploy, $Verbose)
                    $pluginScript = Join-Path $ScriptDir "Build-StreamDeckPlugin.ps1"
                    & $pluginScript -Configuration $Configuration -Clean:$Clean -Deploy:$Deploy -DetailedLog:$DetailedLog
                } -ArgumentList $ScriptDir, $Configuration, $Clean, $Deploy, $Verbose

                # ジョブの完了を待機
                $jobs = @($modJob, $pluginJob)
                $completedJobs = $jobs | Wait-Job

                # 結果の取得
                foreach ($job in $completedJobs) {
                    if ($job.Name -eq $modJob.Name) {
                        if ($job.State -eq "Completed") {
                            $BuildResults.MinecraftMod = "✅ 成功"
                        } else {
                            $BuildResults.MinecraftMod = "❌ 失敗"
                            $Success = $false
                        }
                    }
                    elseif ($job.Name -eq $pluginJob.Name) {
                        if ($job.State -eq "Completed") {
                            $BuildResults.StreamDeckPlugin = "✅ 成功"
                        } else {
                            $BuildResults.StreamDeckPlugin = "❌ 失敗"
                            $Success = $false
                        }
                    }
                }

                # ジョブのクリーンアップ
                $jobs | Remove-Job -Force
            }
        }
    }
}
catch {
    Write-Error "ビルド中にエラーが発生しました: $_"
    $Success = $false
}

# ビルド結果サマリー
$EndTime = Get-Date
$Duration = $EndTime - $StartTime

Write-Host "`n━━━ ビルド結果サマリー ━━━" -ForegroundColor Cyan
Write-Host "総実行時間: $($Duration.ToString('mm\:ss'))" -ForegroundColor Gray

if ($Component -eq "all" -or $Component -eq "mod") {
    Write-Host "Minecraft Mod: $($BuildResults.MinecraftMod)" -ForegroundColor White
}

if ($Component -eq "all" -or $Component -eq "plugin") {
    Write-Host "StreamDeck Plugin: $($BuildResults.StreamDeckPlugin)" -ForegroundColor White
}

if ($Success) {
    Write-Host "`n🎉 すべてのビルドが正常に完了しました！" -ForegroundColor Green

    # 成果物の場所を表示
    Write-Host "`n📦 ビルド成果物の場所:" -ForegroundColor Yellow

    if ($Component -eq "all" -or $Component -eq "mod") {
        Write-Host "  Minecraft Mod:" -ForegroundColor Gray
        Write-Host "    - Fabric: $ProjectRoot\craftdeck-mod\fabric\build\libs\" -ForegroundColor DarkGray
        Write-Host "    - Forge: $ProjectRoot\craftdeck-mod\forge\build\libs\" -ForegroundColor DarkGray
        Write-Host "    - Quilt: $ProjectRoot\craftdeck-mod\quilt\build\libs\" -ForegroundColor DarkGray
    }

    if ($Component -eq "all" -or $Component -eq "plugin") {
        Write-Host "  StreamDeck Plugin:" -ForegroundColor Gray
        Write-Host "    - 実行ファイル: $ProjectRoot\craftdeck-plugin\bin\$Configuration\net6.0-windows\" -ForegroundColor DarkGray
    }

    exit 0
}
else {
    Write-Host "`n❌ ビルドに失敗しました" -ForegroundColor Red
    exit 1
}