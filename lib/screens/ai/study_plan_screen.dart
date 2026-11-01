import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/study_plan.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/ai_result_view.dart';
import '../../widgets/common.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _subjectController = TextEditingController();

  String _level = 'Beginner';
  double _deadline = 30;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _plan;

  List<SavedStudyPlan> _savedPlans = [];
  bool _savedLoading = true;
  String? _savedError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedPlans());
  }

  @override
  void dispose() {
    _goalController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPlans() async {
    if (!mounted) return;
    setState(() {
      _savedLoading = true;
      _savedError = null;
    });
    try {
      final plans = await context.read<AIService>().getSavedPlans();
      if (!mounted) return;
      setState(() => _savedPlans = plans);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _savedError = error.message);
    } finally {
      if (mounted) setState(() => _savedLoading = false);
    }
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
      _plan = null;
    });

    try {
      final plan = await context.read<AIService>().generateStudyPlan(
            goal: _goalController.text.trim(),
            subject: _subjectController.text.trim(),
            currentLevel: _level,
            deadlineDays: _deadline.round(),
          );
      if (!mounted) return;
      setState(() => _plan = plan);
      _loadSavedPlans();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Учебный план'),
        actions: [
          IconButton(
            tooltip: 'Обновить список',
            onPressed: _savedLoading ? null : _loadSavedPlans,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionCard(
            title: 'Параметры обучения',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _goalController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Цель',
                      hintText: 'Например: подготовиться к экзамену на 5',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Опишите цель'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subjectController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Предмет',
                      hintText: 'Например: математический анализ',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Укажите предмет'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _level,
                    decoration: const InputDecoration(
                      labelText: 'Текущий уровень',
                      prefixIcon: Icon(Icons.trending_up),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Beginner',
                        child: Text('Начальный'),
                      ),
                      DropdownMenuItem(
                        value: 'Intermediate',
                        child: Text('Средний'),
                      ),
                      DropdownMenuItem(
                        value: 'Advanced',
                        child: Text('Продвинутый'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _level = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Срок',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${_deadline.round()} дней',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: _deadline,
                    min: 7,
                    max: 120,
                    divisions: 113,
                    label: '${_deadline.round()} дней',
                    onChanged: (value) => setState(() => _deadline = value),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _loading ? 'AI составляет план...' : 'Составить план',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InlineError(message: _error!),
          ],
          if (_plan != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Ваш план',
              child: AiResultView(data: _plan!),
            ),
          ],
          const SizedBox(height: 20),
          SectionCard(
            title: 'Сохранённые планы',
            child: _savedLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _savedError != null
                    ? InlineError(
                        message: _savedError!,
                        onRetry: _loadSavedPlans,
                      )
                    : _savedPlans.isEmpty
                        ? Text(
                            'Сгенерированные планы будут сохраняться здесь.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Column(
                            children: [
                              for (final plan in _savedPlans)
                                Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  child: ExpansionTile(
                                    shape: const Border(),
                                    collapsedShape: const Border(),
                                    title: Text(
                                      plan.subject,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    subtitle: Text(
                                      '${plan.goal} • ${formatDateShort(plan.createdAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      12,
                                    ),
                                    children: [
                                      AiResultView(data: plan.plan),
                                    ],
                                  ),
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
