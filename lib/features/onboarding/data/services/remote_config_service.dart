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
      'onboarding_archetypes': '[]',
      'onboarding_attributes': '[]',
      'onboarding_habit_suggestions': '[]',
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
