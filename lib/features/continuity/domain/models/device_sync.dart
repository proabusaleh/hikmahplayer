/// A known device for cross-device continuity.
class DeviceProfile {
  final String id;
  final String name;
  final String platform;
  final bool isLocal;
  final DateTime lastSeen;
  final bool isOnline;

  const DeviceProfile({
    required this.id,
    required this.name,
    required this.platform,
    this.isLocal = false,
    required this.lastSeen,
    this.isOnline = true,
  });

  DeviceProfile copyWith({
    String? id,
    String? name,
    String? platform,
    bool? isLocal,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return DeviceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      isLocal: isLocal ?? this.isLocal,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform,
        'isLocal': isLocal,
        'lastSeen': lastSeen.toIso8601String(),
        'isOnline': isOnline,
      };

  factory DeviceProfile.fromJson(Map<String, dynamic> json) {
    return DeviceProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      isLocal: json['isLocal'] as bool? ?? false,
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Synced playback state across devices.
class SyncedState {
  final String deviceId;
  final String mediaId;
  final double positionSeconds;
  final DateTime syncedAt;
  final List<String> queue;
  final Map<String, dynamic>? extra;

  const SyncedState({
    required this.deviceId,
    required this.mediaId,
    required this.positionSeconds,
    required this.syncedAt,
    this.queue = const [],
    this.extra,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'mediaId': mediaId,
        'positionSeconds': positionSeconds,
        'syncedAt': syncedAt.toIso8601String(),
        'queue': queue,
        'extra': extra,
      };

  factory SyncedState.fromJson(Map<String, dynamic> json) {
    return SyncedState(
      deviceId: json['deviceId'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0,
      syncedAt: DateTime.tryParse(json['syncedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      queue: (json['queue'] as List<dynamic>? ?? const []).cast<String>(),
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }
}

/// A shared clipboard entry across devices.
class ClipboardEntry {
  final String id;
  final String content;
  final ClipboardEntryType type;
  final String sourceDeviceId;
  final DateTime createdAt;

  const ClipboardEntry({
    required this.id,
    required this.content,
    required this.type,
    required this.sourceDeviceId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type.name,
        'sourceDeviceId': sourceDeviceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClipboardEntry.fromJson(Map<String, dynamic> json) {
    return ClipboardEntry(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: ClipboardEntryType.values.asNameMap()[json['type']] ??
          ClipboardEntryType.text,
      sourceDeviceId: json['sourceDeviceId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

enum ClipboardEntryType { text, link, timestamp, note }

/// A session handoff request between devices.
class HandoffSession {
  final String id;
  final String fromDeviceId;
  final String toDeviceId;
  final String mediaId;
  final double positionSeconds;
  final HandoffState state;
  final DateTime createdAt;
  final DateTime? completedAt;

  const HandoffSession({
    required this.id,
    required this.fromDeviceId,
    required this.toDeviceId,
    required this.mediaId,
    required this.positionSeconds,
    this.state = HandoffState.pending,
    required this.createdAt,
    this.completedAt,
  });

  HandoffSession copyWith({
    String? id,
    String? fromDeviceId,
    String? toDeviceId,
    String? mediaId,
    double? positionSeconds,
    HandoffState? state,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return HandoffSession(
      id: id ?? this.id,
      fromDeviceId: fromDeviceId ?? this.fromDeviceId,
      toDeviceId: toDeviceId ?? this.toDeviceId,
      mediaId: mediaId ?? this.mediaId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromDeviceId': fromDeviceId,
        'toDeviceId': toDeviceId,
        'mediaId': mediaId,
        'positionSeconds': positionSeconds,
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory HandoffSession.fromJson(Map<String, dynamic> json) {
    return HandoffSession(
      id: json['id'] as String? ?? '',
      fromDeviceId: json['fromDeviceId'] as String? ?? '',
      toDeviceId: json['toDeviceId'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0,
      state: HandoffState.values.asNameMap()[json['state']] ??
          HandoffState.pending,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}

enum HandoffState { pending, accepted, active, completed, failed }

/// A remote command sent to another device.
class RemoteCommand {
  final String id;
  final RemoteCommandType type;
  final String targetDeviceId;
  final Map<String, dynamic> payload;
  final DateTime sentAt;
  final RemoteCommandState state;

  const RemoteCommand({
    required this.id,
    required this.type,
    required this.targetDeviceId,
    this.payload = const {},
    required this.sentAt,
    this.state = RemoteCommandState.pending,
  });

  RemoteCommand copyWith({
    String? id,
    RemoteCommandType? type,
    String? targetDeviceId,
    Map<String, dynamic>? payload,
    DateTime? sentAt,
    RemoteCommandState? state,
  }) {
    return RemoteCommand(
      id: id ?? this.id,
      type: type ?? this.type,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      payload: payload ?? this.payload,
      sentAt: sentAt ?? this.sentAt,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'targetDeviceId': targetDeviceId,
        'payload': payload,
        'sentAt': sentAt.toIso8601String(),
        'state': state.name,
      };

  factory RemoteCommand.fromJson(Map<String, dynamic> json) {
    return RemoteCommand(
      id: json['id'] as String? ?? '',
      type: RemoteCommandType.values.asNameMap()[json['type']] ??
          RemoteCommandType.play,
      targetDeviceId: json['targetDeviceId'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      state: RemoteCommandState.values.asNameMap()[json['state']] ??
          RemoteCommandState.pending,
    );
  }
}

enum RemoteCommandType { play, pause, seek, skipNext, skipPrevious, stop, setVolume }
enum RemoteCommandState { pending, sent, acknowledged, completed, failed }
