import 'package:shared_preferences/shared_preferences.dart';

import 'pref_keys.dart';

class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const String defaultThemeMode = 'system';
  static const double defaultVolume = 1.0;
  static const double defaultBrightness = 1.0;
  static const String kDefaultVideoFit = 'contain';
  static const String defaultLoopMode = 'none';

  bool get isFirstLaunch => _prefs.getBool(PrefKeys.isFirstLaunch) ?? true;
  set isFirstLaunch(bool value) =>
      _prefs.setBool(PrefKeys.isFirstLaunch, value);

  bool get onboardingCompleted =>
      _prefs.getBool(PrefKeys.onboardingCompleted) ?? false;
  set onboardingCompleted(bool value) =>
      _prefs.setBool(PrefKeys.onboardingCompleted, value);

  String get appVersion => _prefs.getString(PrefKeys.appVersion) ?? '';
  set appVersion(String value) => _prefs.setString(PrefKeys.appVersion, value);

  int get lastScanTime => _prefs.getInt(PrefKeys.lastScanTime) ?? 0;
  set lastScanTime(int value) => _prefs.setInt(PrefKeys.lastScanTime, value);

  String get themeModeName =>
      _prefs.getString(PrefKeys.themeMode) ?? defaultThemeMode;
  set themeModeName(String value) => _prefs.setString(PrefKeys.themeMode, value);

  bool get useDynamicColor => _prefs.getBool(PrefKeys.useDynamicColor) ?? false;
  set useDynamicColor(bool value) =>
      _prefs.setBool(PrefKeys.useDynamicColor, value);

  int get seedColorIndex => _prefs.getInt(PrefKeys.seedColorIndex) ?? 0;
  set seedColorIndex(int value) => _prefs.setInt(PrefKeys.seedColorIndex, value);

  bool get usePureBlack => _prefs.getBool(PrefKeys.usePureBlack) ?? false;
  set usePureBlack(bool value) => _prefs.setBool(PrefKeys.usePureBlack, value);

  double get defaultPlaybackSpeed =>
      _prefs.getDouble(PrefKeys.defaultPlaybackSpeed) ?? 1.0;
  set defaultPlaybackSpeed(double value) =>
      _prefs.setDouble(PrefKeys.defaultPlaybackSpeed, value);

  bool get resumePlayback => _prefs.getBool(PrefKeys.resumePlayback) ?? true;
  set resumePlayback(bool value) =>
      _prefs.setBool(PrefKeys.resumePlayback, value);

  String get defaultVideoFit =>
      _prefs.getString(PrefKeys.defaultVideoFit) ?? kDefaultVideoFit;
  set defaultVideoFit(String value) =>
      _prefs.setString(PrefKeys.defaultVideoFit, value);

  bool get autoPlay => _prefs.getBool(PrefKeys.autoPlay) ?? false;
  set autoPlay(bool value) => _prefs.setBool(PrefKeys.autoPlay, value);

  String get loopMode =>
      _prefs.getString(PrefKeys.loopMode) ?? defaultLoopMode;
  set loopMode(String value) => _prefs.setString(PrefKeys.loopMode, value);

  double get lastVolume => _prefs.getDouble(PrefKeys.lastVolume) ?? defaultVolume;
  set lastVolume(double value) => _prefs.setDouble(PrefKeys.lastVolume, value);

  double get lastBrightness =>
      _prefs.getDouble(PrefKeys.lastBrightness) ?? defaultBrightness;
  set lastBrightness(double value) =>
      _prefs.setDouble(PrefKeys.lastBrightness, value);

  String get audioEqualizerPreset =>
      _prefs.getString(PrefKeys.audioEqualizerPreset) ?? 'flat';
  set audioEqualizerPreset(String value) =>
      _prefs.setString(PrefKeys.audioEqualizerPreset, value);

  bool get showLyrics => _prefs.getBool(PrefKeys.showLyrics) ?? true;
  set showLyrics(bool value) => _prefs.setBool(PrefKeys.showLyrics, value);

  String get videoSortBy => _prefs.getString(PrefKeys.videoSortBy) ?? 'name';
  set videoSortBy(String value) => _prefs.setString(PrefKeys.videoSortBy, value);

  String get videoSortOrder =>
      _prefs.getString(PrefKeys.videoSortOrder) ?? 'asc';
  set videoSortOrder(String value) =>
      _prefs.setString(PrefKeys.videoSortOrder, value);

  String get videoViewType =>
      _prefs.getString(PrefKeys.videoViewType) ?? 'grid';
  set videoViewType(String value) =>
      _prefs.setString(PrefKeys.videoViewType, value);

  String get audioSortBy => _prefs.getString(PrefKeys.audioSortBy) ?? 'name';
  set audioSortBy(String value) => _prefs.setString(PrefKeys.audioSortBy, value);

  String get audioSortOrder =>
      _prefs.getString(PrefKeys.audioSortOrder) ?? 'asc';
  set audioSortOrder(String value) =>
      _prefs.setString(PrefKeys.audioSortOrder, value);

  String get folderSortBy => _prefs.getString(PrefKeys.folderSortBy) ?? 'name';
  set folderSortBy(String value) =>
      _prefs.setString(PrefKeys.folderSortBy, value);

  List<String> get hiddenFolders =>
      _prefs.getStringList(PrefKeys.hiddenFolders) ?? [];
  set hiddenFolders(List<String> value) =>
      _prefs.setStringList(PrefKeys.hiddenFolders, value);

  bool get incognitoMode => _prefs.getBool(PrefKeys.incognitoMode) ?? false;
  set incognitoMode(bool value) =>
      _prefs.setBool(PrefKeys.incognitoMode, value);
}
