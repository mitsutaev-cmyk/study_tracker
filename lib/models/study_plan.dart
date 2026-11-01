import 'subject.dart';

class SavedStudyPlan {
  final int id;
  final String subject;
  final String goal;
  final Map<String, dynamic> plan;
  final DateTime createdAt;

  const SavedStudyPlan({
    required this.id,
    required this.subject,
    required this.goal,
    required this.plan,
    required this.createdAt,
  });

  factory SavedStudyPlan.fromJson(Map<String, dynamic> json) => SavedStudyPlan(
        id: toInt(json['id']),
        subject: (json['subject'] ?? '').toString(),
        goal: (json['goal'] ?? '').toString(),
        plan: json['plan_data'] is Map<String, dynamic>
            ? json['plan_data'] as Map<String, dynamic>
            : const {},
        createdAt:
            DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
                DateTime.now(),
      );
}
