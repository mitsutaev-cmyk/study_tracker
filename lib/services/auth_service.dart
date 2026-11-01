import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<AuthResult> login(String email, String password) async {
    final data = await _client.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return _parseAuth(data);
  }

  Future<AuthResult> register(String email, String password, String name) async {
    final data = await _client.post(
      '/auth/register',
      body: {
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
      },
    );
    return _parseAuth(data);
  }

  Future<User> me() async {
    final data = await _client.get('/auth/me');
    if (data is! Map || data['user'] is! Map<String, dynamic>) {
      throw const ApiException('Некорректный ответ сервера');
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } on ApiException {
      // The token is stateless; local sign-out must work even without network.
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _client.post(
      '/auth/change-password',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  /// Updates only the fields that are passed in.
  Future<User> updateProfile({
    String? name,
    String? bio,
    String? avatar,
    int? dailyGoalMinutes,
    String? accentColor,
    String? themeMode,
  }) async {
    final data = await _client.patch(
      '/auth/profile',
      body: {
        if (name != null) 'name': name.trim(),
        if (bio != null) 'bio': bio.trim(),
        'avatar': ?avatar,
        'daily_goal_minutes': ?dailyGoalMinutes,
        'accent_color': ?accentColor,
        'theme_mode': ?themeMode,
      },
    );
    if (data is! Map || data['user'] is! Map<String, dynamic>) {
      throw const ApiException('Некорректный ответ сервера');
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  AuthResult _parseAuth(dynamic data) {
    if (data is! Map ||
        data['token'] is! String ||
        data['user'] is! Map<String, dynamic>) {
      throw const ApiException('Некорректный ответ сервера');
    }
    return AuthResult(
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }
}
