import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';

class MockChallengeRepository extends Mock implements ChallengeRepository {}
class MockTribeRepository extends Mock implements TribeRepository {}
class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}
