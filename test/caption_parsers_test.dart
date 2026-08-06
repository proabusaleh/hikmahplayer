import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/ai_service.dart';
import 'package:hikmahplayer/features/ai/domain/parsers/transcript_parser.dart';

void main() {
  group('SrtParser', () {
    test('parses cues with correct timestamps and multi-line text', () {
      const srt = '1\n'
          '00:00:01,000 --> 00:00:03,500\n'
          'Hello world.\n'
          'Welcome back.\n'
          '\n'
          '2\n'
          '00:00:04,000 --> 00:00:06,000\n'
          'Second cue.\n';
      final result = const TranscriptParser().parse(srt, filename: 'a.srt');
      expect(result.segments, hasLength(2));
      expect(result.skippedCues, 0);

      final first = result.segments.first;
      expect(first.start, const Duration(seconds: 1));
      expect(first.end, const Duration(milliseconds: 3500));
      expect(first.text, 'Hello world. Welcome back.');

      expect(result.segments.last.text, 'Second cue.');
    });

    test('handles CRLF and cue index-less blocks', () {
      const srt = '00:00:00,500 --> 00:00:02,000\r\n'
          'First.\r\n'
          '\r\n'
          '00:00:03,000 --> 00:00:04,000\r\n'
          'Second.\r\n';
      final result = const TranscriptParser().parse(srt);
      expect(result.segments, hasLength(2));
      expect(result.segments.first.start, const Duration(milliseconds: 500));
      expect(result.segments.last.text, 'Second.');
    });

    test('skips malformed timing and empty cues with warnings', () {
      const srt = '1\n'
          '00:00:01,000 --> 00:00:03,000\n'
          'Good.\n'
          '\n'
          '2\n'
          'bogus --> line\n'
          'Bad.\n'
          '\n'
          '3\n'
          '00:00:04,000 --> 00:00:05,000\n'
          '\n';
      final result = const TranscriptParser().parse(srt);
      expect(result.segments, hasLength(1));
      expect(result.skippedCues, 2);
      expect(result.warnings, isNotEmpty);
    });

    test('empty input yields empty result', () {
      final result = const TranscriptParser().parse('');
      expect(result.isEmpty, isTrue);
    });
  });

  group('VttParser', () {
    test('skips header and parses cues', () {
      const vtt = 'WEBVTT\n'
          '\n'
          '00:00:01.000 --> 00:00:03.000\n'
          'Hello.\n'
          '\n'
          '00:00:04.000 --> 00:00:06.500\n'
          'World.\n';
      final result = const TranscriptParser().parse(vtt, filename: 'a.vtt');
      expect(result.segments, hasLength(2));
      expect(result.segments.first.start, const Duration(seconds: 1));
      expect(result.segments.first.end, const Duration(seconds: 3));
      expect(result.segments.last.end, const Duration(milliseconds: 6500));
    });

    test('skips NOTE and STYLE blocks and honours cue settings', () {
      const vtt = 'WEBVTT\n'
          '\n'
          'NOTE this is a comment\n'
          'that spans lines\n'
          '\n'
          'STYLE\n'
          '::cue { color: yellow; }\n'
          '\n'
          '00:00:01.000 --> 00:00:03.000 align:start position:50%\n'
          'Cue <c.foo>with</c> tags.\n'
          '\n'
          '00:00:04.000 --> 00:00:05.000\n'
          'Second.\n';
      final result = const TranscriptParser().parse(vtt);
      expect(result.segments, hasLength(2));
      expect(result.segments.first.text, 'Cue with tags.');
      expect(result.segments.first.end, const Duration(seconds: 3));
    });

    test('cue without end time defaults end to start', () {
      const vtt = 'WEBVTT\n'
          '\n'
          '00:00:01.000 -->\n'
          'Open ended.\n';
      final result = const TranscriptParser().parse(vtt);
      expect(result.segments, hasLength(1));
      expect(result.segments.first.end, result.segments.first.start);
    });

    test('handles BOM and comma millisecond separator', () {
      const vtt = '\uFEFFWEBVTT\n'
          '\n'
          '00:00:01,000 --> 00:00:02,000\n'
          'Works.\n';
      final result = const TranscriptParser().parse(vtt);
      expect(result.segments, hasLength(1));
      expect(result.segments.first.text, 'Works.');
    });
  });

  group('TranscriptParser', () {
    test('detect() sniffs formats from content', () {
      expect(const TranscriptParser().detect('WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nHi.\n'),
          CaptionFormat.vtt);
      expect(const TranscriptParser().detect('1\n00:00:01,000 --> 00:00:02,000\nHi.\n'),
          CaptionFormat.srt);
      expect(const TranscriptParser().detect('no timestamps here'),
          CaptionFormat.unknown);
    });

    test('formatForFile uses extension', () {
      expect(const TranscriptParser().formatForFile('movie.srt'), CaptionFormat.srt);
      expect(const TranscriptParser().formatForFile('CAPS.VTT'), CaptionFormat.vtt);
      expect(const TranscriptParser().formatForFile('movie.txt'), CaptionFormat.unknown);
    });

    test('filename takes precedence over content sniffing', () {
      // Content sniffing cannot identify this (no index, stray prefix), but
      // the .srt extension forces the SRT parser which is lenient.
      const content = 'Hello world\n'
          '00:00:01,000 --> 00:00:02,000\n'
          'Hi.\n';
      final sniffed = const TranscriptParser().parse(content);
      expect(sniffed.isEmpty, isTrue);
      final forced = const TranscriptParser().parse(content, filename: 'a.srt');
      expect(forced.segments, hasLength(1));
      expect(forced.segments.single.text, 'Hello world Hi.');
    });

    test('unknown format yields empty result with a warning', () {
      final result = const TranscriptParser().parse('random text');
      expect(result.isEmpty, isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('parseToTranscript builds a Transcript with mediaId', () {
      final transcript = const TranscriptParser().parseToTranscript(
        '1\n00:00:01,000 --> 00:00:02,000\nHi.\n',
        mediaId: 'm1',
        language: 'en',
      );
      expect(transcript.mediaId, 'm1');
      expect(transcript.language, 'en');
      expect(transcript.segments.single.text, 'Hi.');
    });
  });

  group('AIService caption ingestion', () {
    test('addTranscriptFromCaptions parses and registers', () {
      final service = AIService();
      final transcript = service.addTranscriptFromCaptions(
        'm1',
        '1\n00:00:01,000 --> 00:00:03,000\nWelcome to the lesson.\n'
            '2\n00:00:04,000 --> 00:00:06,000\nPhotosynthesis is the process.\n',
        filename: 'lesson.srt',
      );
      expect(transcript, isNotNull);
      expect(service.transcriptFor('m1'), isNotNull);
      expect(service.search('photosynthesis'), isNotEmpty);
    });

    test('unparsable content registers nothing', () {
      final service = AIService();
      final transcript =
          service.addTranscriptFromCaptions('m1', 'not captions at all');
      expect(transcript, isNull);
      expect(service.transcriptFor('m1'), isNull);
    });
  });
}
