plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.emerge.emerge_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    // Memory optimization for 4GB RAM systems
    dexOptions {
        javaMaxHeapSize = "1g"
        preDexLibraries = false
        jumboMode = true
    }

    // splits {
    //     abi {
    //         isEnable = true
    //         reset()
    //         include("armeabi-v7a", "arm64-v8a", "x86_64")
    //         isUniversalApk = false
    //     }
    // }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.emerge.emerge_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // IMPORTANT: Use production signing keys for release builds
            signingConfig = signingConfigs.getByName("release")

            // Enable code shrinking and resource shrinking for maximum performance and security
            isMinifyEnabled = true
            isShrinkResources = true

            // Enable R8 full mode for better obfuscation and optimization
            isJniDebuggable = false

            // Add ProGuard/R8 rules for security
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Additional build optimizations
            buildConfigField("boolean", "DEBUG_MODE", "false")
            buildConfigField("String", "BUILD_TYPE", "\"release\"")
        }

        debug {
            // Debug build optimizations - less secure but easier to debug
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false

            buildConfigField("boolean", "DEBUG_MODE", "true")
            buildConfigField("String", "BUILD_TYPE", "\"debug\"")
        }

        // Add profile build type for testing with optimizations
        // Add profile build type for testing with optimizations
        getByName("profile") {
            // initWith(getByName("release")) // Already initialized by Flutter
            isDebuggable = false
            signingConfig = signingConfigs.getByName("debug")

            buildConfigField("boolean", "DEBUG_MODE", "false")
            buildConfigField("String", "BUILD_TYPE", "\"profile\"")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Play Integrity API for Firebase App Check (Android)
    implementation("com.google.android.play:integrity:1.3.0")
}
