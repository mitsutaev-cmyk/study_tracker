import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Error with a user-readable message.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin wrapper around `http` shared by all services:
/// JSON encoding, auth header, timeouts and error mapping in one place.
class ApiClient {
  final http.Client _http;

  /// Token of the signed-in user. Set by [AuthProvider] on login/logout so
  /// services don't have to pass it around on every call.
  String? token;

  /// Called when the backend rejects the token (401), so the app can sign out.
  void Function()? onUnauthorized;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()), timeout);

  Future<dynamic> post(
    String path, {
    Object? body,
    Duration? timeout,
  }) =>
      _send(
        () => _http.post(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(body ?? const {}),
        ),
        timeout,
      );

  Future<dynamic> delete(String path, {Duration? timeout}) =>
      _send(() => _http.delete(_uri(path), headers: _headers()), timeout);

  Future<dynamic> patch(
    String path, {
    Object? body,
    Duration? timeout,
  }) =>
      _send(
        () => _http.patch(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(body ?? const {}),
        ),
        timeout,
      );

  Future<dynamic> _send(
    Future<http.Response> Function() request,
    Duration? timeout,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout ?? ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException('Сервер не отвечает. Попробуйте позже.');
    } on http.ClientException {
      throw ApiException(
        'Нет соединения с сервером (${ApiConfig.baseUrl}). '
        'Убедитесь, что бэкенд запущен.',
      );
    } catch (_) {
      throw ApiException(
        'Нет соединения с сервером (${ApiConfig.baseUrl}). '
        'Убедитесь, что бэкенд запущен.',
      );
    }

    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        data = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }

    throw ApiException(
      _errorMessage(data, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(dynamic data, int status) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    switch (status) {
      case 401:
        return 'Требуется авторизация';
      case 404:
        return 'Не найдено';
      case 503:
        return 'Сервис временно недоступен';
      default:
        return 'Ошибка сервера ($status)';
    }
  }

  void close() => _http.close();
}
