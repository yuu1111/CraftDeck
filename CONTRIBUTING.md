# Contributing to CraftDeck

Thank you for your interest in contributing to CraftDeck! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Bugs

Before creating a bug report, please check the [existing issues](../../issues) to avoid duplicates.

When reporting a bug, please include:
- **Environment Details**: OS, Java version, Minecraft version, mod loader
- **Steps to Reproduce**: Clear steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Logs**: Relevant error messages or log files
- **Screenshots**: If applicable, visual evidence of the issue

### Suggesting Features

We welcome feature suggestions! Please:
- Check existing [feature requests](../../issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
- Clearly describe the feature and its benefits
- Explain how it fits with CraftDeck's goals
- Consider implementation complexity and maintenance

### Code Contributions

#### Development Setup

1. **Fork the repository** and clone your fork
2. **Set up the development environment**:
   ```bash
   # For Minecraft mod development
   cd craftdeck-mod
   ./gradlew build

   # For Stream Deck plugin development
   cd craftdeck-plugin
   dotnet build
   ```

#### Code Style Guidelines

**Minecraft Mod (Kotlin)**
- Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use meaningful variable and function names
- Add KDoc comments for public APIs

**Stream Deck Plugin (C#)**
- Follow [C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- Use 4 spaces for indentation
- Use PascalCase for public members
- Use camelCase for private members
- Add XML documentation for public APIs

#### Commit Guidelines

- Use clear, descriptive commit messages
- Follow the format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Examples:
  ```
  feat(mod): add inventory data collection
  fix(plugin): resolve connection timeout issue
  docs(readme): update installation instructions
  ```

#### Pull Request Process

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code style guidelines

3. **Test thoroughly**:
   - Minecraft mod: Test with multiple mod loaders
   - Stream Deck plugin: Test with different Stream Deck models
   - Verify WebSocket communication works correctly

4. **Update documentation** if needed

5. **Create a pull request** with:
   - Clear title and description
   - Reference related issues
   - List of changes made
   - Screenshots/videos if applicable

## 🏗️ Architecture Guidelines

### Minecraft Mod Architecture

- **Common Module**: Shared logic across all mod loaders
- **Platform Modules**: Mod loader-specific implementations
- **WebSocket Server**: Handles all client connections
- **Data Collection**: Gathers game state information
- **Command Execution**: Processes incoming commands

### Stream Deck Plugin Architecture

- **Main Action**: Primary plugin action handler
- **WebSocket Client**: Manages server connections
- **Property Inspector**: Configuration UI
- **Data Display**: Formats and displays game information
- **Command Sending**: Formats and sends commands to mod

### Communication Protocol

- **JSON-based**: All messages use JSON format
- **Type-based**: Each message has a `type` field for routing
- **Bidirectional**: Both mod and plugin can initiate communication
- **Error Handling**: Graceful handling of connection issues

## 🧪 Testing

### Minecraft Mod Testing

```bash
# Run Fabric development client
./gradlew :fabric:runClient

# Run Forge development client
./gradlew :forge:runClient

# Run Quilt development client
./gradlew :quilt:runClient
```

### Stream Deck Plugin Testing

```bash
# Build and deploy to Stream Deck
dotnet build

# Manual testing steps:
# 1. Install built plugin in Stream Deck software
# 2. Add CraftDeck action to Stream Deck
# 3. Start Minecraft with mod
# 4. Verify communication and data display
```

### Integration Testing

1. Start Minecraft with CraftDeck mod
2. Verify WebSocket server starts on port 8080
3. Install and configure Stream Deck plugin
4. Test data flow: mod → plugin
5. Test command execution: plugin → mod
6. Test error handling and reconnection

## 📚 Documentation

### Code Documentation

- **Kotlin**: Use KDoc format for public APIs
- **C#**: Use XML documentation comments
- **Examples**: Provide usage examples for complex features
- **Architecture**: Document design decisions and patterns

### User Documentation

- Keep README files updated
- Update wiki pages for new features
- Provide clear installation and configuration instructions
- Include troubleshooting guides

## 🔍 Code Review Process

### Review Criteria

- **Functionality**: Code works as intended
- **Performance**: No unnecessary performance impact
- **Security**: No security vulnerabilities introduced
- **Maintainability**: Code is readable and well-structured
- **Testing**: Adequate test coverage
- **Documentation**: Proper documentation for new features

### Review Timeline

- Initial review: Within 48 hours
- Follow-up reviews: Within 24 hours
- Complex changes may require additional review time

## 🚀 Release Process

### Version Numbering

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers bumped
- [ ] Release notes prepared
- [ ] Artifacts built and tested

## 📞 Communication

### Getting Help

- **Issues**: Use GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub discussions for questions and ideas
- **Code Review**: Use pull request comments for code-specific discussions

### Community Guidelines

- Be respectful and inclusive
- Provide constructive feedback
- Help newcomers get started
- Focus on the project's goals and user needs

## 📄 License

By contributing to CraftDeck, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to CraftDeck! Your efforts help make Minecraft and Stream Deck integration better for everyone.