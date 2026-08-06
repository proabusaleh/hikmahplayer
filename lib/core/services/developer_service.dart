import 'package:flutter/foundation.dart';

import '../../features/developer/domain/models/developer_models.dart';
import '../../features/developer/domain/models/playback_analytics.dart';

/// Orchestrates developer & power-user features: REST API server config,
/// plugin management, scripting, playback analytics, log viewer, custom
/// shaders, and automation integrations (Home Assistant, Tasker, etc.).
class DeveloperService extends ChangeNotifier {
  DeveloperService();

  // ---------------------------------------------------------------------
  // REST API
  // ---------------------------------------------------------------------

  ApiServerConfig _apiConfig = const ApiServerConfig();
  bool _apiRunning = false;

  ApiServerConfig get apiConfig => _apiConfig;
  bool get apiRunning => _apiRunning;

  void setApiConfig(ApiServerConfig config) {
    _apiConfig = config;
    notifyListeners();
  }

  void toggleApiServer() {
    _apiConfig = _apiConfig.copyWith(enabled: !_apiConfig.enabled);
    _apiRunning = _apiConfig.enabled;
    notifyListeners();
  }

  void setApiPort(int port) {
    _apiConfig = _apiConfig.copyWith(port: port);
    notifyListeners();
  }

  void setApiAuth(ApiAuthMethod method, {String? token}) {
    _apiConfig = _apiConfig.copyWith(authMethod: method, authToken: token);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Plugins
  // ---------------------------------------------------------------------

  final List<Plugin> _plugins = [];

  List<Plugin> get plugins => List.unmodifiable(_plugins);

  void installPlugin(PluginManifest manifest) {
    if (_plugins.any((p) => p.manifest.id == manifest.id)) return;
    _plugins.add(Plugin(manifest: manifest, status: PluginStatus.installed));
    notifyListeners();
  }

  void uninstallPlugin(String id) {
    _plugins.removeWhere((p) => p.manifest.id == id);
    notifyListeners();
  }

  void togglePlugin(String id) {
    final idx = _plugins.indexWhere((p) => p.manifest.id == id);
    if (idx == -1) return;
    final p = _plugins[idx];
    _plugins[idx] = p.copyWith(
      status: p.status == PluginStatus.enabled
          ? PluginStatus.disabled
          : PluginStatus.enabled,
    );
    notifyListeners();
  }

  void setPluginSettings(String id, Map<String, dynamic> settings) {
    final idx = _plugins.indexWhere((p) => p.manifest.id == id);
    if (idx == -1) return;
    _plugins[idx] = _plugins[idx].copyWith(settings: settings);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Scripting
  // ---------------------------------------------------------------------

  final List<ScriptEntry> _scripts = [];

  List<ScriptEntry> get scripts => List.unmodifiable(_scripts);

  ScriptEntry addScript({
    required String name,
    required String code,
    ScriptLanguage language = ScriptLanguage.dart,
  }) {
    final script = ScriptEntry(
      id: 'script-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      code: code,
      language: language,
    );
    _scripts.add(script);
    notifyListeners();
    return script;
  }

  void updateScript(String id, {String? name, String? code}) {
    final idx = _scripts.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _scripts[idx] = _scripts[idx].copyWith(
      name: name,
      code: code,
    );
    notifyListeners();
  }

  void removeScript(String id) {
    _scripts.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Simulate running a script (returns mock output).
  void runScript(String id) {
    final idx = _scripts.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _scripts[idx] = _scripts[idx].copyWith(
      status: ScriptStatus.running,
      lastRunAt: DateTime.now(),
    );
    notifyListeners();
    // Simulate completion after a tick.
    Future.microtask(() {
      if (idx < _scripts.length && _scripts[idx].id == id) {
        _scripts[idx] = _scripts[idx].copyWith(
          status: ScriptStatus.idle,
          lastOutput: '[${_scripts[idx].language.name}] Script executed successfully.',
        );
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------------------
  // Playback analytics
  // ---------------------------------------------------------------------

  final List<MediaPlaybackStats> _mediaStats = [];
  final List<EngagementHeatmap> _heatmaps = [];
  final List<SkipAnalysis> _skipAnalyses = [];
  final List<SkipEvent> _recentSkips = [];

  List<MediaPlaybackStats> get mediaStats => List.unmodifiable(_mediaStats);
  List<EngagementHeatmap> get heatmaps => List.unmodifiable(_heatmaps);
  List<SkipAnalysis> get skipAnalyses => List.unmodifiable(_skipAnalyses);
  List<SkipEvent> get recentSkips => List.unmodifiable(_recentSkips);

  void recordPlay(String mediaId, {Duration duration = Duration.zero}) {
    final idx = _mediaStats.indexWhere((s) => s.mediaId == mediaId);
    if (idx >= 0) {
      final existing = _mediaStats[idx];
      final newCount = existing.playCount + 1;
      final totalTime = existing.totalWatchTime + duration;
      final avg = Duration(
        milliseconds: totalTime.inMilliseconds ~/ newCount,
      );
      final completion = duration.inSeconds > 0
          ? (duration.inSeconds / (existing.averageWatchTime.inSeconds > 0
              ? existing.averageWatchTime.inSeconds
              : duration.inSeconds)).clamp(0.0, 1.0)
          : 0.0;
      _mediaStats[idx] = MediaPlaybackStats(
        mediaId: mediaId,
        playCount: newCount,
        totalWatchTime: totalTime,
        averageWatchTime: avg,
        completionRate: (existing.completionRate + completion) / 2,
        skipCount: existing.skipCount,
        rewindCount: existing.rewindCount,
        firstPlayedAt: existing.firstPlayedAt,
        lastPlayedAt: DateTime.now(),
      );
    } else {
      _mediaStats.add(MediaPlaybackStats(
        mediaId: mediaId,
        playCount: 1,
        totalWatchTime: duration,
        averageWatchTime: duration,
        completionRate: 1.0,
        firstPlayedAt: DateTime.now(),
        lastPlayedAt: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  void recordSkip(SkipEvent event) {
    _recentSkips.insert(0, event);
    if (_recentSkips.length > 200) _recentSkips.removeLast();
    // Update per-media skip analysis.
    final idx = _skipAnalyses.indexWhere((s) => s.mediaId ==
        'media-at-${event.fromPositionSeconds}');
    final zone = _positionToZone(event.fromPositionSeconds);
    if (idx >= 0) {
      final existing = _skipAnalyses[idx];
      final newZones = Map<String, int>.from(existing.skipZones);
      newZones[zone] = (newZones[zone] ?? 0) + 1;
      final isRewind = event.type == SkipEventType.rewind;
      _skipAnalyses[idx] = SkipAnalysis(
        mediaId: existing.mediaId,
        totalSkips: existing.totalSkips + (isRewind ? 0 : 1),
        totalRewinds: existing.totalRewinds + (isRewind ? 1 : 0),
        events: [...existing.events, event],
        skipZones: newZones,
      );
    } else {
      _skipAnalyses.add(SkipAnalysis(
        mediaId: 'media-at-${event.fromPositionSeconds}',
        totalSkips: event.type == SkipEventType.rewind ? 0 : 1,
        totalRewinds: event.type == SkipEventType.rewind ? 1 : 0,
        events: [event],
        skipZones: {zone: 1},
      ));
    }
    notifyListeners();
  }

  void addHeatmapPoint(String mediaId, double position, double intensity,
      {Duration mediaDuration = Duration.zero}) {
    final idx = _heatmaps.indexWhere((h) => h.mediaId == mediaId);
    final point = HeatmapPoint(
      positionSeconds: position,
      intensity: intensity,
    );
    if (idx >= 0) {
      final existing = _heatmaps[idx];
      _heatmaps[idx] = EngagementHeatmap(
        mediaId: mediaId,
        points: [...existing.points, point],
        mediaDuration: mediaDuration,
      );
    } else {
      _heatmaps.add(EngagementHeatmap(
        mediaId: mediaId,
        points: [point],
        mediaDuration: mediaDuration,
      ));
    }
    notifyListeners();
  }

  PlaybackAnalyticsSummary get analyticsSummary {
    if (_mediaStats.isEmpty) {
      return const PlaybackAnalyticsSummary();
    }
    var totalPlays = 0;
    var totalWatchTime = Duration.zero;
    var totalCompletion = 0.0;
    var totalSkips = 0;
    var totalRewinds = 0;
    MediaPlaybackStats? mostPlayed;
    MediaPlaybackStats? leastPlayed;

    for (final s in _mediaStats) {
      totalPlays += s.playCount;
      totalWatchTime += s.totalWatchTime;
      totalCompletion += s.completionRate;
      totalSkips += s.skipCount;
      totalRewinds += s.rewindCount;
      if (mostPlayed == null || s.playCount > mostPlayed.playCount) {
        mostPlayed = s;
      }
      if (leastPlayed == null || s.playCount < leastPlayed.playCount) {
        leastPlayed = s;
      }
    }

    return PlaybackAnalyticsSummary(
      totalPlays: totalPlays,
      totalWatchTime: totalWatchTime,
      uniqueMedia: _mediaStats.length,
      averageCompletionRate: totalCompletion / _mediaStats.length,
      totalSkips: totalSkips,
      totalRewinds: totalRewinds,
      mostPlayed: mostPlayed,
      leastPlayed: leastPlayed,
    );
  }

  String _positionToZone(double seconds) {
    final bucket = (seconds ~/ 30) * 30;
    return '$bucket–${bucket + 30}s';
  }

  // ---------------------------------------------------------------------
  // Log viewer
  // ---------------------------------------------------------------------

  final List<LogEntry> _logs = [];
  LogLevel _logFilter = LogLevel.debug;

  List<LogEntry> get logs => List.unmodifiable(_logs);
  LogLevel get logFilter => _logFilter;

  void setLogFilter(LogLevel level) {
    _logFilter = level;
    notifyListeners();
  }

  List<LogEntry> get filteredLogs {
    return _logs.where((l) => l.level.index >= _logFilter.index).toList();
  }

  void log(LogLevel level, String message, {String? tag, String? stackTrace}) {
    _logs.insert(0, LogEntry(
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    ));
    if (_logs.length > 1000) _logs.removeLast();
    if (kDebugMode) {
      debugPrint('[${level.name.toUpperCase()}] ${tag ?? "Hikmah"}: $message');
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Custom shaders
  // ---------------------------------------------------------------------

  final List<ShaderPreset> _shaderPresets = [];

  List<ShaderPreset> get shaderPresets => List.unmodifiable(_shaderPresets);

  void addShaderPreset(ShaderPreset preset) {
    _shaderPresets.add(preset);
    notifyListeners();
  }

  void removeShaderPreset(String id) {
    _shaderPresets.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void toggleShaderPreset(String id) {
    final idx = _shaderPresets.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _shaderPresets[idx] = _shaderPresets[idx].copyWith(
      enabled: !_shaderPresets[idx].enabled,
    );
    notifyListeners();
  }

  void updateShaderParameters(String id, Map<String, double> params) {
    final idx = _shaderPresets.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _shaderPresets[idx] = _shaderPresets[idx].copyWith(parameters: params);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Automation integrations
  // ---------------------------------------------------------------------

  final List<AutomationIntegration> _integrations = [];
  final List<AutomationAction> _actions = [];

  List<AutomationIntegration> get integrations => List.unmodifiable(_integrations);
  List<AutomationAction> get actions => List.unmodifiable(_actions);

  void addIntegration(AutomationIntegration integration) {
    final idx = _integrations.indexWhere((i) => i.type == integration.type);
    if (idx >= 0) {
      _integrations[idx] = integration;
    } else {
      _integrations.add(integration);
    }
    notifyListeners();
  }

  void removeIntegration(IntegrationType type) {
    _integrations.removeWhere((i) => i.type == type);
    notifyListeners();
  }

  void toggleIntegration(IntegrationType type) {
    final idx = _integrations.indexWhere((i) => i.type == type);
    if (idx == -1) return;
    final i = _integrations[idx];
    _integrations[idx] = i.copyWith(
      status: i.status == IntegrationStatus.connected
          ? IntegrationStatus.disconnected
          : IntegrationStatus.connected,
    );
    notifyListeners();
  }

  void addAction(AutomationAction action) {
    _actions.add(action);
    notifyListeners();
  }

  void removeAction(String id) {
    _actions.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void toggleAction(String id) {
    final idx = _actions.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    _actions[idx] = _actions[idx].copyWith(enabled: !_actions[idx].enabled);
    notifyListeners();
  }
}
