using StreamDeckLib;
using StreamDeckLib.Messages;
using System;
using System.Threading.Tasks;
using System.Timers;
using CraftDeck.StreamDeckPlugin.Services;
using CraftDeck.StreamDeckPlugin.Models;

namespace CraftDeck.StreamDeckPlugin.Actions
{
    [ActionUuid(Uuid = "com.craftdeck.plugin.action.playerhealth")]
    public class PlayerHealthAction : BaseStreamDeckActionWithSettingsModel<Models.PlayerMonitorSettingsModel>, IWebSocketClient
    {
        private Timer _updateTimer;
        private PlayerStatusMessage _currentPlayerData;
        private string _clientId;
        private string _currentContext;

        public override async Task OnWillAppear(StreamDeckEventPayload args)
        {
            await base.OnWillAppear(args);

            _currentContext = args.context;

            // Register with shared WebSocket manager
            _clientId = Guid.NewGuid().ToString();
            SharedWebSocketManager.RegisterClient(_clientId, this);

            // Start update timer
            _updateTimer = new Timer(1000);
            _updateTimer.Elapsed += async (sender, e) => await UpdateDisplay();
            _updateTimer.Start();

            // Auto-connect if not connected
            var webSocketService = SharedWebSocketManager.WebSocketService;
            if (!webSocketService.IsConnected)
            {
                await webSocketService.ConnectAsync();
            }

            await UpdateDisplay();
        }

        public override async Task OnWillDisappear(StreamDeckEventPayload args)
        {
            _updateTimer?.Stop();
            _updateTimer?.Dispose();

            // Unregister from shared WebSocket manager
            if (!string.IsNullOrEmpty(_clientId))
            {
                SharedWebSocketManager.UnregisterClient(_clientId);
            }

            await base.OnWillDisappear(args);
        }

        public override async Task OnDidReceiveSettings(StreamDeckEventPayload args)
        {
            await base.OnDidReceiveSettings(args);
            await UpdateDisplay();
        }

        private async Task UpdateDisplay()
        {
            if (string.IsNullOrEmpty(_currentContext)) return;

            try
            {
                string title;
                var webSocketService = SharedWebSocketManager.WebSocketService;
                var displayFormat = string.IsNullOrEmpty(SettingsModel.DisplayFormat) 
                    ? DisplayFormatService.DefaultHealthFormat 
                    : SettingsModel.DisplayFormat;

                if (!webSocketService.IsConnected)
                {
                    title = DisplayFormatService.FormatOfflineMessage(displayFormat, "❤️");
                }
                else if (_currentPlayerData != null &&
                         (string.IsNullOrEmpty(SettingsModel.PlayerName) ||
                          SettingsModel.PlayerName.Equals(_currentPlayerData.Name, StringComparison.OrdinalIgnoreCase)))
                {
                    title = DisplayFormatService.FormatPlayerData(displayFormat, _currentPlayerData);

                    // Change color based on health percentage
                    var healthPercent = _currentPlayerData.Health / _currentPlayerData.MaxHealth;
                    // Could set different background colors based on health here
                }
                else
                {
                    title = DisplayFormatService.FormatNoDataMessage(displayFormat, "❤️");
                }

                await Manager.SetTitleAsync(_currentContext, title);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating health display: {ex.Message}");
            }
        }

        // IWebSocketClient implementation
        public void OnConnectionStateChanged(bool connected)
        {
            // Update display when connection state changes
            _ = Task.Run(async () => await UpdateDisplay());
        }

        public void OnPlayerStatusReceived(PlayerStatusMessage playerStatus)
        {
            // Update if this is the player we're monitoring
            if (string.IsNullOrEmpty(SettingsModel.PlayerName) ||
                SettingsModel.PlayerName.Equals(playerStatus.Name, StringComparison.OrdinalIgnoreCase))
            {
                _currentPlayerData = playerStatus;
                _ = Task.Run(async () => await UpdateDisplay());
            }
        }

        public void OnPlayerJoined(PlayerJoinMessage playerJoin)
        {
            // Not needed for health action
        }

        public void OnPlayerLeft(PlayerLeaveMessage playerLeave)
        {
            // Clear data if the monitored player left
            if (_currentPlayerData != null && _currentPlayerData.Name.Equals(playerLeave.Player, StringComparison.OrdinalIgnoreCase))
            {
                _currentPlayerData = null;
                _ = Task.Run(async () => await UpdateDisplay());
            }
        }

        public void OnCommandResultReceived(CommandResultMessage result)
        {
            // Not needed for health action
        }

        public void OnErrorReceived(string error)
        {
            Console.WriteLine($"WebSocket error in health action: {error}");
        }
    }
}