// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:habit_tracker/db/app_db.dart';
import 'package:habit_tracker/main.dart';

void main() {
  testWidgets('App boots to shell', (WidgetTester tester) async {
    final db = AppDb.test(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.userSettings)
        .insert(
          const UserSettingsCompanion(
            id: Value(1),
            onboardingCompleted: Value(true),
            themeId: Value('light'),
          ),
        );

    await tester.pumpWidget(MyApp(db: db));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
