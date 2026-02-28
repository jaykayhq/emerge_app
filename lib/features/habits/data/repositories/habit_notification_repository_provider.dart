import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/habits/data/repositories/habit_notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final notificationRepositoryProvider = Provider<HabitNotificationRepository>((ref) {
  return HabitNotificationRepository(
    notificationService: ref.watch(notificationServiceProvider),
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
