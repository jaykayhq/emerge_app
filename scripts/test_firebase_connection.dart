// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Standalone script to verify Firebase connectivity.
/// Run with: dart run scripts/test_firebase_connection.dart
///
/// Set USE_EMULATOR=true to test against local emulators.
void main() async {
  print('🔍 Testing Firebase Connection...\n');

  try {
    await Firebase.initializeApp();

    final useEmulator = Platform.environment['USE_EMULATOR'] == 'true';

    if (useEmulator) {
      print('📡 Connecting to local Firebase emulators...');
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } else {
      print('📡 Connecting to production Firebase...');
    }

    await _testFirestoreConnectivity();
    await _testAuthConnectivity();
    await _testBasicReadWrite();

    print('\n✅ All Firebase connection tests passed!');
    exit(0);
  } catch (e) {
    print('\n❌ Firebase connection test failed: $e');
    exit(1);
  }
}

Future<void> _testFirestoreConnectivity() async {
  print('\n1️⃣ Testing Firestore connectivity...');
  try {
    final startTime = DateTime.now();
    await FirebaseFirestore.instance
        .collection('_connection_test')
        .limit(1)
        .get();
    final duration = DateTime.now().difference(startTime);
    print('   ✅ Firestore reachable (${duration.inMilliseconds}ms)');
  } catch (e) {
    print('   ❌ Firestore unreachable: $e');
    rethrow;
  }
}

Future<void> _testAuthConnectivity() async {
  print('\n2️⃣ Testing Auth connectivity...');
  try {
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    print('   ✅ Auth reachable (current user: ${currentUser?.uid ?? 'none'})');
  } catch (e) {
    print('   ❌ Auth unreachable: $e');
    rethrow;
  }
}

Future<void> _testBasicReadWrite() async {
  print('\n3️⃣ Testing basic read/write operations...');
  try {
    final testDoc = FirebaseFirestore.instance
        .collection('_connection_test')
        .doc('ping');

    await testDoc.set({
      'timestamp': FieldValue.serverTimestamp(),
      'test': true,
    });

    final snapshot = await testDoc.get();
    if (snapshot.exists && snapshot.data()?['test'] == true) {
      print('   ✅ Read/write operations working');
    } else {
      throw Exception('Document data mismatch');
    }

    await testDoc.delete();
    print('   ✅ Cleanup successful');
  } catch (e) {
    print('   ❌ Read/write failed: $e');
    rethrow;
  }
}
