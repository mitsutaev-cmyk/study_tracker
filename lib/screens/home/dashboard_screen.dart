import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/motivation.dart';
import '../../models/study_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/motivation_provider.dart';
import '../../providers/study_provider.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  final bool embedded;

  const DashboardScreen({super.key, this.embedded = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MotivationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final auth = context.watch<AuthProvider>();
    final motivation = context.watch<MotivationProvider>();
    final stats = study.statistics;
    final theme = Theme.of(context);

    final content = RefreshIndicator(
      onRefresh: () async {
        final motivationProvider = context.read<MotivationProvider>();
        await study.refreshAll();
        await motivationProvider.load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Привет, ${auth.displayName}!',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.todaySeconds > 0
                          ? 'Сегодня вы уже учились ${formatDuration(stats.todaySeconds)}'
                          : 'Хороший день, чтобы начать заниматься',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    auth.user?.avatar ?? '🎓',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.today_rounded,
                  label: 'Сегодня',
                  value: formatDuration(stats.todaySeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.schedule_rounded,
                  label: 'Всего',
                  value: formatDuration(stats.totalSeconds),
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.monetization_on_outlined,
                  label: 'Монеты',
                  value: '${auth.coins}',
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MotivationCard(
            data: motivation.data,
            loading: motivation.loading,
            onOpen: () => Navigator.pushNamed(context, '/motivation'),
          ),
          if (study.subjectsError != null) ...[
            const SizedBox(height: 16),
            InlineError(
              message: study.subjectsError!,
              onRetry: study.loadSubjects,
            ),
          ],
          if (study.statisticsError != null) ...[
            const SizedBox(height: 16),
            InlineError(
              message: study.statisticsError!,
              onRetry: study.loadStatistics,
            ),
          ],
          if (study.activeSession != null) ...[
            const SizedBox(height: 16),
            _ActiveSessionBanner(
              session: study.activeSession!,
              subjectName: study.activeSubject?.name,
              elapsed: study.elapsed,
            ),
          ],
          const SizedBox(height: 20),
          SectionCard(
            title: 'Быстрые действия',
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                _QuickAction(
                  icon: Icons.menu_book_rounded,
                  label: 'Предметы',
                  onTap: () => Navigator.pushNamed(context, '/subjects'),
                ),
                _QuickAction(
                  icon: Icons.play_circle_outline,
                  label: 'Занятие',
                  onTap: () => Navigator.pushNamed(context, '/study-session'),
                ),
                _QuickAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Календарь',
                  onTap: () => Navigator.pushNamed(context, '/calendar'),
                ),
                _QuickAction(
                  icon: Icons.auto_awesome,
                  label: 'План учёбы',
                  onTap: () => Navigator.pushNamed(context, '/study-plans'),
                ),
                _QuickAction(
                  icon: Icons.insights_rounded,
                  label: 'AI-советы',
                  onTap: () =>
                      Navigator.pushNamed(context, '/ai-recommendations'),
                ),
                _QuickAction(
                  icon: Icons.rate_review_outlined,
                  label: 'Проверка работы',
                  onTap: () => Navigator.pushNamed(context, '/work-review'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Последние занятия',
            child: study.sessionsLoading && study.sessions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : study.sessions.isEmpty
                    ? Text(
                        'Пока нет завершённых занятий.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Column(
                        children: [
                          for (final session in study.sessions.take(5))
                            _SessionRow(session: session),
                        ],
                      ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: content,
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final Motivation data;
  final bool loading;
  final VoidCallback onOpen;

  const _MotivationCard({
    required this.data,
    required this.loading,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Серия: ${data.streak} дн.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ур. ${data.level}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onPrimaryContainer,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Цель дня: ${formatDuration(data.todaySeconds)} из '
                      '${data.dailyGoalMinutes} мин',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    '${(data.dailyGoalProgress * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.dailyGoalProgress,
                  minHeight: 6,
                  backgroundColor: scheme.onPrimaryContainer.withValues(
                    alpha: 0.15,
                  ),
                  color: scheme.onPrimaryContainer,
                ),
              ),
              if (loading && data.sessionCount == 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Загружаем прогресс...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ] else if (data.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  final StudySession session;
  final String? subjectName;
  final ValueListenable<Duration> elapsed;

  const _ActiveSessionBanner({
    required this.session,
    required this.subjectName,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/study-session'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName ?? session.subjectName ?? 'Активное занятие',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ValueListenableBuilder<Duration>(
                      valueListenable: elapsed,
                      builder: (context, value, _) => Text(
                        formatTimer(value),
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final StudySession session;

  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ColorDot(color: colorFromHex(session.subjectColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subjectName ?? 'Занятие',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  formatDateTime(session.startTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            formatDuration(session.duration),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
