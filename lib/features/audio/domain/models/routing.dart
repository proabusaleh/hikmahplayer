/// Physical audio output device kind.
enum AudioDeviceType {
  speaker,
  headphones,
  bluetooth,
  hdmi,
  usb,
  virtual,
}

/// One row of the routing matrix: which app goes to which device.
class AudioRoute {
  /// Application identifier (e.g. `media-player`, `notifications`).
  final String appName;

  final String deviceId;
  final AudioDeviceType deviceType;

  /// Whether this route is currently the active one for [appName].
  final bool active;

  const AudioRoute({
    required this.appName,
    required this.deviceId,
    required this.deviceType,
    this.active = false,
  });

  AudioRoute copyWith({bool? active, String? deviceId, AudioDeviceType? deviceType}) {
    return AudioRoute(
      appName: appName,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'deviceId': deviceId,
        'deviceType': deviceType.name,
        'active': active,
      };

  factory AudioRoute.fromJson(Map<String, dynamic> json) {
    return AudioRoute(
      appName: json['appName'] as String,
      deviceId: json['deviceId'] as String,
      deviceType: AudioDeviceType.values.asNameMap()[json['deviceType']] ??
          AudioDeviceType.speaker,
      active: json['active'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AudioRoute &&
      other.appName == appName &&
      other.deviceId == deviceId &&
      other.deviceType == deviceType &&
      other.active == active;

  @override
  int get hashCode => Object.hash(appName, deviceId, deviceType, active);
}

/// Per-application audio routing matrix.
class RoutingMatrix {
  final List<AudioRoute> routes;

  const RoutingMatrix({this.routes = const []});

  List<AudioRoute> routesFor(String appName) =>
      routes.where((r) => r.appName == appName).toList();

  AudioRoute? activeRouteFor(String appName) {
    final matches = routesFor(appName);
    for (final route in matches) {
      if (route.active) return route;
    }
    return matches.isEmpty ? null : matches.first;
  }

  RoutingMatrix setActive({
    required String appName,
    required String deviceId,
  }) {
    return RoutingMatrix(routes: [
      for (final route in routes)
        route.appName == appName
            ? route.copyWith(active: route.deviceId == deviceId)
            : route,
    ]);
  }

  RoutingMatrix addRoute(AudioRoute route) =>
      RoutingMatrix(routes: [...routes, route]);

  Map<String, dynamic> toJson() =>
      {'routes': routes.map((r) => r.toJson()).toList()};

  factory RoutingMatrix.fromJson(Map<String, dynamic> json) {
    return RoutingMatrix(
      routes: (json['routes'] as List<dynamic>? ?? const [])
          .map((r) => AudioRoute.fromJson((r as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RoutingMatrix && _routeListEquals(other.routes, routes);

  @override
  int get hashCode => Object.hashAll(routes);
}

bool _routeListEquals(List<AudioRoute> a, List<AudioRoute> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
