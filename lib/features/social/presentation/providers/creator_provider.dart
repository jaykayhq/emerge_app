// lib/features/social/presentation/providers/creator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  return CreatorRepository();
});

final creatorProfileProvider = StreamProvider.family<CreatorProfile?, String>((ref, userId) {
  final repository = ref.watch(creatorRepositoryProvider);
  return repository.watchCreatorProfile(userId);
});
