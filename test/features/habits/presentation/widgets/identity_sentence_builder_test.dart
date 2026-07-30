import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/presentation/widgets/identity_sentence_builder.dart';

void main() {
  testWidgets('IdentitySentenceBuilder shows prefix and segments',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IdentitySentenceBuilder(
            emoji: '🔥',
            action: 'meditate',
            time: '7:00 AM',
            location: 'living room',
            frequency: 'daily',
            onEmojiTap: () {},
            onActionTap: () {},
            onTimeTap: () {},
            onLocationTap: () {},
            onFrequencyTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('I am the type of person who'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('meditate'), findsOneWidget);
    expect(find.text('at 7:00 AM'), findsOneWidget);
    expect(find.text('in living room'), findsOneWidget);
    expect(find.text('daily'), findsOneWidget);
  });
}
