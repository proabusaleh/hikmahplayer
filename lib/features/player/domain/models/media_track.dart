import 'media_item.dart';

/// A named media track (video, audio or subtitle) available in a media file.
///
/// This is a UI-friendly, engine-independent representation of a track. The
/// [id] maps back to the underlying playback engine's track identifier and is
/// used when selecting a track.
enum TrackType { video, audio, subtitle }

/// A named media track (video, audio or subtitle) available in a media file.
class MediaTrack {
  /// Kind of track.
  final TrackType type;

  /// Engine-specific track identifier (e.g. `aid:1`, `sid:0`).
  final String id;

  /// Display title of the track.
  final String? title;

  /// ISO language code of the track, when known.
  final String? language;

  /// For external tracks loaded from a URI, the URI of the track.
  final String? uri;

  /// Codec identifier, when known.
  final String? codec;

  /// Video width in pixels, when known.
  final int? width;

  /// Video height in pixels, when known.
  final int? height;

  /// Audio sample rate in Hz, when known.
  final int? sampleRate;

  /// Number of audio channels, when known.
  final int? channels;

  /// Bitrate in bits per second, when known.
  final int? bitrate;

  const MediaTrack({
    required this.type,
    required this.id,
    this.title,
    this.language,
    this.uri,
    this.codec,
    this.width,
    this.height,
    this.sampleRate,
    this.channels,
    this.bitrate,
  });

  /// Whether this track was loaded from an external source (URI) rather than
  /// being embedded in the container.
  bool get isExternal => uri != null;

  /// A human readable label preferring [title], then [language], then [id].
  String get label => title ?? language ?? id;

  @override
  bool operator ==(Object other) {
    return other is MediaTrack &&
        other.type == type &&
        other.id == id &&
        other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(type, id, uri);

  @override
  String toString() =>
      'MediaTrack(type: $type, id: $id, title: $title, language: $language)';
}

/// A caption/subtitle cue used by [MediaItem] sidecar files.
///
/// Kept separate from playback; subtitle parsing lives in the subtitle
/// service.
class SubtitleCue {
  /// Start time of the cue.
  final Duration start;

  /// End time of the cue.
  final Duration end;

  /// The caption text. May contain multiple lines.
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  @override
  String toString() => 'SubtitleCue(start: $start, end: $end, text: $text)';
}
