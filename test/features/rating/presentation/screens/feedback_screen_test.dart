import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/rating/data/repositories/feedback_repository.dart';
import 'package:emerge_app/features/rating/presentation/screens/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements FeedbackRepository {}

/// Pushes the feedback screen onto a `/home` root so `context.pop()` on
/// submit has a route to return to — mirroring production, where the route
/// is pushed from the shell.
GoRouter _buildRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
        GoRoute(
          path: '/feedback',
          builder: (_, __) => const FeedbackScreen(userId: 'u1', rating: 2),
        ),
      ],
    );

void main() {
  testWidgets('submits feedback and pops', (tester) async {
    final repo = _MockRepo();
    when(() => repo.submitFeedback(
          userId: any(named: 'userId'),
          rating: any(named: 'rating'),
          message: any(named: 'message'),
        )).thenAnswer((_) async => const Right<Failure, void>(null));

    final router = _buildRouter();
    await tester.pumpWidget(ProviderScope(
      overrides: [feedbackRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/feedback');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Too hard to track');
    // enterText fires onChanged (scheduling a rebuild) but doesn't pump a
    // frame, so the Submit button is still disabled on tap without this.
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    verify(() => repo.submitFeedback(
          userId: 'u1', rating: 2, message: 'Too hard to track',
        )).called(1);
    expect(find.byType(FeedbackScreen), findsNothing);
  });

  testWidgets('shows the error and re-enables submit on failure', (tester) async {
    final repo = _MockRepo();
    when(() => repo.submitFeedback(
          userId: any(named: 'userId'),
          rating: any(named: 'rating'),
          message: any(named: 'message'),
        )).thenAnswer((_) async => Left<Failure, void>(ServerFailure('offline')));

    final router = _buildRouter();
    await tester.pumpWidget(ProviderScope(
      overrides: [feedbackRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/feedback');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'broken');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('offline'), findsOneWidget);
    // Button re-enabled after the failure.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });
}
