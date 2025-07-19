package com.craftdeck.common

import org.java_websocket.server.WebSocketServer
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.WebSocket
import java.net.InetSocketAddress

class CraftDeckWebSocketServer(port: Int) : WebSocketServer(InetSocketAddress(port)) {

    override fun onStart() {
        println("WebSocket server started successfully on port $port")
    }

    override fun onOpen(conn: WebSocket, handshake: ClientHandshake) {
        println("New connection from ${conn.remoteSocketAddress.address.hostAddress}")
    }

    override fun onClose(conn: WebSocket, code: Int, reason: String, remote: Boolean) {
        println("Closed connection to ${conn.remoteSocketAddress.address.hostAddress}")
    }

    override fun onMessage(conn: WebSocket, message: String) {
        println("Received message from ${conn.remoteSocketAddress.address.hostAddress}: $message")
        // Echo back the message for now
        conn.send("Echo: $message")
    }

    override fun onError(conn: WebSocket?, ex: Exception) {
        ex.printStackTrace()
    }
}
