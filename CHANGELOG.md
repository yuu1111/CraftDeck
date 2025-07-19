# Changelog

All notable changes to CraftDeck will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release planning

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.0.0] - 2024-01-XX

### Added
- **Minecraft Mod (Architectury)**
  - Multi-platform support (Fabric, Forge, Quilt)
  - WebSocket server for real-time communication
  - Player data collection (health, position, level, gamemode)
  - Command execution from external clients
  - `/craftdeck status` and `/craftdeck test` commands
  - Automatic server lifecycle management with shutdown hooks

- **StreamDeck Plugin (C#/.NET 6)**
  - Real-time player monitoring (health, level, position)
  - Custom command execution buttons
  - Multi-language support (English, Japanese)
  - Configurable display formats
  - Auto-reconnection functionality
  - Property inspector for easy configuration

- **WebSocket Communication Protocol**
  - JSON-based message format
  - Bidirectional communication on port 8080
  - Message types: connection, player_status, player_data, execute_command, command_result
  - Error handling and validation

- **Development Tools**
  - PowerShell build scripts for automated deployment
  - Solution-level build configuration
  - Debug auto-deployment for StreamDeck plugin

### Technical Details
- **Minecraft Mod**: Kotlin + Architectury 3.4, Java-WebSocket 1.5.3
- **StreamDeck Plugin**: C# .NET 6, StreamDeckLib 0.5.2040, Newtonsoft.Json
- **Supported Minecraft Versions**: [To be specified]
- **Supported StreamDeck Software**: Stream Deck 6.0+

### Known Limitations
- Port 8080 is hardcoded (configuration system planned for future release)
- Basic echo functionality in initial implementation
- Single-server support only

---

## Version History Guidelines

### Version Format
- **Major.Minor.Patch** (e.g., 1.0.0)
- Major: Breaking changes or significant new features
- Minor: New features, backward compatible
- Patch: Bug fixes, small improvements

### Change Categories
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Release Notes
Each release includes:
- Compatibility information
- Installation/upgrade instructions
- Known issues and workarounds
- Performance improvements
- Breaking changes (if any)