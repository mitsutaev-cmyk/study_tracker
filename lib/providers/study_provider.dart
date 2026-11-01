import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/statistics.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';

class StudyProvider extends ChangeNotifier {
  final ApiService _api;

  StudyProvider(this._api);

  List<Subject> _subjects = [];
  List<StudySession> _sessions = [];
  Statistics _statistics = Statistics.empty;
  StudySession? _activeSession;

  bool _subjectsLoading = false;
  bool _sessionsLoading = false;
  bool _statisticsLoading = false;
  String? _subjectsError;
  String? _sessionsError;
  String? _statisticsError;

  Timer? _ticker;

  /// Ticks once per second while a session is running. Kept separate from
  /// [notifyListeners] so only the timer widgets rebuild.
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);

  List<Subject> get subjects => _subjects;
  List<StudySession> get sessions => _sessions;
  Statistics get statistics => _statistics;
  StudySession? get activeSession => _activeSession;

  bool get subjectsLoading => _subjectsLoading;
  bool get sessionsLoading => _sessionsLoading;
  bool get statisticsLoading => _statisticsLoading;
  String? get subjectsError => _subjectsError;
  String? get sessionsError => _sessionsError;
  String? get statisticsError => _statisticsError;

  bool get hasActiveSession => _activeSession != null;

  Subject? get activeSubject {
    final active = _activeSession;
    if (active == null) return null;
    for (final subject in _subjects) {
      if (subject.id == active.subjectId) return subject;
    }
    return null;
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadSubjects(),
      loadSessions(),
      loadActiveSession(),
      loadStatistics(),
    ]);
  }

  Future<void> loadSubjects() async {
    _subjectsLoading = true;
    _subjectsError = null;
    notifyListeners();
    try {
      _subjects = await _api.getSubjects();
    } on ApiException catch (error) {
      _subjectsError = error.message;
    } finally {
      _subjectsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessions() async {
    _sessionsLoading = true;
    _sessionsError = null;
    notifyListeners();
    try {
      _sessions = await _api.getSessions();
    } on ApiException catch (error) {
      _sessionsError = error.message;
    } finally {
      _sessionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStatistics() async {
    _statisticsLoading = true;
    _statisticsError = null;
    notifyListeners();
    try {
      _statistics = await _api.getStatistics();
    } on ApiException catch (error) {
      _statisticsError = error.message;
    } finally {
      _statisticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveSession() async {
    try {
      final active = await _api.getActiveSession();
      _setActiveSession(active);
    } on ApiException {
      // Keep the known session on a transient network error: the backend will
      // reject a second start with 409 and we resync then.
    }
  }

  Future<Subject> createSubject(String name, String color) async {
    final subject = await _api.createSubject(name, color);
    await Future.wait([loadSubjects(), loadStatistics()]);
    return subject;
  }

  Future<void> deleteSubject(int id) async {
    await _api.deleteSubject(id);
    await Future.wait([
      loadSubjects(),
      loadSessions(),
      loadStatistics(),
      // Deleting a subject also deletes its sessions, including the active one.
      loadActiveSession(),
    ]);
  }

  /// Starts a session and throws [ApiException] when the backend refuses
  /// (e.g. another session is already running).
  Future<void> startSession(int subjectId) async {
    try {
      final session = await _api.startSession(subjectId);
      _setActiveSession(session);
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        await loadActiveSession();
      }
      rethrow;
    }
  }

  Future<EndSessionResult> endSession() async {
    final active = _activeSession;
    if (active == null) {
      throw const ApiException('Нет активного занятия');
    }
    final result = await _api.endSession(active.id);
    _setActiveSession(null);
    await Future.wait([loadSessions(), loadSubjects(), loadStatistics()]);
    return result;
  }

  Future<void> cancelSession() async {
    final active = _activeSession;
    if (active == null) return;
    await _api.cancelSession(active.id);
    _setActiveSession(null);
    await Future.wait([loadSessions(), loadSubjects(), loadStatistics()]);
  }

  void reset() {
    _subjects = [];
    _sessions = [];
    _statistics = Statistics.empty;
    _setActiveSession(null);
    _subjectsError = null;
    _sessionsError = null;
    _statisticsError = null;
    notifyListeners();
  }

  void _setActiveSession(StudySession? session) {
    _activeSession = session;
    if (session == null) {
      _stopTicker();
    } else {
      _tick();
      _startTicker();
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    elapsed.value = Duration.zero;
  }

  void _tick() {
    final active = _activeSession;
    if (active == null) {
      _stopTicker();
      return;
    }
    final value = DateTime.now().difference(active.startTime);
    elapsed.value = value.isNegative ? Duration.zero : value;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    elapsed.dispose();
    super.dispose();
  }
}
