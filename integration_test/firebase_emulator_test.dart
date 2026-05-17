import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Integration tests that run against Firebase Emulators.
///
/// Prerequisites:
/// 1. Start emulators: `firebase emulators:start`
/// 2. Run tests: `flutter test integration_test/firebase_emulator_test.dart`
///
/// These tests verify:
/// - Firestore read/write operations
/// - Authentication flows
/// - Cloud Functions callable endpoints
void main() {
  setUpAll(() async {
    await Firebase.initializeApp();

    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  });

  group('Firestore Emulator', () {
    test('can write and read documents', () async {
      final testDoc = FirebaseFirestore.instance
          .collection('integration_test')
          .doc('basic_crud');

      await testDoc.set({
        'status': 'working',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final snapshot = await testDoc.get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['status'], equals('working'));

      await testDoc.delete();
    });

    test('can query collections', () async {
      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < 3; i++) {
        final doc = FirebaseFirestore.instance
            .collection('integration_test')
            .doc('query_test_$i');
        batch.set(doc, {'index': i, 'test': 'query'});
      }

      await batch.commit();

      final query = await FirebaseFirestore.instance
          .collection('integration_test')
          .where('test', isEqualTo: 'query')
          .get();

      expect(query.docs.length, greaterThanOrEqualTo(3));

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    });

    test('security rules allow test operations', () async {
      final doc = FirebaseFirestore.instance
          .collection('integration_test')
          .doc('rules_test');

      await doc.set({'allowed': true});
      final snapshot = await doc.get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['allowed'], isTrue);

      await doc.delete();
    });
  });

  group('Auth Emulator', () {
    test('can create and delete test user', () async {
      final email = 'test_${DateTime.now().millisecondsSinceEpoch}@emerge.test';
      const password = 'TestPassword123!';

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      expect(userCredential.user, isNotNull);
      expect(userCredential.user!.email, equals(email));

      await userCredential.user!.delete();
    });

    test('rejects invalid credentials', () async {
      expect(
        FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'nonexistent@test.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('Cloud Functions Emulator', () {
    test('getAuraInsight returns default for unauthenticated', () async {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('getAuraInsight').call();

      expect(result.data, isA<Map>());
      expect(result.data['insight'], isA<String>());
    });

    test('getGroqCoachAdvice rejects missing arguments', () async {
      final functions = FirebaseFunctions.instance;

      expect(
        functions.httpsCallable('getGroqCoachAdvice').call({}),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });
}
