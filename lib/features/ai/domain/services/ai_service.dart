import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiService {
  // In a real app, these would call Cloud Functions which then call Vertex AI

  Future<String> getIdentityAffirmation(String context) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return "You are showing the discipline of a true Athlete. Every step counts.";
  }

  Future<String> getPatternRecognition(List<dynamic> history) async {
    await Future.delayed(const Duration(milliseconds: 2000));
    return "I've noticed you tend to skip your evening reading when you have a high-stress day. Consider moving it to the morning.";
  }

  Future<String> getGoldilocksAdjustment(int streak, double difficulty) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (streak > 5) {
      return "You're crushing it! It might be time to increase the challenge. Try adding 5 minutes to your routine.";
    } else {
      return "Consistency is key. Let's make it slightly easier to keep the streak alive. Try reducing the duration by 5 minutes.";
    }
  }

  Future<List<String>> getPersonalizedChallenges() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return [
      "Complete 3 Morning Habits in a row",
      "Log a mood reflection for 5 days",
      "Try a new 'Focus' blueprint",
    ];
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});
