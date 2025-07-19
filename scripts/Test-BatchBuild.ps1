#!/usr/bin/env pwsh
# Test-BatchBuild.ps1 - CraftDeck バッチビルドのテスト実行

param(
    [switch]$FullTest
)

$ScriptDir = $PSScriptRoot
$BuildScript = Join-Path $ScriptDir "Build-AllVersions.ps1"

Write-Host "🧪 CraftDeck バッチビルドテスト開始" -ForegroundColor Yellow

if ($FullTest) {
    Write-Host "📋 フルテスト: 全バージョンをビルド" -ForegroundColor Cyan
    & $BuildScript -OutputDir "test-builds-full" -ContinueOnError
} else {
    Write-Host "📋 クイックテスト: 代表的な3バージョンをビルド" -ForegroundColor Cyan
    $TestVersions = @("1.20.4", "1.21", "1.21.4")
    & $BuildScript -OutputDir "test-builds-quick" -VersionsOnly $TestVersions -ContinueOnError
}

Write-Host "🏁 テスト完了" -ForegroundColor Green