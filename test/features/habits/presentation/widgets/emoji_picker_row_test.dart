import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/presentation/widgets/emoji_picker_row.dart';

void main() {
  testWidgets('EmojiPickerRow shows recent emojis and the + chip',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmojiPickerRow(
            selectedEmoji: '🔥',
            onEmojiSelected: (_) {},
            recentlyUsed: ['🔥', '💧', '🌿'],
          ),
        ),
      ),
    );

    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('💧'), findsOneWidget);
    expect(find.text('🌿'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
  });
}
