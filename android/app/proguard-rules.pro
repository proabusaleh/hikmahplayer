# ═══════════════════════════════════════════════════════════════
#  Hikmah Player — ProGuard / R8 rules
# ═══════════════════════════════════════════════════════════════

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (Flutter deferred components - not used but referenced)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# media_kit / libmpv
-keep class com.alexmercerind.media_kit.** { *; }
-dontwarn com.alexmercerind.media_kit.**

# Drift / SQLite
-keep class app.cash.sqldelight.** { *; }
-keep class org.sqlite.** { *; }

# Audio Service
-keep class com.ryanheise.audioservice.** { *; }

# Freezed models
-keep class com.hikmahplayer.app.domain.** { *; }
-keep class com.hikmahplayer.app.data.models.** { *; }

# TensorFlow Lite
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
