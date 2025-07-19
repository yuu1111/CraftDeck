package com.craftdeck.common

import net.minecraft.server.MinecraftServer
import net.minecraft.server.command.ServerCommandSource
import net.minecraft.text.Text
import net.minecraft.util.math.Vec3d
import net.minecraft.util.math.Vec2f

object CommandHandler {
    
    private var server: MinecraftServer? = null
    
    fun setServer(minecraftServer: MinecraftServer) {
        server = minecraftServer
        CraftDeckMod.LOGGER.info("Command handler initialized with server instance")
    }
    
    fun executeCommand(command: String, playerName: String? = null): CommandResult {
        val currentServer = server
        if (currentServer == null) {
            return CommandResult(false, "Server not available")
        }
        
        return try {
            val commandSource = if (playerName != null) {
                // Execute as specific player
                val player = currentServer.playerManager.getPlayer(playerName)
                if (player != null) {
                    player.commandSource
                } else {
                    // Fallback to server console
                    createServerCommandSource(currentServer)
                }
            } else {
                // Execute as server console
                createServerCommandSource(currentServer)
            }
            
            val result = currentServer.commandManager.executeWithPrefix(commandSource, command)
            CraftDeckMod.LOGGER.info("Executed command '$command' with result: $result")
            
            CommandResult(true, "Command executed successfully", result)
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Failed to execute command: $command", e)
            CommandResult(false, "Command execution failed: ${e.message}")
        }
    }
    
    private fun createServerCommandSource(server: MinecraftServer): ServerCommandSource {
        return ServerCommandSource(
            server,
            Vec3d.ZERO,
            Vec2f.ZERO,
            server.overworld,
            4, // Permission level (operator)
            "CraftDeck",
            Text.literal("CraftDeck"),
            server,
            null
        )
    }
    
    data class CommandResult(
        val success: Boolean,
        val message: String,
        val result: Int = 0
    )
}