import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('avatar renders in idle state when no pending line', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingMilestoneProvider.overrideWith(() => _StubNotifier(null)),
        ],
        child: const MaterialApp(home: Scaffold(body: NarratorAvatar())),
      ),
    );
    expect(find.byType(NarratorAvatar), findsOneWidget);
  });

  testWidgets('avatar is tappable', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingMilestoneProvider.overrideWith(() => _StubNotifier(null)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NarratorAvatar(onTap: () => tapped = true),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(NarratorAvatar));
    expect(tapped, isTrue);
  });

  testWidgets('avatar shows pending dot when a milestone line is pending',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingMilestoneProvider.overrideWith(
            () => _StubNotifier(
              PendingMilestoneLine(
                line: const GenericLine('A path begins.'),
                trigger: NarratorTrigger.onboardingPostArchetype,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: NarratorAvatar())),
      ),
    );
    // The 12x12 status dot should be present when a line is pending.
    final dots = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(NarratorAvatar),
            matching: find.byType(Container),
          ),
        )
        .where((c) => c.constraints?.maxWidth == 12)
        .toList();
    expect(dots, hasLength(1));
  });
}

class _StubNotifier extends PendingMilestone {
  _StubNotifier(this._value);
  final PendingMilestoneLine? _value;
  @override
  PendingMilestoneLine? build() => _value;
}
