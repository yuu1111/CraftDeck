package com.craftdeck.forge

import com.craftdeck.common.CraftDeckMod
import net.minecraftforge.fml.common.Mod

@Mod(CraftDeckMod.MOD_ID)
class CraftDeckForge {
    init {
        CraftDeckMod.init()
    }
}