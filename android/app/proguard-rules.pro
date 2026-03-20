# Flutter engine — keep only what's needed for reflection/JNI
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.** { *; }

# Firebase — keep only annotation-driven reflection targets
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.firebase** { *; }
-keepnames class com.google.android.gms.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.api.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Local notifications
-keep class com.dexterous.** { *; }

# Kotlin metadata (needed for Kotlin reflection, minimal)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Suppress warnings for unused Play Core split-install stubs
-dontwarn com.google.android.play.core.**

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
