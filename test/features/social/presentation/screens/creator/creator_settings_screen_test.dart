import 'dart:typed_data';

import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart'
    hide creatorRepositoryProvider;
import 'package:emerge_app/features/social/data/services/creator_image_picker.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/domain/services/creator_media_service.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_settings_providers.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_settings_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeImagePicker implements CreatorImagePicker {
  PickedCreatorImage? result;

  _FakeImagePicker({this.result});

  @override
  Future<PickedCreatorImage?> pickImage() async => result;
}

class _FakeMediaService implements CreatorMediaService {
  final List<CreatorMediaType> calls = [];
  String url = 'https://cdn.example.com/uploaded.jpg';

  @override
  Future<String> uploadCreatorImage({
    required String userId,
    required CreatorMediaType type,
    required Uint8List bytes,
    String? filename,
    String? blueprintId,
  }) async {
    calls.add(type);
    return url;
  }
}

class _FakeAuthRepository implements AuthRepository {
  String? updatedName;

  @override
  Stream<AuthUser> get user => Stream.value(AuthUser.empty);

  @override
  Future<Either<Failure, void>> updateDisplayName(String displayName) async {
    updatedName = displayName;
    return const Right(null);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle({bool isLogin = false}) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteAccount() => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> sendVerificationEmail() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> applyVerificationCode(String oobCode) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> claimUsername(String username) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> checkUsernameAvailability(String username) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> checkEmailVerified() =>
      throw UnimplementedError();
}

const _profile = CreatorProfile(
  userId: 'uid_1',
  role: 'creator',
  displayName: 'Alex Forge',
  bio: 'I teach focus systems.',
  specialityTags: ['focus', 'deep-work'],
  isVerifiedCreator: true,
);

final _blueprint = Blueprint(
  id: 'bp_1',
  creatorUserId: 'uid_1',
  creatorName: 'Alex Forge',
  creatorArchetype: 'Creator',
  title: 'Deep Work Stack',
  description: '',
  habits: const [BlueprintHabit(title: '90 Min Deep Work')],
  createdAt: DateTime(2026, 1, 1),
  category: 'Productivity',
);

Future<void> _pumpSettings(
  WidgetTester tester, {
  FakeFirebaseFirestore? firestore,
  _FakeImagePicker? picker,
  _FakeMediaService? media,
  _FakeAuthRepository? auth,
}) async {
  // Tall surface so the lazy ListView builds the blueprint-covers section.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final fs = firestore ?? FakeFirebaseFirestore();
  final mediaService = media ?? _FakeMediaService();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(
            const AuthUser(id: 'uid_1', email: 'a@b.com'),
          ),
        ),
        authRepositoryProvider.overrideWithValue(auth ?? _FakeAuthRepository()),
        creatorRepositoryProvider.overrideWithValue(
          CreatorRepository(firestore: fs),
        ),
        blueprintRepositoryProvider.overrideWithValue(
          BlueprintRepository(fs),
        ),
        creatorProfileProvider('uid_1').overrideWith(
          (ref) => Stream.value(_profile),
        ),
        creatorOwnBlueprintsProvider.overrideWith(
          (ref) => Stream.value([_blueprint]),
        ),
        creatorImagePickerProvider.overrideWithValue(
          picker ?? _FakeImagePicker(result: null),
        ),
        creatorMediaServiceProvider.overrideWithValue(mediaService),
      ],
      child: const MaterialApp(home: CreatorSettingsScreen()),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders profile, blueprints, and account sections', (
    tester,
  ) async {
    await _pumpSettings(tester);

    expect(find.text('Creator Settings'), findsOneWidget);
    expect(find.text('Alex Forge'), findsOneWidget);
    expect(find.text('I teach focus systems.'), findsOneWidget);
    expect(find.text('focus'), findsOneWidget);
    expect(find.text('Deep Work Stack'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('avatar tap uploads and writes avatarUrl to the profile doc', (
    tester,
  ) async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('creator_profiles').doc('uid_1').set({
      'userId': 'uid_1',
      'ownerId': 'uid_1',
      'displayName': 'Alex Forge',
      'isVerifiedCreator': true,
    });
    final media = _FakeMediaService();
    final picker = _FakeImagePicker(
      result: PickedCreatorImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'me.jpg',
      ),
    );

    await _pumpSettings(
      tester,
      firestore: fs,
      media: media,
      picker: picker,
    );

    await tester.tap(find.byKey(const Key('creator_settings_avatar')));
    await tester.pumpAndSettle();

    expect(media.calls, [CreatorMediaType.avatar]);
    expect(find.text('Profile image updated.'), findsOneWidget);

    final doc = await fs.collection('creator_profiles').doc('uid_1').get();
    expect(doc.data()?['avatarUrl'], 'https://cdn.example.com/uploaded.jpg');
  });

  testWidgets('cancelled picker is a no-op — no upload, no error', (
    tester,
  ) async {
    final media = _FakeMediaService();
    await _pumpSettings(tester, media: media); // picker returns null by default

    await tester.tap(find.byKey(const Key('creator_settings_avatar')));
    await tester.pumpAndSettle();

    expect(media.calls, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('blueprint cover tap uploads and updates the blueprint doc', (
    tester,
  ) async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('blueprints').doc('bp_1').set({
      'title': 'Deep Work Stack',
      'creatorUserId': 'uid_1',
      'imageUrl': 'assets/images/blueprints/productivity_1.webp',
    });
    final media = _FakeMediaService();
    final picker = _FakeImagePicker(
      result: PickedCreatorImage(
        bytes: Uint8List.fromList([9, 9, 9]),
        filename: 'cover.png',
      ),
    );

    await _pumpSettings(
      tester,
      firestore: fs,
      media: media,
      picker: picker,
    );

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(media.calls, [CreatorMediaType.blueprint]);
    expect(find.text('Blueprint cover updated.'), findsOneWidget);

    final doc = await fs.collection('blueprints').doc('bp_1').get();
    expect(doc.data()?['imageUrl'], 'https://cdn.example.com/uploaded.jpg');
    expect(doc.data()?['title'], 'Deep Work Stack');
  });

  testWidgets('name change updates auth display name and profile mirrors', (
    tester,
  ) async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('creator_profiles').doc('uid_1').set({
      'userId': 'uid_1',
      'ownerId': 'uid_1',
      'displayName': 'Alex Forge',
    });
    // A published blueprint with the stale denormalized name.
    await fs.collection('blueprints').doc('bp_1').set({
      'creatorUserId': 'uid_1',
      'creatorName': 'Alex Forge',
      'title': 'Deep Work Stack',
    });
    final auth = _FakeAuthRepository();

    await _pumpSettings(tester, firestore: fs, auth: auth);

    await tester.tap(find.text('Alex Forge'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nova Smith');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(auth.updatedName, 'Nova Smith');
    final doc = await fs.collection('creator_profiles').doc('uid_1').get();
    expect(doc.data()?['displayName'], 'Nova Smith');
    // Denormalized blueprint creatorName is backfilled too.
    final bp = await fs.collection('blueprints').doc('bp_1').get();
    expect(bp.data()?['creatorName'], 'Nova Smith');
    expect(find.text('Name updated.'), findsOneWidget);
  });

  testWidgets('empty blueprints shows the empty-state message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(id: 'uid_1', email: 'a@b.com'),
            ),
          ),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          creatorProfileProvider('uid_1').overrideWith(
            (ref) => Stream.value(_profile),
          ),
          creatorOwnBlueprintsProvider.overrideWith(
            (ref) => Stream.value(const <Blueprint>[]),
          ),
        ],
        child: const MaterialApp(home: CreatorSettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('No blueprints yet — publish one from the Blueprint Studio.'),
      findsOneWidget,
    );
  });
}
