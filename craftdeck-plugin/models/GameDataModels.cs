using Newtonsoft.Json;
using System.Collections.Generic;

namespace CraftDeck.StreamDeckPlugin.Models
{
    // Base message class
    public class WebSocketMessage
    {
        [JsonProperty("type")]
        public string Type { get; set; }
    }

    // Messages from Minecraft Mod to Plugin
    public class ConnectionMessage : WebSocketMessage
    {
        [JsonProperty("status")]
        public string Status { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }
    }

    public class PlayerStatusMessage : WebSocketMessage
    {
        [JsonProperty("uuid")]
        public string Uuid { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("health")]
        public float Health { get; set; }

        [JsonProperty("max_health")]
        public float MaxHealth { get; set; }

        [JsonProperty("food")]
        public int Food { get; set; }

        [JsonProperty("experience")]
        public float Experience { get; set; }

        [JsonProperty("level")]
        public int Level { get; set; }

        [JsonProperty("gamemode")]
        public string GameMode { get; set; }

        [JsonProperty("position")]
        public Position Position { get; set; }

        [JsonProperty("dimension")]
        public string Dimension { get; set; }
    }

    public class Position
    {
        [JsonProperty("x")]
        public double X { get; set; }

        [JsonProperty("y")]
        public double Y { get; set; }

        [JsonProperty("z")]
        public double Z { get; set; }
    }

    public class PlayerJoinMessage : WebSocketMessage
    {
        [JsonProperty("player")]
        public string Player { get; set; }

        [JsonProperty("uuid")]
        public string Uuid { get; set; }
    }

    public class PlayerLeaveMessage : WebSocketMessage
    {
        [JsonProperty("player")]
        public string Player { get; set; }

        [JsonProperty("uuid")]
        public string Uuid { get; set; }
    }

    public class PlayerDataMessage : WebSocketMessage
    {
        [JsonProperty("players")]
        public List<PlayerStatusMessage> Players { get; set; } = new List<PlayerStatusMessage>();
    }

    public class CommandResultMessage : WebSocketMessage
    {
        [JsonProperty("success")]
        public bool Success { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }

        [JsonProperty("result")]
        public int Result { get; set; }
    }

    public class ErrorMessage : WebSocketMessage
    {
        [JsonProperty("message")]
        public string Message { get; set; }
    }

    // Messages from Plugin to Minecraft Mod
    public class ExecuteCommandMessage : WebSocketMessage
    {
        [JsonProperty("command")]
        public string Command { get; set; }

        [JsonProperty("player")]
        public string Player { get; set; }

        public ExecuteCommandMessage()
        {
            Type = "execute_command";
        }
    }

    public class GetPlayerDataMessage : WebSocketMessage
    {
        public GetPlayerDataMessage()
        {
            Type = "get_player_data";
        }
    }
}