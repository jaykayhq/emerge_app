# ===================================================================
# ProGuard/R8 Configuration for Emerge App
# ===================================================================

# Basic Optimization and Obfuscation Settings
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
-verbose

# Flutter Wrapper - Keep essential Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Security: Obfuscate app-specific classes but keep essential structure
-keep class com.emerge.emerge_app.MainActivity { *; }
-keep class com.emerge.emerge_app.Application { *; }
-keep class com.emerge.emerge_app.BuildConfig { *; }

# Security: Remove debug information in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Google Play Core (for Play Store features)
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# SplitCompat for dynamic feature modules
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Firebase - Essential for app functionality
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keepclassmembers class * {
  @com.google.firebase.messaging.FirebaseMessage <methods>;
}

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }

# RevenueCat - Payment processing
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Riverpod
-keep class dev.flutter_riverpod.** { *; }
-dontwarn dev.flutter_riverpod.**

# Gson (for JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp (used by Firebase and other network libraries)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Java 8+ features
-keep class java.time.** { *; }
-keep class java.util.stream.** { *; }
-keep class java.util.function.** { *; }

# Keep model classes that might be serialized
-keep class com.emerge.emerge_app.** { *; }

# Hive (for local storage)
-keep class org.hivedb.** { *; }
-dontwarn org.hivedb.**

# Freezed
-keep class * extends com.google.errorprone.annotations.Immutable
-keepclassmembers class * {
    @com.google.errorprone.annotations.Immutable <methods>;
}

# Lottie animations
-keep class com.airbnb.lottie.** { *; }
-dontwarn com.airbnb.lottie.**

# UUID
-keep class java.util.UUID { *; }

# Parcelable
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Serializable
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}