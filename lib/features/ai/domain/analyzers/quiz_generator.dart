import 'dart:math';

import '../models/quiz.dart';
import '../models/transcript.dart';
import '../text_utils.dart';

/// Generates multiple-choice questions from a transcript by pairing definition
/// patterns with candidate distractors drawn from other segments.
class QuizGenerator {
  const QuizGenerator();

  /// Maximum questions to produce.
  int get maxQuestions => 10;

  List<QuizQuestion> generate(Transcript transcript, {int maxQuestions = 10}) {
    final segments = transcript.segments;
    if (segments.isEmpty) return const [];

    final rng = Random(transcript.mediaId.hashCode);
    final questions = <QuizQuestion>[];
    final usedPrompts = <String>{};

    for (final segment in segments) {
      if (questions.length >= maxQuestions) break;

      final fact = _extractFact(segment.text);
      if (fact == null) continue;
      if (!usedPrompts.add(fact.$1.toLowerCase())) continue;

      final distractors = _distractors(segments, fact.$2, rng);
      if (distractors.length < 3) continue;

      final options = [fact.$2, ...distractors]..shuffle(rng);
      questions.add(QuizQuestion(
        id: 'q-${transcript.mediaId}-${questions.length}',
        prompt: fact.$1,
        options: options,
        correctIndex: options.indexOf(fact.$2),
        explanation: segment.text.trim(),
        sourceStart: segment.start,
      ));
    }

    return questions;
  }

  /// Returns `(prompt, answer)` from a definition-style statement, else null.
  (String, String)? _extractFact(String text) {
    final tokens = TextUtils.tokenize(text);
    if (tokens.length < 4 || tokens.length > 22) return null;

    final cleaned = text
        .trim()
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
    final patterns = <RegExp>[
      RegExp(r'(.{3,80}?)\s+(is|are|was|were)\s+((?:the|a|an)?\s*.{3,80}?)$'),
      RegExp(r'((?:the|a|an)\s+.{3,80}?)\s+(means|refers to)\s+.{3,80}$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null && match.groupCount >= 3) {
        final subject = _capitalize(match.group(1)!.trim());
        final answer = match.group(3)!.trim();
        if (subject.isEmpty || answer.isEmpty) continue;
        return ('What ${match.group(2)}', answer);
      }
    }
    return null;
  }

  /// Gathers plausible distractors: other frequent terms + a few noun-phrase
  /// fragments from other segments. Excludes [correct] and related words.
  List<String> _distractors(
    List<TranscriptSegment> segments,
    String correct,
    Random rng,
  ) {
    final candidates = <String>[];
    final correctTokens = TextUtils.tokenize(correct.toLowerCase()).toSet();

    final counts = <String, int>{};
    for (final segment in segments) {
      for (final token in TextUtils.significantTokens(segment.text)) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
    }
    final frequent = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in frequent.take(20)) {
      if (!correctTokens.contains(entry.key)) {
        candidates.add(entry.key);
      }
    }

    for (final segment in segments) {
      if (candidates.length >= 6) break;
      final fragments = TextUtils.tokenize(segment.text);
      if (fragments.length >= 3) {
        final idx = rng.nextInt(fragments.length - 2);
        final phrase = fragments.sublist(idx, idx + 3).join(' ');
        if (!correctTokens.contains(phrase.toLowerCase()) &&
            phrase.length > 3) {
          candidates.add(phrase);
        }
      }
    }

    candidates.shuffle(rng);
    return candidates.take(3).toList();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
