// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Standalone script to verify Firebase emulator connectivity.
/// Run with: dart run scripts/test_firebase_emulator.dart
///
/// Tests Firestore and Auth emulators via their REST APIs.
/// No Flutter or mobile device required.

const firestoreHost = 'http://localhost:8080';
const authHost = 'http://localhost:9099';
const functionsHost = 'http://localhost:5001';
const projectId = 'tradeflash-l2966';

void main() async {
  print('🔍 Testing Firebase Emulator Connectivity...\n');

  try {
    await _testFirestoreConnectivity();
    await _testAuthConnectivity();
    await _testFunctionsConnectivity();

    print('\n✅ All Firebase emulator tests passed!');
    exit(0);
  } catch (e) {
    print('\n❌ Firebase emulator test failed: $e');
    exit(1);
  }
}

Future<void> _testFirestoreConnectivity() async {
  print('1️⃣ Testing Firestore emulator...');
  try {
    final startTime = DateTime.now();
    final response = await http.get(Uri.parse('$firestoreHost/'));

    if (response.statusCode == 200) {
      final duration = DateTime.now().difference(startTime);
      print('   ✅ Firestore emulator running (${duration.inMilliseconds}ms)');
    } else {
      throw Exception('Status ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Firestore unreachable: $e');
    rethrow;
  }
}

Future<void> _testAuthConnectivity() async {
  print('\n2️⃣ Testing Auth emulator...');
  try {
    final startTime = DateTime.now();
    final response = await http.get(
      Uri.parse('$authHost/'),
    );

    if (response.statusCode == 200) {
      final duration = DateTime.now().difference(startTime);
      print('   ✅ Auth emulator running (${duration.inMilliseconds}ms)');
    } else {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Auth unreachable: $e');
    rethrow;
  }
}

Future<void> _testFunctionsConnectivity() async {
  print('\n3️⃣ Testing Functions emulator...');
  try {
    final startTime = DateTime.now();
    final response = await http.post(
      Uri.parse('$functionsHost/$projectId/us-central1/getAuraInsight'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': {}}),
    );

    final duration = DateTime.now().difference(startTime);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>;
      print('   ✅ getAuraInsight responded: "${result['insight']}" (${duration.inMilliseconds}ms)');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      print('   ✅ getAuraInsight reachable (correctly rejected unauthenticated request) (${duration.inMilliseconds}ms)');
    } else {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Functions unreachable: $e');
    rethrow;
  }
}
