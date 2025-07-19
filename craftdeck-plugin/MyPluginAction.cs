using StreamDeckLib;
using StreamDeckLib.Messages;
using System;
using System.Threading.Tasks;
using System.Timers;
using CraftDeck.StreamDeckPlugin.Services;
using CraftDeck.StreamDeckPlugin.Models;
using System.Linq;
using System.Collections.Generic;

namespace CraftDeck.StreamDeckPlugin
{
  [ActionUuid(Uuid="com.craftdeck.plugin.action.craftdeckaction")]
  public class MyPluginAction : BaseStreamDeckActionWithSettingsModel<Models.CraftDeckSettingsModel>
  {
    private static MinecraftWebSocketService _webSocketService;
    private static readonly List<MyPluginAction> _instances = new List<MyPluginAction>();
    private Timer _updateTimer;
    private PlayerStatusMessage _currentPlayerData;
    private bool _isConnected = false;

    static MyPluginAction()
    {
      _webSocketService = new MinecraftWebSocketService();
      _webSocketService.ConnectionStateChanged += OnConnectionStateChanged;
      _webSocketService.PlayerStatusReceived += OnPlayerStatusReceived;
      _webSocketService.CommandResultReceived += OnCommandResultReceived;
      _webSocketService.ErrorReceived += OnErrorReceived;
    }

    public MyPluginAction()
    {
      lock (_instances)
      {
        _instances.Add(this);
      }
    }

    public override async Task OnKeyUp(StreamDeckEventPayload args)
    {
      try
      {
        if (!_isConnected)
        {
          await _webSocketService.ConnectAsync();
          await Task.Delay(1000); // Wait for connection
        }

        if (_isConnected && !string.IsNullOrEmpty(SettingsModel.Command))
        {
          var success = await _webSocketService.SendCommandAsync(
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
        Console.WriteLine($"Error executing command: {ex.Message}");
      }
    }

    public override async Task OnDidReceiveSettings(StreamDeckEventPayload args)
    {
      await base.OnDidReceiveSettings(args);

      // Update WebSocket URL if changed
      if (_webSocketService != null && !string.IsNullOrEmpty(SettingsModel.ServerUrl))
      {
        // Reconnect with new URL if needed
        if (!_isConnected && SettingsModel.AutoConnect)
        {
          await _webSocketService.ConnectAsync();
        }
      }

      await UpdateDisplay(args.context);
    }

    public override async Task OnWillAppear(StreamDeckEventPayload args)
    {
      await base.OnWillAppear(args);

      // Start update timer for dynamic content
      _updateTimer = new Timer(1000); // Update every second
      _updateTimer.Elapsed += async (sender, e) => await UpdateDisplay(args.context);
      _updateTimer.Start();

      // Auto-connect if enabled
      if (SettingsModel.AutoConnect && !_isConnected)
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
        string title = "";
        string subtitle = "";

        if (!_isConnected)
        {
          title = "Disconnected";
          subtitle = "No connection";
        }
        else
        {
          switch (SettingsModel.DisplayMode?.ToLower())
          {
            case "health":
              if (_currentPlayerData != null)
              {
                title = $"❤️ {_currentPlayerData.Health:F0}/{_currentPlayerData.MaxHealth:F0}";
                subtitle = _currentPlayerData.Name;
              }
              else
              {
                title = "❤️ --/--";
                subtitle = "No player";
              }
              break;

            case "position":
              if (_currentPlayerData != null)
              {
                title = $"📍 {_currentPlayerData.Position.X:F0},{_currentPlayerData.Position.Y:F0},{_currentPlayerData.Position.Z:F0}";
                subtitle = _currentPlayerData.Name;
              }
              else
              {
                title = "📍 --,--,--";
                subtitle = "No player";
              }
              break;

            case "level":
              if (_currentPlayerData != null)
              {
                title = $"⭐ Lv.{_currentPlayerData.Level}";
                subtitle = $"{_currentPlayerData.Experience:P0}";
              }
              else
              {
                title = "⭐ Lv.--";
                subtitle = "No player";
              }
              break;

            case "command":
            default:
              title = string.IsNullOrEmpty(SettingsModel.Command) ? "No Command" : SettingsModel.Command;
              subtitle = _isConnected ? "Connected" : "Disconnected";
              break;
          }
        }

        await Manager.SetTitleAsync(context, title);
        await Manager.SetImageAsync(context, subtitle);
      }
      catch (Exception ex)
      {
        Console.WriteLine($"Error updating display: {ex.Message}");
      }
    }

    private static void OnConnectionStateChanged(bool connected)
    {
      // All instances need to update their connection state
      foreach (var instance in GetAllInstances())
      {
        instance._isConnected = connected;
      }
    }

    private static void OnPlayerStatusReceived(PlayerStatusMessage playerStatus)
    {
      // Update instances that are monitoring this player
      foreach (var instance in GetAllInstances())
      {
        if (string.IsNullOrEmpty(instance.SettingsModel.PlayerName) ||
            instance.SettingsModel.PlayerName.Equals(playerStatus.Name, StringComparison.OrdinalIgnoreCase))
        {
          instance._currentPlayerData = playerStatus;
        }
      }
    }

    private static List<MyPluginAction> GetAllInstances()
    {
      lock (_instances)
      {
        return _instances.ToList();
      }
    }

    private static void OnCommandResultReceived(CommandResultMessage result)
    {
      Console.WriteLine($"Command result: {result.Success} - {result.Message}");
    }

    private static void OnErrorReceived(string error)
    {
      Console.WriteLine($"WebSocket error: {error}");
    }

    public void Dispose()
    {
      _updateTimer?.Stop();
      _updateTimer?.Dispose();

      lock (_instances)
      {
        _instances.Remove(this);
      }
    }
  }
}
