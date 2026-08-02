import 'package:emerge_app/features/monetization/data/services/manage_premium_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFunctions implements ManagePremiumCaller {
  final calls = <Map<String, dynamic>>[];
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    if (throwError) throw Exception('boom');
    calls.add({...data, '_fn': name});
    return {'ok': true};
  }
}

void main() {
  test('cancel calls the callable with action cancel', () async {
    final fake = _FakeFunctions();
    final service = ManagePremiumService(fake);

    final result = await service.cancel();

    expect(result.isRight(), isTrue);
    expect(fake.calls.single['action'], 'cancel');
    expect(fake.calls.single['_fn'], 'managePremium');
  });

  test('pause calls the callable with action pause', () async {
    final fake = _FakeFunctions();
    final service = ManagePremiumService(fake);

    final result = await service.pause();

    expect(result.isRight(), isTrue);
    expect(fake.calls.single['action'], 'pause');
  });

  test('callable failure returns Left with a message', () async {
    final fake = _FakeFunctions()..throwError = true;
    final service = ManagePremiumService(fake);

    final result = await service.cancel();

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (r) => ''), contains('boom'));
  });
}
