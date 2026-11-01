import 'package:flutter/material.dart';

/// 0 -> "0 мин", 90 -> "1 мин", 3661 -> "1 ч 1 мин".
String formatDuration(int seconds) {
  if (seconds <= 0) return '0 мин';
  if (seconds < 60) return '$seconds сек';

  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;

  if (hours == 0) return '$minutes мин';
  if (restMinutes == 0) return '$hours ч';
  return '$hours ч $restMinutes мин';
}

/// Stopwatch format: HH:MM:SS.
String formatTimer(Duration duration) {
  final total = duration.isNegative ? 0 : duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final parts = [
    if (hours > 0) _pad(hours),
    _pad(minutes),
    _pad(seconds),
  ];
  return parts.join(':');
}

String formatDateTime(DateTime date) {
  final local = date.toLocal();
  return '${_pad(local.day)}.${_pad(local.month)}.${local.year} '
      '${_pad(local.hour)}:${_pad(local.minute)}';
}

String formatDateShort(DateTime date) {
  final local = date.toLocal();
  return '${_pad(local.day)}.${_pad(local.month)}';
}

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

String _pad(int value) => value.toString().padLeft(2, '0');

/// Parses "#RRGGBB" / "#AARRGGBB" and falls back to blue.
Color colorFromHex(String? hex) {
  if (hex == null) return Colors.blue;

  var value = hex.trim().replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return Colors.blue;

  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? Colors.blue : Color(parsed);
}

/// Very light validation shared by the auth forms.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Введите email';
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!regex.hasMatch(email)) return 'Некорректный email';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Введите пароль';
  if (value.length < 6) return 'Минимум 6 символов';
  return null;
}
