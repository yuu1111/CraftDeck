architectury {
    common(rootProject.property("enabled_platforms").toString().split(","))
}

loom {
    // Access widener not needed for now
    // accessWidenerPath.set(file("src/main/resources/craftdeck.accesswidener"))
}

dependencies {
    // We depend on fabric loader here to use the fabric @Environment annotations and get the mixin dependencies
    // Do NOT use other classes from fabric loader
    modImplementation("net.fabricmc:fabric-loader:${rootProject.property("fabric_loader_version")}")
    // Remove the next line if you don't want to depend on the API
    modApi("dev.architectury:architectury:${rootProject.property("architectury_version")}")
    
    // WebSocket library - will be included by platform-specific builds
    api("org.java-websocket:Java-WebSocket:1.5.3")
}