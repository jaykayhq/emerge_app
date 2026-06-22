import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/app_back_handler.dart';

void main() {
  testWidgets('AppBackToHome wraps child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppBackToHome(
          child: Scaffold(body: Text('content')),
        ),
      ),
    );

    expect(find.byType(AppBackToHome), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('AppBackToHome accepts a custom homeRoute', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppBackToHome(
          homeRoute: '/custom',
          child: Scaffold(body: Text('content')),
        ),
      ),
    );

    expect(find.byType(AppBackToHome), findsOneWidget);
  });

  testWidgets('AppDoubleTapExit wraps child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppDoubleTapExit(
          child: Scaffold(
            appBar: AppBar(title: const Text('root')),
            body: const Center(child: Text('content')),
          ),
        ),
      ),
    );

    expect(find.byType(AppDoubleTapExit), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('AppDoubleTapExit renders with default message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppDoubleTapExit(
          child: Scaffold(body: const Text('content')),
        ),
      ),
    );

    expect(find.byType(AppDoubleTapExit), findsOneWidget);
  });

  testWidgets('AppDoubleTapExit accepts a custom message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppDoubleTapExit(
          snackBarMessage: 'Press back to exit',
          child: Scaffold(body: const Text('content')),
        ),
      ),
    );

    expect(find.byType(AppDoubleTapExit), findsOneWidget);
  });

  test('SystemNavigator.pop symbol is exported from flutter/services', () {
    expect(SystemNavigator.pop, isNotNull);
  });
}
