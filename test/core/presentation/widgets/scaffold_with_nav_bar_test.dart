import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/entities/companion_message.dart';
import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
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

  testWidgets('renders CompanionOverlay when companion state is visible and mode is overlay', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cueStreamProvider.overrideWith((ref) => const Stream.empty()),
          companionVisibilityProvider.overrideWithValue(
            const CompanionState(
              visible: true,
              mode: CompanionMode.overlay,
              message: CompanionMessage(
                message: 'Hello overlay message!',
                tone: 'neutral',
              ),
              persona: PersonaConfig(
                name: 'The Sage',
                avatarAsset: 'assets/avatars/sage.png',
                accentColor: Colors.purple,
                systemPrompt: '',
                greetingTemplate: '',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: ScaffoldWithNavBar(navigationShell: mockShell),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hello overlay message!'), findsOneWidget);
    expect(find.text('The Sage'), findsOneWidget);
  });

  testWidgets('renders CompanionInlineCard when companion state is visible and mode is inlineCard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cueStreamProvider.overrideWith((ref) => const Stream.empty()),
          companionVisibilityProvider.overrideWithValue(
            const CompanionState(
              visible: true,
              mode: CompanionMode.inlineCard,
              message: CompanionMessage(
                message: 'Hello inline card message!',
                tone: 'neutral',
              ),
              persona: PersonaConfig(
                name: 'The Coach',
                avatarAsset: 'assets/avatars/coach.png',
                accentColor: Colors.orange,
                systemPrompt: '',
                greetingTemplate: '',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: ScaffoldWithNavBar(navigationShell: mockShell),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hello inline card message!'), findsOneWidget);
    expect(find.text('The Coach'), findsOneWidget);
  });
}
