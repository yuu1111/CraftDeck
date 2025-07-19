using StreamDeckLib;
using StreamDeckLib.Messages;
using System;
using System.Threading.Tasks;
using System.Timers;
using CraftDeck.StreamDeckPlugin.Services;
using CraftDeck.StreamDeckPlugin.Models;
using CraftDeck.StreamDeckPlugin.Constants;

namespace CraftDeck.StreamDeckPlugin.Actions
{
    [ActionUuid(Uuid = AppConstants.Actions.PlayerMonitor)]
    public class PlayerMonitorAction : BaseStreamDeckActionWithSettingsModel<Models.PlayerMonitorSettingsModel>, IWebSocketClient
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

            // Set update interval (1000ms default)
            _updateTimer = new Timer(AppConstants.UI.HealthUpdateInterval);
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

            // Update language setting if specified
            if (!string.IsNullOrEmpty(SettingsModel.Language))
            {
                LocalizationService.SetLanguage(SettingsModel.Language);
            }

            await UpdateDisplay();
        }

        private async Task UpdateDisplay()
        {
            if (string.IsNullOrEmpty(_currentContext)) return;

            try
            {
                string title;
                var webSocketService = SharedWebSocketManager.WebSocketService;

                // Set language before getting display format
                if (!string.IsNullOrEmpty(SettingsModel.Language))
                {
                    LocalizationService.SetLanguage(SettingsModel.Language);
                }

                var displayFormat = GetDisplayFormat();
                const string defaultIcon = "🎮";

                if (!webSocketService.IsConnected)
                {
                    title = DisplayFormatService.FormatOfflineMessage(displayFormat, defaultIcon, SettingsModel.Language);
                }
                else if (_currentPlayerData != null &&
                         (string.IsNullOrEmpty(SettingsModel.PlayerName) ||
                          SettingsModel.PlayerName.Equals(_currentPlayerData.Name, StringComparison.OrdinalIgnoreCase)))
                {
                    // クライアントプレイヤー名を取得（設定されていない場合は現在のプレイヤー名を使用）
                    var clientPlayerName = string.IsNullOrEmpty(SettingsModel.PlayerName)
                        ? _currentPlayerData.Name
                        : SettingsModel.PlayerName;
                    title = DisplayFormatService.FormatPlayerData(displayFormat, _currentPlayerData, clientPlayerName);
                }
                else
                {
                    title = DisplayFormatService.FormatNoDataMessage(displayFormat, defaultIcon, SettingsModel.Language);
                }

                await Manager.SetTitleAsync(_currentContext, title);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating player monitor display: {ex.Message}");
            }
        }

        private string GetDisplayFormat()
        {
            if (!string.IsNullOrEmpty(SettingsModel.DisplayFormat))
                return SettingsModel.DisplayFormat;

            // デフォルトフォーマット（汎用プレイヤーモニター）
            return DisplayFormatService.GetDefaultHealthFormat(SettingsModel.Language);
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
            // Not needed for player monitor action
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
            // Not needed for player monitor action
        }

        public void OnErrorReceived(string error)
        {
            Console.WriteLine($"WebSocket error in {_monitorType} monitor action: {error}");
        }
    }

    // レベル監視用の別のActionUuid
    [ActionUuid(Uuid = AppConstants.Actions.PlayerLevel)]
    public class PlayerLevelMonitorAction : PlayerMonitorAction
    {
        // PlayerMonitorActionを継承するだけで、MonitorTypeはアクションUUIDから自動決定される
    }

    // 座標監視用の別のActionUuid
    [ActionUuid(Uuid = AppConstants.Actions.PlayerPosition)]
    public class PlayerPositionMonitorAction : PlayerMonitorAction
    {
        // PlayerMonitorActionを継承するだけで、MonitorTypeはアクションUUIDから自動決定される
    }
}