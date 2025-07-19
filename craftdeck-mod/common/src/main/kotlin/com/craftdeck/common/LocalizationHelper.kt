package com.craftdeck.common

/**
 * Minecraft Mod側の多言語化サポートクラス
 * 将来的にクライアント言語設定に基づいた多言語化ログ・メッセージに対応
 */
object LocalizationHelper {

    // 現在は英語のみサポート、将来的に拡張予定
    private var currentLanguage = "en"

    // 多言語化されたメッセージマップ
    private val messages = mapOf(
        "en" to mapOf(
            "server.starting" to "Starting WebSocket server on port {port}",
            "server.started" to "WebSocket server started successfully on port {port}",
            "server.stopped" to "WebSocket server stopped",
            "server.error" to "Failed to start WebSocket server: {error}",
            "player.joined" to "Player joined: {player}",
            "player.left" to "Player left: {player}",
            "connection.new" to "New connection from {address}",
            "connection.closed" to "Closed connection to {address}",
            "command.received" to "Received command execution request: {command}",
            "command.executing" to "Executing command '{command}' for player: {player}",
            "command.success" to "Command executed successfully",
            "command.failed" to "Command execution failed: {error}",
            "data.collecting" to "Game data collector initialized",
            "data.updating" to "Updating player data for {count} players",
            "websocket.error" to "WebSocket error occurred",
            "mod.initializing" to "Initializing CraftDeck Mod",
            "mod.ready" to "CraftDeck is ready"
        ),
        "ja" to mapOf(
            "server.starting" to "ポート{port}でWebSocketサーバーを開始中",
            "server.started" to "ポート{port}でWebSocketサーバーが正常に開始されました",
            "server.stopped" to "WebSocketサーバーが停止しました",
            "server.error" to "WebSocketサーバーの開始に失敗しました: {error}",
            "player.joined" to "プレイヤーが参加しました: {player}",
            "player.left" to "プレイヤーが退出しました: {player}",
            "connection.new" to "{address}からの新しい接続",
            "connection.closed" to "{address}への接続を閉じました",
            "command.received" to "コマンド実行要求を受信しました: {command}",
            "command.executing" to "プレイヤー {player} 用のコマンド '{command}' を実行中",
            "command.success" to "コマンドが正常に実行されました",
            "command.failed" to "コマンドの実行に失敗しました: {error}",
            "data.collecting" to "ゲームデータコレクターが初期化されました",
            "data.updating" to "{count}人のプレイヤーデータを更新中",
            "websocket.error" to "WebSocketエラーが発生しました",
            "mod.initializing" to "CraftDeckModを初期化中",
            "mod.ready" to "CraftDeckの準備が完了しました"
        )
    )

    /**
     * 言語を設定（将来的にクライアント設定から取得）
     */
    fun setLanguage(language: String) {
        if (messages.containsKey(language)) {
            currentLanguage = language
        }
    }

    /**
     * 現在の言語を取得
     */
    fun getCurrentLanguage(): String = currentLanguage

    /**
     * 多言語化されたメッセージを取得
     * @param key メッセージキー
     * @param params プレースホルダー用のパラメータ
     * @return 多言語化されたメッセージ
     */
    fun getMessage(key: String, vararg params: Pair<String, Any>): String {
        val languageMessages = messages[currentLanguage] ?: messages["en"]!!
        var message = languageMessages[key] ?: key

        // プレースホルダーを置換
        for ((placeholder, value) in params) {
            message = message.replace("{$placeholder}", value.toString())
        }

        return message
    }
    /**
     * ログ出力用の多言語化メッセージ
     */
    object Log {
        fun serverStarting(port: Int) = getMessage("server.starting", "port" to port)
        fun serverStarted(port: Int) = getMessage("server.started", "port" to port)
        fun serverStopped() = getMessage("server.stopped")
        fun serverError(error: String) = getMessage("server.error", "error" to error)
        fun playerJoined(player: String) = getMessage("player.joined", "player" to player)
        fun playerLeft(player: String) = getMessage("player.left", "player" to player)
        fun connectionNew(address: String) = getMessage("connection.new", "address" to address)
        fun connectionClosed(address: String) = getMessage("connection.closed", "address" to address)
        fun commandReceived(command: String) = getMessage("command.received", "command" to command)
        fun commandExecuting(command: String, player: String?) =
            getMessage("command.executing", "command" to command, "player" to (player ?: "console"))
        fun commandSuccess() = getMessage("command.success")
        fun commandFailed(error: String) = getMessage("command.failed", "error" to error)
        fun dataCollecting() = getMessage("data.collecting")
        fun dataUpdating(count: Int) = getMessage("data.updating", "count" to count)
        fun websocketError() = getMessage("websocket.error")
        fun modInitializing() = getMessage("mod.initializing")
        fun modReady() = getMessage("mod.ready")
    }

    /**
     * JSON レスポンス用の多言語化メッセージ
     */
    object Response {
        fun success() = getMessage("command.success")
        fun failed(error: String) = getMessage("command.failed", "error" to error)
        fun connectionWelcome() = "Welcome to CraftDeck" // 簡単な英語メッセージのまま
    }
}