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

### 📦 Release-CraftDeck.ps1
**用途**: リリース用パッケージ作成スクリプト
**説明**: 本番リリース用のパッケージを作成します。.streamDeckPlugin形式でStreamDeckプラグインを生成。

```powershell
# バージョン1.0.0のリリースパッケージを作成
.\Release-CraftDeck.ps1 -Version "1.0.0"

# 指定ディレクトリに出力
.\Release-CraftDeck.ps1 -Version "1.0.0" -OutputDir "C:\Releases"

# ZIPファイルも同時作成
.\Release-CraftDeck.ps1 -Version "1.0.0" -CreateZip

# テストをスキップしてビルド
.\Release-CraftDeck.ps1 -Version "1.0.0" -SkipTests
```

### 🏷️ Prepare-Release.ps1
**用途**: リリース準備スクリプト
**説明**: バージョン番号の更新、CHANGELOG.md の生成、Git タグの作成を行います。

```powershell
# バージョン1.0.0のリリース準備
.\Prepare-Release.ps1 -Version "1.0.0"

# リリースノートを含めて準備
.\Prepare-Release.ps1 -Version "1.0.0" -ReleaseNotes "新機能を追加しました"

# Gitタグも同時作成
.\Prepare-Release.ps1 -Version "1.0.0" -CreateTag

# ドライランで動作確認
.\Prepare-Release.ps1 -Version "1.0.0" -DryRun
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

### Release-CraftDeck.ps1 専用

| パラメータ | 説明 | デフォルト |
|-----------|------|-----------|
| `-Version` | リリースバージョン（必須） | - |
| `-OutputDir` | 出力ディレクトリ | `.\release` |
| `-CreateZip` | リリース用ZIPファイルを作成 | `false` |
| `-SkipTests` | テスト実行をスキップ | `false` |

### Prepare-Release.ps1 専用

| パラメータ | 説明 | デフォルト |
|-----------|------|-----------|
| `-Version` | リリースバージョン（必須） | - |
| `-ReleaseNotes` | リリースノート | `""` |
| `-CreateTag` | Gitタグを作成 | `false` |
| `-DryRun` | ドライラン（実際には変更しない） | `false` |

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
# 1. リリース準備（バージョン更新、CHANGELOG作成）
.\Prepare-Release.ps1 -Version "1.0.0" -ReleaseNotes "初回リリース" -CreateTag

# 2. リリースパッケージ作成
.\Release-CraftDeck.ps1 -Version "1.0.0" -CreateZip

# 3. GitHub にプッシュ
git push origin main
git push origin v1.0.0
```

### 🎯 完全なリリースワークフロー

```powershell
# ステップ1: バージョン更新とCHANGELOG準備
.\Prepare-Release.ps1 -Version "1.2.0" -ReleaseNotes "新機能追加、バグ修正" -DryRun  # 確認
.\Prepare-Release.ps1 -Version "1.2.0" -ReleaseNotes "新機能追加、バグ修正" -CreateTag  # 実行

# ステップ2: リリースパッケージ作成
.\Release-CraftDeck.ps1 -Version "1.2.0" -CreateZip

# ステップ3: GitHub Actions でのリリース作成
git push origin main
git push origin v1.2.0
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