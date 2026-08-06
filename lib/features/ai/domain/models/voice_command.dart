/// An action a user can invoke by voice.
enum VoiceCommandType {
  play('Play'),
  pause('Pause'),
  resume('Resume'),
  next('Next'),
  previous('Previous'),
  seek('Seek'),
  chapter('Chapter'),
  search('Search'),
  addNote('Add note'),
  bookmark('Bookmark'),
  speed('Speed'),
  showTranscript('Show transcript'),
  showQuiz('Show quiz'),
  showFlashcards('Show flashcards'),
  other('Other');

  const VoiceCommandType(this.label);

  final String label;
}

/// A parsed voice command.
class VoiceCommand {
  final VoiceCommandType type;

  /// Numeric payload, e.g. seek target in milliseconds or target speed.
  final double? numericValue;

  /// Text payload, e.g. a search query.
  final String? textValue;

  /// Raw recognised text that produced this command.
  final String rawText;

  /// How confident the parser was (`0..1`).
  final double confidence;

  const VoiceCommand({
    required this.type,
    this.numericValue,
    this.textValue,
    required this.rawText,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'numericValue': numericValue,
        'textValue': textValue,
        'rawText': rawText,
        'confidence': confidence,
      };

  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    return VoiceCommand(
      type: VoiceCommandType.values.asNameMap()[json['type']] ??
          VoiceCommandType.other,
      numericValue: (json['numericValue'] as num?)?.toDouble(),
      textValue: json['textValue'] as String?,
      rawText: json['rawText'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  String toString() => 'VoiceCommand(${type.label}, raw="$rawText")';
}
