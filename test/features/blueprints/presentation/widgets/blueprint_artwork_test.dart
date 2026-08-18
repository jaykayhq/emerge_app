import 'package:emerge_app/features/blueprints/presentation/widgets/blueprint_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SizedBox(width: 200, height: 200, child: child)),
    );
  }

  group('BlueprintArtwork', () {
    testWidgets('renders branded fallback icon when imageUrl is null', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const BlueprintArtwork(imageUrl: null)));

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders bundled asset image when imageUrl is an assets path', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const BlueprintArtwork(
            imageUrl: 'assets/images/blueprints/morning_1.png',
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/blueprints/morning_1.png');
    });

    testWidgets('renders network image when imageUrl is an https URL', (
      tester,
    ) async {
      const url = 'https://images.unsplash.com/photo-x';
      await tester.pumpWidget(wrap(const BlueprintArtwork(imageUrl: url)));

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.url, url);
    });

    testWidgets('falls back to branded icon when network image fails to load', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const BlueprintArtwork(
            imageUrl: 'https://images.unsplash.com/photo-x',
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });
  });
}
