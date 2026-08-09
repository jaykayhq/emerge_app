import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/rating/data/repositories/feedback_repository.dart';
import 'package:emerge_app/features/rating/presentation/screens/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class _MockRepo extends Mock implements FeedbackRepository {}

void main() {
  testWidgets('submits feedback and pops', (tester) async {
    final repo = _MockRepo();
    when(() => repo.submitFeedback(
          userId: any(named: 'userId'),
          rating: any(named: 'rating'),
          message: any(named: 'message'),
        )).thenAnswer((_) async => const Right<Failure, void>(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [feedbackRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: FeedbackScreen(userId: 'u1', rating: 2)),
    ));
    await tester.enterText(find.byType(TextField), 'Too hard to track');
    // enterText fires onChanged (scheduling a rebuild) but doesn't pump a
    // frame, so the Submit button is still disabled on tap without this.
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    verify(() => repo.submitFeedback(
          userId: 'u1', rating: 2, message: 'Too hard to track',
        )).called(1);
  });
}
