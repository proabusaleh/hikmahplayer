import '../services/accessibility_service.dart';
import '../services/ai_service.dart';
import '../services/audio_service.dart';
import '../services/community_service.dart';
import '../services/continuity_service.dart';
import '../services/developer_service.dart';
import '../services/export_service.dart';
import '../services/hikmah_service.dart';
import '../services/library_service.dart';
import '../services/metadata_service.dart';
import '../services/playback_service.dart';
import '../services/privacy_service.dart';
import '../services/subtitle_service.dart';
import '../services/sync_service.dart';

/// Owns every long-lived application service.
///
/// The real services are constructed once in `main()` and shared through the
/// widget tree via [AppScope]. Tests can inject lightweight replacements by
/// passing them to the constructor — each slot defaults to the production
/// implementation.
class AppServices {
  AppServices({
    PlaybackService? playback,
    LibraryService? library,
    AudioService? audio,
    AIService? ai,
    ExportService? export,
    PrivacyService? privacy,
    AccessibilityService? accessibility,
    SyncService? sync,
    MetadataService? metadata,
    SubtitleService? subtitle,
    CommunityService? community,
    HikmahModeService? hikmah,
    ContinuityService? continuity,
    DeveloperService? developer,
  })  : playback = playback ?? PlaybackService(),
        library = library ?? LibraryService(),
        audio = audio ?? AudioService(),
        ai = ai ?? AIService(),
        export = export ?? ExportService(),
        privacy = privacy ?? PrivacyService(),
        accessibility = accessibility ?? AccessibilityService(),
        sync = sync ?? SyncService(),
        metadata = metadata ?? MetadataService(),
        subtitle = subtitle ?? SubtitleService(),
        community = community ?? CommunityService(),
        hikmah = hikmah ?? HikmahModeService(),
        continuity = continuity ?? ContinuityService(),
        developer = developer ?? DeveloperService();

  /// Unified media playback engine (media_kit / libmpv + FFmpeg).
  final PlaybackService playback;

  /// Media library: folder scanning, indexing, tags, collections.
  final LibraryService library;

  /// Advanced audio layer: PCM analysis + DSP configuration.
  final AudioService audio;

  /// AI/smart features orchestrator (chapters, summaries, flashcards...).
  final AIService ai;

  /// ffmpeg-backed clip/export engine.
  final ExportService export;

  /// Privacy & security posture, permissions, incognito, vault.
  final PrivacyService privacy;

  /// Accessibility configuration (subtitles, colour filters, gestures...).
  final AccessibilityService accessibility;

  /// Watch-together sync and social presence.
  final SyncService sync;

  /// Metadata enrichment (TMDB/TVDB/MusicBrainz...).
  final MetadataService metadata;

  /// Subtitle parsing and sidecar discovery.
  final SubtitleService subtitle;

  /// Community features: bookmarks, chapters, comments, playlists, recommendations.
  final CommunityService community;

  /// Hikmah mode: mindful consumption, reflection, comprehension, journaling, streaks.
  final HikmahModeService hikmah;

  /// Cross-device continuity: sync, handoff, clipboard, universal remote.
  final ContinuityService continuity;

  /// Developer & power-user features: API, plugins, scripting, analytics, shaders, integrations.
  final DeveloperService developer;
}
