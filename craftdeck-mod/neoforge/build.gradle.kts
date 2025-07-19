plugins {
    id("com.github.johnrengelman.shadow")
}

architectury {
    platformSetupLoomIde()
    neoForge()
}

loom {
    // accessWidenerPath.set(project(":common").loom.accessWidenerPath)

    // neoForge {
    //     convertAccessWideners.set(true)
    //     extraAccessWideners.add(loom.accessWidenerPath.get().asFile.name)
    // }
}

val common: Configuration by configurations.creating
val shadowCommon: Configuration by configurations.creating
val developmentNeoForge: Configuration = configurations.getByName("developmentNeoForge")

configurations {
    compileClasspath.get().extendsFrom(common)
    runtimeClasspath.get().extendsFrom(common)
    developmentNeoForge.extendsFrom(common)
}

repositories {
    // NeoForge
    maven {
        name = "NeoForged"
        url = uri("https://maven.neoforged.net/releases/")
    }
    // KotlinForForge
    maven {
        name = "Kotlin for Forge"
        url = uri("https://thedarkcolour.github.io/KotlinForForge/")
    }
}

dependencies {
    "minecraft"("com.mojang:minecraft:${rootProject.property("minecraft_version")}")
    "mappings"(loom.officialMojangMappings())

    // NeoForge dependency using modImplementation configuration
    "modImplementation"("net.neoforged:neoforge:${rootProject.property("neoforge_version")}")

    modApi("dev.architectury:architectury-neoforge:${rootProject.property("architectury_version")}")

    common(project(":common", "namedElements")) { isTransitive = false }
    shadowCommon(project(":common", "transformProductionNeoForge")) { isTransitive = false }

    // Kotlin for NeoForge (thedarkcolour's KFF supports NeoForge)
    implementation("thedarkcolour:kotlinforforge:${rootProject.property("kotlin_for_forge_version")}")

    // WebSocket library
    implementation("org.java-websocket:Java-WebSocket:1.5.3")
}

tasks {
    processResources {
        inputs.property("version", project.version)

        filesMatching("META-INF/mods.toml") {
            expand("version" to project.version)
        }
    }

    shadowJar {
        exclude("fabric.mod.json")
        exclude("quilt.mod.json")
        configurations = listOf(shadowCommon)
        archiveClassifier.set("dev-shadow")
    }

    remapJar {
        inputFile.set(shadowJar.get().archiveFile)
        dependsOn(shadowJar)
        // マルチローダー対応JAR命名規則
        val mcVersion = rootProject.property("minecraft_version").toString()
        archiveClassifier.set("MC${mcVersion}-neoforge")
    }

    jar {
        archiveClassifier.set("dev")
    }

    sourcesJar {
        val commonSources = project(":common").tasks.getByName<Jar>("sourcesJar")
        dependsOn(commonSources)
        from(commonSources.archiveFile.map { zipTree(it) })
    }
}

components.getByName("java") {
    this as AdhocComponentWithVariants
    this.withVariantsFromConfiguration(project.configurations["shadowRuntimeElements"]) {
        skip()
    }
}