import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class DriftUserProfileRepository implements UserProfileRepository {
  final DriftUserStatsRepository _userStatsRepository;

  DriftUserProfileRepository(this._userStatsRepository);

  @override
  Future<Either<String, Unit>> createProfile(UserProfile profile) async {
    try {
      await _userStatsRepository.saveUserStats(profile);
      return const Right(unit);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserProfile>> getProfile(String uid) async {
    try {
      final profile = await _userStatsRepository.getUserStats(uid);
      return Right(profile);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _userStatsRepository.watchUserStats(uid);
  }

  @override
  Future<Either<String, Unit>> updateProfile(UserProfile profile) async {
    try {
      await _userStatsRepository.saveUserStats(profile);
      return const Right(unit);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
