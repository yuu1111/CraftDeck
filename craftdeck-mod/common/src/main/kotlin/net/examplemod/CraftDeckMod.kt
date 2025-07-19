package net.examplemod

import dev.architectury.event.events.common.CommandRegistrationEvent
import com.mojang.brigadier.CommandDispatcher
import com.mojang.brigadier.context.CommandContext
import net.minecraft.server.command.ServerCommandSource
import net.minecraft.text.Text

internal object CraftDeckMod {
    const val MOD_ID = "craftdeck"

    @JvmStatic
    fun init() {
        CommandRegistrationEvent.EVENT.register { dispatcher, registryAccess, environment ->
            dispatcher.register(
                com.mojang.brigadier.builder.LiteralArgumentBuilder.literal<ServerCommandSource>("craftdeck")
                    .then(com.mojang.brigadier.builder.LiteralArgumentBuilder.literal<ServerCommandSource>("test")
                        .executes { context: CommandContext<ServerCommandSource> ->
                            context.getSource().sendFeedback(Text.literal("CraftDeck mod test command executed!"), false)
                            1
                        }
                    )
            )
        }
    }
}