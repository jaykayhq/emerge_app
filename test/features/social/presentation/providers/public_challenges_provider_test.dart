import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publicChallengesProvider streams live statuses only', () async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('challenges').doc('featured_1').set({
      'title': 'Featured One',
      'description': 'd',
      'imageUrl': '',
      'reward': 'r',
      'participants': 1,
      'daysLeft': 7,
      'totalDays': 7,
      'currentDay': 0,
      'status': 'featured',
      'xpReward': 250,
      'steps': <Map<String, dynamic>>[],
    });
    await fake.collection('challenges').doc('active_1').set({
      'title': 'Active One',
      'description': 'd',
      'imageUrl': '',
      'reward': 'r',
      'participants': 1,
      'daysLeft': 5,
      'totalDays': 7,
      'currentDay': 2,
      'status': 'active',
      'xpReward': 250,
      'steps': <Map<String, dynamic>>[],
    });
    await fake.collection('challenges').doc('completed_1').set({
      'title': 'Done',
      'description': 'd',
      'imageUrl': '',
      'reward': 'r',
      'participants': 1,
      'daysLeft': 0,
      'totalDays': 7,
      'currentDay': 7,
      'status': 'completed',
      'xpReward': 250,
      'steps': <Map<String, dynamic>>[],
    });

    final container = ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(publicChallengesProvider, (_, _) {});
    addTearDown(subscription.close);

    final result = await container.read(publicChallengesProvider.future);
    expect(result.map((c) => c.id).toSet(), {'featured_1', 'active_1'});
    expect(result.every((c) => c.status != ChallengeStatus.completed), isTrue);
    expect(result.map((c) => c.title).toSet(), {'Featured One', 'Active One'});
  });
}
