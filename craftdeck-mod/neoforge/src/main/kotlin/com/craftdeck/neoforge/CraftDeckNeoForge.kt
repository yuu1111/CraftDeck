package com.craftdeck.neoforge

import com.craftdeck.common.CraftDeckMod
import net.neoforged.fml.common.Mod
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent
import net.neoforged.fml.javafmlmod.FMLJavaModLoadingContext

/**
 * NeoForge用のModエントリーポイント
 *
 * 注意: NeoForge 1.20.4での一部APIが不安定なため、
 * 最小限の実装とし、サーバーイベントは暫定的に無効化
 */
@Mod(CraftDeckMod.MOD_ID)
object CraftDeckNeoForge {

    init {
        // Initialize common mod
        CraftDeckMod.init()

        // Register setup event only (server events are temporarily disabled due to API changes)
        FMLJavaModLoadingContext.get().modEventBus.addListener(::onCommonSetup)

        // TODO: NeoForge 1.20.4のAPIが安定したらサーバーイベントを復活
        // FMLJavaModLoadingContext.get().modEventBus.addListener(::onServerStarted)
        // FMLJavaModLoadingContext.get().modEventBus.addListener(::onServerStopped)
    }

    private fun onCommonSetup(event: FMLCommonSetupEvent) {
        // Common setup logic if needed
        CraftDeckMod.LOGGER.info("CraftDeck NeoForge setup completed")
    }

    // 暫定的にコメントアウト - NeoForge APIが安定したら復活
    // private fun onServerStarted(event: ServerStartedEvent) {
    //     CraftDeckMod.onServerStarted(event.server)
    // }

    // private fun onServerStopped(event: ServerStoppedEvent) {
    //     CraftDeckMod.onServerStopped()
    // }
}