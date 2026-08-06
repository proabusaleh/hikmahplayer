import '../models/content_classification.dart';
import '../models/transcript.dart';
import '../text_utils.dart';

/// Heuristically classifies a transcript into a [ContentCategory].
class ContentClassifier {
  const ContentClassifier();

  ClassificationResult classify(Transcript transcript) {
    final text = transcript.fullText.toLowerCase();
    final tokens = TextUtils.tokenize(text);
    final total = tokens.length;

    /// Phrase cues match as substrings; single-word cues match exact tokens,
    /// so common short words (e.g. 'la') do not fire inside longer words.
    double ratio(String needle) {
      if (total == 0) return 0;
      if (needle.contains(' ')) {
        return RegExp(RegExp.escape(needle)).allMatches(text).length / total;
      }
      return tokens.where((t) => t == needle).length / total;
    }

    // Music cues: short "vocables", lyric repetition, instrumental phrasing.
    final music = ratio('la') +
        ratio('na') +
        ratio('ooh') +
        ratio('verse') +
        ratio('chorus') +
        ratio('lyrics') +
        ratio('guitar');

    // Lecture / lesson cues.
    final lecture = ratio('welcome') +
        ratio('today we') +
        ratio('lesson') +
        ratio('lecture') +
        ratio('chapter') +
        ratio('we will cover') +
        ratio('in this course');

    // Podcast / conversation cues.
    final podcast = ratio('welcome back') +
        ratio('let me ask') +
        ratio('interview') +
        ratio('episode') +
        ratio('so anyway') +
        ratio('right, so');

    // Tutorial / how-to cues.
    final tutorial = ratio('first, you') +
        ratio('then you') +
        ratio('click') +
        ratio('drag') +
        ratio('settings') +
        ratio('press the button') +
        ratio('step one');

    // Movie / narration cues.
    final movie = ratio('scene') +
        ratio('cut to') +
        ratio('starring') +
        ratio('directed by') +
        ratio('opening credits') +
        ratio('soundtrack');

    // Audiobook / storytelling cues.
    final audiobook = ratio('chapter one') +
        ratio('chapter two') +
        ratio('he said') +
        ratio('she said') +
        ratio('once upon a time') +
        ratio('the end');

    final scores = <ContentCategory, double>{
      ContentCategory.lecture: lecture,
      ContentCategory.music: music,
      ContentCategory.podcast: podcast,
      ContentCategory.tutorial: tutorial,
      ContentCategory.movie: movie,
      ContentCategory.audiobook: audiobook,
      ContentCategory.other: 0.01,
    };

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final totalScore = scores.values.fold<double>(0, (sum, s) => sum + s);

    final evidence = <String>[];
    for (final entry in scores.entries.where((e) => e.value > 0.0005)) {
      evidence.add('${entry.key.label}: ${entry.value.toStringAsFixed(4)}');
    }

    return ClassificationResult(
      category: best.key,
      confidence: totalScore == 0 ? 0 : (best.value / totalScore).clamp(0.0, 1.0),
      evidence: evidence,
      scores: scores,
    );
  }
}
