import 'subject.dart';

class StudySession {
  final int id;
  final int subjectId;
  final String? subjectName;
  final String? subjectColor;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration;

  const StudySession({
    required this.id,
    required this.subjectId,
    required this.startTime,
    this.subjectName,
    this.subjectColor,
    this.endTime,
    this.duration = 0,
  });

  bool get isActive => endTime == null;

  Duration get elapsed => endTime != null
      ? Duration(seconds: duration)
      : DateTime.now().difference(startTime);

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: toInt(json['id']),
        subjectId: toInt(json['subject_id']),
        subjectName: json['subject_name']?.toString(),
        subjectColor: json['subject_color']?.toString(),
        startTime: _parseDate(json['start_time']) ?? DateTime.now(),
        endTime: _parseDate(json['end_time']),
        duration: toInt(json['duration']),
      );
}

class EndSessionResult {
  final StudySession session;
  final int coinsEarned;
  final int coins;

  const EndSessionResult({
    required this.session,
    required this.coinsEarned,
    required this.coins,
  });

  factory EndSessionResult.fromJson(Map<String, dynamic> json) {
    final rawSession = json['session'];
    return EndSessionResult(
      session: rawSession is Map<String, dynamic>
          ? StudySession.fromJson(rawSession)
          : StudySession(
              id: 0,
              subjectId: 0,
              startTime: DateTime.now(),
              endTime: DateTime.now(),
            ),
      coinsEarned: toInt(json['coins_earned']),
      coins: toInt(json['coins']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
