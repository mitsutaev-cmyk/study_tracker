import 'package:flutter/material.dart';

/// Avatars available in the profile editor. Stored as a short string on the
/// server so no image hosting is needed.
const avatarOptions = [
  '🎓',
  '📚',
  '🧠',
  '🚀',
  '🌟',
  '🎯',
  '🔥',
  '🦉',
  '🐱',
  '🐼',
  '🌱',
  '⚡',
];

const accentColorOptions = [
  '#4F46E5',
  '#0EA5E9',
  '#0F766E',
  '#16A34A',
  '#CA8A04',
  '#EA580C',
  '#DC2626',
  '#DB2777',
  '#7C3AED',
  '#475569',
];

const themeModeOptions = [
  ('system', 'Система', Icons.brightness_auto),
  ('light', 'Светлая', Icons.light_mode),
  ('dark', 'Тёмная', Icons.dark_mode),
];

Color seedColorFromHex(String? hex) {
  const fallback = Color(0xFF4F46E5);
  if (hex == null) return fallback;

  var value = hex.replaceFirst('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return fallback;

  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

ThemeMode themeModeFromString(String? value) => switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
