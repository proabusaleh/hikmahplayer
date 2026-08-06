import '../models/transcript.dart';
import '../models/transcript_search.dart';
import '../text_utils.dart';

/// In-memory search index over one or more transcripts.
///
/// Supports substring and per-token queries with a relevance score and
/// word-level hit locations (when the transcript has word timestamps).
class TranscriptSearchIndex {
  final List<Transcript> _transcripts = [];

  TranscriptSearchIndex({Iterable<Transcript>? transcripts}) {
    if (transcripts != null) _transcripts.addAll(transcripts);
  }

  int get transcriptCount => _transcripts.length;

  void add(Transcript transcript) => _transcripts.add(transcript);

  void addAll(Iterable<Transcript> transcripts) => _transcripts.addAll(transcripts);

  void clear() => _transcripts.clear();

  List<TranscriptSearchResult> search(
    String query, {
    String? mediaId,
    int limit = 20,
  }) {
    if (query.trim().isEmpty) return const [];

    final terms = TextUtils.significantTokens(query);
    final results = <TranscriptSearchResult>[];

    for (final transcript in _transcripts) {
      if (mediaId != null && transcript.mediaId != mediaId) continue;
      for (final segment in transcript.segments) {
        final match = _matchSegment(segment, query, terms);
        if (match != null) {
          results.add(TranscriptSearchResult(
            mediaId: transcript.mediaId,
            segment: segment,
            matchedWords: match.$1,
            matchStart: match.$2,
            matchEnd: match.$3,
            score: match.$4,
          ));
        }
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  (List<TranscriptWord>, int, int, double)? _matchSegment(
    TranscriptSegment segment,
    String query,
    List<String> terms,
  ) {
    final segLower = segment.text.toLowerCase();
    final queryLower = query.trim().toLowerCase();

    // Exact substring hit is the strongest signal.
    final exactIndex = segLower.indexOf(queryLower);
    if (exactIndex >= 0) {
      return (
        _wordsInRange(segment, exactIndex, exactIndex + queryLower.length),
        exactIndex,
        exactIndex + queryLower.length,
        1.0,
      );
    }

    if (terms.isEmpty) return null;

    // Token-based: find the best contiguous run of matched words.
    final tokens = TextUtils.tokenize(segment.text);
    var best = (-1, -1, 0.0); // (startToken, endToken, score)
    for (var i = 0; i < tokens.length; i++) {
      var matched = 0;
      for (final term in terms) {
        if (TextUtils.normalizeForSearch(tokens[i]) ==
            TextUtils.normalizeForSearch(term)) {
          matched = 1;
          break;
        }
      }
      if (matched == 0) continue;

      var end = i + 1;
      for (var j = i + 1; j < tokens.length; j++) {
        var m = 0;
        for (final term in terms) {
          if (TextUtils.normalizeForSearch(tokens[j]) ==
              TextUtils.normalizeForSearch(term)) {
            m = 1;
            break;
          }
        }
        if (m == 0) break;
        end = j + 1;
      }
      final score = (end - i) / terms.length;
      if (score > best.$3) {
        best = (i, end, score);
      }
    }

    if (best.$2 < 0) return null;

    final startIndex = _tokenStartOffset(segment.text, best.$1);
    final endIndex = _tokenEndOffset(segment.text, best.$2 - 1);
    return (
      _wordsInRange(segment, startIndex, endIndex),
      startIndex,
      endIndex,
      best.$3,
    );
  }

  List<TranscriptWord> _wordsInRange(
    TranscriptSegment segment,
    int startIndex,
    int endIndex,
  ) {
    if (segment.words.isEmpty) return const [];
    final wordStartIndex = _wordIndexAt(segment, startIndex);
    final wordEndIndex = _wordIndexAt(segment, endIndex);
    final from = wordStartIndex.clamp(0, segment.words.length);
    final to = (wordEndIndex + 1).clamp(from, segment.words.length);
    return segment.words.sublist(from, to);
  }

  /// Approximates which word contains character offset [charIndex] by walking
  /// the segment text and tracking character ranges per word.
  int _wordIndexAt(TranscriptSegment segment, int charIndex) {
    final tokens = TextUtils.tokenize(segment.text);
    var cursor = 0;
    for (var i = 0; i < tokens.length; i++) {
      final relative = segment.text
          .substring(cursor.clamp(0, segment.text.length))
          .toLowerCase()
          .indexOf(tokens[i].toLowerCase());
      if (relative < 0) break;
      final wordStart = cursor + relative;
      final wordEnd = wordStart + tokens[i].length;
      if (charIndex <= wordEnd) return i;
      cursor = wordEnd;
    }
    return tokens.length - 1;
  }

  int _tokenStartOffset(String text, int tokenIndex) {
    final tokens = TextUtils.tokenize(text);
    if (tokenIndex >= tokens.length) return text.length;
    final index = text.toLowerCase().indexOf(tokens[tokenIndex].toLowerCase());
    return index < 0 ? 0 : index;
  }

  int _tokenEndOffset(String text, int tokenIndex) {
    final tokens = TextUtils.tokenize(text);
    if (tokenIndex < 0 || tokenIndex >= tokens.length) return 0;
    final start = _tokenStartOffset(text, tokenIndex);
    return start + tokens[tokenIndex].length;
  }
}
