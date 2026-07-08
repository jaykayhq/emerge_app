import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:emerge_app/features/gamification/domain/services/weekly_recap_service.dart';

class MockWorldHealthService extends Mock implements WorldHealthService {}

class MockWeeklyRecapService extends Mock implements WeeklyRecapService {}
