import '../models/motivation.dart';
import '../models/statistics.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../models/task.dart';
import 'api_client.dart';

/// REST calls for everything except auth and AI.
class ApiService {
  final ApiClient _client;

  ApiService(this._client);

  // ---------------------------------------------------------------- subjects

  Future<List<Subject>> getSubjects() async {
    final data = await _client.get('/subjects');
    return _list(data, 'subjects')
        .whereType<Map<String, dynamic>>()
        .map(Subject.fromJson)
        .toList();
  }

  Future<Subject> createSubject(String name, String color) async {
    final data = await _client.post(
      '/subjects',
      body: {'name': name.trim(), 'color': color},
    );
    final subject = _map(data)['subject'];
    if (subject is! Map<String, dynamic>) {
      throw const ApiException('Некорректный ответ сервера');
    }
    return Subject.fromJson(subject);
  }

  Future<void> deleteSubject(int id) async {
    await _client.delete('/subjects/$id');
  }

  // ---------------------------------------------------------------- sessions

  Future<List<StudySession>> getSessions({int limit = 50}) async {
    final data = await _client.get(
      '/sessions',
      query: {'limit': '$limit'},
    );
    return _list(data, 'sessions')
        .whereType<Map<String, dynamic>>()
        .map(StudySession.fromJson)
        .toList();
  }

  Future<StudySession?> getActiveSession() async {
    final data = await _client.get('/sessions/active');
    final session = _map(data)['session'];
    if (session is! Map<String, dynamic>) return null;
    return StudySession.fromJson(session);
  }

  Future<StudySession> startSession(int subjectId) async {
    final data = await _client.post(
      '/sessions/start',
      body: {'subjectId': subjectId},
    );
    final session = _map(data)['session'];
    if (session is! Map<String, dynamic>) {
      throw const ApiException('Некорректный ответ сервера');
    }
    return StudySession.fromJson(session);
  }

  Future<EndSessionResult> endSession(int sessionId) async {
    final data = await _client.post('/sessions/end/$sessionId');
    return EndSessionResult.fromJson(_map(data));
  }

  Future<void> cancelSession(int sessionId) async {
    await _client.delete('/sessions/$sessionId');
  }

  // -------------------------------------------------------------- statistics

  Future<Statistics> getStatistics() async {
    final data = await _client.get('/statistics');
    return Statistics.fromJson(_map(data));
  }

  // ------------------------------------------------------------------- tasks

  Future<List<Task>> getTasks({DateTime? from, DateTime? to}) async {
    final data = await _client.get(
      '/tasks',
      query: {
        if (from != null) 'from': _dateParam(from),
        if (to != null) 'to': _dateParam(to),
      },
    );
    return _list(data, 'tasks')
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .toList();
  }

  Future<Task> createTask({
    required String title,
    required DateTime dueDate,
    String notes = '',
  }) async {
    final data = await _client.post(
      '/tasks',
      body: {
        'title': title.trim(),
        'notes': notes.trim(),
        'dueDate': _dateParam(dueDate),
      },
    );
    final task = _map(data)['task'];
    if (task is! Map<String, dynamic>) {
      throw const ApiException('Некорректный ответ сервера');
    }
    return Task.fromJson(task);
  }

  Future<Task> updateTask(
    int id, {
    String? title,
    String? notes,
    DateTime? dueDate,
    bool? completed,
  }) async {
    final data = await _client.patch(
      '/tasks/$id',
      body: {
        if (title != null) 'title': title.trim(),
        if (notes != null) 'notes': notes.trim(),
        if (dueDate != null) 'dueDate': _dateParam(dueDate),
        'completed': ?completed,
      },
    );
    final task = _map(data)['task'];
    if (task is! Map<String, dynamic>) {
      throw const ApiException('Некорректный ответ сервера');
    }
    return Task.fromJson(task);
  }

  Future<void> deleteTask(int id) async {
    await _client.delete('/tasks/$id');
  }

  // -------------------------------------------------------------- motivation

  Future<Motivation> getMotivation() async {
    final data = await _client.get('/motivation');
    return Motivation.fromJson(_map(data));
  }

  String _dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const ApiException('Некорректный ответ сервера');
  }

  List<dynamic> _list(dynamic data, String key) {
    final value = _map(data)[key];
    return value is List ? value : const [];
  }
}
