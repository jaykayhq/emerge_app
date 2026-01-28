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
      // RevenueCat API Keys (fallback to empty if Remote Config unavailable)
      'revenuecat_google_api_key': '',
      'revenuecat_apple_api_key': '',
      'onboarding_archetypes': jsonEncode([
        {
          'id': 'athlete',
          'title': 'The Athlete',
          'description': 'Physical discipline, resilience, and vitality.',
          'imageUrl': 'assets/images/archetype_athlete.png',
        },
        {
          'id': 'creator',
          'title': 'The Creator',
          'description': 'Imagination, expression, and bringing ideas to life.',
          'imageUrl': 'assets/images/archetype_creator.png',
        },
        {
          'id': 'scholar',
          'title': 'The Scholar',
          'description': 'Knowledge, curiosity, and intellectual growth.',
          'imageUrl': 'assets/images/archetype_scholar.png',
        },
        {
          'id': 'stoic',
          'title': 'The Stoic',
          'description': 'Mindfulness, emotional control, and inner peace.',
          'imageUrl': 'assets/images/archetype_stoic.png',
        },
        {
          'id': 'mystic',
          'title': 'The Mystic',
          'description':
              'Spiritual connection, transcendence, and inner wisdom.',
          'imageUrl': 'assets/images/archetype_mystic.png',
        },
      ]),
      'onboarding_attributes': jsonEncode([
        {
          'id': 'vitality',
          'title': 'Vitality',
          'description': 'For a life of energy and boundless health.',
          'icon': 'favorite',
          'color': '0xFFF44336', // Red-500
        },
        {
          'id': 'focus',
          'title': 'Focus',
          'description': 'For a mind that is clear, present, and sharp.',
          'icon': 'psychology',
          'color': '0xFF00BCD4', // Cyan-500
        },
        {
          'id': 'creativity',
          'title': 'Creativity',
          'description': 'For a spark of imagination and endless ideas.',
          'icon': 'brush',
          'color': '0xFF9C27B0', // Purple-500
        },
        {
          'id': 'strength',
          'title': 'Strength',
          'description': 'For a body that is resilient and powerful.',
          'icon': 'fitness_center',
          'color': '0xFFFFC107', // Amber-500
        },
        {
          'id': 'spirit',
          'title': 'Spirit',
          'description': 'For a soul aligned with purpose and higher meaning.',
          'icon': 'self_improvement',
          'color': '0xFF673AB7', // Deep Purple-500
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

    // Fetch remote config values
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config fetched successfully');
    } catch (e) {
      // Handle fetch error or use defaults
      debugPrint('⚠️ Remote Config fetch failed: $e (using defaults)');
    }
  }

  /// Get RevenueCat API key from Remote Config
  String getRevenueCatApiKey(String platform) {
    final key = _remoteConfig.getString(
      platform == 'android' ? 'revenuecat_google_api_key' : 'revenuecat_apple_api_key',
    );
    return key;
  }

  /// Check if RevenueCat keys are configured in Remote Config
  bool isRevenueCatConfigured(String platform) {
    final key = getRevenueCatApiKey(platform);
    return key.isNotEmpty && key != 'YOUR_REVENUECAT_API_KEY';
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
