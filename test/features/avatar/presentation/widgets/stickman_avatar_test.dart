import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_pose.dart';
import 'package:emerge_app/features/avatar/presentation/widgets/stickman_avatar.dart';

void main() {
  group('StickmanAvatar', () {
    testWidgets('renders default avatar without errors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickmanAvatar(
              avatarData: AvatarData.defaultAvatar(),
            ),
          ),
        ),
      );
      expect(find.byType(StickmanAvatar), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 50,
              height: 75,
              child: StickmanAvatar(
                avatarData: AvatarData.defaultAvatar(),
                size: 50,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(StickmanAvatar), findsOneWidget);
    });

    testWidgets('renders with different pose', (tester) async {
      final wavePose = AvatarPose.idle().copyWith(leftArmAngle: -1.2);
      final avatar = AvatarData.defaultAvatar().copyWith(pose: wavePose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickmanAvatar(avatarData: avatar),
          ),
        ),
      );
      expect(find.byType(StickmanAvatar), findsOneWidget);
    });
  });
}
