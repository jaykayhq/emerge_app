import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
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
}

class _StubNotifier extends PendingMilestone {
  _StubNotifier(this._value);
  final NarratorLine? _value;
  @override
  NarratorLine? build() => _value;
}
