using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using CraftDeck.StreamDeckPlugin.Models;

namespace CraftDeck.StreamDeckPlugin.Services
{
    public static class DisplayFormatService
    {
        private static readonly Regex PlaceholderRegex = new Regex(@"\{([^}]+)\}", RegexOptions.Compiled);

        /// <summary>
        /// Health用のデフォルトフォーマット
        /// </summary>
        public static readonly string DefaultHealthFormat = "❤️ {health}/{maxHealth}";

        /// <summary>
        /// Position用のデフォルトフォーマット
        /// </summary>
        public static readonly string DefaultPositionFormat = "📍 {x}, {y}, {z}";

        /// <summary>
        /// Level用のデフォルトフォーマット
        /// </summary>
        public static readonly string DefaultLevelFormat = "⭐ Lv.{level} ({experience}%)";

        /// <summary>
        /// プレイヤーデータとフォーマット文字列から表示文字列を生成
        /// </summary>
        public static string FormatPlayerData(string format, PlayerStatusMessage playerData)
        {
            if (string.IsNullOrEmpty(format) || playerData == null)
                return "";

            var placeholders = new Dictionary<string, Func<string>>
            {
                ["health"] = () => playerData.Health.ToString("F0"),
                ["maxHealth"] = () => playerData.MaxHealth.ToString("F0"),
                ["healthPercent"] = () => Math.Round((playerData.Health / playerData.MaxHealth) * 100).ToString("F0"),
                ["food"] = () => playerData.Food.ToString("F0"),
                ["foodPercent"] = () => Math.Round((playerData.Food / 20.0) * 100).ToString("F0"),
                ["level"] = () => playerData.Level.ToString(),
                ["experience"] = () => Math.Round(playerData.Experience * 100).ToString("F0"),
                ["x"] = () => playerData.Position?.X.ToString("F0") ?? "0",
                ["y"] = () => playerData.Position?.Y.ToString("F0") ?? "0",
                ["z"] = () => playerData.Position?.Z.ToString("F0") ?? "0",
                ["gamemode"] = () => playerData.GameMode,
                ["dimension"] = () => playerData.Dimension,
                ["name"] = () => playerData.Name
            };

            return PlaceholderRegex.Replace(format, match =>
            {
                var placeholder = match.Groups[1].Value.ToLower();
                return placeholders.ContainsKey(placeholder) ? placeholders[placeholder]() : match.Value;
            });
        }

        /// <summary>
        /// オフライン時の表示文字列を生成
        /// </summary>
        public static string FormatOfflineMessage(string format, string defaultIcon = "❓")
        {
            if (string.IsNullOrEmpty(format))
                return $"{defaultIcon} Offline";

            // プレースホルダーを"--"で置換
            return PlaceholderRegex.Replace(format, "--");
        }

        /// <summary>
        /// データなし時の表示文字列を生成
        /// </summary>
        public static string FormatNoDataMessage(string format, string defaultIcon = "❓")
        {
            if (string.IsNullOrEmpty(format))
                return $"{defaultIcon} --";

            // プレースホルダーを"--"で置換
            return PlaceholderRegex.Replace(format, "--");
        }

        /// <summary>
        /// 利用可能なプレースホルダーの一覧を取得
        /// </summary>
        public static Dictionary<string, string> GetAvailablePlaceholders()
        {
            return new Dictionary<string, string>
            {
                ["{health}"] = "現在のヘルス",
                ["{maxHealth}"] = "最大ヘルス",
                ["{healthPercent}"] = "ヘルス割合(%)",
                ["{food}"] = "現在の満腹度",
                ["{foodPercent}"] = "満腹度割合(%)",
                ["{level}"] = "経験値レベル",
                ["{experience}"] = "現在レベルの経験値(%)",
                ["{x}"] = "X座標",
                ["{y}"] = "Y座標",
                ["{z}"] = "Z座標",
                ["{gamemode}"] = "ゲームモード",
                ["{dimension}"] = "ディメンション",
                ["{name}"] = "プレイヤー名"
            };
        }
    }
}