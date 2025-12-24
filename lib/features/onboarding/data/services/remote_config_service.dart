import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_service.g.dart';

@Riverpod(keepAlive: true)
RemoteConfigService remoteConfigService(Ref ref) {
  return RemoteConfigService();
}

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await _remoteConfig.setDefaults({
      'onboarding_archetypes': jsonEncode([
        {
          'id': 'athlete',
          'title': 'The Warrior',
          'description': 'Forged in fire, you seek strength and resilience.',
          'imageUrl': 'assets/images/archetype_athlete.png',
        },
        {
          'id': 'scholar',
          'title': 'The Sage',
          'description': 'You seek wisdom, clarity, and focus.',
          'imageUrl': 'assets/images/archetype_scholar.png',
        },
        {
          'id': 'creator',
          'title': 'The Creator',
          'description': 'You bring new ideas and beauty into the world.',
          'imageUrl': 'assets/images/archetype_creator.png',
        },
      ]),
      'onboarding_attributes': jsonEncode([
        {
          'id': 'vitality',
          'title': 'Vitality',
          'description': 'Energy and Health',
          'icon': 'heart',
          'color': '0xFF4CAF50',
        },
        {
          'id': 'focus',
          'title': 'Focus',
          'description': 'Clarity and Concentration',
          'icon': 'brain',
          'color': '0xFF2196F3',
        },
        {
          'id': 'strength',
          'title': 'Strength',
          'description': 'Power and Resilience',
          'icon': 'gym',
          'color': '0xFFF44336',
        },
      ]),
      'onboarding_habit_suggestions': jsonEncode([
        {'id': 'wake_up', 'title': 'Wake Up', 'icon': 'wb_sunny'},
        {'id': 'brush_teeth', 'title': 'Brush Teeth', 'icon': 'oral_disease'},
        {'id': 'coffee', 'title': 'Drink Coffee', 'icon': 'coffee'},
        {'id': 'shower', 'title': 'Shower', 'icon': 'shower'},
        {'id': 'commute', 'title': 'Commute', 'icon': 'train'},
        {'id': 'work_start', 'title': 'Start Work', 'icon': 'work'},
        {'id': 'lunch', 'title': 'Eat Lunch', 'icon': 'restaurant'},
        {'id': 'work_end', 'title': 'End Work', 'icon': 'home'},
        {'id': 'dinner', 'title': 'Eat Dinner', 'icon': 'dining'},
        {'id': 'sleep', 'title': 'Go to Sleep', 'icon': 'bed'},
      ]),
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Handle fetch error or use defaults
      debugPrint('Remote Config fetch failed: $e');
    }
  }

  OnboardingConfig getOnboardingConfig() {
    final archetypesJson = _remoteConfig.getString('onboarding_archetypes');
    final attributesJson = _remoteConfig.getString('onboarding_attributes');
    final habitsJson = _remoteConfig.getString('onboarding_habit_suggestions');

    List<ArchetypeConfig> archetypes = [];
    try {
      archetypes = (jsonDecode(archetypesJson) as List)
          .map((e) => ArchetypeConfig.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error parsing archetypes: $e');
    }

    List<AttributeConfig> attributes = [];
    try {
      attributes = (jsonDecode(attributesJson) as List)
          .map((e) => AttributeConfig.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error parsing attributes: $e');
    }

    List<HabitSuggestion> habits = [];
    try {
      habits = (jsonDecode(habitsJson) as List)
          .map((e) => HabitSuggestion.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error parsing habits: $e');
    }

    return OnboardingConfig(
      archetypes: archetypes,
      attributes: attributes,
      habitSuggestions: habits,
    );
  }
}
