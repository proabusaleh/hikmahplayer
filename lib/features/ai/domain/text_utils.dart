/// Pure-Dart text helpers shared by the AI analyzers.
class TextUtils {
  const TextUtils._();

  /// Words considered noise for keyword extraction, keyed by lowercase word.
  static const Map<String, bool> _stopwords = {
    'the': true, 'a': true, 'an': true, 'and': true, 'or': true, 'but': true,
    'if': true, 'then': true, 'else': true, 'because': true, 'while': true,
    'of': true, 'in': true, 'on': true, 'at': true, 'by': true, 'for': true,
    'with': true, 'from': true, 'to': true, 'into': true, 'during': true,
    'is': true, 'are': true, 'was': true, 'were': true, 'be': true, 'been': true,
    'being': true, 'have': true, 'has': true, 'had': true, 'do': true, 'does': true,
    'did': true, 'will': true, 'would': true, 'can': true, 'could': true,
    'shall': true, 'should': true, 'may': true, 'might': true, 'must': true,
    'it': true, 'this': true, 'that': true, 'these': true, 'those': true,
    'there': true, 'here': true, 'i': true, 'you': true, 'he': true, 'she': true,
    'we': true, 'they': true, 'me': true, 'him': true, 'her': true, 'us': true,
    'them': true, 'my': true, 'your': true, 'our': true, 'their': true,
    'his': true, 'its': true, 'so': true, 'as': true, 'just': true,
    'not': true, 'no': true, 'very': true, 'really': true, 'also': true,
    'how': true, 'what': true, 'when': true, 'where': true, 'why': true,
    'who': true, 'whom': true, 'which': true, 'about': true, 'like': true,
    'get': true, 'got': true, 'go': true, 'went': true, 'one': true, 'two': true,
    'three': true, 'up': true, 'down': true, 'out': true, 'over': true,
    'under': true, 'again': true, 'further': true, 'once': true, 'than': true,
    'too': true, 'only': true, 'own': true, 'same': true, 'any': true,
    'both': true, 'each': true, 'few': true, 'more': true, 'most': true,
    'other': true, 'some': true, 'such': true, 'all': true, 'don': true,
    'aren': true, 'isn': true, 'wasn': true, 'weren': true, 'hasn': true,
    'haven': true, 'didn': true, 'doesn': true, 'couldn': true, 'wouldn': true,
    'won': true, 'shan': true, 'shouldn': true, 'let': true, 'use': true,
    'used': true, 'make': true, 'makes': true, 'made': true, 'know': true,
    'knows': true, 'want': true, 'wants': true, 'see': true, 'saw': true,
    'say': true, 'says': true, 'said': true, 'think': true, 'thought': true,
    'way': true, 'thing': true, 'things': true, 'people': true,
    // Common Arabic stopwords (hikmah player has Arabic content).
    'في': true, 'من': true, 'على': true, 'إلى': true, 'عن': true, 'ان': true,
    'أن': true, 'إن': true, 'لا': true, 'ما': true, 'هذا': true, 'هذه': true,
    'ذلك': true, 'التي': true, 'الذي': true, 'ثم': true, 'كان': true,
    'كانت': true, 'و': true, 'هو': true, 'هي': true, 'هم': true, 'مع': true,
    'قد': true, 'كل': true, 'بين': true, 'عند': true, 'إذا': true, 'حيث': true,
    'لأن': true, 'لقد': true, 'كذلك': true, 'أيضا': true, 'أو': true,
    'نحن': true, 'أنتم': true, 'إياك': true, 'اللذان': true, 'لن': true,
    'لم': true, 'سوف': true, 'فسوف': true, 'سو': true, 'لو': true, 'كي': true,
    'أي': true, 'اي': true, 'علي': true, 'بعد': true, 'قبل': true,
  };

  /// True for common one-character words (articles etc.) and stopwords.
  static bool isStopword(String word) =>
      word.length <= 1 || _stopwords.containsKey(word.toLowerCase());

  /// Splits text into word tokens, lowercased, punctuation stripped.
  static List<String> tokenize(String text) {
    final matches = RegExp(r"[\w'-]+", unicode: true).allMatches(text);
    return matches.map((m) => m.group(0)!.toLowerCase()).toList();
  }

  /// Tokenizes and drops stopwords / short tokens.
  static List<String> significantTokens(String text) =>
      tokenize(text).where((t) => !isStopword(t)).toList();

  /// Splits text into sentences on terminal punctuation, keeping timestamps
  /// out of the equation (pure text).
  static List<String> sentences(String text) {
    final result = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);
      if ('.!?'.contains(char)) {
        result.add(buffer.toString().trim());
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) result.add(buffer.toString().trim());
    return result.where((s) => s.isNotEmpty).toList();
  }

  /// Removes diacritics (Arabic harakat) and normalises hamza/alef forms.
  static String normalizeArabic(String text) {
    return text
        .replaceAll(RegExp('[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp('[\u064E-\u0652]'), '');
  }

  /// Lowercases Latin and normalises Arabic in one pass (for search).
  static String normalizeForSearch(String text) {
    var lower = text.toLowerCase();
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(lower)) {
      lower = normalizeArabic(lower);
    }
    return lower;
  }

  /// Basic text similarity (`0..1`) via character bigram dice coefficient.
  static double similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    Set<String> bigrams(String s) {
      final result = <String>{};
      for (var i = 0; i + 2 <= s.length; i++) {
        result.add(s.substring(i, i + 2));
      }
      return result;
    }

    final ba = bigrams(a);
    final bb = bigrams(b);
    if (ba.isEmpty || bb.isEmpty) return 0.0;
    final intersection = ba.intersection(bb).length;
    return 2.0 * intersection / (ba.length + bb.length);
  }

  /// Deterministic slug suitable for ids.
  static String slugify(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp('[^\\w\\u0600-\\u06FF]+'), '-')
        .replaceAll(RegExp('-+'), '-')
        .replaceAll(RegExp('^-|-\$'), '');
    return cleaned.isEmpty ? 'item' : cleaned;
  }
}
