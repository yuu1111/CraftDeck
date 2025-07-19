# CraftDeck Development Scripts

このフォルダには CraftDeck プロジェクトの開発・デプロイ用スクリプトが含まれています。

## スクリプト一覧

### 🚀 Deploy-CraftDeck.ps1
**用途**: 本番デプロイメント用スクリプト
**説明**: Minecraft Mod と StreamDeck Plugin をビルドしてデプロイします。

```powershell
# 全体をデプロイ (推奨)
.\Deploy-CraftDeck.ps1

# StreamDeck Plugin のみデプロイ
.\Deploy-CraftDeck.ps1 -Component Plugin

# Minecraft Mod のみビルド
.\Deploy-CraftDeck.ps1 -Component Mod

# Debug版でデプロイ
.\Deploy-CraftDeck.ps1 -Configuration Debug

# StreamDeck の自動起動をスキップ
.\Deploy-CraftDeck.ps1 -SkipStreamDeckRestart
```

### 🔨 Build-CraftDeck.ps1
**用途**: 開発用ビルドスクリプト
**説明**: デプロイせずにビルドのみ実行します。CI/CD や開発中のテストに最適。

```powershell
# 全体をビルド
.\Build-CraftDeck.ps1

# StreamDeck Plugin のみビルド
.\Build-CraftDeck.ps1 -Component Plugin

# Release版でビルド
.\Build-CraftDeck.ps1 -Configuration Release

# クリーンビルド
.\Build-CraftDeck.ps1 -Clean

# テストをスキップ
.\Build-CraftDeck.ps1 -SkipTests
```

## パラメータ説明

### 共通パラメータ

| パラメータ | 説明 | 有効値 | デフォルト |
|-----------|------|--------|-----------|
| `-Component` | ビルド対象コンポーネント | `Mod`, `Plugin`, `All` | `All` |
| `-Configuration` | ビルド構成 | `Debug`, `Release` | Deploy: `Release`, Build: `Debug` |

### Deploy-CraftDeck.ps1 専用

| パラメータ | 説明 |
|-----------|------|
| `-SkipStreamDeckRestart` | StreamDeck の自動再起動をスキップ |
| `-SkipTests` | テスト実行をスキップ |

### Build-CraftDeck.ps1 専用

| パラメータ | 説明 |
|-----------|------|
| `-Clean` | ビルド前にクリーンを実行 |
| `-SkipTests` | テスト実行をスキップ |

## 使用シナリオ

### 🎯 開発中の日常ワークフロー

```powershell
# 1. 変更後の動作確認
.\Build-CraftDeck.ps1 -Component Plugin

# 2. StreamDeck で実際にテスト
.\Deploy-CraftDeck.ps1 -Component Plugin -Configuration Debug

# 3. 本格的なテスト前
.\Build-CraftDeck.ps1 -Clean
```

### 🚢 リリース準備

```powershell
# 1. 全体をクリーンビルド
.\Build-CraftDeck.ps1 -Clean -Configuration Release

# 2. 本番デプロイ
.\Deploy-CraftDeck.ps1 -Configuration Release
```

### 🐛 問題調査

```powershell
# 1. 環境チェック付きビルド
.\Build-CraftDeck.ps1 -Component All

# 2. デバッグ版でのテスト
.\Deploy-CraftDeck.ps1 -Configuration Debug -SkipTests
```

## 前提条件

### 必須ソフトウェア

- **PowerShell 7+** (クロスプラットフォーム対応)
- **.NET 6 SDK** (StreamDeck Plugin用)
- **Java 17+** (Minecraft Mod用)
- **StreamDeck アプリケーション** (デプロイ時)

### 環境確認

Build-CraftDeck.ps1 は自動的に以下をチェックします：
- .NET SDK のインストール状況
- Java のインストール状況
- プロジェクトファイルの存在

## トラブルシューティング

### よくある問題

1. **"StreamDeck process cannot be stopped"**
   ```powershell
   # 手動で StreamDeck を終了してから再実行
   .\Deploy-CraftDeck.ps1 -SkipStreamDeckRestart
   ```

2. **"Build failed with access denied"**
   ```powershell
   # クリーンビルドを試行
   .\Build-CraftDeck.ps1 -Clean
   ```

3. **"Java not found"**
   ```bash
   # Java 17+ をインストールし、PATH に追加
   java -version
   ```

### ログとデバッグ

スクリプトは実行中に詳細な情報を表示します：
- 🔨 ビルド進行状況
- 📊 ビルド成果物の情報
- ⚠️ 警告やエラーメッセージ
- ✅ 成功時の次のステップ

## ファイル構成

```
Scripts/
├── Deploy-CraftDeck.ps1    # デプロイメントスクリプト
├── Build-CraftDeck.ps1     # ビルドスクリプト
└── README.md               # このファイル

../craftdeck-mod/           # Minecraft Mod プロジェクト
../craftdeck-plugin/        # StreamDeck Plugin プロジェクト
```

## クロスプラットフォーム対応

スクリプトは以下のプラットフォームで動作します：
- Windows (PowerShell 7+)
- macOS (PowerShell 7+)
- Linux (PowerShell 7+)

プラットフォーム固有の設定は自動的に検出・適用されます。