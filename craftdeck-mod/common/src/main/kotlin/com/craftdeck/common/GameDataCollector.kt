package com.craftdeck.common

import dev.architectury.event.events.common.PlayerEvent
import dev.architectury.event.events.common.TickEvent
import net.minecraft.server.network.ServerPlayerEntity
import net.minecraft.util.Identifier
import java.util.concurrent.ConcurrentHashMap

object GameDataCollector {
    
    private val playerData = ConcurrentHashMap<String, PlayerInfo>()
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
            // Set server reference for command handler on first tick
            CommandHandler.setServer(server)
            onServerTick(server)
        }
        
        CraftDeckMod.LOGGER.info("GameDataCollector initialized")
    }
    
    private fun onPlayerJoin(player: ServerPlayerEntity) {
        CraftDeckMod.LOGGER.info("Player joined: ${player.name.string}")
        updatePlayerData(player)
        
        val webSocketServer = CraftDeckMod.getWebSocketServer()
        val message = """{"type":"player_join","player":"${player.name.string}","uuid":"${player.uuidAsString}"}"""
        webSocketServer?.broadcastToAll(message)
    }
    
    private fun onPlayerLeave(player: ServerPlayerEntity) {
        CraftDeckMod.LOGGER.info("Player left: ${player.name.string}")
        playerData.remove(player.uuidAsString)
        
        val webSocketServer = CraftDeckMod.getWebSocketServer()
        val message = """{"type":"player_leave","player":"${player.name.string}","uuid":"${player.uuidAsString}"}"""
        webSocketServer?.broadcastToAll(message)
    }
    
    private fun onServerTick(server: net.minecraft.server.MinecraftServer) {
        tickCounter++
        
        if (tickCounter >= UPDATE_INTERVAL) {
            tickCounter = 0
            
            // Update player data for all online players
            server.playerManager.playerList.forEach { player ->
                updatePlayerData(player)
            }
            
            // Send batch update to connected clients
            sendPlayerUpdates()
        }
    }
    
    private fun updatePlayerData(player: ServerPlayerEntity) {
        val info = PlayerInfo(
            uuid = player.uuidAsString,
            name = player.name.string,
            health = player.health,
            maxHealth = player.maxHealth,
            food = player.hungerManager.foodLevel,
            experience = player.experienceProgress,
            level = player.experienceLevel,
            gameMode = player.interactionManager.gameMode.getName(),
            posX = player.x,
            posY = player.y,
            posZ = player.z,
            dimension = player.world.registryKey.value.toString()
        )
        
        playerData[player.uuidAsString] = info
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