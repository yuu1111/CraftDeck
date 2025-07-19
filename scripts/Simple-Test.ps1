#!/usr/bin/env pwsh
# Simple-Test.ps1 - 簡単なビルドテスト

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ModDir = Join-Path $ProjectRoot "craftdeck-mod"

Write-Host "🧪 簡単なビルドテスト開始" -ForegroundColor Yellow
Write-Host "📂 作業ディレクトリ: $ModDir" -ForegroundColor Cyan

Set-Location $ModDir

Write-Host "🔨 Fabricのビルドテスト..." -ForegroundColor Green
try {
    # Windows環境でのgradlew実行
    $result = & .\gradlew.bat ":fabric:build" -q 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Fabricビルド成功" -ForegroundColor Green

        # 生成されたJARファイルを確認
        $jar = "fabric/build/libs/craftdeck-1.0.0-MC1.20.4-fabric.jar"
        if (Test-Path $jar) {
            $size = [math]::Round((Get-Item $jar).Length / 1KB, 1)
            Write-Host "📦 JAR生成確認: $jar (${size}KB)" -ForegroundColor Blue
        } else {
            Write-Host "❌ JARファイルが見つかりません: $jar" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Fabricビルド失敗 (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "エラー出力: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 例外発生: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🏁 テスト完了" -ForegroundColor Green