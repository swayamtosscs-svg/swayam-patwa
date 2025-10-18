# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep essential Flutter classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimize memory usage
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove unused code
-dontwarn **
-ignorewarnings

# Keep essential classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View
-keep public class * extends android.app.Fragment

# Keep model classes
-keep class com.example.r_gram.models.** { *; }
-keep class com.example.r_gram.providers.** { *; }
-keep class com.example.r_gram.services.** { *; }

# Maximum compression optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 7
-allowaccessmodification
-overloadaggressively
-repackageclasses ''

# Remove unused resources and code
-dontwarn **
-ignorewarnings
-dontnote **

# Keep only essential classes for reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Remove all debug information and logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Remove System.out.println calls
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void println(**);
}

# Additional compression rules
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep WebRTC classes for call functionality
-keep class org.webrtc.** { *; }
-keep class io.flutter.plugins.flutter_webrtc.** { *; }

# Keep media kit classes for video playback
-keep class com.alexmercerind.mediakit.** { *; }

# Keep camera plugin classes
-keep class io.flutter.plugins.camera.** { *; }

# Keep image picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep socket.io classes
-keep class io.socket.** { *; }

# Keep audio player classes
-keep class xyz.luan.audioplayers.** { *; }

