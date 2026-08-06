import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/chapter_segmenter.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/concept_extractor.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/content_classifier.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/extractive_summarizer.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/flashcard_generator.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/key_moment_scorer.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/knowledge_graph_builder.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/quiz_generator.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/smart_scrubber.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/transcript_search_index.dart';
import 'package:hikmahplayer/features/ai/domain/analyzers/voice_command_parser.dart';
import 'package:hikmahplayer/features/ai/domain/models/content_classification.dart';
import 'package:hikmahplayer/features/ai/domain/models/transcript.dart';
import 'package:hikmahplayer/features/ai/domain/models/voice_command.dart';
import 'package:hikmahplayer/features/ai/domain/text_utils.dart';

Transcript _lecture() {
  return const Transcript(
    mediaId: 'm1',
    language: 'en',
    segments: [
      TranscriptSegment(start: Duration.zero, end: Duration(seconds: 5), text: 'Welcome to the lesson on photosynthesis.'),
      TranscriptSegment(start: Duration(seconds: 5), end: Duration(seconds: 9), text: 'Photosynthesis is the process plants use to make food.'),
      TranscriptSegment(start: Duration(seconds: 9), end: Duration(seconds: 14), text: 'The key ingredient is chlorophyll.'),
      TranscriptSegment(start: Duration(seconds: 14), end: Duration(seconds: 20), text: 'Remember, water and sunlight are essential.'),
      TranscriptSegment(start: Duration(seconds: 20), end: Duration(seconds: 26), text: 'Now let us discuss cellular respiration.'),
      TranscriptSegment(start: Duration(seconds: 26), end: Duration(seconds: 31), text: 'Respiration is how cells release energy.'),
      TranscriptSegment(start: Duration(seconds: 31), end: Duration(seconds: 38), text: 'The mitochondria is the power house of the cell.'),
      TranscriptSegment(start: Duration(seconds: 38), end: Duration(seconds: 45), text: 'Finally we will examine the human circulatory system.'),
      TranscriptSegment(start: Duration(seconds: 45), end: Duration(seconds: 52), text: 'The heart pumps blood through arteries and veins.'),
      TranscriptSegment(start: Duration(seconds: 52), end: Duration(seconds: 58), text: 'Thank you and see you next time.'),
    ],
  );
}

void main() {
  group('TextUtils', () {
    test('tokenize lowercases and strips punctuation', () {
      expect(TextUtils.tokenize('Hello, World! It\'s great.'),
          ['hello', 'world', 'it\'s', 'great']);
    });

    test('significantTokens drops stopwords and short tokens', () {
      expect(TextUtils.significantTokens('the photosynthesis is key'),
          ['photosynthesis', 'key']);
    });

    test('sentences split on terminal punctuation', () {
      expect(TextUtils.sentences('One. Two! Three?'),
          ['One.', 'Two!', 'Three?']);
    });

    test('normalizeForSearch normalizes Arabic', () {
      expect(TextUtils.normalizeForSearch('قَلْب'), 'قلب');
      expect(TextUtils.normalizeArabic('أحمد إبراهيم'), 'احمد ابراهيم');
    });

    test('similarity is 1 for equal strings and symmetric', () {
      expect(TextUtils.similarity('hello', 'hello'), 1.0);
      expect(TextUtils.similarity('hello', 'hell'), greaterThan(0));
      expect(TextUtils.similarity('abc', 'xyz'), lessThan(0.5));
      expect(TextUtils.similarity('', 'x'), 0.0);
    });

    test('slugify is deterministic and safe', () {
      expect(TextUtils.slugify('Hello World!'), 'hello-world');
      expect(TextUtils.slugify('المفاهيم'), 'المفاهيم');
      expect(TextUtils.slugify('??'), 'item');
    });
  });

  group('ChapterSegmenter', () {
    test('produces chapters covering the transcript', () {
      final chapters = const ChapterSegmenter().segment(_lecture());
      expect(chapters, isNotEmpty);
      expect(chapters.first.start, _lecture().segments.first.start);
      expect(chapters.last.end, _lecture().segments.last.end);
      for (final chapter in chapters) {
        expect(chapter.mediaId, 'm1');
        expect(chapter.title, isNotEmpty);
      }
    });

    test('empty transcript yields no chapters', () {
      expect(const ChapterSegmenter().segment(const Transcript(mediaId: 'x')),
          isEmpty);
    });

    test('chapter titles are distinct across topic shifts', () {
      final chapters = const ChapterSegmenter().segment(_lecture());
      final titles = chapters.map((c) => c.title).toSet();
      expect(titles.length, greaterThanOrEqualTo(2),
          reason: 'expected topic shifts: $titles');
    });
  });

  group('KeyMomentScorer', () {
    test('picks non-overlapping moments with reasons', () {
      final moments = const KeyMomentScorer().score(_lecture(), top: 3);
      expect(moments, isNotEmpty);
      expect(moments.length, lessThanOrEqualTo(3));
      for (final moment in moments) {
        expect(moment.score, inInclusiveRange(0, 1));
        expect(moment.label, isNotEmpty);
      }
      // Segments containing "remember" should score high.
      expect(moments.first.score, greaterThanOrEqualTo(0.2));
    });

    test('empty transcript yields no moments', () {
      expect(const KeyMomentScorer().score(const Transcript(mediaId: 'x')),
          isEmpty);
    });
  });

  group('ExtractiveSummarizer', () {
    test('summary preserves headline, key points and compression', () {
      final summary = const ExtractiveSummarizer().summarize(_lecture());
      expect(summary.mediaId, 'm1');
      expect(summary.headline, isNotEmpty);
      expect(summary.paragraphs, isNotEmpty);
      expect(summary.keyPoints, isNotEmpty);
      expect(summary.compressionRatio, inInclusiveRange(0.0, 1.0));
      expect(summary.compressionRatio, lessThan(1.0));
    });

    test('empty transcript yields an empty summary', () {
      final summary =
          const ExtractiveSummarizer().summarize(const Transcript(mediaId: 'x'));
      expect(summary.paragraphs, isEmpty);
    });
  });

  group('ConceptExtractor', () {
    test('extracts frequent terms with occurrences and definitions', () {
      final concepts = const ConceptExtractor().extract(_lecture());
      expect(concepts, isNotEmpty);
      expect(concepts.length, lessThanOrEqualTo(12));

      final photosynthesis =
          concepts.firstWhere((c) => c.label == 'photosynthesis');
      expect(photosynthesis.occurrences, isNotEmpty);
      expect(photosynthesis.occurrences.every((o) => o.mediaId == 'm1'), isTrue);
      expect(photosynthesis.definition, isNotNull);
      expect(photosynthesis.importance, inInclusiveRange(0.0, 1.0));
    });

    test('no text yields no concepts', () {
      expect(const ConceptExtractor().extract(const Transcript(mediaId: 'x')),
          isEmpty);
    });
  });

  group('QuizGenerator', () {
    test('generates questions about definition facts', () {
      final questions = const QuizGenerator().generate(_lecture());
      expect(questions, isNotEmpty);
      for (final question in questions) {
        expect(question.options, hasLength(4));
        expect(question.correctIndex, inInclusiveRange(0, 3));
        expect(question.prompt, isNotEmpty);
        expect(question.sourceStart, isNotNull);
      }
      // Options must contain the answer.
      final first = questions.first;
      expect(first.options[first.correctIndex], first.options[first.correctIndex]);
    });

    test('maxQuestions is respected', () {
      final questions = const QuizGenerator().generate(_lecture(), maxQuestions: 2);
      expect(questions.length, lessThanOrEqualTo(2));
    });
  });

  group('FlashcardGenerator', () {
    test('creates cards from definition statements', () {
      final now = DateTime(2026, 1, 1);
      final cards =
          const FlashcardGenerator().generate(_lecture(), createdAt: now);
      expect(cards, isNotEmpty);
      final photosynthesis =
          cards.firstWhere((c) => c.front.contains('Photosynthesis'));
      expect(photosynthesis.back, contains('process'));
      expect(photosynthesis.sourceStart, isNotNull);
      expect(photosynthesis.sourceEnd, isNotNull);
    });
  });

  group('ContentClassifier', () {
    test('detects lectures', () {
      final result = const ContentClassifier().classify(_lecture());
      expect(result.category.toString(), 'ContentCategory.lecture');
      expect(result.confidence, greaterThanOrEqualTo(0.0));
    });

    test('detects audiobooks from storytelling cues', () {
      const story = Transcript(
        mediaId: 'm2',
        segments: [
          TranscriptSegment(start: Duration.zero, end: Duration(seconds: 4), text: 'Chapter one.'),
          TranscriptSegment(start: Duration(seconds: 4), end: Duration(seconds: 10), text: 'Once upon a time he said hello to the valley.'),
          TranscriptSegment(start: Duration(seconds: 10), end: Duration(seconds: 16), text: 'The end.'),
        ],
      );
      final result = const ContentClassifier().classify(story);
      expect(result.category, ContentCategory.audiobook);
    });

    test('unknown content maps to other', () {
      const empty = Transcript(mediaId: 'm3');
      final result = const ContentClassifier().classify(empty);
      expect(result.category, ContentCategory.other);
    });
  });

  group('SmartScrubber', () {
    test('scrubs to the best matching segment', () {
      final position = const SmartScrubber().scrub(_lecture(), 'cellular respiration');
      expect(position, isNotNull);
      expect(position, const Duration(seconds: 20));
    });

    test('returns null for unmatched queries', () {
      expect(const SmartScrubber().scrub(_lecture(), 'quantum gravity'), isNull);
    });

    test('matchingSegments are relevance-sorted', () {
      final matches =
          const SmartScrubber().matchingSegments(_lecture(), 'photosynthesis');
      expect(matches, isNotEmpty);
      expect(matches.first.text, contains('photosynthesis'));
    });
  });

  group('VoiceCommandParser', () {
    const parser = VoiceCommandParser();

    test('parses seek by timestamp', () {
      final command = parser.parse('go to 1:05');
      expect(command.type, VoiceCommandType.seek);
      expect(command.numericValue, 65000);
    });

    test('parses play/pause', () {
      expect(parser.parse('play').type, VoiceCommandType.play);
      expect(parser.parse('pause').type, VoiceCommandType.pause);
    });

    test('parses chapter navigation', () {
      final command = parser.parse('jump to chapter 3');
      expect(command.type, VoiceCommandType.chapter);
      expect(command.numericValue, 3);
    });

    test('parses search', () {
      final command = parser.parse('search for photosynthesis');
      expect(command.type, VoiceCommandType.search);
      expect(command.textValue, 'photosynthesis');
    });

    test('parses speed change', () {
      final command = parser.parse('play at 1.5x speed');
      expect(command.type, VoiceCommandType.speed);
      expect(command.numericValue, 1.5);
    });

    test('unknown input falls back to other', () {
      expect(parser.parse('banana').type, VoiceCommandType.other);
    });
  });

  group('TranscriptSearchIndex', () {
    test('finds exact phrases and returns previews', () {
      final index = TranscriptSearchIndex()..add(_lecture());
      final results = index.search('cellular respiration');
      expect(results, isNotEmpty);
      expect(results.first.score, 1.0);
      expect(results.first.preview, contains('cellular respiration'));
      expect(results.first.matchedText, 'cellular respiration');
    });

    test('token queries rank best matches first', () {
      final index = TranscriptSearchIndex()..add(_lecture());
      final results = index.search('photosynthesis');
      expect(results, isNotEmpty);
      final first = results.first;
      expect(first.matchStart, lessThan(first.matchEnd));
      expect(first.matchedText.toLowerCase(), 'photosynthesis');
    });

    test('filter by mediaId', () {
      final index = TranscriptSearchIndex()
        ..add(_lecture())
        ..add(const Transcript(mediaId: 'other', segments: [
          TranscriptSegment(start: Duration.zero, end: Duration(seconds: 2), text: 'banana'),
        ]));
      expect(index.search('photosynthesis', mediaId: 'other'), isEmpty);
      expect(index.search('banana', mediaId: 'other'), hasLength(1));
    });

    test('empty query yields no results', () {
      final index = TranscriptSearchIndex()..add(_lecture());
      expect(index.search('   '), isEmpty);
    });

    test('word-level hits are located when timestamps exist', () {
      const t = Transcript(mediaId: 'w', segments: [
        TranscriptSegment(
          start: Duration.zero,
          end: Duration(seconds: 2),
          text: 'alpha beta',
          words: [
            TranscriptWord(text: 'alpha', start: Duration.zero, end: Duration(seconds: 1)),
            TranscriptWord(text: 'beta', start: Duration(seconds: 1), end: Duration(seconds: 2)),
          ],
        ),
      ]);
      final index = TranscriptSearchIndex()..add(t);
      final results = index.search('beta');
      expect(results, hasLength(1));
      expect(results.first.matchedWords.single.text, 'beta');
    });
  });

  group('KnowledgeGraphBuilder', () {
    test('connects co-occurring concepts via segments', () {
      final concepts = const ConceptExtractor().extract(_lecture());
      final graph = const KnowledgeGraphBuilder().build(concepts,
          transcripts: [_lecture()]);
      expect(graph.nodes, isNotEmpty);
      expect(graph.edges, isNotEmpty);
      // photosynthesis and chlorophyll co-occur in segment 2 (index).
      final photosynthesis =
          concepts.firstWhere((c) => c.label == 'photosynthesis');
      final neighbours = graph.neighboursOf(photosynthesis.id);
      expect(neighbours, isNotEmpty);
    });
  });
}
