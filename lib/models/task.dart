import 'subject.dart';

class Task {
  final int id;
  final String title;
  final String notes;
  final DateTime dueDate;
  final bool completed;

  const Task({
    required this.id,
    required this.title,
    required this.notes,
    required this.dueDate,
    required this.completed,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: toInt(json['id']),
        title: (json['title'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),
        dueDate: parseDateOnly(json['due_date']) ?? DateTime.now(),
        completed: json['completed'] == true,
      );

  Task copyWith({
    String? title,
    String? notes,
    DateTime? dueDate,
    bool? completed,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        dueDate: dueDate ?? this.dueDate,
        completed: completed ?? this.completed,
      );
}

/// Parses "YYYY-MM-DD" (or an ISO timestamp) into a local date without time.
DateTime? parseDateOnly(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty) return null;

  final datePart = text.length >= 10 ? text.substring(0, 10) : text;
  final parts = datePart.split('-');
  if (parts.length != 3) return DateTime.tryParse(text)?.toLocal();

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

/// Drops the time part so two dates on the same day compare equal.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
