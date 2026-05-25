import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';
import 'package:emerge_app/features/companion/domain/services/persona_engine.dart';

void main() {
  group('PersonaEngine', () {
    test('returns The Coach for athlete archetype', () {
      final config = PersonaEngine.getPersona('athlete');
      expect(config.name, 'The Coach');
      expect(config.accentColor, const Color(0xFFFF6B35));
    });

    test('returns The Sage for scholar archetype', () {
      final config = PersonaEngine.getPersona('scholar');
      expect(config.name, 'The Sage');
    });

    test('returns The Muse for creator archetype', () {
      final config = PersonaEngine.getPersona('creator');
      expect(config.name, 'The Muse');
    });

    test('returns The Philosopher for stoic archetype', () {
      final config = PersonaEngine.getPersona('stoic');
      expect(config.name, 'The Philosopher');
    });

    test('returns The Visionary for zealot archetype', () {
      final config = PersonaEngine.getPersona('zealot');
      expect(config.name, 'The Visionary');
    });

    test('defaults to The Sage for unknown archetype', () {
      final config = PersonaEngine.getPersona('unknown');
      expect(config.name, 'The Sage');
    });

    test('all personas have unique names', () {
      final names = ['athlete', 'scholar', 'creator', 'stoic', 'zealot']
          .map((a) => PersonaEngine.getPersona(a).name)
          .toSet();
      expect(names.length, 5);
    });
  });
}
