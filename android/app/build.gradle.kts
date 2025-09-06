// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Usa el mismo paquete que publicarás en Play
    namespace = "com.goldlettuce.lumina"

    // Valores que provee el plugin de Flutter
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.goldlettuce.lumina"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 🔐 Firma de RELEASE leyendo android/key.properties
    signingConfigs {
        create("release") {
            val props = Properties()
			val propsFile = rootProject.file("key.properties")
            if (!propsFile.exists()) {
                throw GradleException("No se encontró android/key.properties")
            }
            FileInputStream(propsFile).use { props.load(it) }

            // Ruta relativa a la carpeta android/
            // En tu caso: app/lumina_key.jks
            storeFile = file(props.getProperty("storeFile"))
            storePassword = props.getProperty("storePassword")
            keyAlias = props.getProperty("keyAlias")
            keyPassword = props.getProperty("keyPassword")

            enableV3Signing = true
            enableV4Signing = true
        }
    }

    buildTypes {
        getByName("release") {
            // ✅ Firmar con la config de release (no debug)
            signingConfig = signingConfigs.getByName("release")

            // ✅ App minimalista: reduce tamaño
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // sin cambios
        }
    }
}

flutter {
    source = "../.."
}
