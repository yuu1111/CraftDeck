# 機能要件

## 4. 機能要件

### 4.1. Minecraft Mod (送信機能)

Mod は WebSocket サーバーとして機能し、以下のゲーム内情報を StreamDeck プラグインに送信します。

1.  **プレイヤーの基本ステータス (`player_status`)**:
    *   ヘルス (`health`, `max_health`), 空腹度 (`food`, `saturation`)
    *   経験値 (`experience.level`, `experience.progress`)
    *   座標 (`coords.x`, `coords.y`, `coords.z`, `coords.display_string`)
    *   ディメンション (`dimension.id`, `dimension.name`)
    *   バイオーム (`biome.id`, `biome.name`)
    *   プレイヤーの状態 (`is_sprinting`, `is_sneaking`, `is_on_ground`)
    *   ゲームモード (`gamemode.id`, `gamemode.name`)
    *   **送信トリガー**: ティックイベントベースの定期更新（例: 0.5秒〜1秒ごと）、または値に変化があった場合。
2.  **ゲーム内の時間と天候 (`world_status`)**:
    *   ゲーム内時間 (`game_time`, `day_time_string`)
    *   天候 (`is_raining`, `is_thundering`, `weather_name`)
    *   **送信トリガー**: ティックイベントベースの定期更新、または天候変化時。
3.  **所持アイテム情報 (`inventory_slot`)**:
    *   スロットタイプ (`slot_type`), スロットインデックス (`slot_index`)
    *   アイテム ID (`item_id`), 表示名 (`display_name`), スタック数 (`count`)
    *   耐久度 (`durability.current`, `durability.max`, `durability.percentage`)
    *   エンチャント (`enchantments`: ID, level)
    *   カスタム名 (`has_custom_name`)
    *   **アイテムアイコン (Base64 PNG)**: `item_icon_base64_png`
    *   **送信トリガー**: インベントリ変更イベント発生時、またはアイテムの耐久度変化時。
4.  **ポーション効果リスト (`potion_effect_list`)**:
    *   効果 ID (`effect_id`), 表示名 (`effect_name`), 増幅レベル (`amplifier`)
    *   残り時間 (`duration_ticks`, `duration_string`)
    *   その他の状態 (`is_ambient`, `show_particles`)
    *   **効果アイコン (Base64 PNG)**: `icon_base64_png`
    *   **送信トリガー**: ポーション効果の付与/終了/時間更新イベント時。

### 4.2. StreamDeck Plugin (受信・表示・送信機能)

プラグインは WebSocket クライアントとして機能し、Mod からの情報を受信して StreamDeck に表示し、ボタン操作を Mod に送信します。

#### 4.2.1. 情報の表示機能

*   **テキスト表示**: 受信したデータに基づき、設定されたテンプレート文字列（例: `HP: {health}/{max_health}`）に従ってテキストを表示します。フォントサイズ、色、配置の調整を可能にします。
*   **ゲージ/バー表示**: ヘルス、空腹度、アイテム耐久度などをプログレスバー形式で表示します。色、背景色、方向を設定可能にします。
*   **アイコン表示**: Mod から送信された Base64 PNG 画像をデコードし、ボタン上に表示します。条件に応じたアイコン切り替え（例: ヘルスが低いときにドクロアイコン）を可能にします。
*   **UI 更新**: WebSocket で情報を受信するたびに、関連する StreamDeck ボタンの表示を更新します。

#### 4.2.2. コマンド実行機能

*   **コマンド送信**: ボタンが押下された際に、Property Inspector で設定された Minecraft コマンド文字列を Mod に送信します。
*   **コマンド実行後のフィードバック**: オプションで、コマンド実行成功時に一時的にボタンのアイコンを変更する（例: チェックマーク）。
*   **実行前の確認**: 破壊的なコマンドの場合、確認ダイアログを表示するオプションを提供します。

#### 4.2.3. WebSocket 接続管理

*   **自動接続/再接続**: プラグイン起動時に Mod への自動接続を試み、切断時には一定間隔で再接続を試みます。
*   **接続状態表示**: StreamDeck のボタン上で現在の接続状態（例: "Waiting for Minecraft...", "Connected"）を表示します。

### 4.3. 共通機能

*   **初期接続時のフル送信**: StreamDeck プラグインが Mod に接続を確立した際、Mod は現在のゲーム状態の全情報を一度送信します。
