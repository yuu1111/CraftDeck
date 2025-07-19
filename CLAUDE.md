# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CraftDeck is a dual-component system that enables real-time communication between Minecraft and StreamDeck devices. The system consists of:

1. **Minecraft Mod** (Kotlin/Architectury) - WebSocket server that sends game data and receives commands
2. **StreamDeck Plugin** (C#/.NET 6) - WebSocket client that displays game info and sends commands

The two components communicate via WebSocket using JSON protocol on port 8080 (configurable).

## Development Commands

### Minecraft Mod (Architectury/Kotlin)
```bash
# Navigate to craftdeck-mod directory
cd craftdeck-mod

# Build all mod variants using PowerShell Core (pwsh) script (recommended)
pwsh -ExecutionPolicy Bypass -File "../scripts/Build-Mod.ps1"

# Or build directly with Gradle
./gradlew build

# Run specific platform development
./gradlew :fabric:runClient    # Fabric development client
./gradlew :forge:runClient     # Forge development client
./gradlew :quilt:runClient     # Quilt development client

# Clean build
./gradlew clean

# Generate sources JAR
./gradlew sourcesJar
```

**Note**: Use PowerShell Core (pwsh) instead of Windows PowerShell for cross-platform compatibility. The build script automatically detects and allows selection of Java environments when multiple versions are installed.

### StreamDeck Plugin (C#/.NET)
```bash
# Navigate to craftdeck-plugin directory
cd craftdeck-plugin

# Build and auto-deploy to StreamDeck (Debug mode)
dotnet build

# Build Release version
dotnet build -c Release

# Publish self-contained executable
dotnet publish -c Release --self-contained

# Manual registration (PowerShell)
powershell -ExecutionPolicy Unrestricted -file "RegisterPluginAndStartStreamDeck.ps1"
```

### Solution-level Commands
```bash
# Build entire solution
dotnet build CraftDeckSolution.sln

# Build specific configuration
dotnet build CraftDeckSolution.sln -c Release
```

## Architecture

### Minecraft Mod Structure (Architectury Multi-Platform)
- **common/**: Shared code across all mod loaders
  - `CraftDeckMod.kt`: Main mod entry point, WebSocket server lifecycle
  - `WebSocketServer.kt`: WebSocket communication implementation
- **fabric/**: Fabric-specific implementation
- **forge/**: Forge-specific implementation
- **quilt/**: Quilt-specific implementation

Each platform has its own entry point that calls into the common module.

### StreamDeck Plugin Structure
- **Program.cs**: Entry point using StreamDeckLib framework
- **MyPluginAction.cs**: Main action handler with UUID `com.craftdeck.plugin.action.craftdeckaction`
- **models/**: Settings model classes
- **property_inspector/**: HTML/CSS/JS for plugin configuration UI
- **images/**: Required StreamDeck icons and graphics

### Communication Protocol
- **Transport**: WebSocket over localhost:8080
- **Format**: JSON messages
- **Direction**: Bidirectional
- **Mod → Plugin**: Game state updates (player status, inventory, world info)
- **Plugin → Mod**: Command execution requests

Key message types:
- `player_status`: Health, coordinates, experience, gamemode
- `inventory_slot`: Item details with durability and enchantments
- `execute_command`: Command execution from StreamDeck to Minecraft

### Key Dependencies
- **Mod**: Java-WebSocket 1.5.3, Kotlin 1.8.22, Architectury 3.4
- **Plugin**: StreamDeckLib 0.5.2040, System.Net.WebSockets.Client, Newtonsoft.Json

## Development Workflow

1. **Mod Development**: Use `./gradlew :fabric:runClient` for fastest iteration
2. **Plugin Development**: Debug builds auto-deploy to StreamDeck via post-build event
3. **Testing**: Start Minecraft with mod, then launch StreamDeck with plugin loaded
4. **Port Configuration**: Currently hardcoded to 8080, will need configuration system

## Build Artifacts

### Minecraft Mod
- Multi-platform JARs in `build/libs/` for each platform
- Common JAR contains shared Kotlin code
- Platform-specific JARs contain loader integrations

### StreamDeck Plugin
- Self-contained executable in `publish/`
- Includes all required assets (manifest.json, images, property inspector)
- Auto-registration scripts for development deployment

## Important Notes

- Mod uses shutdown hooks for proper WebSocket server cleanup
- Plugin targets Windows x64 specifically (`win-x64` runtime)
- Property inspector provides web-based configuration UI
- Current implementation is MVP-level with basic echo functionality
- Project structure supports future expansion to server-side monitoring