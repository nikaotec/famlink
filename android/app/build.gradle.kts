plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.avs.famlink"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.avs.famlink"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true

//        ndk {
//            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
//        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    signingConfigs {
        create("release") {
            // Configure sua assinatura aqui para produção
            // Exemplo:
            // storeFile = file("keystore.jks")
            // storePassword = "suaSenha"
            // keyAlias = "seuAlias"
            // keyPassword = "suaSenhaChave"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("androidx.core:core-ktx:1.16.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.multidex:multidex:2.0.1")

    // Solução 1: Usar versão estável recomendada do WebRTC SDK
    implementation("io.github.webrtc-sdk:android:125.6422.03") {
        exclude(group = "com.mesibo.api", module = "webrtc")
    }
}

flutter {
    source = "../.."
}
