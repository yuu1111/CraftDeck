using StreamDeckLib;
using StreamDeckLib.Messages;
using System;
using System.Threading.Tasks;
using CraftDeck.StreamDeckPlugin.Services;
using CraftDeck.StreamDeckPlugin.Models;

namespace CraftDeck.StreamDeckPlugin.Actions
{
    [ActionUuid(Uuid = "com.craftdeck.plugin.action.command")]
    public class CommandAction : BaseStreamDeckActionWithSettingsModel<Models.CommandSettingsModel>, IWebSocketClient
    {
        private string _clientId;

        public override async Task OnKeyUp(StreamDeckEventPayload args)
        {
            try
            {
                var webSocketService = SharedWebSocketManager.WebSocketService;

                if (!webSocketService.IsConnected)
                {
                    await webSocketService.ConnectAsync();
                    await Task.Delay(1000);
                }

                if (webSocketService.IsConnected && !string.IsNullOrEmpty(SettingsModel.Command))
                {
                    var success = await webSocketService.SendCommandAsync(
                        SettingsModel.Command,
                        string.IsNullOrEmpty(SettingsModel.PlayerName) ? null : SettingsModel.PlayerName
                    );

                    if (success)
                    {
                        await Manager.ShowOkAsync(args.context);
                    }
                    else
                    {
                        await Manager.ShowAlertAsync(args.context);
                    }
                }
                else
                {
                    await Manager.ShowAlertAsync(args.context);
                }
            }
            catch (Exception ex)
            {
                await Manager.ShowAlertAsync(args.context);
                Console.WriteLine($"Command execution error: {ex.Message}");
            }
        }

        public override async Task OnWillAppear(StreamDeckEventPayload args)
        {
            await base.OnWillAppear(args);

            // Register with shared WebSocket manager
            _clientId = Guid.NewGuid().ToString();
            SharedWebSocketManager.RegisterClient(_clientId, this);

            // Set command as title
            var title = string.IsNullOrEmpty(SettingsModel.Command) ? "Command" : SettingsModel.Command;
            await Manager.SetTitleAsync(args.context, title);
        }

        public override async Task OnWillDisappear(StreamDeckEventPayload args)
        {
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

            // Update title when settings change
            var title = string.IsNullOrEmpty(SettingsModel.Command) ? "Command" : SettingsModel.Command;
            await Manager.SetTitleAsync(args.context, title);
        }

        // IWebSocketClient implementation
        public void OnConnectionStateChanged(bool connected)
        {
            // Can be used to update UI state
        }

        public void OnPlayerStatusReceived(PlayerStatusMessage playerStatus)
        {
            // Not needed for command action
        }

        public void OnPlayerJoined(PlayerJoinMessage playerJoin)
        {
            // Not needed for command action
        }

        public void OnPlayerLeft(PlayerLeaveMessage playerLeave)
        {
            // Not needed for command action
        }

        public void OnCommandResultReceived(CommandResultMessage result)
        {
            var message = result.Success
                ? LocalizationService.StatusMessages.CommandExecuted
                : LocalizationService.ErrorMessages.CommandExecutionFailed;
            Console.WriteLine($"{message}: {result.Message}");
        }

        public void OnErrorReceived(string error)
        {
            Console.WriteLine($"{LocalizationService.ErrorMessages.WebSocketError}: {error}");
        }
    }
}