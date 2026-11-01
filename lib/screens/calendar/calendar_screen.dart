import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/motivation_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';

const _months = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

class CalendarScreen extends StatefulWidget {
  final bool embedded;

  const CalendarScreen({super.key, this.embedded = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CalendarProvider>().load();
    });
  }

  Future<void> _openTaskEditor({Task? task, DateTime? initialDate}) async {
    final result = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => _TaskDialog(
        task: task,
        initialDate: initialDate ?? context.read<CalendarProvider>().selectedDate,
      ),
    );
    if (result == null || !mounted) return;

    final calendar = context.read<CalendarProvider>();
    try {
      if (task == null) {
        await calendar.addTask(
          title: result.title,
          notes: result.notes,
          dueDate: result.dueDate,
        );
      } else {
        await calendar.updateTask(
          task,
          title: result.title,
          notes: result.notes,
          dueDate: result.dueDate,
        );
      }
      if (!mounted) return;
      context.read<MotivationProvider>().load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _toggle(Task task) async {
    try {
      await context.read<CalendarProvider>().toggleTask(task);
      if (!mounted) return;
      context.read<MotivationProvider>().load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _delete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('«${task.title}» будет удалена.'),
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
      await context.read<CalendarProvider>().deleteTask(task);
      if (!mounted) return;
      context.read<MotivationProvider>().load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarProvider>();
    final theme = Theme.of(context);

    final content = RefreshIndicator(
      onRefresh: calendar.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, widget.embedded ? 96 : 24),
        children: [
          _MonthCard(
            month: calendar.visibleMonth,
            selectedDate: calendar.selectedDate,
            byDay: calendar.byDay,
            onPrevious: calendar.previousMonth,
            onNext: calendar.nextMonth,
            onToday: calendar.goToToday,
            onSelect: calendar.selectDate,
          ),
          if (calendar.error != null) ...[
            const SizedBox(height: 12),
            InlineError(message: calendar.error!, onRetry: calendar.load),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dayTitle(calendar.selectedDate),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openTaskEditor(
                  initialDate: calendar.selectedDate,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Задача'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (calendar.loading && calendar.tasks.isEmpty)
            const SizedBox(height: 180, child: LoadingView())
          else if (calendar.selectedTasks.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 40,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'На этот день задач нет',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Запланируйте, что хотите сделать.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final task in calendar.selectedTasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TaskCard(
                  task: task,
                  onToggle: () => _toggle(task),
                  onEdit: () => _openTaskEditor(task: task),
                  onDelete: () => _delete(task),
                ),
              ),
        ],
      ),
    );

    final fab = FloatingActionButton(
      onPressed: () => _openTaskEditor(),
      tooltip: 'Добавить задачу',
      child: const Icon(Icons.add),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: content,
        floatingActionButton: fab,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),
      body: content,
      floatingActionButton: fab,
    );
  }

  String _dayTitle(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final prefix = isToday ? 'Сегодня, ' : '';
    return '$prefix${date.day} ${_months[date.month - 1].toLowerCase()}';
  }
}

class _MonthCard extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Map<DateTime, List<Task>> byDay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelect;

  const _MonthCard({
    required this.month,
    required this.selectedDate,
    required this.byDay,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    // Monday-first grid: weekday 1..7 -> column 0..6
    final leading = firstDay.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Предыдущий месяц',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${_months[month.month - 1]} ${month.year}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Следующий месяц',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final day in _weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 46,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - leading + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(month.year, month.month, dayNumber);
                return _DayCell(
                  date: date,
                  tasks: byDay[date] ?? const [],
                  isSelected: date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day,
                  isToday: date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day,
                  onTap: () => onSelect(date),
                );
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Сегодня'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final List<Task> tasks;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.tasks,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allDone = tasks.isNotEmpty && tasks.every((task) => task.completed);

    Color background;
    Color foreground;
    if (isSelected) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (isToday) {
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
    } else {
      background = Colors.transparent;
      foreground = scheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: foreground,
                  fontWeight: isToday || isSelected ? FontWeight.w700 : null,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: tasks.isEmpty
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: allDone
                                ? Colors.green.shade600
                                : (isSelected ? scheme.onPrimary : scheme.primary),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (tasks.length > 1) ...[
                          const SizedBox(width: 2),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: (isSelected
                                      ? scheme.onPrimary
                                      : scheme.primary)
                                  .withValues(alpha: 0.45),
                              shape: BoxShape.circle,
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
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = !task.completed &&
        dateOnly(task.dueDate).isBefore(dateOnly(DateTime.now()));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.completed,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (overdue) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Просрочено',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Действия',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Изменить')),
                PopupMenuItem(value: 'delete', child: Text('Удалить')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDraft {
  final String title;
  final String notes;
  final DateTime dueDate;

  const _TaskDraft({
    required this.title,
    required this.notes,
    required this.dueDate,
  });
}

class _TaskDialog extends StatefulWidget {
  final Task? task;
  final DateTime initialDate;

  const _TaskDialog({this.task, required this.initialDate});

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    _dueDate = widget.task?.dueDate ?? widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'К какому дню',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _TaskDraft(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.task == null ? 'Новая задача' : 'Изменить задачу'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Что сделать',
                prefixIcon: Icon(Icons.task_alt),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Введите задачу'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Заметка (необязательно)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'К какому дню',
                  prefixIcon: Icon(Icons.event),
                ),
                child: Text(
                  '${_dueDate.day} ${_months[_dueDate.month - 1].toLowerCase()} '
                  '${_dueDate.year}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }
}
