import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/health/data/services/health_auto_complete_service.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class MockHealthRepository extends Mock implements HealthRepository {}

void main() {
  late MockHealthRepository mockRepo;
  late HealthAutoCompleteService service;

  setUp(() {
    mockRepo = MockHealthRepository();
    service = HealthAutoCompleteService(healthRepository: mockRepo);
  });

  group('HealthAutoCompleteService', () {
    test('returns health step habits when target met', () async {
      when(() => mockRepo.getTodaySteps()).thenAnswer((_) async => 10000);
      when(() => mockRepo.getTodayScreenTime()).thenAnswer((_) async => 0);

      final habits = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Walk 8000 steps',
          createdAt: DateTime.now(),
          integrationType: HabitIntegrationType.healthSteps,
          integrationTarget: 8000,
        ),
        Habit(
          id: 'h2',
          userId: 'u1',
          title: 'Walk 20000 steps',
          createdAt: DateTime.now(),
          integrationType: HabitIntegrationType.healthSteps,
          integrationTarget: 20000,
        ),
      ];

      final ids = await service.getHabitIdsToAutoComplete(habits);
      expect(ids, ['h1']);
    });

    test('returns screen time habits when target met', () async {
      when(() => mockRepo.getTodaySteps()).thenAnswer((_) async => 0);
      when(() => mockRepo.getTodayScreenTime()).thenAnswer((_) async => 90);

      final habits = [
        Habit(
          id: 'h3',
          userId: 'u1',
          title: 'Limit screen to 60 min',
          createdAt: DateTime.now(),
          integrationType: HabitIntegrationType.screenTimeLimit,
          integrationTarget: 60,
        ),
      ];

      final ids = await service.getHabitIdsToAutoComplete(habits);
      expect(ids, ['h3']);
    });

    test('skips already-completed habits', () async {
      when(() => mockRepo.getTodaySteps()).thenAnswer((_) async => 10000);
      when(() => mockRepo.getTodayScreenTime()).thenAnswer((_) async => 0);

      final habits = [
        Habit(
          id: 'h4',
          userId: 'u1',
          title: 'Walk 8000 steps',
          createdAt: DateTime.now(),
          lastCompletedDate: DateTime.now(),
          integrationType: HabitIntegrationType.healthSteps,
          integrationTarget: 8000,
        ),
      ];

      final ids = await service.getHabitIdsToAutoComplete(habits);
      expect(ids, isEmpty);
    });

    test('returns empty when no integration habits', () async {
      when(() => mockRepo.getTodaySteps()).thenAnswer((_) async => 0);
      when(() => mockRepo.getTodayScreenTime()).thenAnswer((_) async => 0);

      final habits = [
        Habit(
          id: 'h5',
          userId: 'u1',
          title: 'Read a book',
          createdAt: DateTime.now(),
          integrationType: HabitIntegrationType.none,
        ),
      ];

      final ids = await service.getHabitIdsToAutoComplete(habits);
      expect(ids, isEmpty);
    });

    test('returns empty when habits list is empty', () async {
      final ids = await service.getHabitIdsToAutoComplete([]);
      expect(ids, isEmpty);
    });
  });
}
