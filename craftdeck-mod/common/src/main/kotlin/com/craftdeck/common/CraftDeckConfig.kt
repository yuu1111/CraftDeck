package com.craftdeck.common

import dev.architectury.platform.Platform
import java.io.File
import java.util.Properties

/**
 * CraftDeck設定管理クラス
 * サーバー管理者が言語やその他の設定を変更可能
 */
object CraftDeckConfig {

    private val configFile = File(Platform.getConfigFolder().toFile(), "craftdeck.properties")
    private val properties = Properties()

    // デフォルト設定値
    private const val DEFAULT_PORT = 8080
    private const val DEFAULT_LANGUAGE = "en"
    private const val DEFAULT_AUTO_START = true
    private const val DEFAULT_UPDATE_INTERVAL = 20 // ticks
    private const val DEFAULT_LOG_LEVEL = "INFO"

    // 設定キー
    private const val KEY_PORT = "websocket.port"
    private const val KEY_LANGUAGE = "server.language"
    private const val KEY_AUTO_START = "websocket.auto_start"
    private const val KEY_UPDATE_INTERVAL = "data.update_interval"
    private const val KEY_LOG_LEVEL = "logging.level"
    private const val KEY_ALLOWED_CLIENTS = "security.allowed_clients"

    init {
        loadConfig()
    }

    /**
     * 設定ファイルを読み込み
     */
    private fun loadConfig() {
        try {
            if (configFile.exists()) {
                configFile.inputStream().use { input ->
                    properties.load(input)
                }
                CraftDeckMod.LOGGER.info("Loaded configuration from: ${configFile.absolutePath}")
            } else {
                // デフォルト設定で新規作成
                createDefaultConfig()
                CraftDeckMod.LOGGER.info("Created default configuration: ${configFile.absolutePath}")
            }
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Failed to load configuration, using defaults", e)
        }
    }

    /**
     * デフォルト設定ファイルを作成
     */
    private fun createDefaultConfig() {
        try {
            configFile.parentFile.mkdirs()

            properties.setProperty(KEY_PORT, DEFAULT_PORT.toString())
            properties.setProperty(KEY_LANGUAGE, DEFAULT_LANGUAGE)
            properties.setProperty(KEY_AUTO_START, DEFAULT_AUTO_START.toString())
            properties.setProperty(KEY_UPDATE_INTERVAL, DEFAULT_UPDATE_INTERVAL.toString())
            properties.setProperty(KEY_LOG_LEVEL, DEFAULT_LOG_LEVEL)
            properties.setProperty(KEY_ALLOWED_CLIENTS, "localhost,127.0.0.1")

            saveConfig()
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Failed to create default configuration", e)
        }
    }

    /**
     * 設定ファイルを保存
     */
    private fun saveConfig() {
        try {
            configFile.outputStream().use { output ->
                properties.store(output, "CraftDeck Configuration")
            }
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Failed to save configuration", e)
        }
    }

    /**
     * 設定を再読み込み
     */
    fun reloadConfig() {
        properties.clear()
        loadConfig()
        CraftDeckMod.LOGGER.info("Configuration reloaded")
    }

    // 設定取得メソッド

    /**
     * WebSocketポート番号
     */
    val port: Int
        get() = properties.getProperty(KEY_PORT, DEFAULT_PORT.toString()).toIntOrNull() ?: DEFAULT_PORT

    /**
     * サーバー言語設定
     */
    val serverLanguage: String
        get() = properties.getProperty(KEY_LANGUAGE, DEFAULT_LANGUAGE)

    /**
     * WebSocket自動開始
     */
    val autoStart: Boolean
        get() = properties.getProperty(KEY_AUTO_START, DEFAULT_AUTO_START.toString()).toBoolean()

    /**
     * データ更新間隔（ティック）
     */
    val updateInterval: Int
        get() = properties.getProperty(KEY_UPDATE_INTERVAL, DEFAULT_UPDATE_INTERVAL.toString()).toIntOrNull() ?: DEFAULT_UPDATE_INTERVAL

    /**
     * ログレベル
     */
    val logLevel: String
        get() = properties.getProperty(KEY_LOG_LEVEL, DEFAULT_LOG_LEVEL)

    /**
     * 許可されたクライアントIPアドレス
     */
    val allowedClients: List<String>
        get() = properties.getProperty(KEY_ALLOWED_CLIENTS, "localhost,127.0.0.1")
            .split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }

    // 設定変更メソッド（runtime変更対応）

    /**
     * サーバー言語を設定
     */
    fun setServerLanguage(language: String) {
        if (isValidLanguage(language)) {
            properties.setProperty(KEY_LANGUAGE, language)
            saveConfig()
            CraftDeckMod.LOGGER.info("Server language changed to: $language")
        } else {
            CraftDeckMod.LOGGER.warn("Invalid language code: $language. Valid codes: en, ja")
        }
    }

    /**
     * WebSocketポートを設定
     */
    fun setPort(port: Int) {
        if (port in 1024..65535) {
            properties.setProperty(KEY_PORT, port.toString())
            saveConfig()
            CraftDeckMod.LOGGER.info("WebSocket port changed to: $port")
        } else {
            CraftDeckMod.LOGGER.warn("Invalid port number: $port. Must be between 1024-65535")
        }
    }

    /**
     * データ更新間隔を設定
     */
    fun setUpdateInterval(interval: Int) {
        if (interval in 1..200) {
            properties.setProperty(KEY_UPDATE_INTERVAL, interval.toString())
            saveConfig()
            CraftDeckMod.LOGGER.info("Update interval changed to: $interval ticks")
        } else {
            CraftDeckMod.LOGGER.warn("Invalid update interval: $interval. Must be between 1-200 ticks")
        }
    }

    /**
     * 有効な言語コードかチェック
     */
    private fun isValidLanguage(language: String): Boolean {
        return language in listOf("en", "ja", "en_us", "ja_jp")
    }

    /**
     * 設定情報を表示
     */
    fun printConfiguration() {
        CraftDeckMod.LOGGER.info("=== CraftDeck Configuration ===")
        CraftDeckMod.LOGGER.info("WebSocket Port: $port")
        CraftDeckMod.LOGGER.info("Server Language: $serverLanguage")
        CraftDeckMod.LOGGER.info("Auto Start: $autoStart")
        CraftDeckMod.LOGGER.info("Update Interval: $updateInterval ticks")
        CraftDeckMod.LOGGER.info("Log Level: $logLevel")
        CraftDeckMod.LOGGER.info("Allowed Clients: ${allowedClients.joinToString(", ")}")
        CraftDeckMod.LOGGER.info("Config File: ${configFile.absolutePath}")
        CraftDeckMod.LOGGER.info("==============================")
    }
}