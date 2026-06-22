// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/data/services/referral_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockAnalytics extends Mock implements FirebaseAnalytics {}

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late ReferralService service;
  late MockFirestore mockFirestore;
  late MockAnalytics mockAnalytics;
  late MockSyncEngine mockSyncEngine;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockDocumentSnapshot mockSnapshot;

  setUp(() {
    mockFirestore = MockFirestore();
    mockAnalytics = MockAnalytics();
    mockSyncEngine = MockSyncEngine();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    service = ReferralService(
      mockSyncEngine,
      firestore: mockFirestore,
      analytics: mockAnalytics,
    );

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDoc);
    when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);

    when(
      () => mockSyncEngine.enqueueSet(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('ReferralService', () {
    test('generateReferralCode enqueues sync if user has no code', () async {
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'referralCode': null});

      // Mock unique code check - need to mock doc and get
      final mockCheckDoc = MockDocumentReference();
      final mockCheckSnapshot = MockDocumentSnapshot();
      when(() => mockCollection.doc(any())).thenReturn(mockCheckDoc);
      when(() => mockCheckDoc.get()).thenAnswer((_) async => mockCheckSnapshot);
      when(() => mockCheckSnapshot.exists).thenReturn(false);

      final code = await service.generateReferralCode('user123');

      expect(code, startsWith('EMERGE_'));
      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'user_stats',
          documentId: 'user123',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('trackReferral enqueues sync tasks for both users', () async {
      // Mock finding the referral code document
      when(() => mockCollection.doc('EMERGE_XYZ')).thenReturn(mockDoc);
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'referrerId': 'owner123'});

      await service.trackReferral('EMERGE_XYZ', 'user123');

      // Should enqueue updates for referrals collection and user stats
      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'referrals',
          documentId: 'EMERGE_XYZ',
          data: any(named: 'data'),
        ),
      ).called(1);

      verify(
        () => mockSyncEngine.enqueueSet(
          collectionPath: 'user_stats',
          documentId: 'user123',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test(
      'processSuccessfulReferral enqueues XP award and status update',
      () async {
        // 1. Mock newUserDoc get
        final mockNewUserDoc = MockDocumentSnapshot();
        final mockNewUserRef = MockDocumentReference();
        when(
          () => mockFirestore.collection('user_stats'),
        ).thenReturn(mockCollection);
        when(() => mockCollection.doc('user123')).thenReturn(mockNewUserRef);
        when(
          () => mockNewUserRef.get(),
        ).thenAnswer((_) async => mockNewUserDoc);
        when(() => mockNewUserDoc.exists).thenReturn(true);
        when(
          () => mockNewUserDoc.data(),
        ).thenReturn({'referredByCode': 'EMERGE_XYZ'});

        // 2. Mock referralDoc get
        final mockReferralDoc = MockDocumentSnapshot();
        final mockReferralRef = MockDocumentReference();
        when(
          () => mockFirestore.collection('referrals'),
        ).thenReturn(mockCollection);
        when(
          () => mockCollection.doc('EMERGE_XYZ'),
        ).thenReturn(mockReferralRef);
        when(
          () => mockReferralRef.get(),
        ).thenAnswer((_) async => mockReferralDoc);
        when(() => mockReferralDoc.exists).thenReturn(true);
        when(
          () => mockReferralDoc.data(),
        ).thenReturn({'referrerId': 'owner123', 'status': 'pending'});

        // 3. Mock _awardReferralXp calls
        final mockOwnerStatsDoc = MockDocumentSnapshot();
        final mockOwnerStatsRef = MockDocumentReference();
        when(
          () => mockCollection.doc('owner123'),
        ).thenReturn(mockOwnerStatsRef);
        when(
          () => mockOwnerStatsRef.get(),
        ).thenAnswer((_) async => mockOwnerStatsDoc);
        when(() => mockOwnerStatsDoc.exists).thenReturn(true);
        when(() => mockOwnerStatsDoc.data()).thenReturn({
          'level': 1,
          'totalXp': 100,
          'successfulReferrals': 0,
          'totalReferralXpEarned': 0,
          'referredUserIds': [],
        });

        await service.processSuccessfulReferral('user123');

        // Should enqueue:
        // 1. referrals status=completed (enqueueSet)
        // 2. user_stats (owner) XP award (enqueueSet)
        // 3. user_activity log (enqueueSet)
        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'referrals',
            documentId: 'EMERGE_XYZ',
            data: any(named: 'data', that: containsPair('status', 'completed')),
          ),
        ).called(1);

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'user_stats',
            documentId: 'owner123',
            data: any(
              named: 'data',
              that: containsPair('totalReferralXpEarned', 500),
            ),
          ),
        ).called(1);
      },
    );

    test('trackReferral handles non-existent referral code', () async {
      when(() => mockSnapshot.exists).thenReturn(false);

      await service.trackReferral('EMERGE_INVALID', 'user123');

      verifyNever(
        () => mockSyncEngine.enqueueSet(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
        ),
      );
    });

    test(
      'generateReferralCode returns existing code without enqueuing',
      () async {
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({
          'referralCode': 'EXISTING',
        });

        final code = await service.generateReferralCode('user123');

        expect(code, 'EXISTING');
        verifyNever(
          () => mockSyncEngine.enqueueSet(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            data: any(named: 'data'),
          ),
        );
      },
    );
  });
}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}
