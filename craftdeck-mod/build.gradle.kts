/**
 * CraftDeck Minecraft Mod - マルチローダー対応ビルドスクリプト
 *
 * このビルドスクリプトは、Minecraft 1.21.6用のModを複数のローダー
 * （Fabric、NeoForge、Quilt）に対応して生成します。
 *
 * 対応技術:
 * - Architectury API: マルチローダー対応基盤
 * - Kotlin DSL: 型安全なビルド設定
 * - Minecraft 1.21.6: 最新の安定版
 */

import net.fabricmc.loom.api.LoomGradleExtensionAPI

plugins {
    java
    kotlin("jvm") version "2.0.0"
    id("architectury-plugin") version "3.4-SNAPSHOT"
    id("dev.architectury.loom") version "1.7-SNAPSHOT" apply false
    id("com.github.johnrengelman.shadow") version "8.1.1" apply false
}


architectury {
    minecraft = rootProject.property("minecraft_version").toString()
}

subprojects {
    apply(plugin = "dev.architectury.loom")

    val loom = project.extensions.getByName<LoomGradleExtensionAPI>("loom")


    dependencies {
        "minecraft"("com.mojang:minecraft:${project.property("minecraft_version")}")
        // The following line declares the mojmap mappings, you may use other mappings as well
        "mappings"(
            loom.officialMojangMappings()
        )
        // The following line declares the yarn mappings you may select this one as well.
        // "mappings"("net.fabricmc:yarn:1.18.2+build.3:v2")
    }
}

allprojects {
    apply(plugin = "java")
    apply(plugin = "kotlin")
    apply(plugin = "architectury-plugin")
    apply(plugin = "maven-publish")

    base.archivesName.set(rootProject.property("archives_base_name").toString())
    version = rootProject.property("mod_version").toString()
    group = rootProject.property("maven_group").toString()

    // マルチローダー対応のJAR命名規則
    // 例: CraftDeck-1.0.0-MC1.21.6-fabric.jar
    tasks.withType<Jar> {
        if (project.name != "common" && name == "jar") {
            val mcVersion = rootProject.property("minecraft_version").toString()
            val loaderName = project.name
            archiveClassifier.set("MC${mcVersion}-${loaderName}")
        }
    }

    repositories {
        // Add repositories to retrieve artifacts from in here.
        maven {
            name = "NeoForged"
            url = uri("https://maven.neoforged.net/releases/")
        }
        maven {
            name = "Quilt"
            url = uri("https://maven.quiltmc.org/repository/release/")
        }
        maven {
            name = "Fabric"
            url = uri("https://maven.fabricmc.net/")
        }
        maven {
            name = "MinecraftForge"
            url = uri("https://maven.minecraftforge.net/")
        }
    }

    dependencies {
        compileOnly("org.jetbrains.kotlin:kotlin-stdlib")
        implementation("org.java-websocket:Java-WebSocket:1.5.3")
    }

    tasks.withType<JavaCompile> {
        options.encoding = "UTF-8"
        options.release.set(17)
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            freeCompilerArgs.addAll(listOf(
                "-Xjvm-default=all",
                "-opt-in=kotlin.RequiresOptIn"
            ))
        }
    }

    java {
        withSourcesJar()
    }
}


