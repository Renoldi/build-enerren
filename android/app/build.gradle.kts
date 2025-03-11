import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val properties = Properties().apply {
    load(FileInputStream(rootProject.file("../config/config.properties")))
}

android {
    namespace = properties["flutter.namespace"].toString()
    compileSdk = properties["flutter.compileSdkVersion"].toString().toInt()
    ndkVersion = properties["flutter.ndkVersion"].toString()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = properties["flutter.namespace"].toString()
        minSdk = properties["flutter.minSdkVersion"].toString().toInt()
        targetSdk = properties["flutter.targetSdkVersion"].toString().toInt()
        versionCode = properties["flutter.versionCode"].toString().toInt()
        versionName = properties["flutter.versionName"].toString()
        manifestPlaceholders.putAll(mapOf(
            "flutter.apiMap" to properties["flutter.apiMap"].toString()
        ))
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(properties["flutter.buildMode"].toString())
        }
    }
}

flutter {
    source = "../.."
}
