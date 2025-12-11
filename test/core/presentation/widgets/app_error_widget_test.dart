import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppErrorWidget displays message and retry button', (
    tester,
  ) async {
    bool retryPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorWidget(
            message: 'Something went wrong',
            onRetry: () => retryPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    expect(retryPressed, isTrue);
  });

  testWidgets('AppErrorWidget hides retry button when onRetry is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppErrorWidget(message: 'Error without retry')),
      ),
    );

    expect(find.text('Error without retry'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
  });
}
