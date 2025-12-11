import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveLayout', () {
    testWidgets('shows mobile widget when width < 600', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('shows tablet widget when 600 <= width < 1200', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('shows desktop widget when width >= 1200', (tester) async {
      tester.view.physicalSize = const Size(1300, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('falls back to mobile if tablet/desktop not provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1300, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: ResponsiveLayout(mobile: Text('Mobile'))),
      );

      expect(find.text('Mobile'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
