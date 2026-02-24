# Flutter-specific ProGuard rules
# Most Flutter plugins ship their own rules via AAR — this file is a safety net.

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase Auth
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Play Core (referenced by Flutter deferred components)
-dontwarn com.google.android.play.core.**

# OkHttp (used by Dio / http packages under the hood)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Gson (used by some Firebase internals)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep R8 from stripping annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
