// ---------------------------------------------------------------------------
// REST API server configuration
// ---------------------------------------------------------------------------

enum ApiAuthMethod { none, token, basic }

class ApiRoute {
  final String method;
  final String path;
  final String description;
  final bool enabled;

  const ApiRoute({
    required this.method,
    required this.path,
    required this.description,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'path': path,
        'description': description,
        'enabled': enabled,
      };

  factory ApiRoute.fromJson(Map<String, dynamic> json) {
    return ApiRoute(
      method: json['method'] as String? ?? 'GET',
      path: json['path'] as String? ?? '/',
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class ApiServerConfig {
  final bool enabled;
  final int port;
  final ApiAuthMethod authMethod;
  final String? authToken;
  final List<String> allowedOrigins;
  final List<ApiRoute> customRoutes;

  const ApiServerConfig({
    this.enabled = false,
    this.port = 8080,
    this.authMethod = ApiAuthMethod.token,
    this.authToken,
    this.allowedOrigins = const ['*'],
    this.customRoutes = const [],
  });

  ApiServerConfig copyWith({
    bool? enabled,
    int? port,
    ApiAuthMethod? authMethod,
    String? authToken,
    List<String>? allowedOrigins,
    List<ApiRoute>? customRoutes,
  }) {
    return ApiServerConfig(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
      authMethod: authMethod ?? this.authMethod,
      authToken: authToken ?? this.authToken,
      allowedOrigins: allowedOrigins ?? this.allowedOrigins,
      customRoutes: customRoutes ?? this.customRoutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'port': port,
        'authMethod': authMethod.name,
        'authToken': authToken,
        'allowedOrigins': allowedOrigins,
        'customRoutes': customRoutes.map((r) => r.toJson()).toList(),
      };

  factory ApiServerConfig.fromJson(Map<String, dynamic> json) {
    return ApiServerConfig(
      enabled: json['enabled'] as bool? ?? false,
      port: json['port'] as int? ?? 8080,
      authMethod: ApiAuthMethod.values.asNameMap()[json['authMethod']] ??
          ApiAuthMethod.token,
      authToken: json['authToken'] as String?,
      allowedOrigins: (json['allowedOrigins'] as List<dynamic>? ?? const ['*']).cast<String>(),
      customRoutes: (json['customRoutes'] as List<dynamic>? ?? const [])
          .map((e) => ApiRoute.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  static const builtInRoutes = [
    ApiRoute(method: 'GET', path: '/api/status', description: 'Player status'),
    ApiRoute(method: 'GET', path: '/api/queue', description: 'Current queue'),
    ApiRoute(method: 'POST', path: '/api/play', description: 'Play media'),
    ApiRoute(method: 'POST', path: '/api/pause', description: 'Pause playback'),
    ApiRoute(method: 'POST', path: '/api/seek', description: 'Seek to position'),
    ApiRoute(method: 'POST', path: '/api/volume', description: 'Set volume'),
    ApiRoute(method: 'GET', path: '/api/library', description: 'List library items'),
    ApiRoute(method: 'GET', path: '/api/stats', description: 'Playback statistics'),
    ApiRoute(method: 'POST', path: '/api/webhook', description: 'Register webhook'),
  ];
}

// ---------------------------------------------------------------------------
// Plugin system
// ---------------------------------------------------------------------------

enum PluginStatus { installed, enabled, disabled, error }

class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final String? homepage;

  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    this.homepage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'author': author,
        'description': description,
        'homepage': homepage,
      };

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '0.0.0',
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      homepage: json['homepage'] as String?,
    );
  }
}

class Plugin {
  final PluginManifest manifest;
  final PluginStatus status;
  final String? errorMessage;
  final Map<String, dynamic> settings;

  const Plugin({
    required this.manifest,
    this.status = PluginStatus.installed,
    this.errorMessage,
    this.settings = const {},
  });

  Plugin copyWith({
    PluginManifest? manifest,
    PluginStatus? status,
    String? errorMessage,
    Map<String, dynamic>? settings,
  }) {
    return Plugin(
      manifest: manifest ?? this.manifest,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'manifest': manifest.toJson(),
        'status': status.name,
        'errorMessage': errorMessage,
        'settings': settings,
      };

  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      manifest: PluginManifest.fromJson(
          (json['manifest'] as Map?)?.cast<String, dynamic>() ?? const {}),
      status: PluginStatus.values.asNameMap()[json['status']] ??
          PluginStatus.installed,
      errorMessage: json['errorMessage'] as String?,
      settings: (json['settings'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

// ---------------------------------------------------------------------------
// Scripting engine
// ---------------------------------------------------------------------------

enum ScriptLanguage { lua, python, dart, javascript }

enum ScriptStatus { idle, running, error }

class ScriptEntry {
  final String id;
  final String name;
  final String code;
  final ScriptLanguage language;
  final ScriptStatus status;
  final String? lastOutput;
  final String? errorMessage;
  final DateTime? lastRunAt;

  const ScriptEntry({
    required this.id,
    required this.name,
    required this.code,
    this.language = ScriptLanguage.dart,
    this.status = ScriptStatus.idle,
    this.lastOutput,
    this.errorMessage,
    this.lastRunAt,
  });

  ScriptEntry copyWith({
    String? id,
    String? name,
    String? code,
    ScriptLanguage? language,
    ScriptStatus? status,
    String? lastOutput,
    String? errorMessage,
    DateTime? lastRunAt,
  }) {
    return ScriptEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      language: language ?? this.language,
      status: status ?? this.status,
      lastOutput: lastOutput ?? this.lastOutput,
      errorMessage: errorMessage ?? this.errorMessage,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'language': language.name,
        'status': status.name,
        'lastOutput': lastOutput,
        'errorMessage': errorMessage,
        'lastRunAt': lastRunAt?.toIso8601String(),
      };

  factory ScriptEntry.fromJson(Map<String, dynamic> json) {
    return ScriptEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      language: ScriptLanguage.values.asNameMap()[json['language']] ??
          ScriptLanguage.dart,
      status: ScriptStatus.values.asNameMap()[json['status']] ??
          ScriptStatus.idle,
      lastOutput: json['lastOutput'] as String?,
      errorMessage: json['errorMessage'] as String?,
      lastRunAt: DateTime.tryParse(json['lastRunAt'] as String? ?? ''),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom shader support
// ---------------------------------------------------------------------------

class ShaderPreset {
  final String id;
  final String name;
  final String fragmentCode;
  final Map<String, double> parameters;
  final bool enabled;

  const ShaderPreset({
    required this.id,
    required this.name,
    required this.fragmentCode,
    this.parameters = const {},
    this.enabled = true,
  });

  ShaderPreset copyWith({
    String? id,
    String? name,
    String? fragmentCode,
    Map<String, double>? parameters,
    bool? enabled,
  }) {
    return ShaderPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      fragmentCode: fragmentCode ?? this.fragmentCode,
      parameters: parameters ?? this.parameters,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fragmentCode': fragmentCode,
        'parameters': parameters,
        'enabled': enabled,
      };

  factory ShaderPreset.fromJson(Map<String, dynamic> json) {
    return ShaderPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fragmentCode: json['fragmentCode'] as String? ?? '',
      parameters: (json['parameters'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0)),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

// ---------------------------------------------------------------------------
// Log viewer
// ---------------------------------------------------------------------------

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final String? stackTrace;

  const LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'message': message,
        'tag': tag,
        'timestamp': timestamp.toIso8601String(),
        'stackTrace': stackTrace,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.asNameMap()[json['level']] ?? LogLevel.info,
      message: json['message'] as String? ?? '',
      tag: json['tag'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      stackTrace: json['stackTrace'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Smart home / automation integrations
// ---------------------------------------------------------------------------

enum IntegrationType { homeAssistant, tasker, shortcuts, mqtt, webhook }

enum IntegrationStatus { disconnected, connected, error }

class AutomationIntegration {
  final IntegrationType type;
  final String name;
  final IntegrationStatus status;
  final Map<String, dynamic> config;
  final String? errorMessage;
  final DateTime? lastSyncAt;

  const AutomationIntegration({
    required this.type,
    required this.name,
    this.status = IntegrationStatus.disconnected,
    this.config = const {},
    this.errorMessage,
    this.lastSyncAt,
  });

  AutomationIntegration copyWith({
    IntegrationType? type,
    String? name,
    IntegrationStatus? status,
    Map<String, dynamic>? config,
    String? errorMessage,
    DateTime? lastSyncAt,
  }) {
    return AutomationIntegration(
      type: type ?? this.type,
      name: name ?? this.name,
      status: status ?? this.status,
      config: config ?? this.config,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'status': status.name,
        'config': config,
        'errorMessage': errorMessage,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
      };

  factory AutomationIntegration.fromJson(Map<String, dynamic> json) {
    return AutomationIntegration(
      type: IntegrationType.values.asNameMap()[json['type']] ??
          IntegrationType.webhook,
      name: json['name'] as String? ?? '',
      status: IntegrationStatus.values.asNameMap()[json['status']] ??
          IntegrationStatus.disconnected,
      config: (json['config'] as Map<String, dynamic>?) ?? const {},
      errorMessage: json['errorMessage'] as String?,
      lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
    );
  }
}

class AutomationAction {
  final String id;
  final String name;
  final IntegrationType integrationType;
  final String action;
  final Map<String, dynamic> payload;
  final bool enabled;

  const AutomationAction({
    required this.id,
    required this.name,
    required this.integrationType,
    required this.action,
    this.payload = const {},
    this.enabled = true,
  });

  AutomationAction copyWith({
    String? id,
    String? name,
    IntegrationType? integrationType,
    String? action,
    Map<String, dynamic>? payload,
    bool? enabled,
  }) {
    return AutomationAction(
      id: id ?? this.id,
      name: name ?? this.name,
      integrationType: integrationType ?? this.integrationType,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'integrationType': integrationType.name,
        'action': action,
        'payload': payload,
        'enabled': enabled,
      };

  factory AutomationAction.fromJson(Map<String, dynamic> json) {
    return AutomationAction(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      integrationType: IntegrationType.values.asNameMap()[json['integrationType']] ??
          IntegrationType.webhook,
      action: json['action'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
