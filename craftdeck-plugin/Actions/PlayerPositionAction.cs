using StreamDeckLib;
using StreamDeckLib.Messages;
using System;
using System.Threading.Tasks;
using System.Timers;
using CraftDeck.StreamDeckPlugin.Services;
using CraftDeck.StreamDeckPlugin.Models;

namespace CraftDeck.StreamDeckPlugin.Actions
{
    [ActionUuid(Uuid = "com.craftdeck.plugin.action.playerposition")]
    public class PlayerPositionAction : BaseStreamDeckActionWithSettingsModel<Models.PlayerMonitorSettingsModel>
    {
        private static MinecraftWebSocketService _webSocketService;
        private Timer _updateTimer;
        private PlayerStatusMessage _currentPlayerData;

        static PlayerPositionAction()
        {
            _webSocketService = new MinecraftWebSocketService();
            _webSocketService.PlayerStatusReceived += OnPlayerStatusReceived;
        }

        public override async Task OnWillAppear(StreamDeckEventPayload args)
        {
            await base.OnWillAppear(args);
            
            _updateTimer = new Timer(1000);
            _updateTimer.Elapsed += async (sender, e) => await UpdateDisplay(args.context);
            _updateTimer.Start();

            if (!_webSocketService.IsConnected)
            {
                await _webSocketService.ConnectAsync();
            }

            await UpdateDisplay(args.context);
        }

        public override async Task OnWillDisappear(StreamDeckEventPayload args)
        {
            _updateTimer?.Stop();
            _updateTimer?.Dispose();
            await base.OnWillDisappear(args);
        }

        private async Task UpdateDisplay(string context)
        {
            try
            {
                string title;

                if (!_webSocketService.IsConnected)
                {
                    title = "📍 Offline";
                }
                else if (_currentPlayerData != null && 
                         (string.IsNullOrEmpty(SettingsModel.PlayerName) || 
                          SettingsModel.PlayerName.Equals(_currentPlayerData.Name, StringComparison.OrdinalIgnoreCase)))
                {
                    title = $"📍 {_currentPlayerData.Position.X:F0},{_currentPlayerData.Position.Y:F0},{_currentPlayerData.Position.Z:F0}";
                }
                else
                {
                    title = "📍 --,--,--";
                }

                await Manager.SetTitleAsync(context, title);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating position display: {ex.Message}");
            }
        }

        private static void OnPlayerStatusReceived(PlayerStatusMessage playerStatus)
        {
            // Instance management would be needed here
        }
    }
}