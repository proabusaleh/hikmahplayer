import '../models/flashcard.dart';
import '../models/transcript.dart';
import '../text_utils.dart';

/// Generates flashcards from definition-style statements in a transcript.
class FlashcardGenerator {
  const FlashcardGenerator();

  /// Maximum cards to produce.
  int get maxCards => 20;

  List<Flashcard> generate(
    Transcript transcript, {
    int maxCards = 20,
    DateTime? createdAt,
  }) {
    final cards = <Flashcard>[];
    final seen = <String>{};

    for (final segment in transcript.segments) {
      if (cards.length >= maxCards) break;
      final fact = _extractFact(segment.text);
      if (fact == null) continue;
      if (!seen.add(fact.$1.toLowerCase())) continue;

      cards.add(Flashcard(
        id: 'card-${transcript.mediaId}-${cards.length}',
        mediaId: transcript.mediaId,
        front: fact.$1,
        back: fact.$2,
        sourceStart: segment.start,
        sourceEnd: segment.end,
        createdAt: createdAt ?? DateTime.now(),
      ));
    }

    return cards;
  }

  (String, String)? _extractFact(String text) {
    final tokens = TextUtils.tokenize(text);
    if (tokens.length < 4 || tokens.length > 24) return null;

    final cleaned = text
        .trim()
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
    final pattern = RegExp(
        r'(.{3,90}?)\s+(is|are|was|were)\s+((?:the|a|an)?\s*.{3,90}?)$');
    final match = pattern.firstMatch(cleaned);
    if (match == null || match.groupCount < 3) return null;

    final subject = _capitalize(match.group(1)!.trim());
    final answer = match.group(3)!.trim();
    if (subject.isEmpty || answer.isEmpty) return null;

    // Flashcards work best on terse facts, not long sentences.
    if (subject.length > 60 || answer.length > 90) return null;

    return ('$subject ?', answer);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
