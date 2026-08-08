import 'package:emerge_app/features/rating/domain/review_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('play store url targets the app bundle id', () {
    expect(
      playStoreReviewUrl,
      'https://play.google.com/store/apps/details?id=com.emerge.emerge_app',
    );
  });
}
