/// What kind of export a [ExportJob] represents.
enum ExportKind {
  clip,
  convert,
  gif,
  audioExtract,
  frames,
  singleFrame,
  merge,
  speed,
  burnSubtitles,
}

/// Lifecycle state of an [ExportJob].
enum ExportStatus { queued, running, succeeded, failed, cancelled }

/// Immutable snapshot of a single ffmpeg export run.
///
/// [progress] is a `0..1` value reported by the backend while running;
/// [args] records the exact ffmpeg argument list for debugging.
class ExportJob {
  /// Stable identifier.
  final String id;

  final ExportKind kind;

  final String inputPath;

  /// Destination file the backend writes to.
  final String outputPath;

  final ExportStatus status;

  /// Fraction of work done (`0..1`), meaningful while [status] is running.
  final double progress;

  /// Human readable error when [status] is failed.
  final String? error;

  final List<String> args;

  final DateTime startedAt;

  final DateTime? finishedAt;

  const ExportJob({
    required this.id,
    required this.kind,
    required this.inputPath,
    required this.outputPath,
    required this.status,
    this.progress = 0,
    this.error,
    this.args = const [],
    required this.startedAt,
    this.finishedAt,
  });

  bool get isRunning => status == ExportStatus.running;

  bool get isDone =>
      status == ExportStatus.succeeded || status == ExportStatus.failed;

  ExportJob copyWith({
    ExportStatus? status,
    double? progress,
    String? error,
    List<String>? args,
    DateTime? finishedAt,
  }) {
    return ExportJob(
      id: id,
      kind: kind,
      inputPath: inputPath,
      outputPath: outputPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      args: args ?? this.args,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'inputPath': inputPath,
        'outputPath': outputPath,
        'status': status.name,
        'progress': progress,
        'error': error,
        'args': args,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
      };

  factory ExportJob.fromJson(Map<String, dynamic> json) {
    return ExportJob(
      id: json['id'] as String,
      kind: ExportKind.values.asNameMap()[json['kind']] ?? ExportKind.clip,
      inputPath: json['inputPath'] as String,
      outputPath: json['outputPath'] as String,
      status: ExportStatus.values.asNameMap()[json['status']] ??
          ExportStatus.queued,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      error: json['error'] as String?,
      args: (json['args'] as List<dynamic>? ?? const []).cast<String>(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.parse(json['finishedAt'] as String),
    );
  }

  @override
  String toString() => 'ExportJob($kind, $status, ${(progress * 100).round()}%)';
}
