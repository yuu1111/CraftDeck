package com.craftdeck.fabric

import com.craftdeck.common.CraftDeckMod
import net.fabricmc.api.ModInitializer

class CraftDeckFabric : ModInitializer {
    override fun onInitialize() {
        CraftDeckMod.init()
    }
}