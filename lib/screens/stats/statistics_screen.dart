import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/statistics.dart';
import '../../providers/study_provider.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/ai_result_view.dart';
import '../../widgets/common.dart';

class StatisticsScreen extends StatefulWidget {
  final bool embedded;

  const StatisticsScreen({super.key, this.embedded = false});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<StudyProvider>().loadStatistics();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final stats = study.statistics;
    final theme = Theme.of(context);

    final content = RefreshIndicator(
      onRefresh: study.loadStatistics,
      child: study.statisticsLoading && stats.sessionCount == 0
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 320, child: LoadingView()),
              ],
            )
          : study.statisticsError != null && stats.sessionCount == 0
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 360,
                      child: ErrorView(
                        message: study.statisticsError!,
                        onRetry: study.loadStatistics,
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (study.statisticsError != null) ...[
                      InlineError(
                        message: study.statisticsError!,
                        onRetry: study.loadStatistics,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            icon: Icons.schedule,
                            label: 'Всего',
                            value: formatDuration(stats.totalSeconds),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(
                            icon: Icons.today,
                            label: 'Сегодня',
                            value: formatDuration(stats.todaySeconds),
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            icon: Icons.date_range,
                            label: 'За 7 дней',
                            value: formatDuration(stats.weekSeconds),
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(
                            icon: Icons.checklist,
                            label: 'Занятий',
                            value: '${stats.sessionCount}',
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (stats.sessionCount == 0)
                      SizedBox(
                        height: 320,
                        child: EmptyView(
                          icon: Icons.bar_chart_rounded,
                          title: 'Статистики пока нет',
                          message:
                              'Завершите первое занятие, и здесь появится график.',
                          action: FilledButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/study-session'),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Начать занятие'),
                          ),
                        ),
                      )
                    else ...[
                      SectionCard(
                        title: 'Последние 7 дней',
                        child: _WeeklyChart(stats: stats),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'По предметам',
                        child: _SubjectBreakdown(stats: stats),
                      ),
                      const SizedBox(height: 16),
                      const _AiAnalysisCard(),
                    ],
                  ],
                ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: content,
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Statistics stats;

  const _WeeklyChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSeconds = stats.maxDailySeconds;

    if (stats.daily.isEmpty) {
      return Text(
        'Нет данных за последнюю неделю.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in stats.daily)
            Expanded(
              child: Tooltip(
                message:
                    '${formatDateShort(day.date)} — ${formatDuration(day.seconds)}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      day.seconds == 0 ? '' : '${day.seconds ~/ 60}м',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: maxSeconds == 0
                          ? 4
                          : (day.seconds / maxSeconds * 90)
                              .clamp(4.0, 90.0)
                              .toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: day.seconds == 0 ? 0.15 : 0.75,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weekdayShort(day.date),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// AI view of the statistics: the backend sends the numbers to the model and
/// returns strengths, weaknesses and concrete recommendations.
class _AiAnalysisCard extends StatefulWidget {
  const _AiAnalysisCard();

  @override
  State<_AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<_AiAnalysisCard> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _analysis;

  Future<void> _analyze() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await context.read<AIService>().analyzeStats();
      if (!mounted) return;
      setState(() => _analysis = result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = _analysis;

    return SectionCard(
      title: 'AI-разбор статистики',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Модель посмотрит на ваши занятия и подскажет, что работает, '
            'где проседает время и что делать дальше.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _loading ? null : _analyze,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _loading
                  ? 'AI анализирует...'
                  : analysis == null
                      ? 'Разобрать мою статистику'
                      : 'Обновить разбор',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            InlineError(message: _error!),
          ],
          if (analysis != null) ...[
            const SizedBox(height: 16),
            AiResultView(data: analysis),
          ],
        ],
      ),
    );
  }
}

class _SubjectBreakdown extends StatelessWidget {
  final Statistics stats;

  const _SubjectBreakdown({required this.stats});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.subjects.isEmpty) {
      return Text(
        'Пока нет данных по предметам.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final maxSeconds = stats.subjects.fold<int>(
      1,
      (max, subject) =>
          subject.totalSeconds > max ? subject.totalSeconds : max,
    );

    return Column(
      children: [
        for (var i = 0; i < stats.subjects.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          _SubjectRow(
            stat: stats.subjects[i],
            maxSeconds: maxSeconds,
          ),
        ],
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectStat stat;
  final int maxSeconds;

  const _SubjectRow({required this.stat, required this.maxSeconds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorFromHex(stat.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ColorDot(color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stat.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Text(
              formatDuration(stat.totalSeconds),
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stat.totalSeconds / maxSeconds,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${stat.sessionCount} занятий',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
