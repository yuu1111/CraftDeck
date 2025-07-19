# Build-StreamDeckPlugin.ps1
# StreamDeck Plugin (CraftDeck) のビルドスクリプト

param(
    [Parameter(HelpMessage="ビルド構成を指定 (Debug, Release)")]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [Parameter(HelpMessage="クリーンビルドを実行")]
    [switch]$Clean,

    [Parameter(HelpMessage="StreamDeckに自動デプロイ")]
    [switch]$Deploy,

    [Parameter(HelpMessage="自己完結型としてパブリッシュ")]
    [switch]$Publish,

    [Parameter(HelpMessage="詳細ログを表示")]
    [switch]$DetailedLog
)

$ErrorActionPreference = "Stop"

# プロジェクトルートディレクトリの設定
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PluginDir = Join-Path $ProjectRoot "craftdeck-plugin"
$PluginProject = Join-Path $PluginDir "CraftDeck.StreamDeckPlugin.csproj"

Write-Host "=== CraftDeck StreamDeck Plugin ビルドスクリプト ===" -ForegroundColor Cyan
Write-Host "プロジェクトディレクトリ: $PluginDir" -ForegroundColor Gray
Write-Host "ビルド構成: $Configuration" -ForegroundColor Gray

# ディレクトリ存在確認
if (-not (Test-Path $PluginDir)) {
    Write-Error "StreamDeck Pluginディレクトリが見つかりません: $PluginDir"
    exit 1
}

# 作業ディレクトリ変更
Push-Location $PluginDir

try {
    # クリーンビルド
    if ($Clean) {
        Write-Host "`nクリーンを実行中..." -ForegroundColor Yellow

        $cleanArgs = @("clean", $PluginProject, "-c", $Configuration)
        if ($DetailedLog) {
            $cleanArgs += "-v", "detailed"
        }

        & dotnet $cleanArgs

        if ($LASTEXITCODE -ne 0) {
            throw "クリーンに失敗しました"
        }
    }

    # パブリッシュ（自己完結型実行可能ファイル）
    if ($Publish) {
        Write-Host "`n自己完結型実行可能ファイルをパブリッシュ中..." -ForegroundColor Yellow

        $publishArgs = @(
            "publish",
            $PluginProject,
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
            throw "パブリッシュに失敗しました"
        }

        Write-Host "パブリッシュ先: $PluginDir\publish" -ForegroundColor Green
    }
    else {
        # 通常ビルド
        Write-Host "`nビルドを実行中..." -ForegroundColor Yellow

        $buildArgs = @("build", $PluginProject, "-c", $Configuration)
        if ($DetailedLog) {
            $buildArgs += "-v", "detailed"
        }

        & dotnet $buildArgs

        if ($LASTEXITCODE -ne 0) {
            throw "ビルドに失敗しました"
        }
    }

    # StreamDeckへのデプロイ
    if ($Deploy) {
        Write-Host "`nStreamDeckにデプロイ中..." -ForegroundColor Yellow

        $registerScript = Join-Path $PluginDir "RegisterPluginAndStartStreamDeck.ps1"
        if (Test-Path $registerScript) {
            Write-Host "登録スクリプトを実行中..." -ForegroundColor Gray
            & powershell -ExecutionPolicy Unrestricted -File $registerScript

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "StreamDeckへの登録に失敗しました"
            } else {
                Write-Host "StreamDeckへの登録が完了しました" -ForegroundColor Green
            }
        } else {
            Write-Warning "登録スクリプトが見つかりません: $registerScript"
        }
    }

    # ビルド成果物の確認
    Write-Host "`nビルド成果物:" -ForegroundColor Green

    $outputDir = if ($Publish) { "publish" } else { "bin\$Configuration\net6.0\win-x64" }
    $exePath = Join-Path $outputDir "CraftDeck.StreamDeckPlugin.exe"

    if (Test-Path $exePath) {
        $fileInfo = Get-Item $exePath
        Write-Host "  実行ファイル: $($fileInfo.Name)" -ForegroundColor Gray
        Write-Host "  サイズ: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "  更新日時: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    }

    # 必要なファイルの確認
    $requiredFiles = @(
        "manifest.json",
        "appsettings.json",
        "images\pluginIcon.png",
        "images\pluginIcon@2x.png",
        "property_inspector\property_inspector.html"
    )

    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $outputDir $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }

    if ($missingFiles.Count -gt 0) {
        Write-Warning "以下の必要なファイルが見つかりません:"
        $missingFiles | ForEach-Object { Write-Warning "  - $_" }
    }

    Write-Host "`n✅ ビルドが正常に完了しました" -ForegroundColor Green
}
catch {
    Write-Error "エラーが発生しました: $_"
    exit 1
}
finally {
    Pop-Location
}