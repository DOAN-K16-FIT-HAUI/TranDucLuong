plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // For Firebase integration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.io.ziblox.financial_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.io.ziblox.financial_app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // Enable multidex support
    }

    signingConfigs {
        create("release") {
            keyAlias = "my-alias" // Replace with your keystore alias
            keyPassword = "12345678" // Replace with your key password
            storeFile = file("my-release-key.jks") // Replace with path to keystore
            storePassword = "12345678" // Replace with your store password
        }
    }

    buildTypes {
        named("release") {
            isMinifyEnabled = true // Enable R8 minification
            isShrinkResources = true // Enable resource shrinking
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
        named("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.2.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.mlkit:text-recognition:16.0.0")
    
    // Add the core library desugaring dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    
    // Add multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}