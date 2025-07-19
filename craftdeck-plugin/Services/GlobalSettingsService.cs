using System;
using System.IO;
using System.Threading.Tasks;
using Newtonsoft.Json;
using CraftDeck.StreamDeckPlugin.Constants;

namespace CraftDeck.StreamDeckPlugin.Services
{
    /// <summary>
    /// プラグイン全体で共有されるグローバル設定を管理
    /// </summary>
    public static class GlobalSettingsService
    {
        private static GlobalSettings _settings;
        private static readonly string _settingsFilePath;
        private static readonly object _lock = new object();

        static GlobalSettingsService()
        {
            // AppDataフォルダにプラグイン専用ディレクトリを作成
            var appDataPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            var pluginDataPath = Path.Combine(appDataPath,
                AppConstants.Paths.GlobalSettingsDirectory,
                AppConstants.Paths.PluginSubDirectory);

            if (!Directory.Exists(pluginDataPath))
            {
                Directory.CreateDirectory(pluginDataPath);
            }

            _settingsFilePath = Path.Combine(pluginDataPath, AppConstants.Paths.GlobalSettingsFileName);
            LoadSettings();
        }

        /// <summary>
        /// グローバル設定データ
        /// </summary>
        public class GlobalSettings
        {
            public string ServerUrl { get; set; } = AppConstants.WebSocket.DefaultServerUrl;
            public string DefaultLanguage { get; set; } = AppConstants.Languages.Auto;
            public bool AutoConnect { get; set; } = true;
            public int ConnectionTimeout { get; set; } = AppConstants.WebSocket.DefaultConnectionTimeout;
            public bool EnableLogging { get; set; } = true;
        }

        /// <summary>
        /// 現在のグローバル設定を取得
        /// </summary>
        public static GlobalSettings Current
        {
            get
            {
                lock (_lock)
                {
                    return _settings ?? (_settings = new GlobalSettings());
                }
            }
        }

        /// <summary>
        /// 設定をファイルから読み込み
        /// </summary>
        private static void LoadSettings()
        {
            try
            {
                if (File.Exists(_settingsFilePath))
                {
                    var json = File.ReadAllText(_settingsFilePath);
                    _settings = JsonConvert.DeserializeObject<GlobalSettings>(json) ?? new GlobalSettings();
                    Console.WriteLine($"Global settings loaded from: {_settingsFilePath}");
                }
                else
                {
                    _settings = new GlobalSettings();
                    Console.WriteLine("Global settings initialized with defaults");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading global settings: {ex.Message}");
                _settings = new GlobalSettings();
            }
        }

        /// <summary>
        /// 設定をファイルに保存
        /// </summary>
        public static async Task SaveSettingsAsync()
        {
            try
            {
                lock (_lock)
                {
                    var json = JsonConvert.SerializeObject(_settings, Formatting.Indented);
                    File.WriteAllText(_settingsFilePath, json);
                }
                Console.WriteLine($"Global settings saved to: {_settingsFilePath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving global settings: {ex.Message}");
            }
        }

        /// <summary>
        /// サーバーURLを更新
        /// </summary>
        public static async Task SetServerUrlAsync(string serverUrl)
        {
            if (string.IsNullOrEmpty(serverUrl))
                return;

            lock (_lock)
            {
                _settings.ServerUrl = serverUrl;
            }

            await SaveSettingsAsync();

            // SharedWebSocketManagerに変更を通知
            SharedWebSocketManager.UpdateServerUrl(serverUrl);
        }

        /// <summary>
        /// デフォルト言語を更新
        /// </summary>
        public static async Task SetDefaultLanguageAsync(string language)
        {
            if (string.IsNullOrEmpty(language))
                return;

            lock (_lock)
            {
                _settings.DefaultLanguage = language;
            }

            await SaveSettingsAsync();

            // LocalizationServiceに適用
            LocalizationService.SetLanguage(language);
        }

        /// <summary>
        /// 自動接続設定を更新
        /// </summary>
        public static async Task SetAutoConnectAsync(bool autoConnect)
        {
            lock (_lock)
            {
                _settings.AutoConnect = autoConnect;
            }

            await SaveSettingsAsync();
        }

        /// <summary>
        /// 現在のサーバーURLを取得
        /// </summary>
        public static string GetServerUrl()
        {
            return Current.ServerUrl;
        }

        /// <summary>
        /// 現在のデフォルト言語を取得
        /// </summary>
        public static string GetDefaultLanguage()
        {
            return Current.DefaultLanguage;
        }

        /// <summary>
        /// 自動接続設定を取得
        /// </summary>
        public static bool GetAutoConnect()
        {
            return Current.AutoConnect;
        }

        /// <summary>
        /// 設定をリセット
        /// </summary>
        public static async Task ResetToDefaultsAsync()
        {
            lock (_lock)
            {
                _settings = new GlobalSettings();
            }

            await SaveSettingsAsync();
            Console.WriteLine("Global settings reset to defaults");
        }

        /// <summary>
        /// 設定変更イベント
        /// </summary>
        public static event Action<GlobalSettings> SettingsChanged;

        /// <summary>
        /// 設定変更を通知
        /// </summary>
        private static void NotifySettingsChanged()
        {
            SettingsChanged?.Invoke(Current);
        }
    }
}