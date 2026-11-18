import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/core/utils/duration_format.dart';

void main() {
  group('formatClockDuration', () {
    test('formats durations below one hour as minutes and seconds', () {
      expect(formatClockDuration(Duration.zero), '00:00');
      expect(formatClockDuration(const Duration(seconds: 7)), '00:07');
      expect(
        formatClockDuration(const Duration(minutes: 5, seconds: 3)),
        '05:03',
      );
      expect(
        formatClockDuration(const Duration(minutes: 42, seconds: 7)),
        '42:07',
      );
    });

    test('adds an hour segment once the duration reaches 60 minutes', () {
      expect(
        formatClockDuration(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
      expect(formatClockDuration(const Duration(minutes: 60)), '1:00:00');
      expect(
        formatClockDuration(const Duration(hours: 1, minutes: 30)),
        '1:30:00',
      );
      expect(
        formatClockDuration(const Duration(hours: 12, minutes: 5, seconds: 9)),
        '12:05:09',
      );
    });

    test('treats negative durations as zero', () {
      expect(formatClockDuration(const Duration(seconds: -5)), '00:00');
    });
  });
}
