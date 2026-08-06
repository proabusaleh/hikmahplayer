enum PartyControlMode { host, democratic }

class PartySettings {
  final PartyControlMode controlMode;
  final bool allowGuestSeek;
  final bool allowGuestPause;
  final bool syncChat;

  const PartySettings({
    this.controlMode = PartyControlMode.host,
    this.allowGuestSeek = false,
    this.allowGuestPause = false,
    this.syncChat = true,
  });

  PartySettings copyWith({
    PartyControlMode? controlMode,
    bool? allowGuestSeek,
    bool? allowGuestPause,
    bool? syncChat,
  }) =>
      PartySettings(
        controlMode: controlMode ?? this.controlMode,
        allowGuestSeek: allowGuestSeek ?? this.allowGuestSeek,
        allowGuestPause: allowGuestPause ?? this.allowGuestPause,
        syncChat: syncChat ?? this.syncChat,
      );

  Map<String, dynamic> toJson() => {
        'controlMode': controlMode.name,
        'allowGuestSeek': allowGuestSeek,
        'allowGuestPause': allowGuestPause,
        'syncChat': syncChat,
      };

  factory PartySettings.fromJson(Map<String, dynamic> json) => PartySettings(
        controlMode:
            PartyControlMode.values.asNameMap()[json['controlMode']] ?? PartyControlMode.host,
        allowGuestSeek: json['allowGuestSeek'] as bool? ?? false,
        allowGuestPause: json['allowGuestPause'] as bool? ?? false,
        syncChat: json['syncChat'] as bool? ?? true,
      );
}
