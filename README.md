# CraftDeck

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Java](https://img.shields.io/badge/Java-17+-orange.svg)](https://www.oracle.com/java/)
[![.NET](https://img.shields.io/badge/.NET-6.0+-purple.svg)](https://dotnet.microsoft.com/)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.19+-green.svg)](https://minecraft.net/)

A real-time bridge between Minecraft and Elgato Stream Deck, enabling interactive game monitoring and control directly from your Stream Deck device.

[日本語版 README](README-JP.md) | [Documentation](../../wiki) | [Contributing](CONTRIBUTING.md)

## 🎮 Features

- **Real-time Game Data**: Display player health, coordinates, experience, inventory, and more
- **Interactive Commands**: Execute Minecraft commands directly from Stream Deck buttons
- **Multi-Platform Support**: Works with Fabric, Forge, and Quilt mod loaders
- **Customizable Interface**: Configure what information appears on each Stream Deck key
- **Low Latency**: WebSocket-based communication for instant updates
- **Easy Setup**: Simple installation process for both Minecraft mod and Stream Deck plugin

## 📋 Requirements

### Minecraft Mod
- Minecraft 1.19.2 or later
- Java 17 or later
- One of the following mod loaders:
  - Fabric Loader 0.14+
  - Forge 43.2+
  - Quilt Loader 0.17+

### Stream Deck Plugin
- Windows 10/11 (x64)
- Elgato Stream Deck Software 6.0+
- .NET 6.0 Runtime
- Elgato Stream Deck device (any model)

## 🚀 Installation

### Minecraft Mod Installation

1. **Download the mod JAR** for your mod loader from [Releases](../../releases)
2. **Install your mod loader** (Fabric/Forge/Quilt) if not already installed
3. **Place the JAR file** in your `mods` folder
4. **Start Minecraft** - the mod will automatically start the WebSocket server on port 8080

### Stream Deck Plugin Installation

1. **Download** `CraftDeck.streamDeckPlugin` from [Releases](../../releases)
2. **Double-click** the file to install it automatically
3. **Add the CraftDeck action** to any Stream Deck key
4. **Configure connection settings** in the property inspector if needed

## 🔧 Configuration

### Minecraft Mod Configuration
The mod will create a configuration file at `config/craftdeck.json`:

```json
{
  "port": 8080,
  "host": "localhost",
  "enableLogging": true,
  "updateInterval": 1000
}
```

### Stream Deck Plugin Configuration
Configure each Stream Deck key through the property inspector:

- **Connection Settings**: Server host and port
- **Display Options**: Choose what game data to show
- **Command Settings**: Set up custom Minecraft commands
- **Update Frequency**: Control how often data refreshes

## 📡 Communication Protocol

CraftDeck uses WebSocket communication with JSON messages:

### Game Data Messages (Mod → Plugin)
```json
{
  "type": "player_status",
  "data": {
    "health": 20,
    "food": 20,
    "experience": 1250,
    "level": 30,
    "gameMode": "SURVIVAL",
    "position": {
      "x": 125.5,
      "y": 64.0,
      "z": -89.2,
      "dimension": "minecraft:overworld"
    }
  }
}
```

### Command Messages (Plugin → Mod)
```json
{
  "type": "execute_command",
  "data": {
    "command": "time set day",
    "requireOp": true
  }
}
```

## 🛠️ Development

### Building from Source

#### Minecraft Mod
```bash
cd craftdeck-mod
./gradlew build
```

#### Stream Deck Plugin
```bash
cd craftdeck-plugin
dotnet build -c Release
```

### Development Setup
See our [Developer Guide](../../wiki/Developer-Guide) for detailed setup instructions.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code style and conventions
- Submitting bug reports
- Proposing new features
- Creating pull requests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Issue Reporting

Found a bug or have a feature request? Please check our [issue tracker](../../issues) and create a new issue if needed.

## 🔗 Links

- **Documentation**: [GitHub Wiki](../../wiki)
- **Releases**: [Latest Downloads](../../releases)
- **Issue Tracker**: [Report Bugs](../../issues)
- **Discussions**: [Community Forum](../../discussions)

## ⭐ Support

If you find CraftDeck useful, please consider:
- ⭐ Starring this repository
- 🐛 Reporting bugs and suggesting improvements
- 🤝 Contributing code or documentation
- 💬 Sharing with the Minecraft and Stream Deck communities

---

**Made with ❤️ for the Minecraft and Stream Deck communities**