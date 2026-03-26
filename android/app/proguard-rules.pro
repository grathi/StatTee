# ── Flutter engine ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# ── Firebase & Google Play Services ──────────────────────────────────────────
# NOTE: -keepnames only prevents renaming; use -keep to also prevent removal.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# ── Firestore model serialisation ────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes JavascriptInterface

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-dontwarn kotlin.**
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**

# ── Coroutines ────────────────────────────────────────────────────────────────
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ── Geolocator ────────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ── Local notifications ───────────────────────────────────────────────────────
-keep class com.dexterous.** { *; }

# ── Gson (used internally by Firebase/Firestore) ──────────────────────────────
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.**

# ── OkHttp / Retrofit (used by some Firebase internals) ──────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# ── Suppress Play Core split-install warnings ─────────────────────────────────
-dontwarn com.google.android.play.core.**

# ── Remove verbose logging in release (safe subset only) ─────────────────────
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
}
