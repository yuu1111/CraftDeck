package com.craftdeck.common

import net.minecraft.world.entity.player.Player
import net.minecraft.server.level.ServerPlayer

/**
 * Version compatibility adapter for handling differences across Minecraft versions.
 * This class provides a unified interface for accessing player and game data
 * that may have different implementations across different Minecraft versions.
 */
object VersionAdapter {

    /**
     * Get the gamemode of a player as a string.
     * Handles version differences in gamemode access.
     */
    fun getGameMode(player: ServerPlayer): String {
        return try {
            // Try modern approach first (1.19+)
            player.gameMode.gameModeForPlayer.name
        } catch (e: Exception) {
            try {
                // Fallback for older versions
                player.gameMode.gameModeForPlayer.toString()
            } catch (e2: Exception) {
                // Ultimate fallback
                "UNKNOWN"
            }
        }
    }

    /**
     * Get the display name of a player as a string.
     * Handles version differences in name access.
     */
    fun getPlayerDisplayName(player: Player): String {
        return try {
            // Modern approach (1.19+)
            player.name.string
        } catch (e: Exception) {
            try {
                // Fallback approach
                player.displayName?.string ?: player.name.toString()
            } catch (e2: Exception) {
                // Ultimate fallback
                "Unknown Player"
            }
        }
    }

    /**
     * Get the dimension name of a player's current world.
     * Handles version differences in dimension access.
     */
    fun getDimensionName(player: ServerPlayer): String {
        return try {
            // Modern approach (1.16+)
            player.level().dimension().location().toString()
        } catch (e: Exception) {
            try {
                // Fallback approach
                player.level().dimension().toString()
            } catch (e2: Exception) {
                // Ultimate fallback
                "unknown_dimension"
            }
        }
    }

    /**
     * Get the current Minecraft version information.
     * Useful for debugging and version-specific behavior.
     */
    fun getMinecraftVersion(): String {
        return try {
            // Try to get version from SharedConstants (1.17+)
            val sharedConstants = Class.forName("net.minecraft.SharedConstants")
            val getCurrentVersion = sharedConstants.getMethod("getCurrentVersion")
            val version = getCurrentVersion.invoke(null)
            val getId = version.javaClass.getMethod("getId")
            getId.invoke(version) as String
        } catch (e: Exception) {
            try {
                // Fallback for older versions
                val detectedVersion = Class.forName("net.minecraft.DetectedVersion")
                val tryDetectVersion = detectedVersion.getMethod("tryDetectVersion")
                val version = tryDetectVersion.invoke(null)
                val getId = version.javaClass.getMethod("getId")
                getId.invoke(version) as String
            } catch (e2: Exception) {
                // Ultimate fallback
                "unknown"
            }
        }
    }

    /**
     * Check if the current Minecraft version supports certain features.
     */
    fun isVersionAtLeast(major: Int, minor: Int): Boolean {
        val version = getMinecraftVersion()
        return try {
            val parts = version.split(".")
            val vMajor = parts.getOrNull(0)?.toIntOrNull() ?: 1
            val vMinor = parts.getOrNull(1)?.toIntOrNull() ?: 16

            when {
                vMajor > major -> true
                vMajor == major -> vMinor >= minor
                else -> false
            }
        } catch (e: Exception) {
            // Assume modern version if we can't detect
            true
        }
    }

    /**
     * Version-specific feature flags
     */
    object Features {
        val hasModernGameMode: Boolean by lazy { isVersionAtLeast(1, 19) }
        val hasModernComponents: Boolean by lazy { isVersionAtLeast(1, 19) }
        val hasModernDimensions: Boolean by lazy { isVersionAtLeast(1, 16) }
        val hasDisplayEntity: Boolean by lazy { isVersionAtLeast(1, 19, 4) }  // Display entities added in 1.19.4
        val hasSmithingTransform: Boolean by lazy { isVersionAtLeast(1, 20) }  // New smithing table in 1.20
        val hasCherryWood: Boolean by lazy { isVersionAtLeast(1, 20) }  // Cherry wood added in 1.20
        val hasSuspiciousBlocks: Boolean by lazy { isVersionAtLeast(1, 20) }  // Archaeology in 1.20
        val hasBreezeAndTrial: Boolean by lazy { isVersionAtLeast(1, 21) }  // Trial chambers in 1.21
    }

    /**
     * Check if the current Minecraft version supports certain features (with patch version).
     */
    fun isVersionAtLeast(major: Int, minor: Int, patch: Int = 0): Boolean {
        val version = getMinecraftVersion()
        return try {
            val parts = version.split(".")
            val vMajor = parts.getOrNull(0)?.toIntOrNull() ?: 1
            val vMinor = parts.getOrNull(1)?.toIntOrNull() ?: 16
            val vPatch = parts.getOrNull(2)?.toIntOrNull() ?: 0

            when {
                vMajor > major -> true
                vMajor == major && vMinor > minor -> true
                vMajor == major && vMinor == minor -> vPatch >= patch
                else -> false
            }
        } catch (e: Exception) {
            // Assume modern version if we can't detect
            true
        }
    }
}