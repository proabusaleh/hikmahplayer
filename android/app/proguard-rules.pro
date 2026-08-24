# Keep rules for release builds (R8).

# Flutter engine & plugin reflection entry points.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# audio_service: background playback service is looked up reflectively.
-keep class com.ryanheise.audioservice.** { *; }

# media_kit native event loop.
-keep class com.alexmercerind.mediakit.** { *; }
