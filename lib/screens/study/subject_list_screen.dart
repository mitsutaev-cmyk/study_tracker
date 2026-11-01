import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/subject.dart';
import '../../providers/study_provider.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

const subjectColors = [
  '#2196F3',
  '#4CAF50',
  '#FF9800',
  '#E91E63',
  '#9C27B0',
  '#009688',
  '#F44336',
  '#795548',
];

class SubjectListScreen extends StatefulWidget {
  final bool embedded;

  const SubjectListScreen({super.key, this.embedded = false});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<StudyProvider>().loadSubjects();
      });
    }
  }

  Future<void> _addSubject() async {
    final result = await showDialog<({String name, String color})>(
      context: context,
      builder: (_) => const _AddSubjectDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await context.read<StudyProvider>().createSubject(result.name, result.color);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _startSession(Subject subject) async {
    final study = context.read<StudyProvider>();

    try {
      if (!study.hasActiveSession) {
        await study.startSession(subject.id);
      }
      if (!mounted) return;
      Navigator.pushNamed(context, '/study-session');
    } on ApiException catch (error) {
      if (!mounted) return;
      if (study.hasActiveSession) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Продолжаем текущее занятие')),
        );
        Navigator.pushNamed(context, '/study-session');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить предмет?'),
        content: Text(
          '«${subject.name}» и все связанные занятия будут удалены безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<StudyProvider>().deleteSubject(subject.id);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final theme = Theme.of(context);

    final content = RefreshIndicator(
      onRefresh: study.loadSubjects,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${study.subjects.length} предметов',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
          if (study.subjectsError != null) ...[
            const SizedBox(height: 12),
            InlineError(
              message: study.subjectsError!,
              onRetry: study.loadSubjects,
            ),
          ],
          const SizedBox(height: 8),
          if (study.subjectsLoading && study.subjects.isEmpty)
            const SizedBox(height: 280, child: LoadingView())
          else if (study.subjects.isEmpty)
            SizedBox(
              height: 360,
              child: EmptyView(
                icon: Icons.menu_book_outlined,
                title: 'Пока нет предметов',
                message: 'Добавьте первый предмет, чтобы начать учитывать время.',
                action: FilledButton.icon(
                  onPressed: _addSubject,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить предмет'),
                ),
              ),
            )
          else
            for (final subject in study.subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorFromHex(subject.color),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
                    title: Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Всего: ${formatDuration(subject.totalSeconds)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Действия',
                      onSelected: (value) {
                        if (value == 'start') _startSession(subject);
                        if (value == 'delete') _deleteSubject(subject);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'start',
                          child: ListTile(
                            leading: Icon(Icons.play_arrow),
                            title: Text('Начать занятие'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Удалить'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Предметы')),
      body: content,
    );
  }
}

class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _color = subjectColors.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      (name: _nameController.text.trim(), color: _color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый предмет'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Введите название'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text('Цвет', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in subjectColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorFromHex(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _color == color
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Добавить')),
      ],
    );
  }
}
