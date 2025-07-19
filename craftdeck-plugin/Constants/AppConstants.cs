namespace CraftDeck.StreamDeckPlugin.Constants
{
    /// <summary>
    /// アプリケーション全体で使用される定数を管理
    /// </summary>
    public static class AppConstants
    {
        /// <summary>
        /// WebSocket接続関連の定数
        /// </summary>
        public static class WebSocket
        {
            /// <summary>
            /// デフォルトのWebSocketサーバーURL
            /// </summary>
            public const string DefaultServerUrl = "ws://localhost:8080";

            /// <summary>
            /// 接続タイムアウト時間（ミリ秒）
            /// </summary>
            public const int DefaultConnectionTimeout = 5000;

            /// <summary>
            /// 再接続試行間隔（ミリ秒）
            /// </summary>
            public const int ReconnectInterval = 3000;

            /// <summary>
            /// 最大再接続試行回数
            /// </summary>
            public const int MaxReconnectAttempts = 5;
        }

        /// <summary>
        /// UI更新関連の定数
        /// </summary>
        public static class UI
        {
            /// <summary>
            /// ヘルス監視の更新間隔（ミリ秒）
            /// </summary>
            public const int HealthUpdateInterval = 1000;

            /// <summary>
            /// 座標監視の更新間隔（ミリ秒）
            /// </summary>
            public const int PositionUpdateInterval = 500;

            /// <summary>
            /// レベル監視の更新間隔（ミリ秒）
            /// </summary>
            public const int LevelUpdateInterval = 1000;
        }

        /// <summary>
        /// プラグイン識別子関連の定数
        /// </summary>
        public static class Plugin
        {
            /// <summary>
            /// プラグインUUID
            /// </summary>
            public const string Uuid = "com.craftdeck.plugin";

            /// <summary>
            /// プラグイン名
            /// </summary>
            public const string Name = "CraftDeck";

            /// <summary>
            /// バージョン
            /// </summary>
            public const string Version = "1.0.0";
        }

        /// <summary>
        /// アクションUUID定数
        /// </summary>
        public static class Actions
        {
            /// <summary>
            /// コマンドアクション
            /// </summary>
            public const string Command = "com.craftdeck.plugin.action.command";

            /// <summary>
            /// 汎用プレイヤーモニターアクション
            /// </summary>
            public const string PlayerMonitor = "com.craftdeck.plugin.action.playermonitor";
        }

        /// <summary>
        /// デフォルト表示フォーマット
        /// </summary>
        public static class DefaultFormats
        {
            /// <summary>
            /// ヘルス表示のデフォルトフォーマット
            /// </summary>
            public const string Health = "❤️ {health}/{maxHealth}";

            /// <summary>
            /// レベル表示のデフォルトフォーマット
            /// </summary>
            public const string Level = "⭐ Lv.{level} ({experience}%)";

            /// <summary>
            /// 座標表示のデフォルトフォーマット
            /// </summary>
            public const string Position = "📍 {x}, {y}, {z}";
        }

        /// <summary>
        /// 言語設定関連の定数
        /// </summary>
        public static class Languages
        {
            /// <summary>
            /// 自動検出
            /// </summary>
            public const string Auto = "auto";

            /// <summary>
            /// 英語
            /// </summary>
            public const string English = "en";

            /// <summary>
            /// 日本語
            /// </summary>
            public const string Japanese = "ja";

            /// <summary>
            /// サポート言語一覧
            /// </summary>
            public static readonly string[] Supported = { English, Japanese };
        }

        /// <summary>
        /// ファイル・ディレクトリパス関連の定数
        /// </summary>
        public static class Paths
        {
            /// <summary>
            /// グローバル設定ディレクトリ名
            /// </summary>
            public const string GlobalSettingsDirectory = "CraftDeck";

            /// <summary>
            /// StreamDeckプラグインサブディレクトリ名
            /// </summary>
            public const string PluginSubDirectory = "StreamDeckPlugin";

            /// <summary>
            /// グローバル設定ファイル名
            /// </summary>
            public const string GlobalSettingsFileName = "GlobalSettings.json";

            /// <summary>
            /// ローカライゼーションファイル名
            /// </summary>
            public const string LocalizationFileName = "Localization.json";
        }

        /// <summary>
        /// ログ関連の定数
        /// </summary>
        public static class Logging
        {
            /// <summary>
            /// デフォルトログレベル
            /// </summary>
            public const string DefaultLogLevel = "Information";

            /// <summary>
            /// ログファイル最大サイズ（MB）
            /// </summary>
            public const int MaxLogFileSizeMB = 10;

            /// <summary>
            /// ログファイル保持日数
            /// </summary>
            public const int LogRetentionDays = 7;
        }
    }
}