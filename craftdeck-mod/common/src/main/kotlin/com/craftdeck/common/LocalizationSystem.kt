package com.craftdeck.common

/**
 * CraftDeck多言語化システム（Config対応版）
 *
 * 設計方針:
 * - サーバーログ: Config設定言語（管理者向け）
 * - クライアント通信: クライアント言語設定（ユーザー向け）
 * - 将来のサーバーサイド対応: 英語固定ログ + 設定可能な通信メッセージ
 */
object LocalizationSystem {

    /**
     * サーバー言語を取得（Config設定から）
     */
    private fun getServerLanguage(): String {
        return try {
            val configLang = CraftDeckConfig.serverLanguage
            // ja_jp -> ja, en_us -> en の正規化
            when {
                configLang.startsWith("ja") -> "ja"
                configLang.startsWith("en") -> "en"
                else -> "en" // デフォルト
            }
        } catch (e: Exception) {
            "en" // Config未初期化時のフォールバック
        }
    }

    // 多言語化されたメッセージマップ
    private val messages = mapOf(
        "en" to mapOf(
            "server.starting" to "Starting WebSocket server on port {port}",
            "server.started" to "WebSocket server started successfully on port {port}",
            "server.stopped" to "WebSocket server stopped",
            "server.error" to "Failed to start WebSocket server: {error}",
            "server.config_loaded" to "Configuration loaded from {file}",
            "server.config_created" to "Default configuration created: {file}",
            "server.config_error" to "Configuration error: {error}",
            "player.joined" to "Player joined: {player}",
            "player.left" to "Player left: {player}",
            "connection.new" to "New connection from {address}",
            "connection.closed" to "Closed connection to {address}",
            "connection.rejected" to "Connection rejected from {address}: not in allowed clients",
            "command.received" to "Received command execution request: {command}",
            "command.executing" to "Executing command '{command}' for player: {player}",
            "command.success" to "Command executed successfully",
            "command.failed" to "Command execution failed: {error}",
            "data.collecting" to "Game data collector initialized",
            "data.updating" to "Updating player data for {count} players",
            "websocket.error" to "WebSocket error occurred",
            "mod.initializing" to "Initializing CraftDeck Mod",
            "mod.ready" to "CraftDeck is ready",
            "config.port_changed" to "WebSocket port changed to: {port}",
            "config.language_changed" to "Server language changed to: {language}",
            "config.interval_changed" to "Update interval changed to: {interval} ticks",
            "config.invalid_port" to "Invalid port number: {port}. Must be between 1024-65535",
            "config.invalid_language" to "Invalid language code: {language}. Valid codes: en, ja",
            "config.invalid_interval" to "Invalid update interval: {interval}. Must be between 1-200 ticks"
        ),
        "ja" to mapOf(
            "server.starting" to "ポート{port}でWebSocketサーバーを開始中",
            "server.started" to "ポート{port}でWebSocketサーバーが正常に開始されました",
            "server.stopped" to "WebSocketサーバーが停止しました",
            "server.error" to "WebSocketサーバーの開始に失敗しました: {error}",
            "server.config_loaded" to "設定ファイルを読み込みました: {file}",
            "server.config_created" to "デフォルト設定を作成しました: {file}",
            "server.config_error" to "設定エラー: {error}",
            "player.joined" to "プレイヤーが参加しました: {player}",
            "player.left" to "プレイヤーが退出しました: {player}",
            "connection.new" to "{address}からの新しい接続",
            "connection.closed" to "{address}への接続を閉じました",
            "connection.rejected" to "{address}からの接続を拒否しました: 許可されていないクライアントです",
            "command.received" to "コマンド実行要求を受信しました: {command}",
            "command.executing" to "プレイヤー {player} 用のコマンド '{command}' を実行中",
            "command.success" to "コマンドが正常に実行されました",
            "command.failed" to "コマンドの実行に失敗しました: {error}",
            "data.collecting" to "ゲームデータコレクターが初期化されました",
            "data.updating" to "{count}人のプレイヤーデータを更新中",
            "websocket.error" to "WebSocketエラーが発生しました",
            "mod.initializing" to "CraftDeckModを初期化中",
            "mod.ready" to "CraftDeckの準備が完了しました",
            "config.port_changed" to "WebSocketポートを変更しました: {port}",
            "config.language_changed" to "サーバー言語を変更しました: {language}",
            "config.interval_changed" to "更新間隔を変更しました: {interval}ティック",
            "config.invalid_port" to "無効なポート番号です: {port}。1024-65535の範囲で指定してください",
            "config.invalid_language" to "無効な言語コードです: {language}。有効なコード: en, ja",
            "config.invalid_interval" to "無効な更新間隔です: {interval}。1-200ティックの範囲で指定してください"
        )
    )

    /**
     * サーバー用メッセージを取得（Config設定言語で）
     * @param key メッセージキー
     * @param params プレースホルダー用のパラメータ
     * @return サーバー設定言語のメッセージ
     */
    fun getServerMessage(key: String, vararg params: Pair<String, Any>): String {
        return getMessage(getServerLanguage(), key, *params)
    }

    /**
     * クライアント用メッセージを取得（指定言語で）
     * @param clientLanguage クライアント言語
     * @param key メッセージキー
     * @param params プレースホルダー用のパラメータ
     * @return 指定言語のメッセージ
     */
    fun getClientMessage(clientLanguage: String, key: String, vararg params: Pair<String, Any>): String {
        val normalizedLang = when {
            clientLanguage.startsWith("ja") -> "ja"
            clientLanguage.startsWith("en") -> "en"
            else -> "en"
        }
        return getMessage(normalizedLang, key, *params)
    }

    /**
     * 指定言語のメッセージを取得
     */
    private fun getMessage(language: String, key: String, vararg params: Pair<String, Any>): String {
        val languageMessages = messages[language] ?: messages["en"]!!
        var message = languageMessages[key] ?: key

        // プレースホルダーを置換
        for ((placeholder, value) in params) {
            message = message.replace("{$placeholder}", value.toString())
        }

        return message
    }

    /**
     * サーバーログ用メッセージ（Config言語設定対応）
     */
    object ServerLog {
        fun serverStarting(port: Int) = getServerMessage("server.starting", "port" to port)
        fun serverStarted(port: Int) = getServerMessage("server.started", "port" to port)
        fun serverStopped() = getServerMessage("server.stopped")
        fun serverError(error: String) = getServerMessage("server.error", "error" to error)
        fun configLoaded(file: String) = getServerMessage("server.config_loaded", "file" to file)
        fun configCreated(file: String) = getServerMessage("server.config_created", "file" to file)
        fun configError(error: String) = getServerMessage("server.config_error", "error" to error)
        fun playerJoined(player: String) = getServerMessage("player.joined", "player" to player)
        fun playerLeft(player: String) = getServerMessage("player.left", "player" to player)
        fun connectionNew(address: String) = getServerMessage("connection.new", "address" to address)
        fun connectionClosed(address: String) = getServerMessage("connection.closed", "address" to address)
        fun connectionRejected(address: String) = getServerMessage("connection.rejected", "address" to address)
        fun commandReceived(command: String) = getServerMessage("command.received", "command" to command)
        fun commandExecuting(command: String, player: String?) =
            getServerMessage("command.executing", "command" to command, "player" to (player ?: "console"))
        fun commandSuccess() = getServerMessage("command.success")
        fun commandFailed(error: String) = getServerMessage("command.failed", "error" to error)
        fun dataCollecting() = getServerMessage("data.collecting")
        fun dataUpdating(count: Int) = getServerMessage("data.updating", "count" to count)
        fun websocketError() = getServerMessage("websocket.error")
        fun modInitializing() = getServerMessage("mod.initializing")
        fun modReady() = getServerMessage("mod.ready")
        fun portChanged(port: Int) = getServerMessage("config.port_changed", "port" to port)
        fun languageChanged(language: String) = getServerMessage("config.language_changed", "language" to language)
        fun intervalChanged(interval: Int) = getServerMessage("config.interval_changed", "interval" to interval)
        fun invalidPort(port: Int) = getServerMessage("config.invalid_port", "port" to port)
        fun invalidLanguage(language: String) = getServerMessage("config.invalid_language", "language" to language)
        fun invalidInterval(interval: Int) = getServerMessage("config.invalid_interval", "interval" to interval)
    }

    /**
     * クライアント通信用メッセージ（指定言語対応）
     */
    object ClientMessage {
        fun success(clientLang: String) = getClientMessage(clientLang, "command.success")
        fun failed(clientLang: String, error: String) = getClientMessage(clientLang, "command.failed", "error" to error)
        fun playerJoined(clientLang: String, player: String) = getClientMessage(clientLang, "player.joined", "player" to player)
        fun playerLeft(clientLang: String, player: String) = getClientMessage(clientLang, "player.left", "player" to player)
        fun connectionWelcome(clientLang: String) = when (clientLang.startsWith("ja")) {
            true -> "CraftDeckへようこそ"
            false -> "Welcome to CraftDeck"
        }
    }

    /**
     * 対応言語一覧を取得
     */
    fun getSupportedLanguages(): Set<String> = messages.keys

    /**
     * 現在のサーバー言語設定を取得
     */
    fun getCurrentServerLanguage(): String = getServerLanguage()
}