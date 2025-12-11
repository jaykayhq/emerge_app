import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:fpdart/fpdart.dart';

abstract class UserProfileRepository {
  Future<Either<String, Unit>> createProfile(UserProfile profile);
  Future<Either<String, UserProfile>> getProfile(String uid);
  Stream<UserProfile?> watchProfile(String uid);
  Future<Either<String, Unit>> updateProfile(UserProfile profile);
}
