import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/creator_profile_screen.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';

void main() {
  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        allBlueprintsStreamProvider.overrideWith((ref) => Stream.value([])),
        creatorProfileProvider('creator123').overrideWith((ref) => Stream.value(
          const CreatorProfile(
            userId: 'creator123',
            displayName: 'Test Creator',
            bio: 'Test Bio',
            specialityTags: ['Fitness'],
            isVerifiedCreator: true,
          )
        )),
      ],
      child: const MaterialApp(
        home: CreatorProfileScreen(creatorId: 'creator123'),
      ),
    );
  }

  testWidgets('renders CreatorProfileScreen and finds Share button', (WidgetTester tester) async {
    // Suppress network image load errors in test environment.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('NetworkImageLoadException') ||
          details.exception.toString().contains('HTTP request failed')) {
        return;
      }
      originalOnError?.call(details);
    };

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Test Bio'), findsOneWidget);
    expect(find.text('Vanguard Elite'), findsOneWidget);
    expect(find.text('Share Creator Profile'), findsOneWidget);
    expect(find.text('JOIN VANGUARD'), findsOneWidget);

    FlutterError.onError = originalOnError;
  });
}
