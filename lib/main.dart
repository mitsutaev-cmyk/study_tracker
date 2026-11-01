import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/motivation_provider.dart';
import 'providers/study_provider.dart';
import 'services/ai_service.dart';
import 'services/api_client.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(AppProviders(prefs: prefs, child: const StudyTrackerApp()));
}

/// Wires services and providers. Kept as a widget so widget tests can build the
/// app with mocked [SharedPreferences] without touching the network.
class AppProviders extends StatefulWidget {
  final SharedPreferences prefs;
  final Widget child;

  const AppProviders({
    super.key,
    required this.prefs,
    required this.child,
  });

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final ApiService _apiService;
  late final AIService _aiService;
  late final AuthProvider _authProvider;
  late final StudyProvider _studyProvider;
  late final CalendarProvider _calendarProvider;
  late final MotivationProvider _motivationProvider;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authService = AuthService(_apiClient);
    _apiService = ApiService(_apiClient);
    _aiService = AIService(_apiClient);
    _authProvider = AuthProvider(_authService, widget.prefs, _apiClient);
    _studyProvider = StudyProvider(_apiService);
    _calendarProvider = CalendarProvider(_apiService);
    _motivationProvider = MotivationProvider(_apiService);
    _authProvider.onSignedOut = () {
      _studyProvider.reset();
      _calendarProvider.reset();
      _motivationProvider.reset();
    };
  }

  @override
  void dispose() {
    _studyProvider.dispose();
    _calendarProvider.dispose();
    _motivationProvider.dispose();
    _authProvider.dispose();
    _apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        Provider<AuthService>.value(value: _authService),
        Provider<ApiService>.value(value: _apiService),
        Provider<AIService>.value(value: _aiService),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<StudyProvider>.value(value: _studyProvider),
        ChangeNotifierProvider<CalendarProvider>.value(value: _calendarProvider),
        ChangeNotifierProvider<MotivationProvider>.value(
          value: _motivationProvider,
        ),
      ],
      child: widget.child,
    );
  }
}
