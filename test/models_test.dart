import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/motivation.dart';
import 'package:flutter_app/models/statistics.dart';
import 'package:flutter_app/models/study_session.dart';
import 'package:flutter_app/models/subject.dart';
import 'package:flutter_app/models/task.dart';
import 'package:flutter_app/models/user.dart';

void main() {
  group('User', () {
    test('parses a user and falls back to the email prefix for the name', () {
      final user = User.fromJson({
        'id': 7,
        'email': 'ivan@example.com',
        'name': '',
        'coins': 42,
      });

      expect(user.id, 7);
      expect(user.name, 'ivan');
      expect(user.coins, 42);
    });

    test('copyWith keeps the id and email', () {
      const user = User(id: 1, email: 'a@b.c', name: 'A', coins: 0);
      final updated = user.copyWith(coins: 10);

      expect(updated.id, 1);
      expect(updated.email, 'a@b.c');
      expect(updated.coins, 10);
    });
  });

  test('Subject parses numeric strings from the backend', () {
    final subject = Subject.fromJson({
      'id': '3',
      'name': 'Math',
      'color': '#FF9800',
      'total_seconds': '3600',
    });

    expect(subject.id, 3);
    expect(subject.totalSeconds, 3600);
  });

  test('StudySession detects an active session', () {
    final active = StudySession.fromJson({
      'id': 1,
      'subject_id': 2,
      'subject_name': 'Physics',
      'start_time': '2026-01-01T10:00:00Z',
      'end_time': null,
      'duration': 0,
    });
    final finished = StudySession.fromJson({
      'id': 2,
      'subject_id': 2,
      'start_time': '2026-01-01T10:00:00Z',
      'end_time': '2026-01-01T10:30:00Z',
      'duration': 1800,
    });

    expect(active.isActive, isTrue);
    expect(active.subjectName, 'Physics');
    expect(finished.isActive, isFalse);
    expect(finished.duration, 1800);
  });

  test('Statistics parses subjects and the daily series', () {
    final stats = Statistics.fromJson({
      'total_seconds': 7200,
      'today_seconds': 1800,
      'week_seconds': 5400,
      'session_count': 4,
      'coins': 120,
      'subjects': [
        {
          'id': 1,
          'name': 'Math',
          'color': '#2196F3',
          'session_count': 2,
          'total_seconds': 3600,
          'total_hours': 1.0,
        },
      ],
      'daily': [
        {'date': '2026-01-01', 'seconds': 1800},
      ],
    });

    expect(stats.totalSeconds, 7200);
    expect(stats.subjects.single.name, 'Math');
    expect(stats.daily.single.seconds, 1800);
    expect(stats.maxDailySeconds, 1800);
  });

  test('Task parses a date-only due date and completion flag', () {
    final task = Task.fromJson({
      'id': 5,
      'title': 'Прочитать главу',
      'notes': 'стр. 10-30',
      'due_date': '2026-03-04',
      'completed': true,
    });

    expect(task.id, 5);
    expect(task.dueDate, DateTime(2026, 3, 4));
    expect(task.completed, isTrue);
    expect(task.copyWith(completed: false).completed, isFalse);
  });

  test('Motivation parses level, streak and achievements', () {
    final motivation = Motivation.fromJson({
      'total_seconds': 36000,
      'today_seconds': 1800,
      'session_count': 12,
      'daily_goal_minutes': 60,
      'daily_goal_seconds': 3600,
      'daily_goal_progress': 0.5,
      'streak': 4,
      'best_streak': 9,
      'level': 3,
      'level_title': 'Практик',
      'level_seconds': 0,
      'level_step_seconds': 18000,
      'level_progress': 0,
      'total_tasks': 10,
      'completed_tasks': 6,
      'completed_today': 1,
      'message': 'Продолжайте!',
      'achievements': [
        {
          'id': 'streak_3',
          'title': 'Три дня подряд',
          'description': 'Занимайтесь 3 дня',
          'icon': 'local_fire_department',
          'progress': 3,
          'target': 3,
          'unlocked': true,
        },
        {
          'id': 'streak_7',
          'title': 'Неделя силы',
          'description': 'Занимайтесь 7 дней',
          'icon': 'whatshot',
          'progress': 4,
          'target': 7,
          'unlocked': false,
        },
      ],
    });

    expect(motivation.level, 3);
    expect(motivation.streak, 4);
    expect(motivation.unlockedCount, 1);
    expect(motivation.achievements.last.ratio, closeTo(4 / 7, 0.001));
  });

  test('User parses profile customisation fields', () {
    final user = User.fromJson({
      'id': 1,
      'email': 'a@b.c',
      'name': 'Ann',
      'coins': 10,
      'avatar': '🚀',
      'bio': 'Учусь',
      'daily_goal_minutes': 90,
      'accent_color': '#0EA5E9',
      'theme_mode': 'dark',
    });

    expect(user.avatar, '🚀');
    expect(user.dailyGoalMinutes, 90);
    expect(user.accentColor, '#0EA5E9');
    expect(user.themeMode, 'dark');
  });
}
