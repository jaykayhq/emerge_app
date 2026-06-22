import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/fallback_initial_avatar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('renders first letter of single word name', (tester) async {
    await tester.pumpWidget(
      wrap(const FallbackInitialAvatar(name: 'Nova')),
    );

    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('renders both initials of multi-word name uppercase',
      (tester) async {
    await tester.pumpWidget(
      wrap(const FallbackInitialAvatar(name: 'nova elite')),
    );

    expect(find.text('NE'), findsOneWidget);
  });

  testWidgets('empty name renders Icons.person_rounded', (tester) async {
    await tester.pumpWidget(
      wrap(const FallbackInitialAvatar(name: '')),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    // No initials text.
    expect(find.text(''), findsNothing);
  });

  testWidgets('null name renders Icons.person_rounded', (tester) async {
    await tester.pumpWidget(
      wrap(const FallbackInitialAvatar()),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('imageUrl layers ClipOval + Image.network on top of fallback',
      (tester) async {
    // Suppress network image error noise for this test.
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (_) {};
    addTearDown(() {
      FlutterError.onError = oldHandler;
    });

    await tester.pumpWidget(
      wrap(
        const FallbackInitialAvatar(
          name: 'Astra',
          size: 64,
          imageUrl: 'https://example.com/avatar.png',
        ),
      ),
    );

    expect(find.byType(ClipOval), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // Pump a frame so the Image.network can attempt its load.
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('borderWidth=0 produces no border decoration on fallback box',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const FallbackInitialAvatar(
          name: 'Vega',
          borderWidth: 0,
          borderColor: Colors.red,
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(FallbackInitialAvatar),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration;
    if (decoration is BoxDecoration) {
      expect(decoration.border, isNull);
    } else {
      // No BoxDecoration present on this container — also fine.
      expect(decoration, isNot(isA<BoxDecoration>()));
    }
  });

  testWidgets('borderWidth>0 produces a visible border decoration',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const FallbackInitialAvatar(
          name: 'Vega',
          borderWidth: 2,
          borderColor: Colors.red,
        ),
      ),
    );

    final containers = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(FallbackInitialAvatar),
        matching: find.byType(Container),
      ),
    );
    final hasBorder = containers.any((c) {
      final deco = c.decoration;
      return deco is BoxDecoration && deco.border != null;
    });
    expect(hasBorder, isTrue);
  });
}
