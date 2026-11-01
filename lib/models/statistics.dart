import 'subject.dart';

class SubjectStat {
  final int id;
  final String name;
  final String color;
  final int sessionCount;
  final int totalSeconds;
  final double totalHours;

  const SubjectStat({
    required this.id,
    required this.name,
    required this.color,
    required this.sessionCount,
    required this.totalSeconds,
    required this.totalHours,
  });

  factory SubjectStat.fromJson(Map<String, dynamic> json) => SubjectStat(
        id: toInt(json['id']),
        name: (json['name'] ?? '').toString(),
        color: (json['color'] ?? '#2196F3').toString(),
        sessionCount: toInt(json['session_count']),
        totalSeconds: toInt(json['total_seconds']),
        totalHours: _toDouble(json['total_hours']),
      );
}

class DailyStat {
  final DateTime date;
  final int seconds;

  const DailyStat({required this.date, required this.seconds});

  factory DailyStat.fromJson(Map<String, dynamic> json) => DailyStat(
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        seconds: toInt(json['seconds']),
      );
}

class Statistics {
  final int totalSeconds;
  final int todaySeconds;
  final int weekSeconds;
  final int sessionCount;
  final int coins;
  final List<SubjectStat> subjects;
  final List<DailyStat> daily;

  const Statistics({
    required this.totalSeconds,
    required this.todaySeconds,
    required this.weekSeconds,
    required this.sessionCount,
    required this.coins,
    required this.subjects,
    required this.daily,
  });

  static const empty = Statistics(
    totalSeconds: 0,
    todaySeconds: 0,
    weekSeconds: 0,
    sessionCount: 0,
    coins: 0,
    subjects: [],
    daily: [],
  );

  factory Statistics.fromJson(Map<String, dynamic> json) => Statistics(
        totalSeconds: toInt(json['total_seconds']),
        todaySeconds: toInt(json['today_seconds']),
        weekSeconds: toInt(json['week_seconds']),
        sessionCount: toInt(json['session_count']),
        coins: toInt(json['coins']),
        subjects: _list(json['subjects'])
            .whereType<Map<String, dynamic>>()
            .map(SubjectStat.fromJson)
            .toList(),
        daily: _list(json['daily'])
            .whereType<Map<String, dynamic>>()
            .map(DailyStat.fromJson)
            .toList(),
      );

  int get maxDailySeconds =>
      daily.fold<int>(0, (max, day) => day.seconds > max ? day.seconds : max);
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
