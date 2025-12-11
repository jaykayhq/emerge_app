import 'dart:convert';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await _remoteConfig.setDefaults({
      'goldilocks_threshold_easy': 0.9,
      'goldilocks_threshold_hard': 0.4,
      'affirmations_json': jsonEncode({
        'athlete': [
          'Pain is weakness leaving the body.',
          'Your body is your temple. Build it strong.',
          'Consistency is the only magic pill.',
        ],
        'creator': [
          'Create before you consume.',
          'Your work matters. Keep showing up.',
          'Inspiration exists, but it has to find you working.',
        ],
        'scholar': [
          'Knowledge compounds like interest.',
          'A day without learning is a day wasted.',
          'Feed your mind with the same discipline you feed your body.',
        ],
        'stoic': [
          'You have power over your mind - not outside events.',
          'The obstacle is the way.',
          'Discipline is freedom.',
        ],
      }),
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Handle fetch error or just rely on defaults
      AppLogger.e('Remote Config fetch failed: $e');
    }
  }

  double get easyThreshold =>
      _remoteConfig.getDouble('goldilocks_threshold_easy');
  double get hardThreshold =>
      _remoteConfig.getDouble('goldilocks_threshold_hard');

  List<String> getAffirmations(String archetype) {
    final jsonString = _remoteConfig.getString('affirmations_json');
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final List<dynamic>? list = map[archetype.toLowerCase()];
      return list?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});
