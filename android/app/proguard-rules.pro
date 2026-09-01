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
# media_kit Android helper (package com.alexmercerind.mediakitandroidhelper)
# and the libs plugin are registered from GeneratedPluginRegistrant and use
# java.lang.System.loadLibrary + JNI; keep them intact for release builds.
-keep class com.alexmercerind.mediakitandroidhelper.** { *; }
-keep class com.alexmercerind.media_kit_libs_android_video.** { *; }

# Flutter engine's split-install (Play Store dynamic delivery) support is
# optional; the play-core classes are absent from this APK. R8 must not fail
# on the missing references (Flutter handles their absence at runtime).
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
