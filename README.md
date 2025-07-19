# Minecraft & StreamDeck 連携システム

## 1. 概要

本プロジェクトは、Minecraft のゲーム内情報を StreamDeck にリアルタイム表示し、StreamDeck のボタン操作を通じて Minecraft の特定コマンドを実行できるシステムを構築することを目的とします。これにより、プレイヤーはより直感的かつ効率的にゲームを操作できるようになります。

## 2. 目標

*   **Minecraft の主要なゲーム内情報を StreamDeck に分かりやすく表示する。**
*   **StreamDeck のボタンから定義済みの Minecraft コマンドを実行可能にする。**
*   シングルプレイヤー、および Mod 導入が許可されたマルチプレイヤー環境下で、**各プレイヤーのクライアントサイドで完結するソリューションを提供する。**
*   将来的に**他の Minecraft Mod と連携可能な API を提供する。**
*   将来的に**サーバーサイド機能（サーバー監視・管理）への拡張を可能にする。**

## 8. 開発ロードマップ (フェーズ別)

### フェーズ 1: MVP (Minimum Viable Product) の開発と完成

1.  **開発環境のセットアップ**: Architectury + Kotlin (Mod) および C# (.NET) + Kotlin (JVM) (Plugin) の開発環境をセットアップ。
2.  **WebSocket 通信の確立**: Mod 側の WebSocket サーバーと Plugin 側の WebSocket クライアントの最小限の実装。
3.  **最初のデータ連携**: Mod から**プレイヤーのヘルス情報**を取得し、Plugin へ送信、StreamDeck にテキスト表示。
4.  **最初のコマンド実行**: StreamDeck ボタンから**簡単な Minecraft コマンド**を Mod へ送信し、実行。
5.  **接続管理とフィードバック**: WebSocket 接続状態の表示、Plugin 側の再接続ロジックを実装。
