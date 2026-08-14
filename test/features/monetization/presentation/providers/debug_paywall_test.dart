import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug resolve', () {
    // ignore: avoid_print
    print('resolve on file base: "${Uri.base.resolve('/order-confirmed')}"');
    final webBase = Uri.parse('https://emerge.web.app/some/path');
    // ignore: avoid_print
    print('resolve on web base: "${webBase.resolve('/order-confirmed')}"');
  });
}
