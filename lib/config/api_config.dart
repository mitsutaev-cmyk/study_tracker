import 'package:flutter/foundation.dart';

/// Backend address.
///
/// Override at build/run time:
///   flutter run --dart-define=API_URL=http://192.168.1.10:5000/api
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // On the Android emulator `localhost` is the emulator itself;
    // 10.0.2.2 points to the host machine.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static const Duration timeout = Duration(seconds: 15);

  /// AI requests can take much longer than regular ones.
  static const Duration aiTimeout = Duration(seconds: 90);
}
