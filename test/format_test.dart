import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/shared/utils/format.dart';

void main() {
  group('Fmt.duration', () {
    test('formats zero duration', () {
      expect(Fmt.duration(Duration.zero), '0:00');
    });

    test('formats seconds only', () {
      expect(Fmt.duration(const Duration(seconds: 45)), '0:45');
    });

    test('formats minutes and seconds', () {
      expect(
        Fmt.duration(const Duration(minutes: 3, seconds: 24)),
        '3:24',
      );
    });

    test('formats hours, minutes, seconds', () {
      expect(
        Fmt.duration(const Duration(hours: 1, minutes: 5, seconds: 30)),
        '1:05:30',
      );
    });

    test('formats null duration as placeholder', () {
      expect(Fmt.duration(null), '--:--');
    });

    test('formats with milliseconds', () {
      expect(
        Fmt.duration(
          const Duration(minutes: 1, seconds: 30, milliseconds: 500),
          showMillis: true,
        ),
        '1:30.5',
      );
    });
  });

  group('Fmt.bytes', () {
    test('formats bytes', () {
      expect(Fmt.bytes(500), '500 B');
    });

    test('formats kilobytes', () {
      expect(Fmt.bytes(1536), '1.50 KB');
    });

    test('formats megabytes', () {
      expect(Fmt.bytes(1048576), '1.00 MB');
    });

    test('formats gigabytes', () {
      expect(Fmt.bytes(2147483648), '2.00 GB');
    });

    test('handles null', () {
      expect(Fmt.bytes(null), '\u2014');
    });

    test('handles zero', () {
      expect(Fmt.bytes(0), '0 B');
    });

    test('handles negative', () {
      expect(Fmt.bytes(-1), '\u2014');
    });
  });
}
