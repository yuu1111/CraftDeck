# CraftDeck Developer Guide

This guide provides technical information for developers who want to contribute to CraftDeck, understand its architecture, or extend its functionality.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Building the Project](#building-the-project)
4. [WebSocket Protocol Specification](#websocket-protocol-specification)
5. [Extending CraftDeck](#extending-craftdeck)
6. [Testing](#testing)
7. [Contributing](#contributing)
8. [Release Process](#release-process)

## Architecture Overview

CraftDeck consists of two main components that communicate via WebSocket protocol:

```
┌─────────────────┐    WebSocket     ┌─────────────────┐
│  Minecraft Mod  │◄──────────────►│StreamDeck Plugin│
│    (Kotlin)     │   Port 8080     │     (C#)        │
└─────────────────┘                 └─────────────────┘
```

### Minecraft Mod (craftdeck-mod)

**Technology Stack:**
- **Language**: Kotlin
- **Framework**: Architectury (multi-platform mod development)
- **WebSocket**: Java-WebSocket 1.5.3
- **Build Tool**: Gradle

**Module Structure:**
```
craftdeck-mod/
├── common/          # Shared code across all platforms
│   ├── CraftDeckMod.kt           # Main mod entry point
│   ├── WebSocketServer.kt        # WebSocket server implementation
│   ├── GameDataCollector.kt      # Player data collection
│   └── CommandHandler.kt         # Command execution handling
├── fabric/          # Fabric-specific implementation
├── forge/           # Forge-specific implementation
└── quilt/           # Quilt-specific implementation
```

**Key Components:**

1. **CraftDeckMod**: Main mod class that initializes the WebSocket server and registers commands
2. **CraftDeckWebSocketServer**: WebSocket server that handles client connections and message routing
3. **GameDataCollector**: Collects player data (health, position, level, etc.) from Minecraft
4. **CommandHandler**: Executes Minecraft commands received from StreamDeck

### StreamDeck Plugin (craftdeck-plugin)

**Technology Stack:**
- **Language**: C#
- **Framework**: .NET 6
- **WebSocket**: System.Net.WebSockets.Client
- **StreamDeck**: StreamDeckLib 0.5.2040
- **JSON**: Newtonsoft.Json

**Project Structure:**
```
craftdeck-plugin/
├── Actions/                      # StreamDeck action implementations
│   ├── PlayerMonitorAction.cs    # Player data monitoring
│   └── CommandAction.cs          # Command execution
├── Services/                     # Business logic services
│   ├── MinecraftWebSocketService.cs    # WebSocket client
│   ├── SharedWebSocketManager.cs       # Connection management
│   ├── DisplayFormatService.cs         # Data formatting
│   └── LocalizationService.cs          # Multi-language support
├── Models/                       # Data models
│   └── GameDataModels.cs         # WebSocket message models
└── property_inspector/           # Web-based configuration UI
```

## Development Environment Setup

### Prerequisites

**For Minecraft Mod Development:**
- Java Development Kit (JDK) 17+
- IntelliJ IDEA (recommended) or VS Code
- Git

**For StreamDeck Plugin Development:**
- .NET 6 SDK
- Visual Studio 2022 (recommended) or VS Code
- StreamDeck Software 6.0+
- StreamDeck device (for testing)

### Setting Up the Development Environment

1. **Clone the Repository**
   ```bash
   git clone https://github.com/[username]/craftdeck.git
   cd craftdeck
   ```

2. **Minecraft Mod Setup**
   ```bash
   cd craftdeck-mod
   ./gradlew build
   ```

3. **StreamDeck Plugin Setup**
   ```bash
   cd craftdeck-plugin
   dotnet restore
   dotnet build
   ```

### IDE Configuration

**IntelliJ IDEA (for Minecraft Mod):**
1. Open the `craftdeck-mod` folder as a Gradle project
2. Wait for Gradle sync to complete
3. Configure run configurations for each platform (Fabric, Forge, Quilt)

**Visual Studio (for StreamDeck Plugin):**
1. Open `CraftDeckSolution.sln`
2. Restore NuGet packages
3. Set `CraftDeck.StreamDeckPlugin` as startup project

## Building the Project

### Minecraft Mod

**Build All Platforms:**
```bash
cd craftdeck-mod
./gradlew build
```

**Platform-Specific Builds:**
```bash
# Fabric only
./gradlew :fabric:build

# Forge only
./gradlew :forge:build

# Quilt only
./gradlew :quilt:build
```

**Development Testing:**
```bash
# Run Fabric development client
./gradlew :fabric:runClient

# Run Forge development client
./gradlew :forge:runClient
```

### StreamDeck Plugin

**Debug Build:**
```bash
cd craftdeck-plugin
dotnet build
```

**Release Build:**
```bash
dotnet build -c Release
```

**Create StreamDeck Plugin Package:**
```bash
dotnet publish -c Release --self-contained
# Manual packaging required for .streamDeckPlugin file
```

### Automated Build Scripts

**PowerShell Scripts** (Windows):
```powershell
# Build everything
.\scripts\Build-All.ps1

# Build mod only
.\scripts\Build-MinecraftMod.ps1

# Build plugin only
.\scripts\Build-StreamDeckPlugin.ps1

# Prepare release packages
.\scripts\Prepare-Release.ps1
```

## WebSocket Protocol Specification

### Connection Details
- **Protocol**: WebSocket (ws://)
- **Host**: localhost (127.0.0.1)
- **Port**: 8080
- **Message Format**: JSON

### Message Types

#### Connection Messages

**Connection Established (Mod → Plugin)**
```json
{
  "type": "connection",
  "status": "connected",
  "message": "Welcome to CraftDeck"
}
```

#### Player Data Messages

**Player Status Update (Mod → Plugin)**
```json
{
  "type": "player_status",
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "PlayerName",
  "health": 20.0,
  "max_health": 20.0,
  "food": 20,
  "experience": 0.5,
  "level": 30,
  "gamemode": "survival",
  "position": {
    "x": 100.5,
    "y": 64.0,
    "z": 200.3
  },
  "dimension": "minecraft:overworld"
}
```

**Player Data Request (Plugin → Mod)**
```json
{
  "type": "get_player_data"
}
```

**Player Data Response (Mod → Plugin)**
```json
{
  "type": "player_data",
  "players": [
    {
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "PlayerName",
      "health": 20.0,
      "max_health": 20.0,
      "food": 20,
      "experience": 0.5,
      "level": 30,
      "gamemode": "survival",
      "position": {
        "x": 100.5,
        "y": 64.0,
        "z": 200.3
      },
      "dimension": "minecraft:overworld"
    }
  ]
}
```

#### Command Execution Messages

**Execute Command (Plugin → Mod)**
```json
{
  "type": "execute_command",
  "command": "time set day",
  "player": "PlayerName"
}
```

**Command Result (Mod → Plugin)**
```json
{
  "type": "command_result",
  "success": true,
  "message": "Set the time to 1000",
  "result": 1
}
```

#### Error Messages

**Error Response (Mod → Plugin)**
```json
{
  "type": "error",
  "message": "Command execution failed: Permission denied"
}
```

### Protocol Flow

1. **Connection Establishment**
   - StreamDeck plugin connects to Minecraft mod on port 8080
   - Mod sends connection confirmation message

2. **Data Synchronization**
   - Plugin requests initial player data
   - Mod sends current player status
   - Mod continuously sends updates when player data changes

3. **Command Execution**
   - Plugin sends command execution request
   - Mod executes command and sends result back

4. **Error Handling**
   - Both sides handle connection drops gracefully
   - Error messages provide debugging information

## Extending CraftDeck

### Adding New Data Types

**Step 1: Update GameDataCollector (Mod)**
```kotlin
// Add new data collection method
fun getNewDataType(): NewDataType {
    // Implementation
}

// Update player data structure
data class PlayerInfo(
    // existing fields...
    val newField: String
)
```

**Step 2: Update WebSocket Messages**
```kotlin
// Mod side - update message building
private fun buildPlayerStatusMessage(info: PlayerInfo): String {
    return buildString {
        // existing fields...
        append(""""new_field":"${info.newField}",""")
    }
}
```

```csharp
// Plugin side - update data models
public class PlayerStatusMessage : WebSocketMessage
{
    // existing properties...

    [JsonProperty("new_field")]
    public string NewField { get; set; }
}
```

**Step 3: Update StreamDeck Actions**
```csharp
// Create new action or update existing ones
[ActionUuid(Uuid = "com.craftdeck.plugin.action.newaction")]
public class NewDataAction : BaseStreamDeckActionWithSettingsModel<NewDataSettingsModel>
{
    // Implementation
}
```

### Adding New Commands

**Step 1: Update CommandHandler (Mod)**
```kotlin
object CommandHandler {
    fun executeCommand(command: String, playerName: String?): CommandResult {
        // Add validation for new command types
        // Add execution logic
    }
}
```

**Step 2: Create New StreamDeck Action**
```csharp
[ActionUuid(Uuid = "com.craftdeck.plugin.action.newcommand")]
public class NewCommandAction : BaseStreamDeckActionWithSettingsModel<CommandSettingsModel>
{
    public override async Task OnKeyDown(StreamDeckEventPayload args)
    {
        var webSocketService = SharedWebSocketManager.WebSocketService;
        await webSocketService.SendCommandAsync(SettingsModel.Command);
    }
}
```

### Adding New StreamDeck Actions

1. **Create Action Class**
   - Inherit from `BaseStreamDeckActionWithSettingsModel<T>`
   - Add `[ActionUuid]` attribute with unique UUID

2. **Create Settings Model**
   - Define configuration properties
   - Add JSON serialization attributes

3. **Create Property Inspector**
   - Design HTML/CSS/JS configuration interface
   - Handle settings validation and updates

4. **Update Manifest**
   - Add action definition to `manifest.json`
   - Include icons and localization

## Testing

### Unit Testing

**Minecraft Mod Testing:**
```kotlin
// Example test structure
@Test
fun testWebSocketServerStartup() {
    val server = CraftDeckWebSocketServer(8080)
    server.start()
    assertTrue(server.isStarted)
    server.stop()
}
```

**StreamDeck Plugin Testing:**
```csharp
[Test]
public async Task TestWebSocketConnection()
{
    var service = new MinecraftWebSocketService();
    var connected = await service.ConnectAsync();
    Assert.IsTrue(connected);
}
```

### Integration Testing

1. **Manual Testing Process**
   - Start Minecraft with mod in development environment
   - Install plugin in StreamDeck Software
   - Test all actions and data synchronization
   - Verify error handling and reconnection

2. **Automated Testing** (Future Enhancement)
   - Mock WebSocket server for plugin testing
   - Automated UI testing for StreamDeck actions
   - Protocol compliance testing

### Debug Configuration

**Minecraft Mod Debugging:**
```kotlin
// Enable debug logging
CraftDeckMod.LOGGER.info("Debug message")
```

**StreamDeck Plugin Debugging:**
```csharp
// Use console output for debugging
Console.WriteLine($"Debug: {message}");

// Enable verbose WebSocket logging
```

## Contributing

### Code Style Guidelines

**Kotlin (Minecraft Mod):**
- Follow Kotlin coding conventions
- Use meaningful variable and function names
- Add KDoc comments for public APIs
- Prefer immutable data structures

**C# (StreamDeck Plugin):**
- Follow C# coding conventions
- Use PascalCase for public members
- Add XML documentation comments
- Use async/await for asynchronous operations

### Git Workflow

1. **Fork the Repository**
2. **Create Feature Branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. **Make Changes and Test**
4. **Commit with Descriptive Messages**
   ```bash
   git commit -m "Add new player monitoring feature"
   ```
5. **Push and Create Pull Request**

### Pull Request Guidelines

- Follow the PR template
- Include tests for new features
- Update documentation as needed
- Ensure all CI checks pass
- Request review from maintainers

## Release Process

### Version Numbering
- Follow Semantic Versioning (SemVer)
- Format: MAJOR.MINOR.PATCH
- Update all relevant files with new version

### Release Checklist

1. **Pre-Release**
   - [ ] Update version numbers in all project files
   - [ ] Update CHANGELOG.md with new features and fixes
   - [ ] Run full test suite
   - [ ] Build release artifacts for all platforms

2. **Release**
   - [ ] Create Git tag with version number
   - [ ] Build final release packages
   - [ ] Create GitHub release with artifacts
   - [ ] Update documentation

3. **Post-Release**
   - [ ] Update package managers (if applicable)
   - [ ] Announce release in community channels
   - [ ] Monitor for issues and feedback

### Automated Release Scripts

```powershell
# Full release preparation
.\scripts\Prepare-Release.ps1 -Version "1.0.0"

# Create release packages
.\scripts\Release-CraftDeck.ps1
```

---

For user documentation, see the [User Guide](User-Guide.md).

For the latest development updates, visit the [CraftDeck GitHub Repository](https://github.com/[username]/craftdeck).