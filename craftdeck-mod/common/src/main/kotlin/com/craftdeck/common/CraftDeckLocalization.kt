package com.craftdeck.common

import net.minecraft.network.chat.Component

/**
 * CraftDeck正規多言語化システム
 *
 * Minecraft標準の多言語化制約に準拠:
 * - サーバーログ: 英語固定（管理者向け）
 * - ゲーム内メッセージ: Component.translatable()使用（プレイヤーのクライアント言語で表示）
 * - WebSocket通信: 翻訳キー送信（StreamDeck Plugin側で翻訳）
 */
object CraftDeckLocalization {

    /**
     * サーバーログ用メッセージ（英語固定）
     * サーバー管理者向けのログは常に英語で統一
     */
    object ServerLog {
        fun serverStarting(port: Int) = "Starting WebSocket server on port $port"
        fun serverStarted(port: Int) = "WebSocket server started successfully on port $port"
        fun serverStopped() = "WebSocket server stopped"
        fun serverError(error: String) = "Failed to start WebSocket server: $error"
        fun configLoaded(file: String) = "Configuration loaded from: $file"
        fun configCreated(file: String) = "Default configuration created: $file"
        fun configError(error: String) = "Configuration error: $error"
        fun playerJoined(player: String) = "Player joined: $player"
        fun playerLeft(player: String) = "Player left: $player"
        fun connectionNew(address: String) = "New connection from $address"
        fun connectionClosed(address: String) = "Closed connection to $address"
        fun connectionRejected(address: String) = "Connection rejected from $address: not in allowed clients"
        fun commandReceived(command: String) = "Received command execution request: $command"
        fun commandExecuting(command: String, player: String?) =
            "Executing command '$command' for player: ${player ?: "console"}"
        fun commandSuccess() = "Command executed successfully"
        fun commandFailed(error: String) = "Command execution failed: $error"
        fun dataCollecting() = "Game data collector initialized"
        fun dataUpdating(count: Int) = "Updating player data for $count players"
        fun websocketError() = "WebSocket error occurred"
        fun modInitializing() = "Initializing CraftDeck Mod"
        fun modReady() = "CraftDeck is ready"
        fun portChanged(port: Int) = "WebSocket port changed to: $port"
        fun languageChanged(language: String) = "Server language changed to: $language"
        fun intervalChanged(interval: Int) = "Update interval changed to: $interval ticks"
        fun invalidPort(port: Int) = "Invalid port number: $port. Must be between 1024-65535"
        fun invalidLanguage(language: String) = "Invalid language code: $language. Valid codes: en, ja"
        fun invalidInterval(interval: Int) = "Invalid update interval: $interval. Must be between 1-200 ticks"
    }

    /**
     * ゲーム内メッセージ用（Component.translatable使用）
     * プレイヤーのクライアント言語設定で自動翻訳される
     */
    object GameMessage {
        fun serverStarted(port: Int): Component =
            Component.translatable("craftdeck.server.started", port)

        fun serverStopped(): Component =
            Component.translatable("craftdeck.server.stopped")

        fun playerJoined(player: String): Component =
            Component.translatable("craftdeck.player.joined", player)

        fun playerLeft(player: String): Component =
            Component.translatable("craftdeck.player.left", player)

        fun commandSuccess(): Component =
            Component.translatable("craftdeck.command.success")

        fun commandFailed(error: String): Component =
            Component.translatable("craftdeck.command.failed", error)

        fun connectionStatus(connected: Boolean): Component = when (connected) {
            true -> Component.translatable("craftdeck.status.connected")
            false -> Component.translatable("craftdeck.status.disconnected")
        }

        fun configReloaded(): Component =
            Component.translatable("craftdeck.config.reloaded")

        fun configPortChanged(port: Int): Component =
            Component.translatable("craftdeck.config.port_changed", port)

        fun configLanguageChanged(language: String): Component =
            Component.translatable("craftdeck.config.language_changed", language)

        fun configIntervalChanged(interval: Int): Component =
            Component.translatable("craftdeck.config.interval_changed", interval)

        fun configInvalidPort(port: Int): Component =
            Component.translatable("craftdeck.config.invalid_port", port)

        fun configInvalidLanguage(language: String): Component =
            Component.translatable("craftdeck.config.invalid_language", language)

        fun configInvalidInterval(interval: Int): Component =
            Component.translatable("craftdeck.config.invalid_interval", interval)
    }

    /**
     * WebSocket通信用翻訳キー
     * StreamDeck Plugin側で各言語に翻訳される
     */
    object TranslationKeys {
        const val SERVER_STARTED = "craftdeck.server.started"
        const val SERVER_STOPPED = "craftdeck.server.stopped"
        const val PLAYER_JOINED = "craftdeck.player.joined"
        const val PLAYER_LEFT = "craftdeck.player.left"
        const val COMMAND_SUCCESS = "craftdeck.command.success"
        const val COMMAND_FAILED = "craftdeck.command.failed"
        const val STATUS_CONNECTED = "craftdeck.status.connected"
        const val STATUS_DISCONNECTED = "craftdeck.status.disconnected"
        const val STATUS_WAITING = "craftdeck.status.waiting"
        const val CONNECTION_WELCOME = "craftdeck.connection.welcome"
    }

    /**
     * WebSocket JSONメッセージ生成
     * 翻訳キーとパラメータを含むメッセージを生成
     */
    object WebSocketMessage {
        fun playerJoined(player: String, uuid: String): String = buildString {
            append("""{"type":"player_join",""")
            append(""""player":"$player",""")
            append(""""uuid":"$uuid",""")
            append(""""translation_key":"${TranslationKeys.PLAYER_JOINED}",""")
            append(""""params":{"player":"$player"}""")
            append("}")
        }

        fun playerLeft(player: String, uuid: String): String = buildString {
            append("""{"type":"player_leave",""")
            append(""""player":"$player",""")
            append(""""uuid":"$uuid",""")
            append(""""translation_key":"${TranslationKeys.PLAYER_LEFT}",""")
            append(""""params":{"player":"$player"}""")
            append("}")
        }

        fun commandResult(success: Boolean, message: String): String = buildString {
            append("""{"type":"command_result",""")
            append(""""success":$success,""")
            append(""""message":"${message.replace("\"", "\\\"")}",""")
            append(""""translation_key":"${if (success) TranslationKeys.COMMAND_SUCCESS else TranslationKeys.COMMAND_FAILED}"""")
            if (!success) {
                append(""","params":{"error":"${message.replace("\"", "\\\"")}"}""")
            }
            append("}")
        }

        fun connectionStatus(connected: Boolean): String = buildString {
            append("""{"type":"connection_status",""")
            append(""""connected":$connected,""")
            append(""""translation_key":"${if (connected) TranslationKeys.STATUS_CONNECTED else TranslationKeys.STATUS_DISCONNECTED}"""")
            append("}")
        }

        fun welcome(): String = buildString {
            append("""{"type":"connection",""")
            append(""""status":"connected",""")
            append(""""message":"Welcome to CraftDeck",""")
            append(""""translation_key":"${TranslationKeys.CONNECTION_WELCOME}"""")
            append("}")
        }
    }

    /**
     * StreamDeck Plugin側で使用される翻訳マッピング
     * この情報をPlugin側の言語ファイルに反映する
     */
    fun getTranslationMapping(): Map<String, Map<String, String>> = mapOf(
        "en" to mapOf(
            TranslationKeys.SERVER_STARTED to "CraftDeck server started on port %s",
            TranslationKeys.SERVER_STOPPED to "CraftDeck server stopped",
            TranslationKeys.PLAYER_JOINED to "Player joined: %s",
            TranslationKeys.PLAYER_LEFT to "Player left: %s",
            TranslationKeys.COMMAND_SUCCESS to "Command executed successfully",
            TranslationKeys.COMMAND_FAILED to "Command execution failed: %s",
            TranslationKeys.STATUS_CONNECTED to "Connected to CraftDeck",
            TranslationKeys.STATUS_DISCONNECTED to "Disconnected from CraftDeck",
            TranslationKeys.STATUS_WAITING to "Waiting for CraftDeck connection",
            TranslationKeys.CONNECTION_WELCOME to "Welcome to CraftDeck"
        ),
        "ja" to mapOf(
            TranslationKeys.SERVER_STARTED to "CraftDeckサーバーがポート%sで開始されました",
            TranslationKeys.SERVER_STOPPED to "CraftDeckサーバーが停止しました",
            TranslationKeys.PLAYER_JOINED to "プレイヤーが参加しました: %s",
            TranslationKeys.PLAYER_LEFT to "プレイヤーが退出しました: %s",
            TranslationKeys.COMMAND_SUCCESS to "コマンドが正常に実行されました",
            TranslationKeys.COMMAND_FAILED to "コマンドの実行に失敗しました: %s",
            TranslationKeys.STATUS_CONNECTED to "CraftDeckに接続しました",
            TranslationKeys.STATUS_DISCONNECTED to "CraftDeckから切断しました",
            TranslationKeys.STATUS_WAITING to "CraftDeck接続を待機中",
            TranslationKeys.CONNECTION_WELCOME to "CraftDeckへようこそ"
        )
    )
}