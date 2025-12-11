import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_stats.dart';
import 'package:fpdart/fpdart.dart';

abstract class GamificationRepository {
  Stream<UserStats> watchUserStats(String userId);
  Future<Either<Failure, Unit>> updateUserStats(UserStats stats);
  Future<Either<Failure, Unit>> addXp(String userId, int amount);
}
