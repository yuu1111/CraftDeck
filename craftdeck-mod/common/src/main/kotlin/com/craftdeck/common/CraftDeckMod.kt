package com.craftdeck.common

import org.slf4j.Logger
import org.slf4j.LoggerFactory

object CraftDeckMod {
    const val MOD_ID = "craftdeck"
    val LOGGER: Logger = LoggerFactory.getLogger(MOD_ID)

    private var webSocketServer: CraftDeckWebSocketServer? = null

    fun init() {
        LOGGER.info("Initializing CraftDeck Mod")

        // Start WebSocket server
        try {
            val port = 8080 // TODO: Make this configurable
            webSocketServer = CraftDeckWebSocketServer(port)
            webSocketServer?.start()
        } catch (e: Exception) {
            LOGGER.error("Failed to start WebSocket server", e)
        }

        // Register shutdown hook
        Runtime.getRuntime().addShutdownHook(Thread {
            stop()
        })
    }

    fun stop() {
        LOGGER.info("Stopping CraftDeck Mod")
        try {
            webSocketServer?.stop()
        } catch (e: Exception) {
            LOGGER.error("Failed to stop WebSocket server", e)
        }
    }
}
