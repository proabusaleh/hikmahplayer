import 'package:shared_preferences/shared_preferences.dart';

import '../services/accessibility_service.dart';
import '../services/ai_service.dart';
import '../services/audio_service.dart';
import '../services/community_service.dart';
import '../services/continuity_service.dart';
import '../services/developer_service.dart';
import '../services/export_service.dart';
import '../services/hikmah_service.dart';
import '../services/library_service.dart';
import '../services/media_scan_service.dart';
import '../services/metadata_service.dart';
import '../services/playback_service.dart';
import '../services/privacy_service.dart';
import '../services/subtitle_service.dart';
import '../services/sync_service.dart';
import '../storage/app_database.dart';
import '../storage/prefs_service.dart';
import '../storage/repositories/folder_repository.dart';
import '../storage/repositories/history_repository.dart';
import '../storage/repositories/media_repository.dart';
import '../storage/repositories/playlist_repository.dart';
import '../theme/theme_controller.dart';

/// Owns every long-lived application service.
///
/// The real services are constructed once in `main()` and shared through the
/// widget tree via [AppScope]. Tests can inject lightweight replacements by
/// passing them to the constructor — each slot defaults to the production
/// implementation.
class AppServices {
  AppServices({
    required this.prefs,
    AppDatabase? database,
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
  })  : database = database ?? AppDatabase(),
        _playbackOverride = playback,
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
        developer = developer ?? DeveloperService() {
    theme = ThemeController(prefs);
    media = MediaRepository(this.database);
    playlists = PlaylistRepository(this.database);
    history = HistoryRepository(this.database);
    folders = FolderRepository(this.database);
  }

  static Future<AppServices> create({
    AppDatabase? database,
  }) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    return AppServices(prefs: PrefsService(sharedPrefs), database: database);
  }

  /// Key-value preferences (SharedPreferences-backed).
  final PrefsService prefs;

  /// SQLite media library database (Drift).
  final AppDatabase database;

  /// Theme mode / color preferences controller.
  late final ThemeController theme;

  /// Media items repository (videos & audio).
  late final MediaRepository media;

  /// MediaStore scanner → persisted library importer.
  late final MediaScanService mediaScan = MediaScanService(media);

  /// Playlists repository.
  late final PlaylistRepository playlists;

  /// Play history repository.
  late final HistoryRepository history;

  /// Folder index repository.
  late final FolderRepository folders;

  /// Unified media playback engine (media_kit / libmpv + FFmpeg).
  ///
  /// Created lazily so tests can assemble an [AppServices] around an
  /// in-memory database without loading media_kit's native engine.
  late final PlaybackService playback = _playbackOverride ?? PlaybackService();

  /// Injection slot backing [playback]; `null` uses the real engine.
  final PlaybackService? _playbackOverride;

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
