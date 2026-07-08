import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/habits/presentation/providers/cue_providers.dart';

class MockStatefulNavigationShell extends Mock implements StatefulNavigationShell {
  @override
  StatefulElement createElement() => StatefulElement(this);

  @override
  State createState() => _MockStatefulNavigationShellState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class _MockStatefulNavigationShellState extends State<MockStatefulNavigationShell> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void main() {
  late MockStatefulNavigationShell mockShell;

  setUp(() {
    mockShell = MockStatefulNavigationShell();
    when(() => mockShell.currentIndex).thenReturn(0);
    registerFallbackValue(0);
  });

  testWidgets('renders child via navigationShell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cueStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp(
          home: ScaffoldWithNavBar(navigationShell: mockShell),
        ),
      ),
    );
    await tester.pump();

    // ScaffoldWithNavBar should render without errors
    expect(find.byType(Scaffold), findsWidgets);
  });
}
