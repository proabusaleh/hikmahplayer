/// A single recognised word with a precise timestamp.
class TranscriptWord {
  final String text;
  final Duration start;
  final Duration end;

  /// Recognition confidence `0..1` (default `1` when unknown).
  final double confidence;

  const TranscriptWord({
    required this.text,
    required this.start,
    required this.end,
    this.confidence = 1.0,
  });

  Duration get duration => end - start;

  Map<String, dynamic> toJson() => {
        'text': text,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'confidence': confidence,
      };

  factory TranscriptWord.fromJson(Map<String, dynamic> json) {
    return TranscriptWord(
      text: json['text'] as String,
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  String toString() => text;
}

/// One contiguous block of recognised speech.
class TranscriptSegment {
  final Duration start;
  final Duration end;
  final String text;

  /// Speaker label (id from the transcript's [Transcript.speakers]).
  final String? speakerId;

  /// Segment-level recognition confidence `0..1`.
  final double confidence;

  /// Word-level timestamps when available.
  final List<TranscriptWord> words;

  const TranscriptSegment({
    required this.start,
    required this.end,
    required this.text,
    this.speakerId,
    this.confidence = 1.0,
    this.words = const [],
  });

  Duration get duration => end - start;

  bool contains(Duration position) => position >= start && position <= end;

  /// Whether this segment ends with sentence punctuation.
  bool get endsSentence {
    final t = text.trim();
    return t.isEmpty ||
        ['.', '!', '?', '"', ':', ';'].contains(t[t.length - 1]);
  }

  Map<String, dynamic> toJson() => {
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'text': text,
        'speakerId': speakerId,
        'confidence': confidence,
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
      text: json['text'] as String,
      speakerId: json['speakerId'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      words: (json['words'] as List<dynamic>? ?? const [])
          .map((w) => TranscriptWord.fromJson((w as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  String toString() => 'TranscriptSegment(${start.inMilliseconds}ms-'
      '${end.inMilliseconds}ms: $text)';
}

/// A labelled speaker.
class Speaker {
  final String id;
  final String label;

  const Speaker({required this.id, required this.label});

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }

  @override
  String toString() => 'Speaker($id, $label)';
}

/// A full speech-to-text result for one media item.
///
/// This is the central data structure every AI feature (chaptering,
/// summarising, flashcards, navigation, search) builds on. It is deliberately
/// engine-agnostic: the same shape serves Whisper, DeepSpeech or a cloud API.
class Transcript {
  final String mediaId;

  /// BCP-47 language code (e.g. `en`, `ar`), when known.
  final String? language;

  final List<TranscriptSegment> segments;
  final List<Speaker> speakers;

  const Transcript({
    required this.mediaId,
    this.language,
    this.segments = const [],
    this.speakers = const [],
  });

  /// Concatenated plain text.
  String get fullText => segments.map((s) => s.text).join(' ').trim();

  /// Approximate media duration covered by the transcript.
  Duration? get duration {
    if (segments.isEmpty) return null;
    return segments.last.end;
  }

  TranscriptSegment? segmentAt(Duration position) {
    for (final segment in segments) {
      if (segment.contains(position)) return segment;
    }
    return null;
  }

  /// The word whose range contains [position], if any.
  TranscriptWord? wordAt(Duration position) {
    for (final segment in segments) {
      for (final word in segment.words) {
        if (position >= word.start && position <= word.end) return word;
      }
    }
    return null;
  }

  Transcript copyWith({
    String? language,
    List<TranscriptSegment>? segments,
    List<Speaker>? speakers,
  }) {
    return Transcript(
      mediaId: mediaId,
      language: language ?? this.language,
      segments: segments ?? this.segments,
      speakers: speakers ?? this.speakers,
    );
  }

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'language': language,
        'segments': segments.map((s) => s.toJson()).toList(),
        'speakers': speakers.map((s) => s.toJson()).toList(),
      };

  factory Transcript.fromJson(Map<String, dynamic> json) {
    return Transcript(
      mediaId: json['mediaId'] as String,
      language: json['language'] as String?,
      segments: (json['segments'] as List<dynamic>? ?? const [])
          .map((s) => TranscriptSegment.fromJson((s as Map).cast<String, dynamic>()))
          .toList(),
      speakers: (json['speakers'] as List<dynamic>? ?? const [])
          .map((s) => Speaker.fromJson((s as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  String toString() => 'Transcript($mediaId, ${segments.length} segments, '
      '${segments.fold<int>(0, (sum, s) => sum + s.text.split(' ').length)} words)';
}
