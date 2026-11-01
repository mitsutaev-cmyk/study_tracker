import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/task.dart';
import 'package:flutter_app/utils/format.dart';
import 'package:flutter_app/utils/profile_options.dart';

void main() {
  group('formatDuration', () {
    test('handles seconds, minutes and hours', () {
      expect(formatDuration(0), '0 мин');
      expect(formatDuration(30), '30 сек');
      expect(formatDuration(60), '1 мин');
      expect(formatDuration(3600), '1 ч');
      expect(formatDuration(3661), '1 ч 1 мин');
      expect(formatDuration(-10), '0 мин');
    });
  });

  group('formatTimer', () {
    test('pads minutes and seconds and shows hours when needed', () {
      expect(formatTimer(Duration.zero), '00:00');
      expect(formatTimer(const Duration(minutes: 5, seconds: 7)), '05:07');
      expect(
        formatTimer(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });
  });

  group('dates', () {
    test('parseDateOnly keeps the calendar day', () {
      expect(parseDateOnly('2026-03-04'), DateTime(2026, 3, 4));
      expect(parseDateOnly(null), isNull);
      expect(dateOnly(DateTime(2026, 3, 4, 18, 30)), DateTime(2026, 3, 4));
    });
  });

  group('profile options', () {
    test('theme mode strings map to ThemeMode', () {
      expect(themeModeFromString('dark'), ThemeMode.dark);
      expect(themeModeFromString('light'), ThemeMode.light);
      expect(themeModeFromString(null), ThemeMode.system);
      expect(themeModeFromString('unknown'), ThemeMode.system);
    });

    test('seed colour falls back to the default', () {
      expect(seedColorFromHex('#0EA5E9'), const Color(0xFF0EA5E9));
      expect(seedColorFromHex('bad'), const Color(0xFF4F46E5));
      expect(seedColorFromHex('#12345'), const Color(0xFF4F46E5));
      expect(colorFromHex('bad'), Colors.blue);
      expect(colorFromHex('#4CAF50'), const Color(0xFF4CAF50));
    });
  });
}
