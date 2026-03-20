import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';

/// Service that manages daily/weekly challenge refresh
/// Automatically invalidates the challenge bundle provider when the date changes
class ChallengeRefreshService {
  Timer? _refreshTimer;
  LocalSettingsRepository? _settingsRepository;

  /// Get the settings repository (lazy loaded from provider or created if needed)
  LocalSettingsRepository _getRepository(Ref ref) {
    _settingsRepository ??= ref.read(localSettingsRepositoryProvider);
    return _settingsRepository!;
  }

  /// Start the automatic refresh timer
  /// Checks every hour if the date has changed and refreshes challenges if needed
  void startAutoRefresh(Ref ref) {
    // Stop any existing timer
    stopAutoRefresh();

    // Check immediately on start
    _checkAndRefresh(ref);

    // Set up timer to check every hour
    _refreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkAndRefresh(ref);
    });
  }

  /// Stop the automatic refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Check if date has changed and refresh challenges if needed
  void _checkAndRefresh(Ref ref) {
    final now = DateTime.now();
    final currentDate = '${now.year}-${now.month}-${now.day}';
    final repo = _getRepository(ref);

    // Get the last refresh date from local storage
    final lastRefreshDate = repo.getLastChallengeRefreshDate();

    if (lastRefreshDate != currentDate) {
      // Date has changed, refresh challenges
      ref.invalidate(challengeBundleProvider);
      ref.invalidate(weeklySpotlightFromBundleProvider);
      ref.invalidate(dailyQuestFromBundleProvider);

      // Save the current date as last refresh date
      repo.saveLastChallengeRefreshDate(currentDate);
    }
  }

  /// Manually trigger a challenge refresh
  /// Useful for testing or when user explicitly requests refresh
  void manualRefresh(Ref ref) {
    final now = DateTime.now();
    final currentDate = '${now.year}-${now.month}-${now.day}';
    final repo = _getRepository(ref);

    ref.invalidate(challengeBundleProvider);
    ref.invalidate(weeklySpotlightFromBundleProvider);
    ref.invalidate(dailyQuestFromBundleProvider);

    repo.saveLastChallengeRefreshDate(currentDate);
  }
}

/// Provider for the challenge refresh service
/// Automatically starts the refresh timer when first accessed
final challengeRefreshServiceProvider = Provider<ChallengeRefreshService>((ref) {
  final service = ChallengeRefreshService();
  // Auto-start the refresh service when provider is first read
  service.startAutoRefresh(ref);

  ref.onDispose(() {
    service.stopAutoRefresh();
  });
  return service;
});

/// Provider that tracks whether challenge refresh is active
final challengeRefreshActiveProvider = Provider<bool>((ref) {
  // Service is active when the provider is being read
  ref.watch(challengeRefreshServiceProvider);
  return true;
});
