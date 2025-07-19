package com.craftdeck.common

import net.minecraft.commands.CommandSourceStack
import net.minecraft.network.chat.Component
import net.minecraft.server.MinecraftServer
import net.minecraft.world.phys.Vec2
import net.minecraft.world.phys.Vec3

object CommandHandler {

    private var server: MinecraftServer? = null
    private var isInitialized = false

    fun setServer(minecraftServer: MinecraftServer) {
        if (!isInitialized) {
            server = minecraftServer
            isInitialized = true
            CraftDeckMod.LOGGER.info("Command handler initialized with server instance")
        } else {
            // Just update the server reference without logging
            server = minecraftServer
        }
    }

    fun executeCommand(command: String, playerName: String? = null): CommandResult {
        val currentServer = server
        if (currentServer == null) {
            return CommandResult(false, "Server not available")
        }

        return try {
            val commandSource = if (playerName != null) {
                // Execute as specific player
                val player = currentServer.playerList.getPlayerByName(playerName)
                if (player != null) {
                    player.createCommandSourceStack()
                } else {
                    return CommandResult(false, "Player '$playerName' not found")
                }
            } else {
                // Auto-select first available player as sender
                val availablePlayers = currentServer.playerList.players
                if (availablePlayers.isNotEmpty()) {
                    val firstPlayer = availablePlayers[0]
                    CraftDeckMod.LOGGER.info("Auto-selecting player '${firstPlayer.name.string}' as command sender")
                    firstPlayer.createCommandSourceStack()
                } else {
                    // No players online, use server console as fallback
                    CraftDeckMod.LOGGER.warn("No players online, executing command as server console")
                    createServerCommandSource(currentServer)
                }
            }

            val result = currentServer.commands.performPrefixedCommand(commandSource, command)
            CraftDeckMod.LOGGER.info("Executed command '$command' with result: $result")

            CommandResult(true, "Command executed successfully", result)
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Failed to execute command: $command", e)
            CommandResult(false, "Command execution failed: ${e.message}")
        }
    }

    private fun createServerCommandSource(server: MinecraftServer): CommandSourceStack {
        return CommandSourceStack(
            server,
            Vec3.ZERO,
            Vec2.ZERO,
            server.overworld(),
            4, // Permission level (operator)
            "CraftDeck",
            Component.literal("CraftDeck"),
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