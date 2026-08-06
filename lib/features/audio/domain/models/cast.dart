/// Casting / streaming protocol of a destination.
enum CastProtocol {
  upnp,
  chromecast,
  airplay2,
  sonos,
  bluetooth,
}

/// Session state for a cast target.
enum CastSessionState { idle, connecting, streaming, paused, error }

/// A remote playback destination.
class CastDevice {
  final String id;
  final String name;
  final CastProtocol protocol;

  /// Whether this device supports lossless (PCM/FLAC) streaming.
  final bool lossless;

  final bool supportsRemoteControl;

  const CastDevice({
    required this.id,
    required this.name,
    required this.protocol,
    this.lossless = false,
    this.supportsRemoteControl = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'protocol': protocol.name,
        'lossless': lossless,
        'supportsRemoteControl': supportsRemoteControl,
      };

  factory CastDevice.fromJson(Map<String, dynamic> json) {
    return CastDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      protocol: CastProtocol.values.asNameMap()[json['protocol']] ??
          CastProtocol.upnp,
      lossless: json['lossless'] as bool? ?? false,
      supportsRemoteControl: json['supportsRemoteControl'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) => other is CastDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Live state of a cast session.
class CastSession {
  final CastDevice device;
  final CastSessionState state;
  final Duration position;
  final bool bitPerfectLossless;

  const CastSession({
    required this.device,
    this.state = CastSessionState.idle,
    this.position = Duration.zero,
    this.bitPerfectLossless = false,
  });

  CastSession copyWith({
    CastSessionState? state,
    Duration? position,
    bool? bitPerfectLossless,
  }) {
    return CastSession(
      device: device,
      state: state ?? this.state,
      position: position ?? this.position,
      bitPerfectLossless: bitPerfectLossless ?? this.bitPerfectLossless,
    );
  }

  @override
  String toString() => 'CastSession(${device.name}, ${state.name})';
}

/// Global casting settings.
class CastSettings {
  final bool losslessPreferred;
  final int bufferSeconds;

  const CastSettings({
    this.losslessPreferred = true,
    this.bufferSeconds = 5,
  });

  CastSettings copyWith({bool? losslessPreferred, int? bufferSeconds}) {
    return CastSettings(
      losslessPreferred: losslessPreferred ?? this.losslessPreferred,
      bufferSeconds: bufferSeconds ?? this.bufferSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'losslessPreferred': losslessPreferred,
        'bufferSeconds': bufferSeconds,
      };

  factory CastSettings.fromJson(Map<String, dynamic> json) {
    return CastSettings(
      losslessPreferred: json['losslessPreferred'] as bool? ?? true,
      bufferSeconds: json['bufferSeconds'] as int? ?? 5,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CastSettings &&
      other.losslessPreferred == losslessPreferred &&
      other.bufferSeconds == bufferSeconds;

  @override
  int get hashCode => Object.hash(losslessPreferred, bufferSeconds);
}
