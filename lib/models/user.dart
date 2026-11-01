class User {
  final int id;
  final String email;
  final String name;
  final int coins;
  final String avatar;
  final String bio;
  final int dailyGoalMinutes;
  final String accentColor;
  final String themeMode;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.coins,
    this.avatar = '🎓',
    this.bio = '',
    this.dailyGoalMinutes = 60,
    this.accentColor = '#4F46E5',
    this.themeMode = 'system',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] ?? '').toString();
    final rawName = (json['name'] ?? '').toString().trim();
    return User(
      id: _toInt(json['id']),
      email: email,
      name: rawName.isNotEmpty ? rawName : _nameFromEmail(email),
      coins: _toInt(json['coins']),
      avatar: (json['avatar'] ?? '🎓').toString(),
      bio: (json['bio'] ?? '').toString(),
      dailyGoalMinutes: _toInt(json['daily_goal_minutes']),
      accentColor: (json['accent_color'] ?? '#4F46E5').toString(),
      themeMode: (json['theme_mode'] ?? 'system').toString(),
    );
  }

  User copyWith({
    String? name,
    int? coins,
    String? avatar,
    String? bio,
    int? dailyGoalMinutes,
    String? accentColor,
    String? themeMode,
  }) =>
      User(
        id: id,
        email: email,
        name: name ?? this.name,
        coins: coins ?? this.coins,
        avatar: avatar ?? this.avatar,
        bio: bio ?? this.bio,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        accentColor: accentColor ?? this.accentColor,
        themeMode: themeMode ?? this.themeMode,
      );

  static String _nameFromEmail(String email) {
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }
}

class AuthResult {
  final User user;
  final String token;

  const AuthResult({required this.user, required this.token});
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
