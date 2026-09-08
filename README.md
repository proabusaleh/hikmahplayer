# Hikmah Player

A cross-platform media player for Android, iOS, Windows, macOS, and Linux. Hikmah Player discovers the media library on your device, plays audio and video with a rich, gesture-driven player UI, and bundles on-device AI tools -- translation, speech recognition, Whisper transcription, and media analysis -- so your content stays private.

## Features

- **Media library** -- automatic scan of on-device audio, video, and images with metadata + artwork.
- **Playback** -- audio and video playback powered by `libmpv` (media_kit) with gesture controls for brightness, volume, and seeking; background playback with lock-screen controls.
- **Smart playlists** -- auto-generated playlists from media metadata and listening habits.
- **On-device AI** -- translation (MLKit), voice input, Whisper transcription (whisper.cpp), and media analysis (TFLite). No cloud round-trips.
- **Creative tools** -- create clips and convert media with FFmpeg, generate thumbnails, and capture frames.
- **Accessibility** -- text-to-speech, subtitles/captions, and a reader-friendly interface with Arabic (RTL) support.
- **Privacy** -- local-first storage; nothing leaves your device without consent.
- **Continuity** -- Chromecast / AirPlay targets, picture-in-picture, and cross-device syncing via WebSocket.
- **Material 3 theming** -- light/dark/system modes with dynamic color (Material You).

## Getting Started

### Prerequisites

- Flutter `>=3.29.0` (project pinned to Dart `>=3.7.0`).
- Platform toolchains for the targets you build (Android SDK, Xcode, Visual Studio, etc.).

### Install dependencies

```sh
flutter pub get
```

### Code generation

Drift, Riverpod, and Freezed require generated code. After changing any annotated models or providers, run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

### Generate launcher icons & splash

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

> Note: icon/splash generation requires `assets/icons/app_icon.png`, `assets/icons/app_icon_foreground.png`, and `assets/icons/splash_logo*.png` to exist (see the `flutter_launcher_icons` and `flutter_native_splash` blocks in `pubspec.yaml`).

### Run in debug mode

```sh
flutter run
```

## Testing

```sh
flutter analyze
flutter test
```

## Building for release

```sh
# Android (APK)
flutter build apk --release

# Android (App Bundle for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Project structure

```
lib/
├── main.dart                  # Boot, error handling, media-kit/Hive init
├── app.dart                   # Root MaterialApp + routing
├── core/                      # DI, router, theme, platform, storage, services
├── domain/                    # Domain models
├── features/                  # Feature-first modules (player, library, ai, ...)
├── presentation/              # Shared providers
└── shared/                    # Shared UI utilities
```

## Tech stack

- **Playback**: `media_kit` (libmpv), `just_audio`, `video_player`
- **State management**: Riverpod, Freezed
- **Database**: Drift (SQLite)
- **AI**: TFLite, MLKit Translation, whisper.cpp (via `whisper_ggml`)
- **Video processing**: FFmpeg (`ffmpeg_kit_flutter`)
- **Networking**: Dio, WebSocket (`web_socket_channel`)