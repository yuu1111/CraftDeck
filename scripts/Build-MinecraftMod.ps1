# Build-MinecraftMod.ps1
# Minecraft Mod (CraftDeck) のビルドスクリプト

param(
    [Parameter(HelpMessage="ビルドタイプを指定 (all, fabric, forge, quilt)")]
    [ValidateSet("all", "fabric", "forge", "quilt")]
    [string]$Platform = "all",
    
    [Parameter(HelpMessage="クリーンビルドを実行")]
    [switch]$Clean,
    
    [Parameter(HelpMessage="開発クライアントを起動")]
    [switch]$RunClient,
    
    [Parameter(HelpMessage="詳細ログを表示")]
    [switch]$DetailedLog
)

$ErrorActionPreference = "Stop"

# プロジェクトルートディレクトリの設定
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ModDir = Join-Path $ProjectRoot "craftdeck-mod"

Write-Host "=== CraftDeck Minecraft Mod ビルドスクリプト ===" -ForegroundColor Cyan
Write-Host "プロジェクトディレクトリ: $ModDir" -ForegroundColor Gray

# ディレクトリ存在確認
if (-not (Test-Path $ModDir)) {
    Write-Error "Minecraft Modディレクトリが見つかりません: $ModDir"
    exit 1
}

# 作業ディレクトリ変更
Push-Location $ModDir

try {
    # クリーンビルド
    if ($Clean) {
        Write-Host "`nクリーンビルドを実行中..." -ForegroundColor Yellow
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            & .\gradlew.bat clean
        } else {
            & ./gradlew clean
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "クリーンビルドに失敗しました"
        }
    }

    # 開発クライアント起動
    if ($RunClient) {
        Write-Host "`n開発クライアントを起動中 ($Platform)..." -ForegroundColor Yellow
        
        $runTask = switch ($Platform) {
            "fabric" { ":fabric:runClient" }
            "forge" { ":forge:runClient" }
            "quilt" { ":quilt:runClient" }
            default { ":fabric:runClient" }
        }
        
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            & .\gradlew.bat $runTask
        } else {
            & ./gradlew $runTask
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "開発クライアントの起動に失敗しました"
        }
    }
    else {
        # ビルド実行
        Write-Host "`nビルドを実行中 ($Platform)..." -ForegroundColor Yellow
        
        $buildTask = switch ($Platform) {
            "all" { "build" }
            "fabric" { ":fabric:build" }
            "forge" { ":forge:build" }
            "quilt" { ":quilt:build" }
        }
        
        if ($DetailedLog) {
            if ($IsWindows -or $env:OS -eq "Windows_NT") {
                & .\gradlew.bat $buildTask --info
            } else {
                & ./gradlew $buildTask --info
            }
        } else {
            if ($IsWindows -or $env:OS -eq "Windows_NT") {
                & .\gradlew.bat $buildTask
            } else {
                & ./gradlew $buildTask
            }
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "ビルドに失敗しました"
        }
        
        # ビルド成果物の表示
        Write-Host "`nビルド成果物:" -ForegroundColor Green
        
        if ($Platform -eq "all" -or $Platform -eq "fabric") {
            $fabricJar = Get-ChildItem -Path "fabric\build\libs" -Filter "*.jar" -Exclude "*-sources.jar" | Select-Object -First 1
            if ($fabricJar) {
                Write-Host "  Fabric: $($fabricJar.Name)" -ForegroundColor Gray
            }
        }
        
        if ($Platform -eq "all" -or $Platform -eq "forge") {
            $forgeJar = Get-ChildItem -Path "forge\build\libs" -Filter "*.jar" -Exclude "*-sources.jar" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($forgeJar) {
                Write-Host "  Forge: $($forgeJar.Name)" -ForegroundColor Gray
            }
        }
        
        if ($Platform -eq "all" -or $Platform -eq "quilt") {
            $quiltJar = Get-ChildItem -Path "quilt\build\libs" -Filter "*.jar" -Exclude "*-sources.jar" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($quiltJar) {
                Write-Host "  Quilt: $($quiltJar.Name)" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host "`n✅ 処理が正常に完了しました" -ForegroundColor Green
}
catch {
    Write-Error "エラーが発生しました: $_"
    exit 1
}
finally {
    Pop-Location
}