#!/usr/bin/env pwsh
# Build-AllVersions.ps1 - CraftDeck 全バージョン一括ビルドスクリプト

param(
    [string]$OutputDir = "builds",
    [switch]$SkipClean,
    [switch]$ContinueOnError,
    [string[]]$LoadersOnly = @(),
    [string[]]$VersionsOnly = @()
)

# 設定
$OriginalLocation = Get-Location
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ModDir = Join-Path $ProjectRoot "craftdeck-mod"
$PropertiesFile = Join-Path $ModDir "gradle.properties"

# 対応バージョン定義
$SupportedVersions = @{
    "fabric" = @("1.16.5", "1.17.1", "1.18.1", "1.18.2", "1.19", "1.19.1", "1.19.2", "1.19.3", "1.19.4", "1.20", "1.20.1", "1.20.2", "1.20.3", "1.20.4", "1.20.5", "1.20.6", "1.21", "1.21.1", "1.21.2", "1.21.3", "1.21.4", "1.21.5", "1.21.6", "1.21.7")
    "forge" = @("1.16.5", "1.17.1", "1.18.1", "1.18.2", "1.19", "1.19.1", "1.19.2", "1.19.3", "1.19.4", "1.20", "1.20.1", "1.20.2", "1.20.3", "1.20.4", "1.20.6", "1.21", "1.21.1", "1.21.2", "1.21.3", "1.21.4", "1.21.5", "1.21.6", "1.21.7")
    "quilt" = @("1.18.2", "1.19", "1.19.1", "1.19.2", "1.19.3", "1.19.4", "1.20", "1.20.1", "1.20.2", "1.20.3", "1.20.4", "1.20.5", "1.20.6", "1.21", "1.21.1", "1.21.2", "1.21.3", "1.21.4", "1.21.5", "1.21.6", "1.21.7")
    "neoforge" = @("1.20.4", "1.21", "1.21.1", "1.21.2", "1.21.3", "1.21.4", "1.21.5", "1.21.6", "1.21.7")
}

function Write-Header {
    param([string]$Title)
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "🚀 $Title" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor Cyan
}

function Write-Progress {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "📦 $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

try {
    Set-Location $ModDir

    # 元のバージョンを保存
    $OriginalProperties = Get-Content $PropertiesFile -Raw
    $OriginalVersion = ($OriginalProperties | Select-String "minecraft_version=(.+)").Matches[0].Groups[1].Value

    # 出力ディレクトリ作成
    $BuildsDir = Join-Path $ProjectRoot $OutputDir
    if (Test-Path $BuildsDir) {
        Remove-Item $BuildsDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $BuildsDir -Force | Out-Null

    Write-Header "CraftDeck 全バージョン一括ビルド開始"
    Write-Host "📂 出力ディレクトリ: $BuildsDir" -ForegroundColor Cyan
    Write-Host "🎯 元バージョン: $OriginalVersion" -ForegroundColor Cyan

    # 統計変数
    $TotalBuilds = 0
    $SuccessfulBuilds = 0
    $BuildResults = @{}

    # 全バージョンを取得
    $AllVersions = $SupportedVersions.Values | ForEach-Object { $_ } | Sort-Object -Unique

    # フィルタリング
    if ($VersionsOnly.Count -gt 0) {
        $AllVersions = $AllVersions | Where-Object { $_ -in $VersionsOnly }
    }

    $LoadersToUse = if ($LoadersOnly.Count -gt 0) { $LoadersOnly } else { $SupportedVersions.Keys }

    Write-Host "🎯 対象バージョン数: $($AllVersions.Count)" -ForegroundColor Cyan
    Write-Host "🎯 対象ローダー: $($LoadersToUse -join ', ')" -ForegroundColor Cyan

    foreach ($Version in $AllVersions) {
        Write-Progress "Minecraft $Version のビルド開始..."

        # minecraft_version を変更
        $UpdatedProperties = $OriginalProperties -replace "minecraft_version=$OriginalVersion", "minecraft_version=$Version"
        Set-Content -Path $PropertiesFile -Value $UpdatedProperties -NoNewline

        $BuildResults[$Version] = @{}

        foreach ($Loader in $LoadersToUse) {
            if ($SupportedVersions[$Loader] -contains $Version) {
                $TotalBuilds++
                Write-Host "  🔨 $Loader をビルド中..." -ForegroundColor Yellow

                try {
                    # Windows環境でのgradlew実行
                    if (-not $SkipClean) {
                        & .\gradlew.bat ":$Loader:clean" -q
                    }

                    & .\gradlew.bat ":$Loader:build" -q

                    if ($LASTEXITCODE -eq 0) {
                        $SuccessfulBuilds++
                        $BuildResults[$Version][$Loader] = "SUCCESS"
                        Write-Success "${Loader}: ビルド成功"

                        # JARファイルをコピー
                        $SourceJar = Join-Path $ModDir "$Loader/build/libs/craftdeck-1.0.0-MC$Version-$Loader.jar"
                        if (Test-Path $SourceJar) {
                            $DestPath = Join-Path $BuildsDir "craftdeck-1.0.0-MC$Version-$Loader.jar"
                            Copy-Item $SourceJar $DestPath
                            Write-Host "    📦 JAR保存: $DestPath" -ForegroundColor Blue
                        }
                    } else {
                        throw "Gradle build failed with exit code $LASTEXITCODE"
                    }
                } catch {
                    $BuildResults[$Version][$Loader] = "FAILED: $($_.Exception.Message)"
                    Write-Error "${Loader}: ビルド失敗 - $($_.Exception.Message)"

                    if (-not $ContinueOnError) {
                        throw "Build failed for $Loader $Version"
                    }
                }
            }
        }
    }

    # 結果サマリー
    Write-Header "ビルド結果サマリー"

    foreach ($Version in $AllVersions) {
        if ($BuildResults.ContainsKey($Version)) {
            Write-Host "`n🎯 Minecraft ${Version}:" -ForegroundColor Cyan
            foreach ($Loader in $LoadersToUse) {
                if ($BuildResults[$Version].ContainsKey($Loader)) {
                    $Result = $BuildResults[$Version][$Loader]
                    if ($Result -eq "SUCCESS") {
                        Write-Success "  ${Loader}"
                    } else {
                        Write-Error "  ${Loader} - $Result"
                    }
                }
            }
        }
    }

    # 統計
    Write-Host "`n📈 統計:" -ForegroundColor Yellow
    Write-Host "  総ビルド数: $TotalBuilds" -ForegroundColor White
    Write-Host "  成功: $SuccessfulBuilds" -ForegroundColor Green
    Write-Host "  失敗: $($TotalBuilds - $SuccessfulBuilds)" -ForegroundColor Red
    $SuccessRate = if ($TotalBuilds -gt 0) { [math]::Round(($SuccessfulBuilds / $TotalBuilds) * 100, 1) } else { 0 }
    Write-Host "  成功率: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 80) { "Green" } else { "Yellow" })

    # 生成されたJARファイル一覧
    $GeneratedJars = Get-ChildItem $BuildsDir -Filter "*.jar" | Sort-Object Name
    Write-Host "`n📦 生成されたJARファイル ($($GeneratedJars.Count)個):" -ForegroundColor Yellow
    foreach ($Jar in $GeneratedJars) {
        $Size = [math]::Round($Jar.Length / 1KB, 1)
        Write-Host "  $($Jar.Name) (${Size}KB)" -ForegroundColor Green
    }

    Write-Header "一括ビルド完了！"
    Write-Host "🎉 すべてのビルドが完了しました！" -ForegroundColor Green
    Write-Host "📂 成果物は $BuildsDir に保存されています" -ForegroundColor Cyan

} catch {
    Write-Error "ビルド中にエラーが発生しました: $($_.Exception.Message)"
    exit 1
} finally {
    # 元のバージョンに戻す
    if ($OriginalProperties) {
        Set-Content -Path $PropertiesFile -Value $OriginalProperties -NoNewline
        Write-Host "🔄 minecraft_version を $OriginalVersion に復元しました" -ForegroundColor Blue
    }

    Set-Location $OriginalLocation
}