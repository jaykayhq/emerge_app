import 'package:emerge_app/features/monetization/domain/entities/habit_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitContract', () {
    final testDate = DateTime(2025, 6, 15, 10, 30, 0);
    final testEndDate = DateTime(2025, 7, 15, 10, 30, 0);

    group('constructor', () {
      test('sets all fields correctly', () {
        final contract = HabitContract(
          id: 'c1',
          userId: 'u1',
          habitId: 'h1',
          habitName: 'Morning Run',
          partnerEmail: 'friend@example.com',
          partnerId: 'p1',
          partnerName: 'Friend',
          penaltyAmount: 10.0,
          isActive: true,
          signatureUrl: 'https://example.com/sig.png',
          signedAt: testDate,
          contractStart: testDate,
          contractEnd: testEndDate,
          missedDays: 2,
          totalDays: 30,
          status: 'active',
        );

        expect(contract.id, 'c1');
        expect(contract.userId, 'u1');
        expect(contract.habitId, 'h1');
        expect(contract.habitName, 'Morning Run');
        expect(contract.partnerEmail, 'friend@example.com');
        expect(contract.partnerId, 'p1');
        expect(contract.partnerName, 'Friend');
        expect(contract.penaltyAmount, 10.0);
        expect(contract.isActive, isTrue);
        expect(contract.signatureUrl, 'https://example.com/sig.png');
        expect(contract.signedAt, testDate);
        expect(contract.contractStart, testDate);
        expect(contract.contractEnd, testEndDate);
        expect(contract.missedDays, 2);
        expect(contract.totalDays, 30);
        expect(contract.status, 'active');
      });

      test('applies default values', () {
        final contract = HabitContract(
          id: 'c1',
          userId: 'u1',
          habitId: 'h1',
          partnerEmail: 'friend@example.com',
          penaltyAmount: 10.0,
        );

        expect(contract.habitName, 'Habit Contract');
        expect(contract.missedDays, 0);
        expect(contract.totalDays, 30);
        expect(contract.status, 'active');
        expect(contract.isActive, isTrue);
        expect(contract.partnerId, isNull);
        expect(contract.partnerName, isNull);
        expect(contract.signatureUrl, isNull);
        expect(contract.signedAt, isNull);
        expect(contract.contractStart, isNull);
        expect(contract.contractEnd, isNull);
      });
    });

    group('Equatable', () {
      test('equal when all fields match', () {
        final a = HabitContract(
          id: 'c1',
          userId: 'u1',
          habitId: 'h1',
          habitName: 'Morning Run',
          partnerEmail: 'friend@example.com',
          penaltyAmount: 10.0,
        );
        final b = HabitContract(
          id: 'c1',
          userId: 'u1',
          habitId: 'h1',
          habitName: 'Morning Run',
          partnerEmail: 'friend@example.com',
          penaltyAmount: 10.0,
        );

        expect(a, equals(b));
      });

      test('not equal when fields differ', () {
        final a = HabitContract(
          id: 'c1',
          userId: 'u1',
          habitId: 'h1',
          partnerEmail: 'friend@example.com',
          penaltyAmount: 10.0,
        );
        final b = HabitContract(
          id: 'c2',
          userId: 'u1',
          habitId: 'h1',
          partnerEmail: 'friend@example.com',
          penaltyAmount: 10.0,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('toMap / fromMap', () {
      test('roundtrip with all fields populated', () {
        final original = HabitContract(
          id: 'c1',
          userId: 'u1',
          habitId: 'h1',
          habitName: 'Morning Run',
          partnerEmail: 'friend@example.com',
          partnerId: 'p1',
          partnerName: 'Friend',
          penaltyAmount: 10.0,
          isActive: true,
          signatureUrl: 'https://example.com/sig.png',
          signedAt: testDate,
          contractStart: testDate,
          contractEnd: testEndDate,
          missedDays: 2,
          totalDays: 30,
          status: 'active',
        );

        final map = original.toMap();
        final reconstructed = HabitContract.fromMap(map);

        expect(reconstructed.id, original.id);
        expect(reconstructed.userId, original.userId);
        expect(reconstructed.habitId, original.habitId);
        expect(reconstructed.habitName, original.habitName);
        expect(reconstructed.partnerEmail, original.partnerEmail);
        expect(reconstructed.partnerId, original.partnerId);
        expect(reconstructed.partnerName, original.partnerName);
        expect(reconstructed.penaltyAmount, original.penaltyAmount);
        expect(reconstructed.isActive, original.isActive);
        expect(reconstructed.signatureUrl, original.signatureUrl);
        expect(reconstructed.signedAt, original.signedAt);
        expect(reconstructed.contractStart, original.contractStart);
        expect(reconstructed.contractEnd, original.contractEnd);
        expect(reconstructed.missedDays, original.missedDays);
        expect(reconstructed.totalDays, original.totalDays);
        expect(reconstructed.status, original.status);
      });

      test('roundtrip with null optional fields', () {
        final original = HabitContract(
          id: 'c1',
          userId: 'u1',
          habitId: 'h1',
          partnerEmail: 'friend@example.com',
          penaltyAmount: 10.0,
        );

        final map = original.toMap();
        final reconstructed = HabitContract.fromMap(map);

        expect(reconstructed.partnerId, isNull);
        expect(reconstructed.partnerName, isNull);
        expect(reconstructed.signatureUrl, isNull);
        expect(reconstructed.signedAt, isNull);
        expect(reconstructed.contractStart, isNull);
        expect(reconstructed.contractEnd, isNull);
        expect(reconstructed.habitName, 'Habit Contract');
        expect(reconstructed.missedDays, 0);
        expect(reconstructed.totalDays, 30);
        expect(reconstructed.status, 'active');
      });

      test('fromMap handles missing and malformed fields', () {
        final map = <String, dynamic>{
          'id': 'c1',
          'userId': 'u1',
          'habitId': 'h1',
          'partnerEmail': 'friend@example.com',
          'penaltyAmount': 10.0,
          'signedAt': 'not-a-valid-date',
        };

        final contract = HabitContract.fromMap(map);

        expect(contract.id, 'c1');
        expect(contract.habitName, 'Habit Contract');
        expect(contract.isActive, false); // missing key → ?? false
        expect(contract.missedDays, 0);
        expect(contract.totalDays, 30);
        expect(contract.status, 'active');
        expect(contract.signedAt, isNull); // DateTime.tryParse fails
      });

      test('fromMap with null date fields returns null for those fields', () {
        final map = <String, dynamic>{
          'id': 'c1',
          'userId': 'u1',
          'habitId': 'h1',
          'partnerEmail': 'friend@example.com',
          'penaltyAmount': 10.0,
          'signedAt': null,
          'contractStart': null,
          'contractEnd': null,
        };

        final contract = HabitContract.fromMap(map);

        expect(contract.signedAt, isNull);
        expect(contract.contractStart, isNull);
        expect(contract.contractEnd, isNull);
      });

      test('fromMap parses DateTime from ISO string', () {
        final map = <String, dynamic>{
          'id': 'c1',
          'userId': 'u1',
          'habitId': 'h1',
          'partnerEmail': 'friend@example.com',
          'penaltyAmount': 10.0,
          'signedAt': '2025-06-15T10:30:00.000',
          'contractStart': '2025-06-15T10:30:00.000',
        };

        final contract = HabitContract.fromMap(map);

        expect(contract.signedAt, DateTime(2025, 6, 15, 10, 30, 0));
        expect(contract.contractStart, DateTime(2025, 6, 15, 10, 30, 0));
      });
    });
  });
}
