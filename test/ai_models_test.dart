import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/ai/domain/models/chapter.dart';
import 'package:hikmahplayer/features/ai/domain/models/concept.dart';
import 'package:hikmahplayer/features/ai/domain/models/flashcard.dart';
import 'package:hikmahplayer/features/ai/domain/models/key_moment.dart';
import 'package:hikmahplayer/features/ai/domain/models/knowledge_graph.dart';
import 'package:hikmahplayer/features/ai/domain/models/notes.dart';
import 'package:hikmahplayer/features/ai/domain/models/quiz.dart';
import 'package:hikmahplayer/features/ai/domain/models/rsvp_settings.dart';
import 'package:hikmahplayer/features/ai/domain/models/summary.dart';
import 'package:hikmahplayer/features/ai/domain/models/transcript.dart';
import 'package:hikmahplayer/features/ai/domain/models/transcript_search.dart';
import 'package:hikmahplayer/features/ai/domain/models/translation.dart';
import 'package:hikmahplayer/features/ai/domain/models/voice_command.dart';

void main() {
  group('Transcript', () {
    final word = TranscriptWord(text: 'Hello', start: Duration.zero, end: const Duration(milliseconds: 500), confidence: 0.9);
    final segment = TranscriptSegment(
      start: Duration.zero,
      end: const Duration(seconds: 2),
      text: 'Hello world.',
      speakerId: 's1',
      confidence: 0.95,
      words: [word],
    );
    final transcript = Transcript(
      mediaId: 'm1',
      language: 'en',
      segments: [segment],
      speakers: const [Speaker(id: 's1', label: 'Narrator')],
    );

    test('fullText joins segments', () {
      const other = TranscriptSegment(
        start: Duration(seconds: 2),
        end: Duration(seconds: 4),
        text: 'Second sentence.',
      );
      final t = Transcript(mediaId: 'm2', segments: [segment, other]);
      expect(t.fullText, 'Hello world. Second sentence.');
    });

    test('duration is last segment end', () {
      expect(transcript.duration, const Duration(seconds: 2));
    });

    test('segmentAt / wordAt hit ranges and miss outside', () {
      expect(transcript.segmentAt(const Duration(seconds: 1))?.text, 'Hello world.');
      expect(transcript.segmentAt(const Duration(seconds: 5)), isNull);
      expect(transcript.wordAt(const Duration(milliseconds: 200))?.text, 'Hello');
      expect(transcript.wordAt(const Duration(seconds: 3)), isNull);
    });

    test('JSON round-trip preserves fields', () {
      final restored = Transcript.fromJson(transcript.toJson());
      expect(restored.mediaId, 'm1');
      expect(restored.language, 'en');
      expect(restored.segments, hasLength(1));
      expect(restored.segments.first.text, 'Hello world.');
      expect(restored.segments.first.words.single.confidence, 0.9);
      expect(restored.speakers.single.label, 'Narrator');
    });

    test('copyWith overrides only requested fields', () {
      final copy = transcript.copyWith(language: 'ar');
      expect(copy.language, 'ar');
      expect(copy.mediaId, 'm1');
      expect(copy.segments, transcript.segments);
    });

    test('segment.endsSentence detects punctuation', () {
      expect(segment.endsSentence, isTrue);
      const no = TranscriptSegment(
        start: Duration.zero,
        end: Duration(seconds: 1),
        text: 'no punctuation',
      );
      expect(no.endsSentence, isFalse);
    });
  });

  group('AiChapter', () {
    test('JSON round-trip with reason enum', () {
      const chapter = AiChapter(
        id: 'c1',
        mediaId: 'm1',
        title: 'Intro',
        start: Duration.zero,
        end: Duration(seconds: 10),
        confidence: 0.8,
        reason: ChapterReason.scene,
      );
      final restored = AiChapter.fromJson(chapter.toJson());
      expect(restored.title, 'Intro');
      expect(restored.reason, ChapterReason.scene);
      expect(restored.duration, const Duration(seconds: 10));
      expect(restored.contains(const Duration(seconds: 5)), isTrue);
      expect(restored.contains(const Duration(seconds: 10)), isFalse);
    });

    test('unknown reason falls back to transcriptTopic', () {
      final restored = AiChapter.fromJson({
        'id': 'c',
        'mediaId': 'm',
        'title': 't',
        'start': 0,
        'end': 1000,
        'confidence': 1,
        'reason': 'bogus',
      });
      expect(restored.reason, ChapterReason.transcriptTopic);
    });
  });

  group('KeyMoment', () {
    test('JSON round-trip', () {
      const moment = KeyMoment(
        id: 'k1',
        mediaId: 'm1',
        start: Duration(seconds: 5),
        end: Duration(seconds: 9),
        score: 0.75,
        reason: KeyMomentReason.emphasis,
        label: 'The key point',
      );
      final restored = KeyMoment.fromJson(moment.toJson());
      expect(restored.score, 0.75);
      expect(restored.reason, KeyMomentReason.emphasis);
      expect(restored.duration, const Duration(seconds: 4));
    });
  });

  group('ContentSummary', () {
    test('JSON round-trip with paragraphs and key points', () {
      const summary = ContentSummary(
        mediaId: 'm1',
        headline: 'Headline',
        paragraphs: [
          SummaryParagraph(text: 'Para one', sourceStart: Duration(seconds: 1)),
        ],
        keyPoints: ['A', 'B'],
        compressionRatio: 0.2,
      );
      final restored = ContentSummary.fromJson(summary.toJson());
      expect(restored.headline, 'Headline');
      expect(restored.paragraphs.single.sourceStart, const Duration(seconds: 1));
      expect(restored.keyPoints, ['A', 'B']);
      expect(restored.compressionRatio, 0.2);
    });
  });

  group('Concept & KnowledgeGraph', () {
    const concept = Concept(
      id: 'c1',
      label: 'Photosynthesis',
      definition: 'Photosynthesis is a process.',
      importance: 0.9,
      occurrences: [
        ConceptOccurrence(
          mediaId: 'm1',
          start: Duration.zero,
          end: Duration(seconds: 1),
          context: 'Photosynthesis is a process.',
        ),
      ],
    );

    test('Concept JSON round-trip', () {
      final restored = Concept.fromJson(concept.toJson());
      expect(restored.label, 'Photosynthesis');
      expect(restored.definition, contains('process'));
      expect(restored.occurrences.single.mediaId, 'm1');
    });

    test('KnowledgeGraph adds concepts and edges with dedupe', () {
      var graph = const KnowledgeGraph()
          .addConcept(concept)
          .addConcept(concept);
      expect(graph.nodes, hasLength(1));

      const other = Concept(id: 'c2', label: 'Chlorophyll');
      graph = graph.addConcept(other).addEdge('c1', 'c2').addEdge('c1', 'c2');
      expect(graph.edges, hasLength(1));
      expect(graph.edges.single.weight, 2);

      final neighbours = graph.neighboursOf('c1');
      expect(neighbours, hasLength(1));
      expect(neighbours.single.$1, 'c2');
    });

    test('KnowledgeGraph JSON round-trip', () {
      const graph = KnowledgeGraph(nodes: [concept]);
      final restored = KnowledgeGraph.fromJson(graph.toJson());
      expect(restored.nodes.single.label, 'Photosynthesis');
    });

    test('self-loops are ignored', () {
      final graph = const KnowledgeGraph().addEdge('c1', 'c1');
      expect(graph.edges, isEmpty);
    });
  });

  group('Flashcard', () {
    test('JSON round-trip and SM-2 scheduling', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(
        id: 'f1',
        mediaId: 'm1',
        front: 'Q ?',
        back: 'A',
        createdAt: now,
      );
      expect(card.isDue, isTrue);

      final correct = card.recordReview(correct: true, now: now);
      expect(correct.nextReviewAt, now.add(const Duration(days: 3)));
      expect(correct.intervalDays, 3);
      expect(correct.correctCount, 1);

      final wrong = card.recordReview(correct: false, now: now);
      expect(wrong.intervalDays, 1);
      expect(wrong.ease, closeTo(2.3, 0.001));

      final restored = Flashcard.fromJson(correct.toJson());
      expect(restored.front, 'Q ?');
      expect(restored.intervalDays, 3);
      expect(restored.nextReviewAt, now.add(const Duration(days: 3)));
    });
  });

  group('Quiz', () {
    test('JSON round-trip and correctness check', () {
      const question = QuizQuestion(
        id: 'q1',
        prompt: 'What is X?',
        options: ['A', 'B', 'C'],
        correctIndex: 1,
        explanation: 'Because.',
      );
      expect(question.isCorrect(1), isTrue);
      expect(question.isCorrect(0), isFalse);

      final quiz = Quiz(
        id: 'z1',
        mediaId: 'm1',
        title: 'T',
        questions: [question],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final restored = Quiz.fromJson(quiz.toJson());
      expect(restored.questions.single.correctIndex, 1);
    });
  });

  group('TimestampedNote', () {
    test('copyWith updates text and tags', () {
      final now = DateTime(2026, 1, 1);
      final note = TimestampedNote(
        id: 'n1',
        mediaId: 'm1',
        position: const Duration(seconds: 10),
        text: 'original',
        createdAt: now,
      );
      final updated = note.copyWith(
        text: 'edited',
        tags: ['ai'],
        updatedAt: DateTime(2026, 1, 2),
      );
      expect(updated.text, 'edited');
      expect(updated.tags, ['ai']);
      expect(updated.position, note.position);
      expect(updated.updatedAt, DateTime(2026, 1, 2));

      final restored = TimestampedNote.fromJson(updated.toJson());
      expect(restored.text, 'edited');
      expect(restored.createdAt, now);
    });
  });

  group('RsvpSettings', () {
    test('word duration derives from wpm', () {
      const settings = RsvpSettings(wordsPerMinute: 300);
      expect(settings.wordDuration, const Duration(milliseconds: 200));
      expect(settings.copyWith(wordsPerMinute: 600).wordDuration,
          const Duration(milliseconds: 100));
      expect(settings == const RsvpSettings(), isTrue);
      expect(settings == const RsvpSettings(wordsPerMinute: 250), isFalse);
    });

    test('JSON round-trip', () {
      const settings = RsvpSettings(wordsPerMinute: 250, phraseSize: 4, format: RsvpFormat.phrase, pauseAtPunctuation: false);
      final restored = RsvpSettings.fromJson(settings.toJson());
      expect(restored, settings);
    });
  });

  group('VoiceCommand', () {
    test('JSON round-trip', () {
      const command = VoiceCommand(
        type: VoiceCommandType.seek,
        numericValue: 65000,
        textValue: null,
        rawText: 'go to 1:05',
        confidence: 0.95,
      );
      final restored = VoiceCommand.fromJson(command.toJson());
      expect(restored.type, VoiceCommandType.seek);
      expect(restored.numericValue, 65000);
    });
  });

  group('TranslationRequest & TranscriptSearchResult', () {
    test('TranslationRequest JSON round-trip', () {
      const request = TranslationRequest(
        mediaId: 'm1',
        start: Duration.zero,
        end: Duration(seconds: 2),
        sourceText: 'Hello',
        targetLanguage: 'ar',
      );
      final restored = TranslationRequest.fromJson(request.toJson());
      expect(restored.targetLanguage, 'ar');
      expect(restored.sourceText, 'Hello');
    });

    test('TranscriptSearchResult preview brackets the match', () {
      const segment = TranscriptSegment(
        start: Duration.zero,
        end: Duration(seconds: 2),
        text: 'The quick brown fox',
      );
      const result = TranscriptSearchResult(
        mediaId: 'm1',
        segment: segment,
        matchStart: 4,
        matchEnd: 9,
        score: 1.0,
      );
      expect(result.matchedText, 'quick');
      expect(result.preview, 'The [quick] brown fox');
    });
  });
}
