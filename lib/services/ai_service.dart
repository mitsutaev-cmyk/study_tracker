import '../config/api_config.dart';
import '../models/study_plan.dart';
import 'api_client.dart';

/// Calls the AI endpoints of the backend. The backend talks to OpenAI, so the
/// API key never lives in the Flutter app.
class AIService {
  final ApiClient _client;

  AIService(this._client);

  Future<Map<String, dynamic>> generateStudyPlan({
    required String goal,
    required String subject,
    required String currentLevel,
    required int deadlineDays,
  }) async {
    final data = await _client.post(
      '/ai/study-plan',
      body: {
        'goal': goal,
        'subject': subject,
        'currentLevel': currentLevel,
        'deadline': deadlineDays,
      },
      timeout: ApiConfig.aiTimeout,
    );
    final map = _asMap(data);
    final plan = map['plan'];
    return plan is Map<String, dynamic> ? plan : map;
  }

  Future<List<SavedStudyPlan>> getSavedPlans() async {
    final data = await _client.get('/ai/study-plans');
    final plans = _asMap(data)['plans'];
    return (plans is List ? plans : const [])
        .whereType<Map<String, dynamic>>()
        .map(SavedStudyPlan.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> analyzeStats() async {
    final data = await _client.get(
      '/ai/analyze-stats',
      timeout: ApiConfig.aiTimeout,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getRecommendations() async {
    final data = await _client.get(
      '/ai/recommendations',
      timeout: ApiConfig.aiTimeout,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> reviewWork({
    required String workType,
    required String workContent,
    required String subject,
    required String level,
  }) async {
    final data = await _client.post(
      '/ai/review-work',
      body: {
        'workType': workType,
        'workContent': workContent,
        'subject': subject,
        'level': level,
      },
      timeout: ApiConfig.aiTimeout,
    );
    final map = _asMap(data);
    final review = map['review'];
    return review is Map<String, dynamic> ? review : map;
  }

  Future<Map<String, dynamic>> generateMotivationalQuote({
    required String goal,
    required String subject,
  }) async {
    final data = await _client.post(
      '/ai/motivational-quote',
      body: {'goal': goal, 'subject': subject},
      timeout: ApiConfig.aiTimeout,
    );
    return _asMap(data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const ApiException('AI вернул неожиданный ответ');
  }
}
