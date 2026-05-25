import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';

void main() {
  test('PersonaConfig can be constructed', () {
    final config = PersonaConfig(
      name: 'The Coach',
      avatarAsset: 'assets/avatars/coach.riv',
      accentColor: const Color(0xFFFF6B35),
      systemPrompt: 'You are a no-nonsense coach...',
      greetingTemplate: 'Ready for today\'s reps?',
    );
    expect(config.name, 'The Coach');
    expect(config.avatarAsset, 'assets/avatars/coach.riv');
  });
}
