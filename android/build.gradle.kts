plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

buildscript {
    val kotlinVersion = "2.1.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.google.gms:google-services:4.4.2")  // Add this for Firebase/AdMob
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Optimize for low-memory systems (4GB RAM)
    tasks.withType<JavaCompile> {
        options.isFork = true
        options.forkOptions.memoryMaximumSize = "512m"
        options.isIncremental = true
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
