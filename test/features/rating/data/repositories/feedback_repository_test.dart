import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/rating/data/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDoc extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  test('submitFeedback writes to feedback/{uid}', () async {
    final firestore = _MockFirestore();
    final collection = _MockCollection();
    final doc = _MockDoc();
    when(() => firestore.collection('feedback')).thenReturn(collection);
    when(() => collection.doc('u1')).thenReturn(doc);
    when(() => doc.set(any())).thenAnswer((_) async {});

    final repo = FeedbackRepository(firestore);
    final result = await repo.submitFeedback(
      userId: 'u1',
      rating: 2,
      message: 'Too hard to track',
    );

    expect(result.isRight(), isTrue);
    final data = verify(() => doc.set(captureAny())).captured.single as Map<String, dynamic>;
    expect(data['userId'], 'u1');
    expect(data['rating'], 2);
    expect(data['message'], 'Too hard to track');
    expect(data.containsKey('createdAt'), isTrue);
  });

  test('submitFeedback returns Left on failure', () async {
    final firestore = _MockFirestore();
    final collection = _MockCollection();
    final doc = _MockDoc();
    when(() => firestore.collection('feedback')).thenReturn(collection);
    when(() => collection.doc('u1')).thenReturn(doc);
    when(() => doc.set(any())).thenThrow(Exception('offline'));

    final repo = FeedbackRepository(firestore);
    final result = await repo.submitFeedback(userId: 'u1', rating: 1, message: 'x');
    expect(result.isLeft(), isTrue);
  });
}
