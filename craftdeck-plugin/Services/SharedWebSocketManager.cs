using System;
using System.Collections.Concurrent;
using CraftDeck.StreamDeckPlugin.Models;

namespace CraftDeck.StreamDeckPlugin.Services
{
    public static class SharedWebSocketManager
    {
        private static MinecraftWebSocketService _webSocketService;
        private static readonly object _lock = new object();
        private static readonly ConcurrentDictionary<string, IWebSocketClient> _registeredClients = new ConcurrentDictionary<string, IWebSocketClient>();

        static SharedWebSocketManager()
        {
            // グローバル設定変更の監視
            GlobalSettingsService.SettingsChanged += OnGlobalSettingsChanged;
        }

        public static MinecraftWebSocketService WebSocketService
        {
            get
            {
                if (_webSocketService == null)
                {
                    lock (_lock)
                    {
                        if (_webSocketService == null)
                        {
                            // グローバル設定からサーバーURLを取得
                            var serverUrl = GlobalSettingsService.GetServerUrl();
                            _webSocketService = new MinecraftWebSocketService(serverUrl);
                            SetupEventHandlers();
                        }
                    }
                }
                return _webSocketService;
            }
        }

        public static void RegisterClient(string clientId, IWebSocketClient client)
        {
            _registeredClients.TryAdd(clientId, client);
        }

        public static void UnregisterClient(string clientId)
        {
            _registeredClients.TryRemove(clientId, out _);
        }

        private static void SetupEventHandlers()
        {
            _webSocketService.ConnectionStateChanged += OnConnectionStateChanged;
            _webSocketService.PlayerStatusReceived += OnPlayerStatusReceived;
            _webSocketService.PlayerJoined += OnPlayerJoined;
            _webSocketService.PlayerLeft += OnPlayerLeft;
            _webSocketService.CommandResultReceived += OnCommandResultReceived;
            _webSocketService.ErrorReceived += OnErrorReceived;
        }

        private static void OnConnectionStateChanged(bool connected)
        {
            foreach (var client in _registeredClients.Values)
            {
                try
                {
                    client.OnConnectionStateChanged(connected);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error notifying client of connection state change: {ex.Message}");
                }
            }
        }

        private static void OnPlayerStatusReceived(PlayerStatusMessage playerStatus)
        {
            foreach (var client in _registeredClients.Values)
            {
                try
                {
                    client.OnPlayerStatusReceived(playerStatus);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error notifying client of player status: {ex.Message}");
                }
            }
        }

        private static void OnPlayerJoined(PlayerJoinMessage playerJoin)
        {
            foreach (var client in _registeredClients.Values)
            {
                try
                {
                    client.OnPlayerJoined(playerJoin);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error notifying client of player join: {ex.Message}");
                }
            }
        }

        private static void OnPlayerLeft(PlayerLeaveMessage playerLeave)
        {
            foreach (var client in _registeredClients.Values)
            {
                try
                {
                    client.OnPlayerLeft(playerLeave);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error notifying client of player leave: {ex.Message}");
                }
            }
        }

        private static void OnCommandResultReceived(CommandResultMessage result)
        {
            foreach (var client in _registeredClients.Values)
            {
                try
                {
                    client.OnCommandResultReceived(result);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error notifying client of command result: {ex.Message}");
                }
            }
        }

        private static void OnErrorReceived(string error)
        {
            foreach (var client in _registeredClients.Values)
            {
                try
                {
                    client.OnErrorReceived(error);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error notifying client of error: {ex.Message}");
                }
            }
        }

        /// <summary>
        /// グローバル設定が変更された時の処理
        /// </summary>
        private static void OnGlobalSettingsChanged(GlobalSettingsService.GlobalSettings settings)
        {
            Console.WriteLine("Global settings changed, updating WebSocket service");

            // 既存の接続があれば切断
            if (_webSocketService != null && _webSocketService.IsConnected)
            {
                _webSocketService.DisconnectAsync();
            }

            // 新しい設定でWebSocketサービスを再作成
            lock (_lock)
            {
                _webSocketService = new MinecraftWebSocketService(settings.ServerUrl);
                SetupEventHandlers();
            }

            // 自動接続が有効な場合は再接続
            if (settings.AutoConnect)
            {
                _ = _webSocketService.ConnectAsync();
            }
        }

        /// <summary>
        /// サーバーURLを更新（GlobalSettingsServiceから呼び出される）
        /// </summary>
        public static void UpdateServerUrl(string newServerUrl)
        {
            Console.WriteLine($"Updating WebSocket server URL to: {newServerUrl}");

            // 既存の接続があれば切断
            if (_webSocketService != null && _webSocketService.IsConnected)
            {
                _webSocketService.DisconnectAsync();
            }

            // 新しいURLでWebSocketサービスを再作成
            lock (_lock)
            {
                _webSocketService = new MinecraftWebSocketService(newServerUrl);
                SetupEventHandlers();
            }

            // 自動接続が有効な場合は再接続
            if (GlobalSettingsService.GetAutoConnect())
            {
                _ = _webSocketService.ConnectAsync();
            }
        }

        /// <summary>
        /// 現在のサーバーURLを取得
        /// </summary>
        public static string GetCurrentServerUrl()
        {
            return GlobalSettingsService.GetServerUrl();
        }
    }

    public interface IWebSocketClient
    {
        void OnConnectionStateChanged(bool connected);
        void OnPlayerStatusReceived(PlayerStatusMessage playerStatus);
        void OnPlayerJoined(PlayerJoinMessage playerJoin);
        void OnPlayerLeft(PlayerLeaveMessage playerLeave);
        void OnCommandResultReceived(CommandResultMessage result);
        void OnErrorReceived(string error);
    }
}