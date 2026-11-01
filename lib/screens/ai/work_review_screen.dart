import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../widgets/ai_result_view.dart';
import '../../widgets/common.dart';

class WorkReviewScreen extends StatefulWidget {
  const WorkReviewScreen({super.key});

  @override
  State<WorkReviewScreen> createState() => _WorkReviewScreenState();
}

class _WorkReviewScreenState extends State<WorkReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();

  String _workType = 'essay';
  String _level = 'intermediate';

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _review;

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
      _review = null;
    });

    try {
      final review = await context.read<AIService>().reviewWork(
            workType: _workType,
            workContent: _contentController.text.trim(),
            subject: _subjectController.text.trim(),
            level: _level,
          );
      if (!mounted) return;
      setState(() => _review = review);
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
      appBar: AppBar(title: const Text('Проверка работы')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionCard(
            title: 'Работа на проверку',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _workType,
                    decoration: const InputDecoration(
                      labelText: 'Тип работы',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'essay', child: Text('Эссе')),
                      DropdownMenuItem(
                        value: 'homework',
                        child: Text('Домашняя работа'),
                      ),
                      DropdownMenuItem(value: 'project', child: Text('Проект')),
                      DropdownMenuItem(
                        value: 'test',
                        child: Text('Тест / контрольная'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Другое')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _workType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subjectController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Предмет',
                      hintText: 'Например: история',
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
                      labelText: 'Уровень',
                      prefixIcon: Icon(Icons.trending_up),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'beginner',
                        child: Text('Начальный'),
                      ),
                      DropdownMenuItem(
                        value: 'intermediate',
                        child: Text('Средний'),
                      ),
                      DropdownMenuItem(
                        value: 'advanced',
                        child: Text('Продвинутый'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _level = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contentController,
                    minLines: 6,
                    maxLines: 12,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Текст работы',
                      alignLabelWithHint: true,
                      hintText: 'Вставьте текст эссе, ответы или описание проекта',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Вставьте текст работы';
                      if (text.length < 20) {
                        return 'Слишком короткий текст для проверки';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.rate_review_outlined),
                      label: Text(
                        _loading ? 'AI проверяет...' : 'Проверить работу',
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
          if (_review != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Отзыв AI',
              child: AiResultView(data: _review!),
            ),
          ] else if (!_loading) ...[
            const SizedBox(height: 20),
            Text(
              'AI даст оценку, укажет сильные стороны, ошибки и следующие шаги.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
