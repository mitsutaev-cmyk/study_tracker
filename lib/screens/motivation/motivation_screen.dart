import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/motivation.dart';
import '../../providers/motivation_provider.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class MotivationScreen extends StatefulWidget {
  const MotivationScreen({super.key});

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MotivationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MotivationProvider>();
    final data = provider.data;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мотивация'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: provider.loading ? null : provider.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (provider.error != null) ...[
              InlineError(message: provider.error!, onRetry: provider.load),
              const SizedBox(height: 12),
            ],
            Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange.shade800,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Серия: ${data.streak} дн.',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'Лучший результат: ${data.bestStreak} дн.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Цель дня',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatDuration(data.todaySeconds)} из '
                          '${data.dailyGoalMinutes} мин',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        '${(data.dailyGoalProgress * 100).round()}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: data.dailyGoalProgress,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.dailyGoalProgress >= 1
                        ? 'Цель выполнена — так держать!'
                        : 'Осталось ${formatDuration((data.dailyGoalSeconds - data.todaySeconds).clamp(0, 1 << 31))}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Уровень ${data.level} · ${data.levelTitle}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: data.levelProgress,
                      minHeight: 10,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${formatDuration(data.levelSeconds)} из '
                    '${formatDuration(data.levelStepSeconds)} до уровня ${data.level + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Задачи',
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Выполнено сегодня',
                      value: '${data.completedToday}',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Всего выполнено',
                      value: '${data.completedTasks}',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Всего задач',
                      value: '${data.totalTasks}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Достижения',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Открыто ${data.unlockedCount} из ${data.achievements.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final achievement in data.achievements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AchievementCard(achievement: achievement),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.unlocked;
    final accent =
        unlocked ? Colors.green.shade600 : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: unlocked
                  ? Colors.green.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                unlocked ? Icons.emoji_events : _icon(achievement.icon),
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (unlocked)
                        Icon(Icons.check_circle, size: 18, color: accent),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!unlocked && achievement.target > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.ratio,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String key) {
    switch (key) {
      case 'play':
        return Icons.play_arrow;
      case 'hourglass':
        return Icons.hourglass_bottom;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'whatshot':
        return Icons.whatshot;
      case 'military_tech':
        return Icons.military_tech;
      case 'checklist':
        return Icons.checklist;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'task_alt':
        return Icons.task_alt;
      case 'event_available':
        return Icons.event_available;
      case 'flag':
        return Icons.flag;
      default:
        return Icons.star;
    }
  }
}
