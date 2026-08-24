abstract class SettingsRepository {
  Future<bool> getOnboardingComplete();
  Future<void> setOnboardingComplete({required bool complete});

  Future<String?> getThemeModeName();
  Future<void> setThemeModeName(String? value);
  Future<int?> getSeedColorValue();
  Future<void> setSeedColorValue(int? value);

  Future<double> getPlaybackSpeed();
  Future<void> setPlaybackSpeed(double speed);

  Future<Duration> getResumePosition(String mediaId);
  Future<void> saveResumePosition(String mediaId, Duration position);
}
