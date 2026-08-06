/// A request to translate part of a transcript.
class TranslationRequest {
  final String mediaId;
  final Duration start;
  final Duration end;

  /// Source text to translate (usually the matching transcript slice).
  final String sourceText;

  /// Target language code (e.g. `ar`, `en`, `fr`).
  final String targetLanguage;

  const TranslationRequest({
    required this.mediaId,
    required this.start,
    required this.end,
    required this.sourceText,
    required this.targetLanguage,
  });

  /// Whether this request is still pending / unsent (no transcript id).
  bool get isPending => true;

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'sourceText': sourceText,
        'targetLanguage': targetLanguage,
      };

  factory TranslationRequest.fromJson(Map<String, dynamic> json) {
    return TranslationRequest(
      mediaId: json['mediaId'] as String,
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
      sourceText: json['sourceText'] as String,
      targetLanguage: json['targetLanguage'] as String,
    );
  }

  @override
  String toString() => 'TranslationRequest($targetLanguage, '
      '${start.inMilliseconds}-${end.inMilliseconds}ms)';
}
