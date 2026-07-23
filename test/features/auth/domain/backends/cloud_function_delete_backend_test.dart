import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/backends/cloud_function_delete_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult {}

void main() {
  late CloudFunctionDeleteBackend backend;
  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    when(() => functions.httpsCallable('deleteMyAccount')).thenReturn(callable);
    backend = CloudFunctionDeleteBackend(functions);
  });

  test('returns Right(unit) when server reports success', () async {
    final result = _MockResult();
    when(() => result.data).thenReturn({'success': true});
    when(() => callable.call(any())).thenAnswer((_) async => result);

    final res = await backend.delete(deletionRequestId: 'req-1');
    expect(res, const Right<Failure, Unit>(unit));
    verify(() => callable.call({'deletionRequestId': 'req-1'})).called(1);
  });

  test('returns Left(ServerFailure) when server reports failure', () async {
    final result = _MockResult();
    when(() => result.data).thenReturn({'success': false});
    when(() => callable.call(any())).thenAnswer((_) async => result);

    final res = await backend.delete(deletionRequestId: 'req-2');
    expect(res.isLeft(), isTrue);
  });

  test('returns Left(AuthFailure) on unauthenticated', () async {
    when(() => callable.call(any())).thenThrow(
      FirebaseFunctionsException(code: 'unauthenticated', message: 'nope'),
    );
    final res = await backend.delete(deletionRequestId: 'req-3');
    expect(res.isLeft(), isTrue);
    res.fold(
      (f) => expect(f, isA<AuthFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('returns Left(ServerFailure) on generic exception', () async {
    when(() => callable.call(any())).thenThrow(Exception('boom'));
    final res = await backend.delete(deletionRequestId: 'req-4');
    expect(res.isLeft(), isTrue);
    res.fold(
      (f) => expect(f, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
