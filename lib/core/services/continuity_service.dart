import 'package:flutter/foundation.dart';

import '../../features/continuity/domain/models/device_sync.dart';

/// Orchestrates cross-device continuity: playback sync, clipboard sharing,
/// device handoff, and universal remote control.
class ContinuityService extends ChangeNotifier {
  ContinuityService();

  final List<DeviceProfile> _devices = [];
  final List<ClipboardEntry> _clipboard = [];
  final List<HandoffSession> _handoffs = [];
  final List<RemoteCommand> _commands = [];
  SyncedState? _lastSyncedState;

  String? _localDeviceId;

  // ---------------------------------------------------------------------
  // Device management
  // ---------------------------------------------------------------------

  List<DeviceProfile> get devices => List.unmodifiable(_devices);
  String? get localDeviceId => _localDeviceId;

  DeviceProfile? get localDevice =>
      _devices.where((d) => d.isLocal).firstOrNull;

  List<DeviceProfile> get remoteDevices =>
      _devices.where((d) => !d.isLocal && d.isOnline).toList();

  void setLocalDevice(String id, String name, String platform) {
    _localDeviceId = id;
    _devices.removeWhere((d) => d.isLocal);
    _devices.add(DeviceProfile(
      id: id,
      name: name,
      platform: platform,
      isLocal: true,
      lastSeen: DateTime.now(),
      isOnline: true,
    ));
    notifyListeners();
  }

  DeviceProfile addRemoteDevice({
    required String id,
    required String name,
    required String platform,
  }) {
    final existing = _devices.where((d) => d.id == id).firstOrNull;
    if (existing != null) {
      final idx = _devices.indexOf(existing);
      _devices[idx] = existing.copyWith(
        lastSeen: DateTime.now(),
        isOnline: true,
      );
      notifyListeners();
      return _devices[idx];
    }
    final device = DeviceProfile(
      id: id,
      name: name,
      platform: platform,
      lastSeen: DateTime.now(),
    );
    _devices.add(device);
    notifyListeners();
    return device;
  }

  void removeDevice(String id) {
    _devices.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void setDeviceOnline(String id, bool online) {
    final idx = _devices.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    _devices[idx] = _devices[idx].copyWith(
      isOnline: online,
      lastSeen: DateTime.now(),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Playback position sync
  // ---------------------------------------------------------------------

  SyncedState? get lastSyncedState => _lastSyncedState;

  void syncPosition({
    required String deviceId,
    required String mediaId,
    required double positionSeconds,
    List<String> queue = const [],
    Map<String, dynamic>? extra,
  }) {
    _lastSyncedState = SyncedState(
      deviceId: deviceId,
      mediaId: mediaId,
      positionSeconds: positionSeconds,
      syncedAt: DateTime.now(),
      queue: queue,
      extra: extra,
    );
    notifyListeners();
  }

  SyncedState? getStateForDevice(String deviceId) {
    if (_lastSyncedState?.deviceId == deviceId) return _lastSyncedState;
    return null;
  }

  // ---------------------------------------------------------------------
  // Clipboard sync
  // ---------------------------------------------------------------------

  List<ClipboardEntry> get clipboard => List.unmodifiable(_clipboard);

  ClipboardEntry copyToClipboard({
    required String content,
    required ClipboardEntryType type,
    required String sourceDeviceId,
  }) {
    final entry = ClipboardEntry(
      id: 'clip-${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      type: type,
      sourceDeviceId: sourceDeviceId,
      createdAt: DateTime.now(),
    );
    _clipboard.insert(0, entry);
    if (_clipboard.length > 50) _clipboard.removeLast();
    notifyListeners();
    return entry;
  }

  ClipboardEntry? getLatestClipboard({ClipboardEntryType? type}) {
    if (type != null) {
      return _clipboard.where((e) => e.type == type).firstOrNull;
    }
    return _clipboard.firstOrNull;
  }

  void clearClipboard() {
    _clipboard.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Device handoff
  // ---------------------------------------------------------------------

  List<HandoffSession> get handoffs => List.unmodifiable(_handoffs);

  HandoffRequest initiateHandoff({
    required String toDeviceId,
    required String mediaId,
    required double positionSeconds,
  }) {
    final fromId = _localDeviceId ?? 'unknown';
    final session = HandoffSession(
      id: 'handoff-${DateTime.now().microsecondsSinceEpoch}',
      fromDeviceId: fromId,
      toDeviceId: toDeviceId,
      mediaId: mediaId,
      positionSeconds: positionSeconds,
      state: HandoffState.pending,
      createdAt: DateTime.now(),
    );
    _handoffs.add(session);
    notifyListeners();
    return HandoffRequest._(this, session);
  }

  void _acceptHandoff(String id) {
    final idx = _handoffs.indexWhere((h) => h.id == id);
    if (idx == -1) return;
    _handoffs[idx] = _handoffs[idx].copyWith(state: HandoffState.accepted);
    notifyListeners();
  }

  void _activateHandoff(String id) {
    final idx = _handoffs.indexWhere((h) => h.id == id);
    if (idx == -1) return;
    _handoffs[idx] = _handoffs[idx].copyWith(state: HandoffState.active);
    notifyListeners();
  }

  void completeHandoff(String id) {
    final idx = _handoffs.indexWhere((h) => h.id == id);
    if (idx == -1) return;
    _handoffs[idx] = _handoffs[idx].copyWith(
      state: HandoffState.completed,
      completedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void failHandoff(String id) {
    final idx = _handoffs.indexWhere((h) => h.id == id);
    if (idx == -1) return;
    _handoffs[idx] = _handoffs[idx].copyWith(state: HandoffState.failed);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Universal remote
  // ---------------------------------------------------------------------

  List<RemoteCommand> get commands => List.unmodifiable(_commands);

  RemoteCommand sendCommand({
    required RemoteCommandType type,
    required String targetDeviceId,
    Map<String, dynamic> payload = const {},
  }) {
    final cmd = RemoteCommand(
      id: 'cmd-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      targetDeviceId: targetDeviceId,
      payload: payload,
      sentAt: DateTime.now(),
    );
    _commands.insert(0, cmd);
    if (_commands.length > 100) _commands.removeLast();
    notifyListeners();
    return cmd;
  }

  void acknowledgeCommand(String id) {
    final idx = _commands.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _commands[idx] = _commands[idx].copyWith(state: RemoteCommandState.acknowledged);
    notifyListeners();
  }

  void completeCommand(String id) {
    final idx = _commands.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _commands[idx] = _commands[idx].copyWith(state: RemoteCommandState.completed);
    notifyListeners();
  }
}

/// Fluent builder for completing a handoff from the target device's perspective.
class HandoffRequest {
  HandoffRequest._(this._service, this._session);

  final ContinuityService _service;
  final HandoffSession _session;

  HandoffSession get session => _session;

  void accept() => _service._acceptHandoff(_session.id);
  void activate() => _service._activateHandoff(_session.id);
  void complete() => _service.completeHandoff(_session.id);
  void fail() => _service.failHandoff(_session.id);
}
