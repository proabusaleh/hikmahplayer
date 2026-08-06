import 'package:flutter/foundation.dart';

import '../../features/ai/domain/analyzers/chapter_segmenter.dart';
import '../../features/ai/domain/analyzers/concept_extractor.dart';
import '../../features/ai/domain/analyzers/content_classifier.dart';
import '../../features/ai/domain/analyzers/extractive_summarizer.dart';
import '../../features/ai/domain/analyzers/flashcard_generator.dart';
import '../../features/ai/domain/analyzers/key_moment_scorer.dart';
import '../../features/ai/domain/analyzers/knowledge_graph_builder.dart';
import '../../features/ai/domain/analyzers/quiz_generator.dart';
import '../../features/ai/domain/analyzers/smart_scrubber.dart';
import '../../features/ai/domain/analyzers/transcript_search_index.dart';
import '../../features/ai/domain/analyzers/voice_command_parser.dart';
import '../../features/ai/domain/models/chapter.dart';
import '../../features/ai/domain/models/concept.dart';
import '../../features/ai/domain/models/content_classification.dart';
import '../../features/ai/domain/models/flashcard.dart';
import '../../features/ai/domain/models/key_moment.dart';
import '../../features/ai/domain/models/knowledge_graph.dart';
import '../../features/ai/domain/models/notes.dart';
import '../../features/ai/domain/models/quiz.dart';
import '../../features/ai/domain/models/rsvp_settings.dart';
import '../../features/ai/domain/models/summary.dart';
import '../../features/ai/domain/models/transcript.dart';
import '../../features/ai/domain/models/transcript_search.dart';
import '../../features/ai/domain/models/voice_command.dart';
import '../../features/ai/domain/parsers/transcript_parser.dart';

/// What the analysers are currently doing, for the UI.
enum AiAnalysisStatus { idle, running, done }

/// Central orchestrator for the AI / smart features layer.
///
/// Holds transcripts in memory, runs the pure-Dart analysers on demand and
/// caches results so repeated reads are cheap. ML-backed engines (Whisper STT,
/// embeddings, etc.) are intentionally not wired here yet; their outputs feed
/// the same data models ([Transcript], [Concept], ...).
class AIService extends ChangeNotifier {
  AIService();

  /// Transcripts currently loaded, keyed by media id.
  final Map<String, Transcript> transcripts = {};

  /// Current analysis status, one per media id.
  final Map<String, AiAnalysisStatus> status = {};

  // ---------------------------------------------------------------------
  // Pipeline results
  // ---------------------------------------------------------------------

  final Map<String, List<AiChapter>> _chapters = {};
  final Map<String, List<KeyMoment>> _keyMoments = {};
  final Map<String, ContentSummary> _summaries = {};
  final Map<String, List<Concept>> _concepts = {};
  final Map<String, ClassificationResult> _classifications = {};
  final Map<String, List<Flashcard>> _flashcards = {};
  final Map<String, List<Quiz>> _quizzes = {};
  final Map<String, List<TimestampedNote>> _notes = {};

  KnowledgeGraph? _knowledgeGraph;

  final ChapterSegmenter _chapterSegmenter = const ChapterSegmenter();
  final KeyMomentScorer _keyMomentScorer = const KeyMomentScorer();
  final ExtractiveSummarizer _summarizer = const ExtractiveSummarizer();
  final ConceptExtractor _conceptExtractor = const ConceptExtractor();
  final ContentClassifier _classifier = const ContentClassifier();
  final FlashcardGenerator _flashcardGenerator = const FlashcardGenerator();
  final QuizGenerator _quizGenerator = const QuizGenerator();
  final SmartScrubber _scrubber = const SmartScrubber();
  final VoiceCommandParser _voiceParser = const VoiceCommandParser();
  final KnowledgeGraphBuilder _graphBuilder = const KnowledgeGraphBuilder();
  final TranscriptSearchIndex _searchIndex = TranscriptSearchIndex();

  // ---------------------------------------------------------------------
  // Transcript ingestion
  // ---------------------------------------------------------------------

  void addTranscript(Transcript transcript) {
    transcripts[transcript.mediaId] = transcript;
    _searchIndex.add(transcript);
    notifyListeners();
  }

  void removeTranscript(String mediaId) {
    transcripts.remove(mediaId);
    status.remove(mediaId);
    _chapters.remove(mediaId);
    _keyMoments.remove(mediaId);
    _summaries.remove(mediaId);
    _concepts.remove(mediaId);
    _classifications.remove(mediaId);
    _flashcards.remove(mediaId);
    _quizzes.remove(mediaId);
    _notes.remove(mediaId);
    _rebuildSearchIndex();
    notifyListeners();
  }

  Transcript? transcriptFor(String mediaId) => transcripts[mediaId];

  /// Parses an SRT/VTT caption file and registers it as a transcript.
  /// Returns `null` (and registers nothing) when no cues could be parsed.
  Transcript? addTranscriptFromCaptions(
    String mediaId,
    String content, {
    String? filename,
    String? language,
  }) {
    final transcript = const TranscriptParser().parseToTranscript(
      content,
      mediaId: mediaId,
      filename: filename,
      language: language,
    );
    if (transcript.segments.isEmpty) return null;
    addTranscript(transcript);
    return transcript;
  }

  // ---------------------------------------------------------------------
  // Chaptering
  // ---------------------------------------------------------------------

  List<AiChapter> chaptersFor(String mediaId) {
    final cached = _chapters[mediaId];
    if (cached != null) return cached;
    final transcript = transcripts[mediaId];
    if (transcript == null) return const [];

    _statusOf(mediaId, AiAnalysisStatus.running);
    final chapters = _chapterSegmenter.segment(transcript);
    _chapters[mediaId] = chapters;
    _statusOf(mediaId, AiAnalysisStatus.done);
    return chapters;
  }

  // ---------------------------------------------------------------------
  // Key moments
  // ---------------------------------------------------------------------

  List<KeyMoment> keyMomentsFor(String mediaId, {int top = 5}) {
    final transcript = transcripts[mediaId];
    if (transcript == null) return const [];
    final moments = _keyMoments[mediaId];
    if (moments != null) return moments;

    final result = _keyMomentScorer.score(transcript, top: top);
    _keyMoments[mediaId] = result;
    return result;
  }

  // ---------------------------------------------------------------------
  // Summaries
  // ---------------------------------------------------------------------

  ContentSummary? summaryFor(String mediaId) {
    final cached = _summaries[mediaId];
    if (cached != null) return cached;
    final transcript = transcripts[mediaId];
    if (transcript == null) return null;
    final summary = _summarizer.summarize(transcript);
    _summaries[mediaId] = summary;
    return summary;
  }

  // ---------------------------------------------------------------------
  // Concepts / knowledge graph
  // ---------------------------------------------------------------------

  List<Concept> conceptsFor(String mediaId) {
    final cached = _concepts[mediaId];
    if (cached != null) return cached;
    final transcript = transcripts[mediaId];
    if (transcript == null) return const [];
    final concepts = _conceptExtractor.extract(transcript);
    _concepts[mediaId] = concepts;
    return concepts;
  }

  KnowledgeGraph get knowledgeGraph {
    if (_knowledgeGraph != null) return _knowledgeGraph!;
    final all = _concepts.values.expand((c) => c).toList();
    _knowledgeGraph = _graphBuilder.build(all, transcripts: transcripts.values.toList());
    return _knowledgeGraph!;
  }

  // ---------------------------------------------------------------------
  // Classification
  // ---------------------------------------------------------------------

  ClassificationResult? classify(String mediaId) {
    final cached = _classifications[mediaId];
    if (cached != null) return cached;
    final transcript = transcripts[mediaId];
    if (transcript == null) return null;
    final result = _classifier.classify(transcript);
    _classifications[mediaId] = result;
    return result;
  }

  // ---------------------------------------------------------------------
  // Learning content
  // ---------------------------------------------------------------------

  List<Flashcard> flashcardsFor(String mediaId, {int maxCards = 20}) {
    final cached = _flashcards[mediaId];
    if (cached != null) return cached;
    final transcript = transcripts[mediaId];
    if (transcript == null) return const [];
    final cards = _flashcardGenerator.generate(transcript, maxCards: maxCards);
    _flashcards[mediaId] = cards;
    return cards;
  }

  List<Quiz> quizzesFor(String mediaId, {int maxQuestions = 10}) {
    final cached = _quizzes[mediaId];
    if (cached != null) return cached;
    final transcript = transcripts[mediaId];
    if (transcript == null) return const [];
    final quiz = Quiz(
      id: 'quiz-$mediaId',
      mediaId: mediaId,
      title: 'Quiz for $mediaId',
      questions: _quizGenerator.generate(transcript, maxQuestions: maxQuestions),
      createdAt: DateTime.now(),
    );
    _quizzes[mediaId] = [quiz];
    return [quiz];
  }

  // ---------------------------------------------------------------------
  // Notes
  // ---------------------------------------------------------------------

  List<TimestampedNote> notesFor(String mediaId) => _notes[mediaId] ?? const [];

  TimestampedNote addNote(String mediaId, {
    required Duration position,
    required String text,
    List<String> tags = const [],
  }) {
    final note = TimestampedNote(
      id: 'note-$mediaId-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      position: position,
      text: text,
      tags: tags,
      createdAt: DateTime.now(),
    );
    _notes[mediaId] = [..._notes[mediaId] ?? const [], note];
    notifyListeners();
    return note;
  }

  TimestampedNote? updateNote(String mediaId, String noteId, {
    String? text,
    Duration? position,
    List<String>? tags,
  }) {
    final current = _notes[mediaId];
    if (current == null) return null;
    TimestampedNote? updated;
    _notes[mediaId] = current.map((n) {
      if (n.id != noteId) return n;
      updated = n.copyWith(
        text: text,
        position: position,
        tags: tags,
        updatedAt: DateTime.now(),
      );
      return updated!;
    }).toList();
    notifyListeners();
    return updated;
  }

  void deleteNote(String mediaId, String noteId) {
    _notes[mediaId] = (notesFor(mediaId)..removeWhere((n) => n.id == noteId));
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Search / scrub / voice
  // ---------------------------------------------------------------------

  List<TranscriptSearchResult> search(String query, {String? mediaId}) =>
      _searchIndex.search(query, mediaId: mediaId);

  Duration? scrub(String mediaId, String query) {
    final transcript = transcripts[mediaId];
    if (transcript == null) return null;
    return _scrubber.scrub(transcript, query);
  }

  VoiceCommand parseVoiceCommand(String raw) => _voiceParser.parse(raw);

  // ---------------------------------------------------------------------
  // RSVP / reading along
  // ---------------------------------------------------------------------

  RsvpSettings rsvp = const RsvpSettings();

  void setRsvp(RsvpSettings value) {
    rsvp = value;
    notifyListeners();
  }

  /// The words to flash next given a position, chunked per [rsvp].
  List<List<String>> chunkForReading(Transcript transcript, Duration position) {
    final segment = transcript.segmentAt(position);
    if (segment == null) return const [];
    final tokens = segment.text.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final size = rsvp.format == RsvpFormat.word ? 1 : rsvp.phraseSize;
    final chunks = <List<String>>[];
    var current = <String>[];
    for (final token in tokens) {
      current.add(token);
      if (current.length >= size) {
        chunks.add(current);
        current = [];
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  // ---------------------------------------------------------------------
  // Status / reset
  // ---------------------------------------------------------------------

  AiAnalysisStatus statusOf(String mediaId) => status[mediaId] ?? AiAnalysisStatus.idle;

  void _statusOf(String mediaId, AiAnalysisStatus next) {
    status[mediaId] = next;
    notifyListeners();
  }

  void _rebuildSearchIndex() {
    _searchIndex.clear();
    _searchIndex.addAll(transcripts.values);
  }

  /// Forgets all transcripts and computed results.
  void reset() {
    transcripts.clear();
    status.clear();
    _chapters.clear();
    _keyMoments.clear();
    _summaries.clear();
    _concepts.clear();
    _classifications.clear();
    _flashcards.clear();
    _quizzes.clear();
    _notes.clear();
    _knowledgeGraph = null;
    _rebuildSearchIndex();
    notifyListeners();
  }
}