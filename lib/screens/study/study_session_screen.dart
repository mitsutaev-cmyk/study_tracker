import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/motivation_provider.dart';
import '../../providers/study_provider.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  int? _selectedSubjectId;
  bool _starting = false;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    final study = context.read<StudyProvider>();

    if (study.subjects.isEmpty) {
      await study.loadSubjects();
    }
    if (!mounted) return;
    await study.loadActiveSession();
    if (!mounted) return;

    if (study.subjects.isNotEmpty && _selectedSubjectId == null) {
      setState(() => _selectedSubjectId = study.subjects.first.id);
    }
  }

  Future<void> _start() async {
    final subjectId = _selectedSubjectId;
    if (subjectId == null || _starting) return;

    setState(() => _starting = true);
    try {
      await context.read<StudyProvider>().startSession(subjectId);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _finish() async {
    if (_ending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Завершить занятие?'),
        content: const Text('Время будет сохранено, а монеты начислены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _ending = true);
    try {
      final result = await context.read<StudyProvider>().endSession();
      if (!mounted) return;
      context.read<AuthProvider>().setCoins(result.coins);
      context.read<MotivationProvider>().load();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Занятие завершено'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Длительность: ${formatDuration(result.session.duration)}'),
              const SizedBox(height: 8),
              Text('Заработано монет: ${result.coinsEarned}'),
              const SizedBox(height: 8),
              Text('Баланс: ${result.coins}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отлично'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Отменить занятие?'),
        content: const Text('Время не будет засчитано, монеты не начислятся.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Отменить занятие'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _ending = true);
    try {
      await context.read<StudyProvider>().cancelSession();
      if (!mounted) return;
      context.read<MotivationProvider>().load();
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  Future<void> _openSubjects() async {
    await Navigator.pushNamed(context, '/subjects');
    if (!mounted) return;
    await context.read<StudyProvider>().loadSubjects();
    if (!mounted) return;
    final subjects = context.read<StudyProvider>().subjects;
    if (subjects.isNotEmpty && _selectedSubjectId == null) {
      setState(() => _selectedSubjectId = subjects.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Занятие')),
      body: SafeArea(
        child: study.activeSession != null
            ? _buildActive(context, study)
            : _buildStart(context, study),
      ),
    );
  }

  Widget _buildActive(BuildContext context, StudyProvider study) {
    final active = study.activeSession!;
    final subject = study.activeSubject;
    final theme = Theme.of(context);
    final color = colorFromHex(subject?.color ?? active.subjectColor);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Icons.book_rounded, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              subject?.name ?? active.subjectName ?? 'Занятие',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Начато ${formatDateTime(active.startTime)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ValueListenableBuilder<Duration>(
                valueListenable: study.elapsed,
                builder: (context, value, _) => Text(
                  formatTimer(value),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '1 монета за каждую полную минуту учёбы',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _ending ? null : _finish,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _ending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop_circle_outlined),
                label: const Text('Завершить занятие'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _ending ? null : _cancel,
              child: const Text('Отменить без сохранения'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStart(BuildContext context, StudyProvider study) {
    final theme = Theme.of(context);

    if (study.subjectsLoading && study.subjects.isEmpty) {
      return const LoadingView(message: 'Загружаем предметы...');
    }

    if (study.subjects.isEmpty) {
      return EmptyView(
        icon: Icons.menu_book_outlined,
        title: 'Сначала добавьте предмет',
        message: 'Занятие привязывается к предмету, чтобы статистика была точной.',
        action: FilledButton.icon(
          onPressed: _openSubjects,
          icon: const Icon(Icons.add),
          label: const Text('Добавить предмет'),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Новое занятие',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите предмет и запустите таймер.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              DropdownButtonFormField<int>(
                initialValue: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Предмет',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: [
                  for (final subject in study.subjects)
                    DropdownMenuItem(
                      value: subject.id,
                      child: Text(
                        subject.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedSubjectId = value),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _starting || _selectedSubjectId == null
                    ? null
                    : _start,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Начать занятие'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _openSubjects,
                child: const Text('Управление предметами'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
