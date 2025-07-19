package com.craftdeck.quilt

import com.craftdeck.common.CraftDeckMod
import org.quiltmc.loader.api.ModContainer
import org.quiltmc.qsl.base.api.entrypoint.ModInitializer

class CraftDeckQuilt : ModInitializer {
    override fun onInitialize(mod: ModContainer) {
        CraftDeckMod.init()
    }
}