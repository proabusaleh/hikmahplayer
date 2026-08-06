import '../models/concept.dart';
import '../models/transcript.dart';
import '../text_utils.dart';

/// Extracts key terms (concepts) from a transcript using term frequency and
/// part-of-speech-ish heuristics, and locates definition sentences.
class ConceptExtractor {
  const ConceptExtractor();

  /// Maximum concepts to return.
  int get maxConcepts => 12;

  List<Concept> extract(Transcript transcript) {
    // Token -> frequency across all segments.
    final counts = <String, int>{};
    for (final segment in transcript.segments) {
      for (final token in TextUtils.significantTokens(segment.text)) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return const [];

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final selected = entries.take(maxConcepts).map((e) => e.key).toList();

    return selected.map((label) {
      final occurrences = <ConceptOccurrence>[];
      for (final segment in transcript.segments) {
        if (!TextUtils.significantTokens(segment.text).contains(label)) {
          continue;
        }
        occurrences.add(ConceptOccurrence(
          mediaId: transcript.mediaId,
          start: segment.start,
          end: segment.end,
          context: _surroundingContext(segment.text, label),
        ));
      }
      final importance = (counts[label] ?? 0) /
          (entries.first.value == 0 ? 1 : entries.first.value);
      return Concept(
        id: 'concept-${transcript.mediaId}-${TextUtils.slugify(label)}',
        label: label,
        definition: _definition(transcript, label),
        importance: importance.clamp(0.0, 1.0),
        occurrences: occurrences,
      );
    }).toList();
  }

  String? _definition(Transcript transcript, String label) {
    for (final segment in transcript.segments) {
      final lower = segment.text.toLowerCase();
      final patterns = [
        '$label is',
        '$label means',
        '$label refers to',
        '$label describes',
        '$label was',
        'what is $label',
        'definition of $label',
      ];
      for (final pattern in patterns) {
        if (lower.contains(pattern)) {
          return segment.text.trim();
        }
      }
    }
    return null;
  }

  String _surroundingContext(String segmentText, String label) {
    final lower = segmentText.toLowerCase();
    final index = lower.indexOf(label.toLowerCase());
    if (index < 0) {
      final trimmed = segmentText.trim();
      return trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed;
    }
    final start = (index - 40).clamp(0, segmentText.length);
    final end = (index + label.length + 60).clamp(start, segmentText.length);
    return segmentText.substring(start, end).trim();
  }
}
