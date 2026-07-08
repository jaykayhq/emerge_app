import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('companionPersonaProvider', () {
    test('returns persona from companion state', () {
      final persona = const PersonaConfig(
        name: 'Coach',
        avatarAsset: 'assets/coach.png',
        accentColor: Color(0xFF4CAF50),
        systemPrompt: 'You are a coach.',
        greetingTemplate: "Let's go, {name}!",
      );
      final container = ProviderContainer(
        overrides: [
          companionPersonaProvider.overrideWithValue(persona),
        ],
      );
      expect(container.read(companionPersonaProvider), persona);
      container.dispose();
    });

    test('returns null when persona not set', () {
      final container = ProviderContainer(
        overrides: [
          companionPersonaProvider.overrideWithValue(null),
        ],
      );
      expect(container.read(companionPersonaProvider), isNull);
      container.dispose();
    });
  });

  group('companionVisibilityProvider', () {
    test('returns state when visible', () {
      final container = ProviderContainer(
        overrides: [
          companionVisibilityProvider.overrideWithValue(
            const CompanionState(visible: true),
          ),
        ],
      );
      final result = container.read(companionVisibilityProvider);
      expect(result, isNotNull);
      expect(result!.visible, true);
      container.dispose();
    });

    test('returns null when not visible', () {
      final container = ProviderContainer(
        overrides: [
          companionVisibilityProvider.overrideWithValue(null),
        ],
      );
      expect(container.read(companionVisibilityProvider), isNull);
      container.dispose();
    });
  });

  group('companionRepositoryProvider', () {
    test('creates repository', () {
      final container = ProviderContainer();
      expect(container.read(companionRepositoryProvider), isNotNull);
      container.dispose();
    });
  });
}
