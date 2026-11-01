import 'subject.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int progress;
  final int target;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
    required this.unlocked,
  });

  double get ratio => target <= 0 ? 0 : (progress / target).clamp(0, 1);

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        icon: (json['icon'] ?? 'star').toString(),
        progress: toInt(json['progress']),
        target: toInt(json['target']),
        unlocked: json['unlocked'] == true,
      );
}

class Motivation {
  final int totalSeconds;
  final int todaySeconds;
  final int sessionCount;
  final int dailyGoalMinutes;
  final int dailyGoalSeconds;
  final double dailyGoalProgress;
  final int streak;
  final int bestStreak;
  final int level;
  final String levelTitle;
  final int levelSeconds;
  final int levelStepSeconds;
  final double levelProgress;
  final int totalTasks;
  final int completedTasks;
  final int completedToday;
  final String message;
  final List<Achievement> achievements;

  const Motivation({
    required this.totalSeconds,
    required this.todaySeconds,
    required this.sessionCount,
    required this.dailyGoalMinutes,
    required this.dailyGoalSeconds,
    required this.dailyGoalProgress,
    required this.streak,
    required this.bestStreak,
    required this.level,
    required this.levelTitle,
    required this.levelSeconds,
    required this.levelStepSeconds,
    required this.levelProgress,
    required this.totalTasks,
    required this.completedTasks,
    required this.completedToday,
    required this.message,
    required this.achievements,
  });

  static const empty = Motivation(
    totalSeconds: 0,
    todaySeconds: 0,
    sessionCount: 0,
    dailyGoalMinutes: 60,
    dailyGoalSeconds: 3600,
    dailyGoalProgress: 0,
    streak: 0,
    bestStreak: 0,
    level: 1,
    levelTitle: 'Новичок',
    levelSeconds: 0,
    levelStepSeconds: 18000,
    levelProgress: 0,
    totalTasks: 0,
    completedTasks: 0,
    completedToday: 0,
    message: 'Начните занятие или отметьте задачу в календаре.',
    achievements: [],
  );

  int get unlockedCount => achievements.where((a) => a.unlocked).length;

  factory Motivation.fromJson(Map<String, dynamic> json) => Motivation(
        totalSeconds: toInt(json['total_seconds']),
        todaySeconds: toInt(json['today_seconds']),
        sessionCount: toInt(json['session_count']),
        dailyGoalMinutes: toInt(json['daily_goal_minutes']),
        dailyGoalSeconds: toInt(json['daily_goal_seconds']),
        dailyGoalProgress: _toDouble(json['daily_goal_progress']),
        streak: toInt(json['streak']),
        bestStreak: toInt(json['best_streak']),
        level: toInt(json['level']),
        levelTitle: (json['level_title'] ?? 'Новичок').toString(),
        levelSeconds: toInt(json['level_seconds']),
        levelStepSeconds: toInt(json['level_step_seconds']),
        levelProgress: _toDouble(json['level_progress']),
        totalTasks: toInt(json['total_tasks']),
        completedTasks: toInt(json['completed_tasks']),
        completedToday: toInt(json['completed_today']),
        message: (json['message'] ?? '').toString(),
        achievements:
            (json['achievements'] is List ? json['achievements'] as List : const [])
                .whereType<Map<String, dynamic>>()
                .map(Achievement.fromJson)
                .toList(),
      );
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
