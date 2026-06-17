import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeAuthUser extends Fake implements AuthUser {}

final AuthUser testAuthUser = AuthUser(
  id: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
);
