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
                            _webSocketService = new MinecraftWebSocketService();
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