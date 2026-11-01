import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';

class CalendarProvider extends ChangeNotifier {
  final ApiService _api;

  CalendarProvider(this._api);

  List<Task> _tasks = [];
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = dateOnly(DateTime.now());

  bool _loading = false;
  String? _error;
  int _requestId = 0;

  List<Task> get tasks => _tasks;
  DateTime get visibleMonth => _visibleMonth;
  DateTime get selectedDate => _selectedDate;
  bool get loading => _loading;
  String? get error => _error;

  List<Task> get selectedTasks =>
      _tasks.where((task) => _isSameDay(task.dueDate, _selectedDate)).toList();

  /// Tasks grouped by day, used by the month grid.
  Map<DateTime, List<Task>> get byDay {
    final map = <DateTime, List<Task>>{};
    for (final task in _tasks) {
      final key = dateOnly(task.dueDate);
      map.putIfAbsent(key, () => []).add(task);
    }
    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    // Only the latest request may update state: switching months quickly must
    // not leave the grid showing data for a month the user already left.
    final requestId = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      final last = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      final tasks = await _api.getTasks(from: first, to: last);
      if (requestId != _requestId) return;
      _tasks = tasks;
    } on ApiException catch (error) {
      if (requestId != _requestId) return;
      _error = error.message;
    } finally {
      if (requestId == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = dateOnly(date);
    if (_selectedDate.month != _visibleMonth.month ||
        _selectedDate.year != _visibleMonth.year) {
      _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
      notifyListeners();
      load();
      return;
    }
    notifyListeners();
  }

  void showMonth(DateTime month) {
    _visibleMonth = DateTime(month.year, month.month);
    notifyListeners();
    load();
  }

  void previousMonth() =>
      showMonth(DateTime(_visibleMonth.year, _visibleMonth.month - 1));

  void nextMonth() =>
      showMonth(DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  void goToToday() {
    final today = dateOnly(DateTime.now());
    _selectedDate = today;
    if (_visibleMonth.year != today.year || _visibleMonth.month != today.month) {
      _visibleMonth = DateTime(today.year, today.month);
      notifyListeners();
      load();
    } else {
      notifyListeners();
    }
  }

  Future<void> addTask({
    required String title,
    required DateTime dueDate,
    String notes = '',
  }) async {
    final task = await _api.createTask(
      title: title,
      dueDate: dueDate,
      notes: notes,
    );
    _insert(task);
    _selectedDate = dateOnly(dueDate);
    notifyListeners();
  }

  Future<void> updateTask(
    Task task, {
    String? title,
    String? notes,
    DateTime? dueDate,
  }) async {
    final updated = await _api.updateTask(
      task.id,
      title: title,
      notes: notes,
      dueDate: dueDate,
    );
    _replace(updated);
    notifyListeners();
  }

  Future<void> toggleTask(Task task) async {
    // Optimistic update keeps the checkbox responsive.
    final optimistic = task.copyWith(completed: !task.completed);
    _replace(optimistic);
    notifyListeners();

    try {
      final updated = await _api.updateTask(task.id, completed: !task.completed);
      _replace(updated);
    } on ApiException {
      _replace(task);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteTask(Task task) async {
    await _api.deleteTask(task.id);
    _tasks = _tasks.where((item) => item.id != task.id).toList();
    notifyListeners();
  }

  void reset() {
    _requestId++;
    _tasks = [];
    _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDate = dateOnly(DateTime.now());
    _error = null;
    _loading = false;
    notifyListeners();
  }

  void _insert(Task task) {
    if (task.dueDate.month != _visibleMonth.month ||
        task.dueDate.year != _visibleMonth.year) {
      _visibleMonth = DateTime(task.dueDate.year, task.dueDate.month);
      load();
      return;
    }
    _tasks = [..._tasks, task]..sort(_compare);
  }

  void _replace(Task task) {
    _tasks = [
      for (final item in _tasks)
        if (item.id == task.id) task else item,
    ]..sort(_compare);
  }

  int _compare(Task a, Task b) {
    final byDate = a.dueDate.compareTo(b.dueDate);
    if (byDate != 0) return byDate;
    if (a.completed != b.completed) return a.completed ? 1 : -1;
    return a.id.compareTo(b.id);
  }
}
