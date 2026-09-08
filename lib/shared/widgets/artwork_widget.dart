import 'package:flutter/material.dart';

import '../../core/services/artwork_service.dart';

/// Renders media artwork from a local file path, falling back to a
/// title-derived gradient tile when no artwork exists.
///
/// Unlike [LibraryThumbnail], which is optimised for grid layouts, this widget
/// works anywhere a thumbnail with a graceful fallback is needed (analytics,
/// storage lists, detail rows).
class ArtworkWidget extends StatelessWidget {
  const ArtworkWidget({
    super.key,
    required this.title,
    this.path,
    this.size = 48,
    this.isVideo = true,
    this.borderRadius,
    this.customArtPath,
  });

  /// Title used to derive the gradient fallback.
  final String title;

  /// Local artwork file path (`thumbnailPath` / `albumArtPath`).
  final String? path;

  /// Optional override path that wins over [path].
  final String? customArtPath;

  final double size;
  final bool isVideo;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    final artwork = ArtworkService.instance.providerFor(customArtPath ?? path);

    final placeholder = _GradientPlaceholder(
      title: title,
      isVideo: isVideo,
      size: size,
      borderRadius: radius,
    );

    if (artwork == null) return placeholder;

    return ClipRRect(
      borderRadius: radius,
      child: Image(
        image: artwork,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({
    required this.title,
    required this.isVideo,
    required this.size,
    required this.borderRadius,
  });

  final String title;
  final bool isVideo;
  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colours = ArtworkService.fallbackGradient(title, isVideo: isVideo);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colours,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          ArtworkService.fallbackIcon(isVideo),
          color: Colors.white70,
          size: size * 0.5,
        ),
      ),
    );
  }
}