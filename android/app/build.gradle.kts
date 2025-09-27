plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_auth_app"
    compileSdk = 35

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.my_auth_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23  // Required by camera plugin
        targetSdk = 34  // Reduced from 35 for stability
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Memory optimization
        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true
        
        // APK size optimization - removed ABI filters to avoid conflicts with splits
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Maximum compression for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            isZipAlignEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Additional compression optimizations
            ndk {
                debugSymbolLevel = "NONE"
            }
            
            // Enable all optimizations
            buildConfigField("boolean", "ENABLE_VIDEO_FEATURES", "true")
            buildConfigField("boolean", "ENABLE_CAMERA_FEATURES", "true")
            buildConfigField("boolean", "ENABLE_STORY_FEATURES", "true")
            buildConfigField("boolean", "ENABLE_CALL_FEATURES", "true")
        }
        debug {
            // Compressed debug build with all features enabled
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = true
            isZipAlignEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Additional optimizations for debug APK
            buildConfigField("boolean", "DEBUG", "true")
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            
            // Maximum size optimizations
            ndk {
                debugSymbolLevel = "NONE"
            }
            
            // Additional size optimizations for debug APK
            isJniDebuggable = false
            
            // Universal APK for maximum compatibility
            splits {
                abi {
                    isEnable = true
                    reset()
                    include("arm64-v8a", "armeabi-v7a") // Include both ARM architectures
                    isUniversalApk = true // Create universal APK
                }
            }
            
            // Feature flags - all enabled
            buildConfigField("boolean", "ENABLE_DEBUG_FEATURES", "true")
            buildConfigField("boolean", "ENABLE_ANALYTICS", "false")
            buildConfigField("boolean", "ENABLE_CRASH_REPORTING", "false")
            
            // All features enabled
            buildConfigField("boolean", "ENABLE_VIDEO_FEATURES", "true")
            buildConfigField("boolean", "ENABLE_CAMERA_FEATURES", "true")
            buildConfigField("boolean", "ENABLE_STORY_FEATURES", "true")
            buildConfigField("boolean", "ENABLE_CALL_FEATURES", "true")
        }
    }
    
    // Memory optimization
    dexOptions {
        javaMaxHeapSize = "2g"
        preDexLibraries = false
    }
    
    packagingOptions {
        exclude("META-INF/DEPENDENCIES")
        exclude("META-INF/LICENSE")
        exclude("META-INF/LICENSE.txt")
        exclude("META-INF/license.txt")
        exclude("META-INF/NOTICE")
        exclude("META-INF/NOTICE.txt")
        exclude("META-INF/notice.txt")
        exclude("META-INF/ASL2.0")
        
        // Additional exclusions for smaller APK
        exclude("**/attach_hotspot_windows.dll")
        exclude("META-INF/*.kotlin_module")
        exclude("META-INF/*.version")
        exclude("META-INF/com.android.tools/**")
        exclude("META-INF/com.google.android.material_material.version")
        exclude("META-INF/androidx.**")
        exclude("META-INF/services/**")
        exclude("META-INF/INDEX.LIST")
        exclude("META-INF/MANIFEST.MF")
        
        // Keep essential files for app functionality
    }
    
    // APK size optimization - disabled for universal APK
    // splits {
    //     abi {
    //         isEnable = true
    //         reset()
    //         include("arm64-v8a", "armeabi-v7a", "x86_64")
    //         isUniversalApk = false
    //     }
    // }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
