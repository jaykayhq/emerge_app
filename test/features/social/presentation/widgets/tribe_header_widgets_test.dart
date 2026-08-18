import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_header_widgets.dart';

const _contributors = [
  {
    'userId': 'u1',
    'id': 'u1',
    'userName': 'U1',
    'xp': 120,
    'contributionCount': 120,
    'level': 3,
  },
  {
    'userId': 'u2',
    'id': 'u2',
    'userName': 'U2',
    'xp': 80,
    'contributionCount': 80,
    'level': 2,
  },
];

Future<void> _pumpContributors(
  WidgetTester tester, {
  required List<String> members,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clubContributorsProvider(
          'tribeA',
        ).overrideWith((ref) => Stream.value(_contributors)),
        userOnlineStatusProvider(
          'u1',
        ).overrideWith((ref) => Stream.value(false)),
        userOnlineStatusProvider(
          'u2',
        ).overrideWith((ref) => Stream.value(false)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ContributorsSection(clubId: 'tribeA', members: members),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('ContributorsSection hides users not in the members array', (
    tester,
  ) async {
    await _pumpContributors(tester, members: const ['u1']);

    // ContributorAvatar renders the initial + rank badge, not the full
    // name, so assert on avatar count and ranks instead of find.text.
    expect(find.byType(ContributorAvatar), findsOneWidget);
    expect(find.text('Top 1'), findsOneWidget);
  });

  testWidgets('ContributorsSection shows everyone when members is empty '
      '(creator tribes)', (tester) async {
    await _pumpContributors(tester, members: const []);

    expect(find.byType(ContributorAvatar), findsNWidgets(2));
    expect(find.text('Top 1'), findsOneWidget);
    expect(find.text('Top 2'), findsOneWidget);
  });
}
