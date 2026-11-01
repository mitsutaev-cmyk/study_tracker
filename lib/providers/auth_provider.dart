import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SharedPreferences _prefs;
  final ApiClient _apiClient;

  static const _tokenKey = 'token';

  User? _user;
  String? _token;
  String? _errorMessage;
  bool _isInitializing = true;
  bool _isSubmitting = false;

  AuthProvider(this._authService, this._prefs, this._apiClient) {
    _apiClient.onUnauthorized = _handleUnauthorized;
    _initialize();
  }

  void _handleUnauthorized() {
    if (_token == null) return;
    _clearSession().then((_) => notifyListeners());
  }

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isInitializing || _isSubmitting;
  bool get isInitializing => _isInitializing;
  bool get isSubmitting => _isSubmitting;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  int get coins => _user?.coins ?? 0;
  String get displayName {
    final name = _user?.name.trim() ?? '';
    return name.isEmpty ? 'Студент' : name;
  }

  /// Called when the session is dropped (logout or expired token).
  VoidCallback? onSignedOut;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _initialize() async {
    _token = _prefs.getString(_tokenKey);
    if (_token == null || _token!.isEmpty) {
      _token = null;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _apiClient.token = _token;
    try {
      _user = await _authService.me();
    } on ApiException catch (error) {
      // Expired/invalid token -> sign out. Network problems are not a reason to
      // drop a valid session, so the app still opens in that case.
      if (error.isUnauthorized) {
        await _clearSession();
      }
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) =>
      _authenticate(() => _authService.login(email, password));

  Future<bool> register(String email, String password, String name) =>
      _authenticate(() => _authService.register(email, password, name));

  Future<bool> _authenticate(Future<AuthResult> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      _token = result.token;
      _user = result.user;
      _apiClient.token = result.token;
      await _prefs.setString(_tokenKey, result.token);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _errorMessage = 'Не удалось выполнить запрос: $error';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_token == null) return;
    try {
      _user = await _authService.me();
      notifyListeners();
    } on ApiException {
      // Keep the cached profile; the next successful request will refresh it.
    }
  }

  /// Called after a session changes the coin balance.
  void setCoins(int coins) {
    if (_user == null || _user!.coins == coins) return;
    _user = _user!.copyWith(coins: coins);
    notifyListeners();
  }

  /// Saves profile customisation and updates the cached user.
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatar,
    int? dailyGoalMinutes,
    String? accentColor,
    String? themeMode,
  }) async {
    final updated = await _authService.updateProfile(
      name: name,
      bio: bio,
      avatar: avatar,
      dailyGoalMinutes: dailyGoalMinutes,
      accentColor: accentColor,
      themeMode: themeMode,
    );
    _user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    _apiClient.token = null;
    await _prefs.remove(_tokenKey);
    await _prefs.remove('userId');
    onSignedOut?.call();
  }
}
