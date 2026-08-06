import '../models/voice_command.dart';
import '../text_utils.dart';

/// Parses free-form voice input into a structured [VoiceCommand].
///
/// Pure-Dart keyword matching tuned for playback control, navigation,
/// note-taking and learning commands. Specific commands with payloads (seek,
/// speed, chapter) are matched before bare transport verbs so phrases like
/// "play at 1.5x speed" resolve to [VoiceCommandType.speed].
class VoiceCommandParser {
  const VoiceCommandParser();

  VoiceCommand parse(String raw) {
    final normalized = raw.trim().toLowerCase();
    final tokens = TextUtils.tokenize(normalized);
    if (tokens.isEmpty) {
      return VoiceCommand(type: VoiceCommandType.other, rawText: raw, confidence: 0);
    }

    final seek = _parseSeek(normalized, raw);
    if (seek != null) return seek;

    final speed = _parseSpeed(normalized, raw);
    if (speed != null) return speed;

    final chapter = _parseChapter(normalized, raw);
    if (chapter != null) return chapter;

    if (_hasAny(normalized, ['search for', 'find ', 'look for'])) {
      return VoiceCommand(
        type: VoiceCommandType.search,
        textValue: _extractAfter(normalized, ['search for', 'find ', 'look for']),
        rawText: raw,
        confidence: 0.8,
      );
    }

    if (tokens.contains('resume') || _hasAny(normalized, ['start playing'])) {
      return _simple(raw, VoiceCommandType.resume);
    }
    if (tokens.contains('play') || tokens.contains('start')) {
      return _simple(raw, VoiceCommandType.play);
    }
    if (tokens.contains('pause') || _hasAny(normalized, ['stop playing'])) {
      return _simple(raw, VoiceCommandType.pause);
    }
    if (tokens.contains('next') || tokens.contains('skip')) {
      return _simple(raw, VoiceCommandType.next);
    }
    if (tokens.contains('previous') || tokens.contains('back')) {
      return _simple(raw, VoiceCommandType.previous);
    }

    if (_hasAny(normalized, ['take a note', 'make a note', 'add note', 'note down'])) {
      return _simple(raw, VoiceCommandType.addNote);
    }
    if (_hasAny(normalized, ['bookmark', 'save this spot'])) {
      return _simple(raw, VoiceCommandType.bookmark);
    }

    if (_hasAny(normalized, ['show transcript', 'open transcript'])) {
      return _simple(raw, VoiceCommandType.showTranscript);
    }
    if (_hasAny(normalized, ['show quiz', 'start quiz'])) {
      return _simple(raw, VoiceCommandType.showQuiz);
    }
    if (_hasAny(normalized, ['show flashcards', 'start flashcards', 'review cards'])) {
      return _simple(raw, VoiceCommandType.showFlashcards);
    }

    return VoiceCommand(type: VoiceCommandType.other, rawText: raw, confidence: 0.3);
  }

  bool _hasAny(String text, List<String> needles) =>
      needles.any((n) => text.contains(n));

  VoiceCommand _simple(String raw, VoiceCommandType type) {
    return VoiceCommand(type: type, rawText: raw, confidence: 0.9);
  }

  VoiceCommand? _parseSeek(String normalized, String raw) {
    final matches = RegExp(
            r'(?:go to|skip to|jump to|seek to)?\s*(\d{1,3}):(\d{2})\b')
        .firstMatch(normalized);
    if (matches != null) {
      final minutes = int.parse(matches.group(1)!);
      final seconds = int.parse(matches.group(2)!);
      return VoiceCommand(
        type: VoiceCommandType.seek,
        numericValue: (Duration(minutes: minutes, seconds: seconds)).inMilliseconds.toDouble(),
        rawText: raw,
        confidence: 0.95,
      );
    }
    final secondsMatch = RegExp(r'\b(\d{1,3})\s*seconds\b').firstMatch(normalized);
    if (secondsMatch != null) {
      return VoiceCommand(
        type: VoiceCommandType.seek,
        numericValue: (int.parse(secondsMatch.group(1)!) * 1000).toDouble(),
        rawText: raw,
        confidence: 0.9,
      );
    }
    return null;
  }

  VoiceCommand? _parseChapter(String normalized, String raw) {
    final match = RegExp(r'(?:go to|jump to|chapter|open)\s+(chapter\s+)?(\d{1,3})\b')
        .firstMatch(normalized);
    if (match != null) {
      return VoiceCommand(
        type: VoiceCommandType.chapter,
        numericValue: int.parse(match.group(2)!).toDouble(),
        rawText: raw,
        confidence: 0.9,
      );
    }
    return null;
  }

  VoiceCommand? _parseSpeed(String normalized, String raw) {
    final match = RegExp(r'\b(\d+(?:\.\d+)?)\s*(?:x|times)\s*(?:speed)?')
        .firstMatch(normalized);
    if (match != null) {
      final speed = double.parse(match.group(1)!);
      if (speed >= 0.5 && speed <= 3.0) {
        return VoiceCommand(
          type: VoiceCommandType.speed,
          numericValue: speed,
          rawText: raw,
          confidence: 0.85,
        );
      }
    }
    return null;
  }

  String? _extractAfter(String text, List<String> prefixes) {
    for (final prefix in prefixes) {
      final index = text.indexOf(prefix);
      if (index >= 0) {
        final rest = text.substring(index + prefix.length).trim();
        if (rest.isNotEmpty) return rest;
      }
    }
    return null;
  }
}
