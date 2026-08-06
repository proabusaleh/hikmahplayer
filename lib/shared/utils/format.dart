/// Small formatting helpers shared across screens.
class Fmt {
  Fmt._();

  /// `83:12` style duration (or `1:03:07` when an hour or more).
  static String duration(Duration? d, {bool showMillis = false}) {
    if (d == null) return '--:--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ms = d.inMilliseconds.remainder(1000) ~/ 100;
    final seconds = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:$seconds';
    }
    if (showMillis) {
      return '$m:${seconds.padLeft(2, '0')}.$ms';
    }
    return '$m:${seconds.padLeft(2, '0')}';
  }

  /// Human readable byte size: `1.4 GB`, `820 KB`.
  static String bytes(int? bytes) {
    if (bytes == null || bytes < 0) return '—';
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB', 'PB'];
    var value = bytes.toDouble();
    var unit = -1;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final precision = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
    return '${value.toStringAsFixed(precision)} ${units[unit]}';
  }

  /// Compact date like `4 Aug 2026`.
  static String date(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
