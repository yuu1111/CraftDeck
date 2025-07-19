using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CraftDeck.StreamDeckPlugin.Services
{
    public static class LocalizationService
    {
        private static JObject _localizationData;
        private static string _currentLanguage = "en";

        static LocalizationService()
        {
            LoadLocalizationData();
            DetectSystemLanguage();
        }

        /// <summary>
        /// ローカライゼーションデータをロード（フォールバックデータのみ）
        /// </summary>
        private static void LoadLocalizationData()
        {
            // 現在は en.json と ja.json を使用しているため、フォールバックのみ提供
            CreateFallbackData();
        }

        /// <summary>
        /// フォールバック用の基本データを作成
        /// </summary>
        private static void CreateFallbackData()
        {
            _localizationData = JObject.Parse(@"{
                ""en"": {
                    ""common"": {
                        ""offline"": ""Offline"",
                        ""noData"": ""No Data""
                    },
                    ""health"": {
                        ""offline"": ""❤️ Offline"",
                        ""noData"": ""❤️ --/--""
                    }
                },
                ""ja"": {
                    ""common"": {
                        ""offline"": ""オフライン"",
                        ""noData"": ""データなし""
                    },
                    ""health"": {
                        ""offline"": ""❤️ オフライン"",
                        ""noData"": ""❤️ --/--""
                    }
                }
            }");
        }

        /// <summary>
        /// システムの言語設定を自動検出
        /// </summary>
        private static void DetectSystemLanguage()
        {
            try
            {
                var culture = CultureInfo.CurrentUICulture;
                var languageCode = culture.TwoLetterISOLanguageName.ToLower();

                Console.WriteLine($"System language detected: {languageCode} ({culture.Name})");

                // サポートされている言語の場合は自動設定
                var supportedLanguages = new[] { "en", "ja" };
                if (Array.IndexOf(supportedLanguages, languageCode) >= 0)
                {
                    _currentLanguage = languageCode;
                    Console.WriteLine($"Auto-setting language to: {_currentLanguage}");
                }
                else
                {
                    Console.WriteLine($"Language '{languageCode}' not supported, using default: {_currentLanguage}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error detecting system language: {ex.Message}");
            }
        }

        /// <summary>
        /// 現在の言語を設定
        /// </summary>
        public static void SetLanguage(string language)
        {
            if (string.IsNullOrEmpty(language))
                return;

            // "auto"の場合はシステム言語自動検出を再実行
            if (language.ToLower() == "auto")
            {
                DetectSystemLanguage();
                return;
            }

            var supportedLanguages = new[] { "en", "ja" };
            if (Array.IndexOf(supportedLanguages, language.ToLower()) >= 0)
            {
                _currentLanguage = language.ToLower();
                Console.WriteLine($"Language manually set to: {_currentLanguage}");
            }
        }

        /// <summary>
        /// 現在の言語を取得
        /// </summary>
        public static string GetCurrentLanguage()
        {
            return _currentLanguage;
        }

        /// <summary>
        /// サポート言語一覧を取得
        /// </summary>
        public static Dictionary<string, string> GetSupportedLanguages()
        {
            return new Dictionary<string, string>
            {
                ["en"] = "English",
                ["ja"] = "日本語"
            };
        }

        /// <summary>
        /// ローカライズされた文字列を取得
        /// </summary>
        public static string Get(string key, string fallback = null)
        {
            try
            {
                if (_localizationData == null)
                    return fallback ?? key;

                var languageData = _localizationData[_currentLanguage];
                if (languageData == null)
                {
                    // フォールバック: 英語を試す
                    languageData = _localizationData["en"];
                    if (languageData == null)
                        return fallback ?? key;
                }

                var parts = key.Split('.');
                JToken current = languageData;

                foreach (var part in parts)
                {
                    current = current[part];
                    if (current == null)
                        break;
                }

                return current?.ToString() ?? fallback ?? key;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting localized string for key '{key}': {ex.Message}");
                return fallback ?? key;
            }
        }

        /// <summary>
        /// プレースホルダー付きのローカライズされた文字列を取得
        /// </summary>
        public static string Get(string key, Dictionary<string, string> placeholders, string fallback = null)
        {
            var text = Get(key, fallback);

            if (placeholders != null)
            {
                foreach (var placeholder in placeholders)
                {
                    text = text.Replace($"{{{placeholder.Key}}}", placeholder.Value);
                }
            }

            return text;
        }

        /// <summary>
        /// ヘルス表示用の文字列を取得
        /// </summary>
        public static class Health
        {
            public static string Offline => Get("health.offline");
            public static string NoData => Get("health.noData");
            public static string DefaultFormat => Get("health.defaultFormat");
        }

        /// <summary>
        /// レベル表示用の文字列を取得
        /// </summary>
        public static class Level
        {
            public static string Offline => Get("level.offline");
            public static string NoData => Get("level.noData");
            public static string DefaultFormat => Get("level.defaultFormat");
        }

        /// <summary>
        /// 座標表示用の文字列を取得
        /// </summary>
        public static class Position
        {
            public static string Offline => Get("position.offline");
            public static string NoData => Get("position.noData");
            public static string DefaultFormat => Get("position.defaultFormat");
        }

        /// <summary>
        /// コマンド実行用の文字列を取得
        /// </summary>
        public static class Command
        {
            public static string Executing => Get("command.executing");
            public static string Success => Get("command.success");
            public static string Failed => Get("command.failed");
            public static string Offline => Get("command.offline");
        }

        /// <summary>
        /// 共通文字列を取得
        /// </summary>
        public static class Common
        {
            public static string Offline => Get("common.offline");
            public static string NoData => Get("common.noData");
            public static string Connecting => Get("common.connecting");
            public static string Connected => Get("common.connected");
            public static string Disconnected => Get("common.disconnected");
        }
    }
}