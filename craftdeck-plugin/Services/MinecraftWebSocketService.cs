using System;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using CraftDeck.StreamDeckPlugin.Models;
using System.Collections.Concurrent;
using System.Linq;
using System.Collections.Generic;

namespace CraftDeck.StreamDeckPlugin.Services
{
    public class MinecraftWebSocketService : IDisposable
    {
        private ClientWebSocket _webSocket;
        private readonly CancellationTokenSource _cancellationTokenSource;
        private readonly string _serverUrl;
        private bool _isConnected = false;
        private readonly ConcurrentDictionary<string, PlayerStatusMessage> _playerData;

        // Events
        public event Action<bool> ConnectionStateChanged;
        public event Action<PlayerStatusMessage> PlayerStatusReceived;
        public event Action<PlayerJoinMessage> PlayerJoined;
        public event Action<PlayerLeaveMessage> PlayerLeft;
        public event Action<CommandResultMessage> CommandResultReceived;
        public event Action<string> ErrorReceived;

        public MinecraftWebSocketService(string serverUrl = "ws://localhost:8080")
        {
            _serverUrl = serverUrl;
            _cancellationTokenSource = new CancellationTokenSource();
            _playerData = new ConcurrentDictionary<string, PlayerStatusMessage>();
        }

        public bool IsConnected => _isConnected && _webSocket?.State == WebSocketState.Open;

        public async Task<bool> ConnectAsync()
        {
            try
            {
                if (_webSocket?.State == WebSocketState.Open)
                    return true;

                _webSocket?.Dispose();
                _webSocket = new ClientWebSocket();

                await _webSocket.ConnectAsync(new Uri(_serverUrl), _cancellationTokenSource.Token);
                _isConnected = true;
                ConnectionStateChanged?.Invoke(true);

                // Start listening for messages
                _ = Task.Run(async () => await ListenForMessages(_cancellationTokenSource.Token));

                return true;
            }
            catch (Exception ex)
            {
                _isConnected = false;
                ConnectionStateChanged?.Invoke(false);
                ErrorReceived?.Invoke($"Connection failed: {ex.Message}");
                return false;
            }
        }

        public async Task DisconnectAsync()
        {
            try
            {
                _isConnected = false;
                if (_webSocket?.State == WebSocketState.Open)
                {
                    await _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Disconnect requested", CancellationToken.None);
                }
                ConnectionStateChanged?.Invoke(false);
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke($"Disconnect error: {ex.Message}");
            }
        }

        public async Task<bool> SendCommandAsync(string command, string player = null)
        {
            if (!IsConnected) return false;

            try
            {
                var message = new ExecuteCommandMessage
                {
                    Command = command,
                    Player = player
                };

                var json = JsonConvert.SerializeObject(message);
                var bytes = Encoding.UTF8.GetBytes(json);
                var buffer = new ArraySegment<byte>(bytes);

                await _webSocket.SendAsync(buffer, WebSocketMessageType.Text, true, _cancellationTokenSource.Token);
                return true;
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke($"Failed to send command: {ex.Message}");
                return false;
            }
        }

        public async Task<bool> RequestPlayerDataAsync()
        {
            if (!IsConnected) return false;

            try
            {
                var message = new GetPlayerDataMessage();
                var json = JsonConvert.SerializeObject(message);
                var bytes = Encoding.UTF8.GetBytes(json);
                var buffer = new ArraySegment<byte>(bytes);

                await _webSocket.SendAsync(buffer, WebSocketMessageType.Text, true, _cancellationTokenSource.Token);
                return true;
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke($"Failed to request player data: {ex.Message}");
                return false;
            }
        }

        private async Task ListenForMessages(CancellationToken cancellationToken)
        {
            var buffer = new byte[1024 * 4];

            try
            {
                while (_webSocket.State == WebSocketState.Open && !cancellationToken.IsCancellationRequested)
                {
                    var result = await _webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), cancellationToken);

                    if (result.MessageType == WebSocketMessageType.Text)
                    {
                        var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                        await ProcessMessage(message);
                    }
                    else if (result.MessageType == WebSocketMessageType.Close)
                    {
                        break;
                    }
                }
            }
            catch (OperationCanceledException)
            {
                // Expected when cancellation is requested
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke($"Message listening error: {ex.Message}");
            }
            finally
            {
                _isConnected = false;
                ConnectionStateChanged?.Invoke(false);
            }
        }

        private async Task ProcessMessage(string message)
        {
            try
            {
                var baseMessage = JsonConvert.DeserializeObject<WebSocketMessage>(message);

                switch (baseMessage.Type)
                {
                    case "connection":
                        var connectionMsg = JsonConvert.DeserializeObject<ConnectionMessage>(message);
                        // Connection confirmed
                        break;

                    case "player_status":
                        var playerStatus = JsonConvert.DeserializeObject<PlayerStatusMessage>(message);
                        _playerData.AddOrUpdate(playerStatus.Uuid, playerStatus, (key, oldValue) => playerStatus);
                        PlayerStatusReceived?.Invoke(playerStatus);
                        break;

                    case "player_join":
                        var playerJoin = JsonConvert.DeserializeObject<PlayerJoinMessage>(message);
                        PlayerJoined?.Invoke(playerJoin);
                        break;

                    case "player_leave":
                        var playerLeave = JsonConvert.DeserializeObject<PlayerLeaveMessage>(message);
                        _playerData.TryRemove(playerLeave.Uuid, out _);
                        PlayerLeft?.Invoke(playerLeave);
                        break;

                    case "player_data":
                        var playerData = JsonConvert.DeserializeObject<PlayerDataMessage>(message);
                        foreach (var player in playerData.Players)
                        {
                            _playerData.AddOrUpdate(player.Uuid, player, (key, oldValue) => player);
                        }
                        break;

                    case "command_result":
                        var commandResult = JsonConvert.DeserializeObject<CommandResultMessage>(message);
                        CommandResultReceived?.Invoke(commandResult);
                        break;

                    case "error":
                        var errorMsg = JsonConvert.DeserializeObject<ErrorMessage>(message);
                        ErrorReceived?.Invoke(errorMsg.Message);
                        break;

                    default:
                        // Unknown message type
                        break;
                }
            }
            catch (Exception ex)
            {
                ErrorReceived?.Invoke($"Failed to process message: {ex.Message}");
            }
        }

        public PlayerStatusMessage GetPlayerData(string playerName)
        {
            return _playerData.Values.FirstOrDefault(p => p.Name.Equals(playerName, StringComparison.OrdinalIgnoreCase));
        }

        public IEnumerable<PlayerStatusMessage> GetAllPlayerData()
        {
            return _playerData.Values.ToList();
        }

        public void Dispose()
        {
            _cancellationTokenSource?.Cancel();
            _webSocket?.Dispose();
            _cancellationTokenSource?.Dispose();
        }
    }
}