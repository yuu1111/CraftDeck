package com.craftdeck.common

import dev.architectury.event.events.common.PlayerEvent
import dev.architectury.event.events.common.TickEvent
import net.minecraft.server.level.ServerPlayer
import net.minecraft.server.MinecraftServer
import java.util.concurrent.ConcurrentHashMap

object GameDataCollector {

    private val playerData = ConcurrentHashMap<String, PlayerInfo>()
    private var server: MinecraftServer? = null
    private var tickCounter = 0
    private const val UPDATE_INTERVAL = 20 // Send updates every second (20 ticks)

    data class PlayerInfo(
        val uuid: String,
        val name: String,
        val health: Float,
        val maxHealth: Float,
        val food: Int,
        val experience: Float,
        val level: Int,
        val gameMode: String,
        val posX: Double,
        val posY: Double,
        val posZ: Double,
        val dimension: String
    )

    fun init() {
        // Register event listeners
        PlayerEvent.PLAYER_JOIN.register { player ->
            onPlayerJoin(player)
        }

        PlayerEvent.PLAYER_QUIT.register { player ->
            onPlayerLeave(player)
        }

        TickEvent.SERVER_POST.register { server ->
            // Set server reference for command handler (only logs once)
            CommandHandler.setServer(server)
            onServerTick(server)
        }

        CraftDeckMod.LOGGER.info("GameDataCollector initialized")
    }

    fun setServer(server: MinecraftServer) {
        this.server = server
        CommandHandler.setServer(server)
    }

    private fun onPlayerJoin(player: ServerPlayer) {
        val playerName = VersionAdapter.getPlayerDisplayName(player)
        CraftDeckMod.LOGGER.info(CraftDeckLocalization.ServerLog.playerJoined(playerName))
        updatePlayerData(player)

        val webSocketServer = CraftDeckMod.getWebSocketServer()
        webSocketServer?.broadcastToAll(
            CraftDeckLocalization.WebSocketMessage.playerJoined(playerName, player.stringUUID)
        )
    }

    private fun onPlayerLeave(player: ServerPlayer) {
        val playerName = VersionAdapter.getPlayerDisplayName(player)
        CraftDeckMod.LOGGER.info(CraftDeckLocalization.ServerLog.playerLeft(playerName))
        playerData.remove(player.stringUUID)

        val webSocketServer = CraftDeckMod.getWebSocketServer()
        webSocketServer?.broadcastToAll(
            CraftDeckLocalization.WebSocketMessage.playerLeft(playerName, player.stringUUID)
        )
    }

    private fun onServerTick(server: net.minecraft.server.MinecraftServer) {
        tickCounter++

        if (tickCounter >= UPDATE_INTERVAL) {
            tickCounter = 0

            // Update player data for all online players
            server.playerList.players.forEach { player ->
                updatePlayerData(player)
            }

            // Send batch update to connected clients
            sendPlayerUpdates()
        }
    }

    private fun updatePlayerData(player: ServerPlayer) {
        val info = PlayerInfo(
            uuid = player.stringUUID,
            name = VersionAdapter.getPlayerDisplayName(player),
            health = player.health,
            maxHealth = player.maxHealth,
            food = player.foodData.foodLevel,
            experience = player.experienceProgress,
            level = player.experienceLevel,
            gameMode = VersionAdapter.getGameMode(player),
            posX = player.x,
            posY = player.y,
            posZ = player.z,
            dimension = VersionAdapter.getDimensionName(player)
        )

        playerData[player.stringUUID] = info
    }

    private fun sendPlayerUpdates() {
        if (playerData.isEmpty()) return

        val webSocketServer = CraftDeckMod.getWebSocketServer() ?: return

        playerData.values.forEach { info ->
            val message = buildString {
                append("""{"type":"player_status",""")
                append(""""uuid":"${info.uuid}",""")
                append(""""name":"${info.name}",""")
                append(""""health":${info.health},""")
                append(""""max_health":${info.maxHealth},""")
                append(""""food":${info.food},""")
                append(""""experience":${info.experience},""")
                append(""""level":${info.level},""")
                append(""""gamemode":"${info.gameMode}",""")
                append(""""position":{"x":${info.posX},"y":${info.posY},"z":${info.posZ}},""")
                append(""""dimension":"${info.dimension}"""")
                append("}")
            }

            webSocketServer.broadcastToAll(message)
        }
    }

    fun getPlayerData(): Map<String, PlayerInfo> = playerData.toMap()
}