# アーキテクチャと通信プロトコル

## 3. 技術スタック

### 3.1. Minecraft Mod

*   **言語**: Kotlin
*   **Mod ローダーフレームワーク**: Architectury
    *   **対応ローダー**: Fabric API, Forge API
*   **通信ライブラリ**: Kotlin/Java 標準の WebSocket ライブラリ

### 3.2. StreamDeck Plugin

*   **言語**: C# (.NET)
    *   **C# (.NET)**: StreamDeck SDKとの直接的なインターフェース、WebSocket通信、JSONデータのパース、ボタン描画、Property Inspector（設定画面）の実装など、プラグインのすべてのロジックを担当します。
*   **通信ライブラリ**: .NET 標準の WebSocket クライアント (`System.Net.WebSockets.ClientWebSocket`)

### 3.3. 通信プロトコル

*   **形式**: WebSocket (JSON 形式)
*   **データフォーマット**: JSON
*   **通信方向**: 双方向通信
*   **データ量**: ローカル環境での動作が主であるため、アイコンなどのデータ量によるコストは許容します。

## 6. データフローとイベントトリガー

### 6.1. Mod → Plugin (ゲーム内情報の通知)

Mod は、以下のイベントトリガーに基づいてゲーム内情報を WebSocket で送信します。

*   **ティックイベントベースの定期更新**: プレイヤーのヘルス、空腹度、座標、現在の時間、天候など、頻繁に変動する可能性のある情報を、ティックごとに変化をチェックし、変化があった場合または設定された時間間隔（例: 0.5秒〜1秒ごと）が経過した場合に送信します。
*   **イベント駆動の更新**: インベントリの変更、アイテムの耐久度の変化、ポーション効果の付与/終了、実績の解除など、特定の Minecraft イベントが発生した直後に送信します。
*   **初期接続時のフル送信**: StreamDeck Plugin が WebSocket 接続を確立した直後、初期表示に必要な全ての情報を一括で送信します。

### 6.2. Plugin → Mod (コマンド実行要求)

StreamDeck Plugin は、ユーザーのボタン操作に応じて、Minecraft Mod へコマンド実行を要求します。

*   **トリガー**: StreamDeck のボタンが押下された時。
*   **フロー**: Plugin がボタンに紐付けられたコマンド文字列を JSON 形式 (`{"type": "execute_command", "command": "..."}`) に整形し、Mod サーバーへ送信します。Mod からの成功/失敗レスポンスを受け取り、StreamDeck 上でフィードバックを行うことも検討します。

### 6.3. WebSocket 接続管理

*   **Mod 側 (サーバー)**: 起動時に指定ポートで WebSocket サーバーを起動し、Plugin からの接続を待機します。Mod 終了時にサーバーを適切にシャットダウンします。
*   **Plugin 側 (クライアント)**: 起動時に Mod サーバーへの接続を試み、接続に失敗した場合や切断された場合、一定の間隔で再接続を試みます。再接続中は StreamDeck のボタンに「Not Connected」などの状態を表示します。

## 7. JSON スキーマ詳細

(本仕様書では、上記「4.1. Minecraft Mod (送信機能)」に記載された JSON 構造を具体的なスキーマとして採用します。以下は例として一部を再掲しますが、詳細は機能要件セクションを参照ください。)

### 7.1. Mod → Plugin (情報送信) 例

#### 7.1.1. プレイヤーの基本ステータス (`player_status`)

```json
{
  "type": "player_status",
  "data": {
    "health": 20.0,
    "max_health": 20.0,
    "food": 20,
    "saturation": 5.0,
    "experience": {
      "level": 15,
      "progress": 0.75
    },
    "coords": {
      "x": 123.45,
      "y": 64.0,
      "z": -789.01,
      "display_string": "X:123 Y:64 Z:-789"
    },
    "dimension": {
      "id": "minecraft:overworld",
      "name": "Overworld"
    },
    "biome": {
      "id": "minecraft:plains",
      "name": "Plains"
    },
    "is_sprinting": true,
    "is_sneaking": false,
    "is_on_ground": true,
    "gamemode": {
      "id": "survival",
      "name": "Survival"
    }
  }
}
```

#### 7.1.2. 所持アイテム (`inventory_slot`)

```json
{
  "type": "inventory_slot",
  "data": {
    "slot_type": "mainhand",
    "slot_index": 0,
    "item_id": "minecraft:diamond_pickaxe",
    "display_name": "Diamond Pickaxe",
    "count": 1,
    "durability": {
      "current": 1234,
      "max": 1561,
      "percentage": 0.79
    },
    "enchantments": [
      {"id": "minecraft:unbreaking", "level": 3}
    ],
    "has_custom_name": false,
    "item_icon_base64_png": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8...",
    "nbt": {}
  }
}
```

### 7.2. Plugin → Mod (コマンド実行)

```json
{
  "type": "execute_command",
  "command": "gamemode creative",
  "source": "streamdeck_plugin"
}
```
