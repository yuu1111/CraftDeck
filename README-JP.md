# CraftDeck

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Java](https://img.shields.io/badge/Java-17+-orange.svg)](https://www.oracle.com/java/)
[![.NET](https://img.shields.io/badge/.NET-6.0+-purple.svg)](https://dotnet.microsoft.com/)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.19+-green.svg)](https://minecraft.net/)

MinecraftとElgato Stream Deckをリアルタイムで接続し、Stream Deckデバイスから直接ゲームの監視と操作を可能にするシステムです。

[English README](README.md) | [ドキュメント](../../wiki) | [コントリビューション](CONTRIBUTING.md)

## 🎮 機能

- **リアルタイムゲームデータ**: プレイヤーの体力、座標、経験値、インベントリなどを表示
- **インタラクティブコマンド**: Stream DeckボタンからMinecraftコマンドを直接実行
- **マルチプラットフォーム対応**: Fabric、Forge、Quilt mod loaderに対応
- **カスタマイズ可能インターフェース**: 各Stream Deckキーに表示する情報を設定可能
- **低遅延**: WebSocketベースの通信で瞬時に更新
- **簡単セットアップ**: Minecraft ModとStream Deckプラグインの簡単インストール

## 📋 必要要件

### Minecraft Mod
- Minecraft 1.19.2 以降
- Java 17 以降
- 以下のいずれかのmod loader:
  - Fabric Loader 0.14+
  - Forge 43.2+
  - Quilt Loader 0.17+

### Stream Deck プラグイン
- Windows 10/11 (x64)
- Elgato Stream Deck Software 6.0+
- .NET 6.0 Runtime
- Elgato Stream Deck デバイス（全モデル対応）

## 🚀 インストール

### Minecraft Mod インストール

1. **mod JARファイルをダウンロード** [リリース](../../releases)から対応するmod loader用ファイルを取得
2. **mod loaderをインストール** (Fabric/Forge/Quilt) 未インストールの場合
3. **JARファイルを配置** `mods`フォルダに配置
4. **Minecraftを起動** - Modが自動的にWebSocketサーバーをポート8080で開始

### Stream Deck プラグイン インストール

1. **ダウンロード** [リリース](../../releases)から`CraftDeck.streamDeckPlugin`をダウンロード
2. **ダブルクリック** ファイルをダブルクリックして自動インストール
3. **CraftDeckアクションを追加** 任意のStream Deckキーに追加
4. **接続設定を構成** 必要に応じてプロパティインスペクターで設定

## 🔧 設定

### Minecraft Mod設定
Modは設定ファイルを `config/craftdeck.json` に作成します:

```json
{
  "port": 8080,
  "host": "localhost",
  "enableLogging": true,
  "updateInterval": 1000
}
```

### Stream Deck プラグイン設定
プロパティインスペクターで各Stream Deckキーを設定:

- **接続設定**: サーバーホストとポート
- **表示オプション**: 表示するゲームデータを選択
- **コマンド設定**: カスタムMinecraftコマンドの設定
- **更新頻度**: データ更新の頻度を制御

## 📡 通信プロトコル

CraftDeckはJSONメッセージを使用したWebSocket通信を使用:

### ゲームデータメッセージ (モMod → プラグイン)
```json
{
  "type": "player_status",
  "data": {
    "health": 20,
    "food": 20,
    "experience": 1250,
    "level": 30,
    "gameMode": "SURVIVAL",
    "position": {
      "x": 125.5,
      "y": 64.0,
      "z": -89.2,
      "dimension": "minecraft:overworld"
    }
  }
}
```

### コマンドメッセージ (プラグイン → Mod)
```json
{
  "type": "execute_command",
  "data": {
    "command": "time set day",
    "requireOp": true
  }
}
```

## 🛠️ 開発

### ソースからビルド

#### Minecraft Mod
```bash
cd craftdeck-mod
./gradlew build
```

#### Stream Deck プラグイン
```bash
cd craftdeck-plugin
dotnet build -c Release
```

### 開発環境セットアップ
詳細なセットアップ手順は [開発者ガイド](../../wiki/Developer-Guide) をご覧ください。

## 🤝 コントリビューション

コントリビューションを歓迎します！詳細は [コントリビューションガイドライン](CONTRIBUTING.md) をご覧ください:

- コードスタイルと規約
- バグレポートの提出
- 新機能の提案
- プルリクエストの作成

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています - 詳細は [LICENSE](LICENSE) ファイルをご覧ください。

## 🐛 問題報告

バグを発見したり機能要求がある場合は、[issue tracker](../../issues) を確認して新しいissueを作成してください。

## 🔗 リンク

- **ドキュメント**: [GitHub Wiki](../../wiki)
- **リリース**: [最新ダウンロード](../../releases)
- **Issue Tracker**: [バグ報告](../../issues)
- **ディスカッション**: [コミュニティフォーラム](../../discussions)

## ⭐ サポート

CraftDeckが役に立った場合は、以下をご検討ください:
- ⭐ このリポジトリにスターを付ける
- 🐛 バグレポートや改善提案
- 🤝 コードやドキュメントへのコントリビューション
- 💬 MinecraftやStream Deckコミュニティでの共有

---

**MinecraftとStream Deckコミュニティのために ❤️ を込めて作られました**