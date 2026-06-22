import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonaConfig', () {
    test('constructor sets all fields including Color accentColor', () {
      const config = PersonaConfig(
        name: 'Mentor',
        avatarAsset: 'assets/mentor.png',
        accentColor: Color(0xFF4CAF50),
        systemPrompt: 'You are a helpful mentor.',
        greetingTemplate: 'Hello, {name}!',
      );

      expect(config.name, 'Mentor');
      expect(config.avatarAsset, 'assets/mentor.png');
      expect(config.accentColor, const Color(0xFF4CAF50));
      expect(config.systemPrompt, 'You are a helpful mentor.');
      expect(config.greetingTemplate, 'Hello, {name}!');
    });
  });
}
