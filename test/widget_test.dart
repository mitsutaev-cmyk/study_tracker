import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/app.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('signed-out user sees the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      AppProviders(prefs: prefs, child: const StudyTrackerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Study Tracker'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
  });

  testWidgets('login form validates empty fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      AppProviders(prefs: prefs, child: const StudyTrackerApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();

    expect(find.text('Введите email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });

  testWidgets('login screen opens the registration form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      AppProviders(prefs: prefs, child: const StudyTrackerApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
    await tester.pumpAndSettle();

    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Создайте аккаунт'), findsOneWidget);
  });
}

