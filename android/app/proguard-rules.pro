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
