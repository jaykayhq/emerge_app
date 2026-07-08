import 'package:emerge_app/features/onboarding/domain/entities/onboarding_milestone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingMilestone', () {
    const fullMilestone = OnboardingMilestone(
      order: 1,
      title: 'Choose Archetype',
      description: 'Pick your path',
      routePath: '/onboarding/archetype',
      icon: Icons.star,
      isCompleted: true,
      canSkip: false,
      backgroundImageUrl: 'https://example.com/bg.png',
    );

    test('constructor with all fields sets correctly', () {
      expect(fullMilestone.order, 1);
      expect(fullMilestone.title, 'Choose Archetype');
      expect(fullMilestone.description, 'Pick your path');
      expect(fullMilestone.routePath, '/onboarding/archetype');
      expect(fullMilestone.icon, Icons.star);
      expect(fullMilestone.isCompleted, isTrue);
      expect(fullMilestone.canSkip, isFalse);
      expect(fullMilestone.backgroundImageUrl, 'https://example.com/bg.png');
    });

    test('defaults: isCompleted=false, canSkip=true', () {
      const defaultMilestone = OnboardingMilestone(
        order: 2,
        title: 'Select Anchors',
        description: 'Pick your anchors',
        routePath: '/onboarding/anchors',
        icon: Icons.anchor,
      );

      expect(defaultMilestone.isCompleted, isFalse);
      expect(defaultMilestone.canSkip, isTrue);
      expect(defaultMilestone.backgroundImageUrl, isNull);
    });

    test('copyWith overrides each field', () {
      final copied = fullMilestone.copyWith(
        order: 2,
        title: 'Build Stacks',
        description: 'Build your stacks',
        routePath: '/onboarding/stacks',
        icon: Icons.build,
        isCompleted: false,
        canSkip: true,
        backgroundImageUrl: 'https://example.com/new-bg.png',
      );

      expect(copied.order, 2);
      expect(copied.title, 'Build Stacks');
      expect(copied.description, 'Build your stacks');
      expect(copied.routePath, '/onboarding/stacks');
      expect(copied.icon, Icons.build);
      expect(copied.isCompleted, isFalse);
      expect(copied.canSkip, isTrue);
      expect(copied.backgroundImageUrl, 'https://example.com/new-bg.png');
    });

    test('copyWith without args returns same values', () {
      final copied = fullMilestone.copyWith();

      expect(copied.order, fullMilestone.order);
      expect(copied.title, fullMilestone.title);
      expect(copied.description, fullMilestone.description);
      expect(copied.routePath, fullMilestone.routePath);
      expect(copied.icon, fullMilestone.icon);
      expect(copied.isCompleted, fullMilestone.isCompleted);
      expect(copied.canSkip, fullMilestone.canSkip);
      expect(copied.backgroundImageUrl, fullMilestone.backgroundImageUrl);
    });

    test('Equatable equality', () {
      final a = OnboardingMilestone(
        order: 1,
        title: 'Test',
        description: 'Desc',
        routePath: '/test',
        icon: Icons.ac_unit,
        isCompleted: true,
        canSkip: false,
        backgroundImageUrl: 'url',
      );
      final b = OnboardingMilestone(
        order: 1,
        title: 'Test',
        description: 'Desc',
        routePath: '/test',
        icon: Icons.ac_unit,
        isCompleted: true,
        canSkip: false,
        backgroundImageUrl: 'url',
      );
      final c = OnboardingMilestone(
        order: 2,
        title: 'Test',
        description: 'Desc',
        routePath: '/test',
        icon: Icons.ac_unit,
        isCompleted: true,
        canSkip: false,
        backgroundImageUrl: 'url',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('backgroundImageUrl null vs non-null', () {
      const withBg = OnboardingMilestone(
        order: 1,
        title: 'T',
        description: 'D',
        routePath: '/t',
        icon: Icons.ac_unit,
        backgroundImageUrl: 'https://example.com/bg.png',
      );
      const withoutBg = OnboardingMilestone(
        order: 1,
        title: 'T',
        description: 'D',
        routePath: '/t',
        icon: Icons.ac_unit,
      );

      expect(withBg.backgroundImageUrl, isNotNull);
      expect(withoutBg.backgroundImageUrl, isNull);
      expect(withBg, isNot(equals(withoutBg)));
    });
  });
}
