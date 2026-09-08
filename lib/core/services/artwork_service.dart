import 'dart:io';

import 'package:flutter/material.dart';

/// Caches local artwork (video thumbnails / album art) for the UI.
///
/// The library already persists generated `thumbnailPath` / `albumArtPath`
/// rows from scans; this service layers a cheap in-memory provider cache on
/// top so repeated list builds don't stat the filesystem, and provides a
/// deterministic gradient fallback for items without artwork.
class ArtworkService {
  ArtworkService._();

  static final ArtworkService instance = ArtworkService._();

  final Map<String, ImageProvider> _cache = {};
  final Set<String> _missing = {};

  /// Returns a cached [ImageProvider] for [path], or `null` when the file is
  /// missing or unreachable. Failed paths are remembered so lists don't retry
  /// them every frame.
  ImageProvider? providerFor(String? path) {
    if (path == null || path.isEmpty) return null;
    final cached = _cache[path];
    if (cached != null) return cached;
    if (_missing.contains(path)) return null;
    final file = File(path);
    if (!file.existsSync()) {
      _missing.add(path);
      return null;
    }
    final provider = FileImage(file);
    if (_cache.length > 512) _cache.remove(_cache.keys.first);
    _cache[path] = provider;
    return provider;
  }

  /// Drops cached state for [path] (e.g. after a thumbnail regenerates).
  void evict(String path) {
    _cache.remove(path);
    _missing.remove(path);
  }

  /// Clears the whole cache.
  void evictAll() {
    _cache.clear();
    _missing.clear();
  }

  /// Deterministic, title-derived gradient used as a rich placeholder when no
  /// artwork file exists.
  static List<Color> fallbackGradient(String title, {bool isVideo = true}) {
    // Stable hues from the title so each item keeps a recognizable colour.
    final hue = (title.hashCode.abs() % 360).toDouble();
    final base = HSLColor.fromAHSL(1, hue, 0.55, 0.38).toColor();
    final second = HSLColor.fromAHSL(1, (hue + 38) % 360, 0.6, 0.26).toColor();
    return [base, second];
  }

  /// Icon used by the fallback tile.
  static IconData fallbackIcon(bool isVideo) =>
      isVideo ? Icons.movie_outlined : Icons.music_note_outlined;
}