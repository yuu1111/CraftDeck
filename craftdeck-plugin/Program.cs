﻿using StreamDeckLib;
using System.Threading.Tasks;

namespace CraftDeck.StreamDeckPlugin
{
    class Program
    {

        static async Task Main(string[] args)
        {

            using (var config = StreamDeckLib.Config.ConfigurationBuilder.BuildDefaultConfiguration(args))
            {

                await ConnectionManager.Initialize(args, config.LoggerFactory)
                                                             .RegisterAllActions(typeof(Program).Assembly)
                                                             .StartAsync();

            }

        }

    }
}
