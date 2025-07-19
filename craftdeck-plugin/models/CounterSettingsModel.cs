using CraftDeck.StreamDeckPlugin.Constants;

namespace CraftDeck.StreamDeckPlugin.Models
{
  public class CraftDeckSettingsModel
  {
    public string Command { get; set; } = "";
    public string PlayerName { get; set; } = "";
    public string DisplayMode { get; set; } = "command"; // "command", "health", "position", "level"
    public string ServerUrl { get; set; } = AppConstants.WebSocket.DefaultServerUrl;
    public bool AutoConnect { get; set; } = true;
  }

  // Command action specific settings
  public class CommandSettingsModel
  {
    public string Command { get; set; } = "";
    public string PlayerName { get; set; } = "";
    public string ServerUrl { get; set; } = AppConstants.WebSocket.DefaultServerUrl;
    public string Language { get; set; } = AppConstants.Languages.English;
  }

  // Player monitoring specific settings
  public class PlayerMonitorSettingsModel
  {
    public string PlayerName { get; set; } = "";
    public string ServerUrl { get; set; } = AppConstants.WebSocket.DefaultServerUrl;
    public bool AutoConnect { get; set; } = true;
    public string DisplayFormat { get; set; } = "";
    public string Language { get; set; } = AppConstants.Languages.English;
  }

  // Keep the old model for backward compatibility
  public class CounterSettingsModel
  {
	public int Counter { get; set; } = 0;
  }
}
