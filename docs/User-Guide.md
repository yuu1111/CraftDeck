# CraftDeck User Guide

Welcome to CraftDeck! This guide will help you set up and use the CraftDeck system to connect your Minecraft gameplay with your StreamDeck device.

## Table of Contents
1. [What is CraftDeck?](#what-is-craftdeck)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Quick Setup](#quick-setup)
5. [Using CraftDeck](#using-craftdeck)
6. [Configuration](#configuration)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

## What is CraftDeck?

CraftDeck is a dual-component system that creates a real-time bridge between Minecraft and your Elgato StreamDeck device. It consists of:

- **Minecraft Mod**: Runs inside Minecraft and broadcasts game data via WebSocket
- **StreamDeck Plugin**: Receives game data and displays it on your StreamDeck buttons

### Features
- **Real-time Player Monitoring**: Display health, level, position, and gamemode
- **Command Execution**: Execute Minecraft commands directly from StreamDeck
- **Multi-Language Support**: English and Japanese interfaces
- **Cross-Platform**: Supports Fabric, Forge, and Quilt mod loaders
- **Customizable Display**: Configure what information is shown and how

## Prerequisites

### Minecraft Requirements
- **Minecraft Java Edition**: Version 1.20+ (specific versions may vary)
- **Mod Loader**: One of the following:
  - Fabric Loader 0.14.21+
  - Forge 47.1.0+
  - Quilt Loader (latest)

### StreamDeck Requirements
- **Hardware**: Any Elgato StreamDeck device
- **Software**: StreamDeck Software 6.0+
- **Operating System**: Windows 10/11 (primary support)

### System Requirements
- **Network**: Local network access (mod and plugin run on same machine)
- **Ports**: Port 8080 must be available for WebSocket communication

## Installation

### Step 1: Install the Minecraft Mod

1. **Download the Mod**
   - Go to the [CraftDeck Releases](https://github.com/[username]/craftdeck/releases) page
   - Download the appropriate JAR file for your mod loader:
     - `craftdeck-fabric-x.x.x.jar` for Fabric
     - `craftdeck-forge-x.x.x.jar` for Forge
     - `craftdeck-quilt-x.x.x.jar` for Quilt

2. **Install the Mod**
   - Place the JAR file in your Minecraft `mods` folder
   - The mod folder is typically located at:
     - Windows: `%APPDATA%\.minecraft\mods`
     - macOS: `~/Library/Application Support/minecraft/mods`
     - Linux: `~/.minecraft/mods`

3. **Verify Installation**
   - Launch Minecraft with your mod loader
   - Check the mod list to ensure CraftDeck is loaded
   - Look for CraftDeck startup messages in the game log

### Step 2: Install the StreamDeck Plugin

1. **Download the Plugin**
   - Download `craftdeck-plugin-x.x.x.streamDeckPlugin` from the releases page

2. **Install the Plugin**
   - Double-click the `.streamDeckPlugin` file
   - StreamDeck Software will automatically install the plugin
   - Restart StreamDeck Software if prompted

3. **Verify Installation**
   - Open StreamDeck Software
   - Look for CraftDeck actions in the actions library
   - You should see categories like "CraftDeck" with various actions

## Quick Setup

### Step 1: Start Minecraft
1. Launch Minecraft with the CraftDeck mod installed
2. Create or load a world (single-player or multi-player)
3. Verify the mod is running by typing `/craftdeck status` in chat
4. You should see connection information and player count

### Step 2: Configure StreamDeck

1. **Add a Player Monitor Action**
   - Open StreamDeck Software
   - Drag "Player Monitor" from CraftDeck category to a button
   - The button should show "Connecting..." initially

2. **Configure the Action**
   - Click the button in StreamDeck Software to open settings
   - Set your player name (optional - defaults to current player)
   - Choose display format (Health, Level, Position)
   - Select language preference

3. **Test Connection**
   - Start Minecraft and join a world
   - The StreamDeck button should update with your player data
   - Health, level, or position should be displayed based on your configuration

### Step 3: Add Command Actions

1. **Add a Command Action**
   - Drag "Command Executor" to another button
   - Configure the command you want to execute
   - Example commands: `/time set day`, `/gamemode creative`, `/tp 0 100 0`

2. **Test Commands**
   - Press the command button on your StreamDeck
   - The command should execute in Minecraft
   - Check the game chat for command results

## Using CraftDeck

### Player Monitoring

The Player Monitor actions display real-time information about your Minecraft character:

**Health Monitor**
- Shows current health and maximum health
- Updates in real-time as you take damage or heal
- Displays health icons and percentages

**Level Monitor**
- Shows current experience level
- Updates when you gain or lose experience
- Displays level number and progress

**Position Monitor**
- Shows current coordinates (X, Y, Z)
- Updates as you move around the world
- Displays dimension information

### Command Execution

Command actions let you execute Minecraft commands with a button press:

**Common Use Cases**
- Quick time changes (`/time set day`, `/time set night`)
- Gamemode switches (`/gamemode creative`, `/gamemode survival`)
- Teleportation (`/tp 0 100 0`, `/spawn`)
- Weather control (`/weather clear`, `/weather rain`)

**Command Syntax**
- Use standard Minecraft command syntax
- Do not include the leading `/` in the configuration
- Commands execute with your player's permission level

### Multi-Language Support

CraftDeck supports multiple languages for the interface:

**Supported Languages**
- English (en)
- Japanese (ja)

**Changing Language**
1. Click on any CraftDeck action in StreamDeck Software
2. Open the Property Inspector
3. Select your preferred language from the dropdown
4. The display will update to use the selected language

## Configuration

### Display Formats

You can customize how information is displayed on StreamDeck buttons:

**Health Display Options**
- `{icon} {health}/{maxHealth}` - Shows icon with current/max health
- `{health}HP` - Shows current health with HP suffix
- `{healthPercent}%` - Shows health as percentage

**Level Display Options**
- `LV.{level}` - Shows level with LV prefix
- `Level {level}` - Shows level with Level prefix
- `{level} ({experience}%)` - Shows level with experience percentage

**Position Display Options**
- `{x}, {y}, {z}` - Shows coordinates separated by commas
- `X:{x} Y:{y} Z:{z}` - Shows coordinates with labels
- `{dimension}\n{x}, {y}, {z}` - Shows dimension and coordinates

### Network Configuration

**Default Settings**
- **Port**: 8080 (currently hardcoded)
- **Host**: localhost (127.0.0.1)
- **Protocol**: WebSocket (ws://)

**Firewall Configuration**
- Ensure port 8080 is not blocked by firewall
- No internet access required (local communication only)

## Troubleshooting

### Common Issues

**StreamDeck shows "Disconnected" or "No Data"**
- Verify Minecraft is running with CraftDeck mod loaded
- Check that port 8080 is not blocked by firewall
- Try restarting both Minecraft and StreamDeck Software
- Verify the mod appears in Minecraft's mod list

**Commands don't execute**
- Check that you have permission to execute the command
- Verify command syntax (don't include leading `/`)
- Check Minecraft chat for error messages
- Ensure you're in a world (commands don't work in main menu)

**Display shows wrong information**
- Check player name configuration in Property Inspector
- Verify you're monitoring the correct player
- Try refreshing the action by removing and re-adding it

**Connection keeps dropping**
- Check system firewall settings
- Verify no other applications are using port 8080
- Try restarting the WebSocket connection
- Check Minecraft and StreamDeck logs for errors

### Getting Help

**Log Files**
- **Minecraft Logs**: Check `logs/latest.log` in your Minecraft directory
- **StreamDeck Logs**: Available in StreamDeck Software diagnostic tools

**In-Game Debugging**
- Use `/craftdeck status` to check mod status
- Use `/craftdeck test` to verify mod functionality

**Community Support**
- Check the [Issues](https://github.com/[username]/craftdeck/issues) page for known problems
- Search existing issues before creating new ones
- Provide logs and system information when reporting bugs

## FAQ

**Q: Does CraftDeck work with Minecraft servers?**
A: Yes, CraftDeck works with both single-player and multiplayer servers. The mod needs to be installed on the client (your computer), not the server.

**Q: Can I monitor other players?**
A: Currently, CraftDeck only monitors the player running the mod. Multi-player monitoring may be added in future versions.

**Q: Does this work with Minecraft Bedrock Edition?**
A: No, CraftDeck is only compatible with Minecraft Java Edition due to modding limitations in Bedrock Edition.

**Q: Can I change the port number?**
A: Currently, the port is hardcoded to 8080. Configuration options will be added in a future release.

**Q: Is this safe to use on servers?**
A: CraftDeck is a client-side mod that doesn't modify game mechanics. However, always check server rules regarding client-side mods before use.

**Q: Can I use multiple StreamDeck devices?**
A: Yes, multiple StreamDeck devices can connect to the same Minecraft instance, and all will receive the same data.

---

For more technical information, see the [Developer Guide](Developer-Guide.md).

For the latest updates and releases, visit the [CraftDeck GitHub Repository](https://github.com/[username]/craftdeck).