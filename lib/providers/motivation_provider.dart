import 'package:flutter/foundation.dart';

import '../models/motivation.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';

class MotivationProvider extends ChangeNotifier {
  final ApiService _api;

  MotivationProvider(this._api);

  Motivation _data = Motivation.empty;
  bool _loading = false;
  String? _error;

  Motivation get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _api.getMotivation();
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void reset() {
    _data = Motivation.empty;
    _error = null;
    notifyListeners();
  }
}
