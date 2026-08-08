import 'package:emerge_app/features/rating/domain/rating_prompt_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists and reads back the rating prompt state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesRatingPromptStore();

    expect(await store.lastAskedAt(), isNull);
    expect(await store.versionAskedFor(), isNull);
    expect(await store.dontAskAgain(), isFalse);

    await store.recordAsked(DateTime(2026, 8, 8, 12), '1.0.7+12');
    await store.setDontAskAgain();

    expect(await store.lastAskedAt(), DateTime(2026, 8, 8, 12));
    expect(await store.versionAskedFor(), '1.0.7+12');
    expect(await store.dontAskAgain(), isTrue);
  });
}
