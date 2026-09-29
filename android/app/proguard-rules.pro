# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / GoTrue / Postgrest (if needed for reflection/serialization)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.supabase.** { *; }

# AdMob (google_mobile_ads)
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep public class com.google.ads.** {
   public *;
}

# Image Cropper (uCrop)
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }

# Connectivity Plus
-keep class io.flutter.plugins.connectivity.** { *; }

# App Links
-keep class com.llfbandit.app_links.** { *; }

# Flutter Deferred Components (Play Core)
# These classes are referenced by the Flutter engine but aren't always present.
-dontwarn com.google.android.play.core.**
