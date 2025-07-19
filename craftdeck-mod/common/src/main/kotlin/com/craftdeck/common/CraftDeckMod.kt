package com.craftdeck.common

import com.mojang.brigadier.context.CommandContext
import dev.architectury.event.events.common.CommandRegistrationEvent
import net.minecraft.commands.CommandSourceStack
import net.minecraft.network.chat.Component
import net.minecraft.server.MinecraftServer
import org.slf4j.Logger
import org.slf4j.LoggerFactory

object CraftDeckMod {
    const val MOD_ID = "craftdeck"
    val LOGGER: Logger = LoggerFactory.getLogger(MOD_ID)

    private var webSocketServer: CraftDeckWebSocketServer? = null

    fun init() {
        LOGGER.info(CraftDeckLocalization.ServerLog.modInitializing())

        // Start WebSocket server
        try {
            val port = CraftDeckConfig.port
            webSocketServer = CraftDeckWebSocketServer(port)
            webSocketServer?.start()
            LOGGER.info(CraftDeckLocalization.ServerLog.serverStarted(port))
        } catch (e: Exception) {
            LOGGER.error(CraftDeckLocalization.ServerLog.serverError(e.message ?: "Unknown error"))
        }

        // Initialize game data collector
        try {
            GameDataCollector.init()
            LOGGER.info(CraftDeckLocalization.ServerLog.dataCollecting())
        } catch (e: Exception) {
            LOGGER.error("Failed to initialize game data collector", e)
        }

        // Register commands
        registerCommands()

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

    fun getWebSocketServer(): CraftDeckWebSocketServer? = webSocketServer

    fun onServerStarted(server: MinecraftServer) {
        LOGGER.info(CraftDeckLocalization.ServerLog.modReady())
        GameDataCollector.setServer(server)
    }

    fun onServerStopped() {
        LOGGER.info("Server stopped, stopping CraftDeck")
        stop()
    }

    private fun registerCommands() {
        CommandRegistrationEvent.EVENT.register { dispatcher, registryAccess, environment ->
            dispatcher.register(
                com.mojang.brigadier.builder.LiteralArgumentBuilder.literal<CommandSourceStack>("craftdeck")
                    .then(com.mojang.brigadier.builder.LiteralArgumentBuilder.literal<CommandSourceStack>("status")
                        .executes { context: CommandContext<CommandSourceStack> ->
                            val server = webSocketServer
                            val clientCount = server?.getConnectedClientCount() ?: 0
                            val playerCount = GameDataCollector.getPlayerData().size

                            context.source.sendSuccess(
                                Component.literal("CraftDeck Status:"),
                                false
                            )
                            context.source.sendSuccess(
                                Component.literal("- WebSocket clients: $clientCount"),
                                false
                            )
                            context.source.sendSuccess(
                                Component.literal("- Tracked players: $playerCount"),
                                false
                            )
                            1
                        }
                    )
                    .then(com.mojang.brigadier.builder.LiteralArgumentBuilder.literal<CommandSourceStack>("test")
                        .executes { context: CommandContext<CommandSourceStack> ->
                            context.source.sendSuccess(
                                Component.literal("CraftDeck mod is working correctly!"),
                                false
                            )
                            1
                        }
                    )
            )
        }
    }
}
