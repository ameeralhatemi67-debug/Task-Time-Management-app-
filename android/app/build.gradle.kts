plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.task_manager_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Enable desugaring (REQUIRED for notifications)
        isCoreLibraryDesugaringEnabled = true
        
        // Target Java 8 for Java code
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // Target Java 8 for Kotlin code (MUST MATCH ABOVE)
        jvmTarget = "17" 
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.task_manager_app"
        
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for notifications
    add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-auth")
}
// Add this at the bottom of android/app/build.gradle.kts

// ... existing code ...

configurations.all {
    resolutionStrategy {
        // This forces the app to use versions compatible with your current Gradle
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.browser:browser:1.8.0")
    }
}