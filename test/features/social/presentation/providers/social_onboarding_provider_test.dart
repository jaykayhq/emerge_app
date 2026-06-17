import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SocialOnboardingNotifier extends SocialOnboardingNotifier {
  _SocialOnboardingNotifier(this._value);
  final bool _value;

  @override
  Future<bool> build() async => _value;
}

void main() {
  group('socialOnboardingCompletedProvider', () {
    test('initial state is false', () async {
      final container = ProviderContainer(
        overrides: [
          socialOnboardingCompletedProvider.overrideWith(
            () => _SocialOnboardingNotifier(false),
          ),
        ],
      );
      final result = await container.read(socialOnboardingCompletedProvider.future);
      expect(result, false);
      container.dispose();
    });

    test('can be set to true', () async {
      final container = ProviderContainer(
        overrides: [
          socialOnboardingCompletedProvider.overrideWith(
            () => _SocialOnboardingNotifier(true),
          ),
        ],
      );
      final result = await container.read(socialOnboardingCompletedProvider.future);
      expect(result, true);
      container.dispose();
    });
  });
}
