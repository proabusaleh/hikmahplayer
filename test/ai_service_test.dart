import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/ai_service.dart';
import 'package:hikmahplayer/features/ai/domain/models/rsvp_settings.dart';
import 'package:hikmahplayer/features/ai/domain/models/transcript.dart';

Transcript _sample({String mediaId = 'm1'}) {
  return Transcript(
    mediaId: mediaId,
    language: 'en',
    segments: const [
      TranscriptSegment(start: Duration.zero, end: Duration(seconds: 5), text: 'Welcome to the lesson on photosynthesis.'),
      TranscriptSegment(start: Duration(seconds: 5), end: Duration(seconds: 9), text: 'Photosynthesis is the process plants use to make food.'),
      TranscriptSegment(start: Duration(seconds: 9), end: Duration(seconds: 14), text: 'The key ingredient is chlorophyll.'),
      TranscriptSegment(start: Duration(seconds: 14), end: Duration(seconds: 20), text: 'Now let us discuss cellular respiration.'),
      TranscriptSegment(start: Duration(seconds: 20), end: Duration(seconds: 26), text: 'Respiration is how cells release energy.'),
      TranscriptSegment(start: Duration(seconds: 26), end: Duration(seconds: 31), text: 'Thank you and see you next time.'),
    ],
  );
}

void main() {
  group('AIService ingestion', () {
    test('addTranscript registers and indexes', () {
      final service = AIService();
      service.addTranscript(_sample());
      expect(service.transcripts, contains('m1'));
      expect(service.transcriptFor('m1'), isNotNull);
      expect(service.search('photosynthesis'), isNotEmpty);
    });

    test('removeTranscript clears pipelines and search', () {
      final service = AIService();
      service.addTranscript(_sample());
      service.chaptersFor('m1');
      service.removeTranscript('m1');
      expect(service.transcripts, isEmpty);
      expect(service.chaptersFor('m1'), isEmpty);
      expect(service.search('photosynthesis'), isEmpty);
    });

    test('reset clears everything', () {
      final service = AIService();
      service.addTranscript(_sample());
      service.addNote('m1', position: const Duration(seconds: 1), text: 'hi');
      service.reset();
      expect(service.transcripts, isEmpty);
      expect(service.notesFor('m1'), isEmpty);
    });
  });

  group('AIService pipelines', () {
    late AIService service;

    setUp(() {
      service = AIService();
      service.addTranscript(_sample());
    });

    test('chaptersFor caches and updates status', () {
      expect(service.statusOf('m1'), AiAnalysisStatus.idle);
      final chapters = service.chaptersFor('m1');
      expect(chapters, isNotEmpty);
      expect(service.statusOf('m1'), AiAnalysisStatus.done);
      // Cached on second call.
      expect(identical(service.chaptersFor('m1'), chapters), isTrue);
    });

    test('keyMomentsFor returns scored moments', () {
      final moments = service.keyMomentsFor('m1');
      expect(moments, isNotEmpty);
      expect(moments.every((m) => m.score >= 0 && m.score <= 1), isTrue);
    });

    test('summaryFor produces headline and key points', () {
      final summary = service.summaryFor('m1');
      expect(summary, isNotNull);
      expect(summary!.headline, isNotEmpty);
      expect(summary.keyPoints, isNotEmpty);
    });

    test('conceptsFor and knowledgeGraph are linked', () {
      final concepts = service.conceptsFor('m1');
      expect(concepts, isNotEmpty);
      final graph = service.knowledgeGraph;
      expect(graph.nodes, hasLength(greaterThanOrEqualTo(concepts.length)));
    });

    test('classify returns a category', () {
      final result = service.classify('m1');
      expect(result, isNotNull);
      expect(result!.category.toString(), 'ContentCategory.lecture');
    });

    test('flashcardsFor and quizzesFor generate content', () {
      final cards = service.flashcardsFor('m1');
      expect(cards, isNotEmpty);
      final quizzes = service.quizzesFor('m1');
      expect(quizzes, isNotEmpty);
      expect(quizzes.first.questions, isNotEmpty);
    });

    test('notes CRUD', () {
      final note = service.addNote('m1',
          position: const Duration(seconds: 3), text: 'remember this');
      expect(service.notesFor('m1'), hasLength(1));

      final updated = service.updateNote('m1', note.id, text: 'edited');
      expect(updated!.text, 'edited');

      service.deleteNote('m1', note.id);
      expect(service.notesFor('m1'), isEmpty);
    });

    test('scrub finds a seek target', () {
      expect(service.scrub('m1', 'cellular respiration'),
          const Duration(seconds: 14));
    });

    test('parseVoiceCommand routes through parser', () {
      final command = service.parseVoiceCommand('pause');
      expect(command.type.toString(), 'VoiceCommandType.pause');
    });

    test('rsvp chunking honors format and phrase size', () {
      service.setRsvp(service.rsvp.copyWith(format: RsvpFormat.word));
      var chunks = service.chunkForReading(_sample(), Duration.zero);
      expect(chunks.every((c) => c.length == 1), isTrue);

      service.setRsvp(service.rsvp.copyWith(format: RsvpFormat.phrase, phraseSize: 3));
      chunks = service.chunkForReading(_sample(), Duration.zero);
      expect(chunks.first.length, 3);
    });
  });

  group('AIService edge cases', () {
    test('empty service returns empty results safely', () {
      final service = AIService();
      expect(service.chaptersFor('missing'), isEmpty);
      expect(service.summaryFor('missing'), isNull);
      expect(service.keyMomentsFor('missing'), isEmpty);
      expect(service.conceptsFor('missing'), isEmpty);
      expect(service.classify('missing'), isNull);
      expect(service.flashcardsFor('missing'), isEmpty);
      expect(service.quizzesFor('missing'), isEmpty);
      expect(service.scrub('missing', 'anything'), isNull);
      expect(service.search('anything'), isEmpty);
    });

    test('reset then reuse works', () {
      final service = AIService();
      service.addTranscript(_sample());
      service.reset();
      service.addTranscript(_sample(mediaId: 'm2'));
      expect(service.transcriptFor('m2'), isNotNull);
      expect(service.search('respiration'), isNotEmpty);
    });
  });
}
