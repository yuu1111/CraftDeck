package com.craftdeck.common

import org.java_websocket.server.WebSocketServer
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.WebSocket
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap

class CraftDeckWebSocketServer(port: Int) : WebSocketServer(InetSocketAddress(port)) {

    private val connectedClients = ConcurrentHashMap<WebSocket, String>()

    override fun onStart() {
        CraftDeckMod.LOGGER.info(CraftDeckLocalization.ServerLog.serverStarted(port))
    }

    override fun onOpen(conn: WebSocket, handshake: ClientHandshake) {
        val clientAddress = conn.remoteSocketAddress.address.hostAddress
        connectedClients[conn] = clientAddress
        CraftDeckMod.LOGGER.info(CraftDeckLocalization.ServerLog.connectionNew(clientAddress))

        // Send initial connection confirmation with translation key
        conn.send(CraftDeckLocalization.WebSocketMessage.welcome())
    }

    override fun onClose(conn: WebSocket, code: Int, reason: String, remote: Boolean) {
        val clientAddress = connectedClients.remove(conn)
        CraftDeckMod.LOGGER.info(CraftDeckLocalization.ServerLog.connectionClosed(clientAddress ?: "unknown"))
    }

    override fun onMessage(conn: WebSocket, message: String) {
        val clientAddress = connectedClients[conn]
        CraftDeckMod.LOGGER.info("Received message from $clientAddress: $message")

        try {
            handleMessage(conn, message)
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Error handling message: $message", e)
            val errorResponse = """{"type":"error","message":"Failed to process command: ${e.message}"}"""
            conn.send(errorResponse)
        }
    }

    override fun onError(conn: WebSocket?, ex: Exception) {
        CraftDeckMod.LOGGER.error("WebSocket error", ex)
    }

    private fun handleMessage(conn: WebSocket, message: String) {
        try {
            // Parse JSON message (basic parsing for now)
            when {
                message.contains("\"type\":\"execute_command\"") -> {
                    handleCommandExecution(conn, message)
                }
                message.contains("\"type\":\"get_player_data\"") -> {
                    handlePlayerDataRequest(conn)
                }
                else -> {
                    // Echo back with JSON format for unknown messages
                    val response = """{"type":"echo","original":"$message","timestamp":"${System.currentTimeMillis()}"}"""
                    conn.send(response)
                }
            }
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Error parsing message: $message", e)
            val errorResponse = """{"type":"error","message":"Invalid message format"}"""
            conn.send(errorResponse)
        }
    }

    private fun handleCommandExecution(conn: WebSocket, message: String) {
        try {
            CraftDeckMod.LOGGER.info(CraftDeckLocalization.ServerLog.commandReceived(message))

            // Extract command from JSON (basic extraction)
            val commandStart = message.indexOf("\"command\":\"") + 11
            val commandEnd = message.indexOf("\"", commandStart)
            val command = message.substring(commandStart, commandEnd)

            CraftDeckMod.LOGGER.info("Extracted command: '$command'")

            // Extract player name if specified
            val playerName = if (message.contains("\"player\":\"")) {
                val playerStart = message.indexOf("\"player\":\"") + 10
                val playerEnd = message.indexOf("\"", playerStart)
                message.substring(playerStart, playerEnd)
            } else null

            CraftDeckMod.LOGGER.info(CraftDeckLocalization.ServerLog.commandExecuting(command, playerName))
            val result = CommandHandler.executeCommand(command, playerName)

            // Send result with translation key
            conn.send(CraftDeckLocalization.WebSocketMessage.commandResult(result.success, result.message))
        } catch (e: Exception) {
            CraftDeckMod.LOGGER.error("Error executing command", e)
            val errorResponse = """{"type":"error","message":"Command execution failed: ${e.message}"}"""
            conn.send(errorResponse)
        }
    }

    private fun handlePlayerDataRequest(conn: WebSocket) {
        val playerData = GameDataCollector.getPlayerData()
        val response = buildString {
            append("""{"type":"player_data","players":[""")
            playerData.values.forEachIndexed { index, info ->
                if (index > 0) append(",")
                append("""{""")
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
            append("]}")
        }
        conn.send(response)
    }

    fun broadcastToAll(message: String) {
        connectedClients.keys.forEach { conn ->
            try {
                conn.send(message)
            } catch (e: Exception) {
                CraftDeckMod.LOGGER.error("Failed to send message to client", e)
            }
        }
    }

    fun getConnectedClientCount(): Int = connectedClients.size
}
