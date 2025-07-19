package com.craftdeck.neoforge

import com.craftdeck.common.CraftDeckMod
import net.neoforged.fml.common.Mod
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent
import net.neoforged.neoforge.common.NeoForge
import net.neoforged.neoforge.event.server.ServerStartedEvent
import net.neoforged.neoforge.event.server.ServerStoppedEvent
import thedarkcolour.kotlinforforge.neoforge.forge.MOD_BUS

@Mod(CraftDeckMod.MOD_ID)
object CraftDeckNeoForge {

    init {
        // Initialize common mod
        CraftDeckMod.init()

        // Register setup event
        MOD_BUS.addListener(::onCommonSetup)

        // Register server events
        NeoForge.EVENT_BUS.addListener(::onServerStarted)
        NeoForge.EVENT_BUS.addListener(::onServerStopped)
    }

    private fun onCommonSetup(event: FMLCommonSetupEvent) {
        // Common setup logic if needed
    }

    private fun onServerStarted(event: ServerStartedEvent) {
        CraftDeckMod.onServerStarted(event.server)
    }

    private fun onServerStopped(event: ServerStoppedEvent) {
        CraftDeckMod.onServerStopped()
    }
}