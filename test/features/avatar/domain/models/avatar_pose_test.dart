import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_pose.dart';

void main() {
  group('AvatarPose', () {
    test('idle pose has expected arm angles', () {
      final pose = AvatarPose.idle();
      expect(pose.leftArmAngle, closeTo(-0.15, 0.001));
      expect(pose.rightArmAngle, closeTo(0.15, 0.001));
    });

    test('idle pose has slight leg offset', () {
      final pose = AvatarPose.idle();
      expect(pose.leftLegAngle, closeTo(0.1, 0.001));
      expect(pose.rightLegAngle, closeTo(-0.1, 0.001));
    });

    test('wave pose has raised arm', () {
      final pose = AvatarPose.wave();
      expect(pose.leftArmAngle, lessThan(-0.5));
    });

    test('attack pose has both arms raised', () {
      final pose = AvatarPose.attack();
      expect(pose.leftArmAngle, lessThan(-0.5));
      expect(pose.rightArmAngle, lessThan(-0.5));
    });

    test('copyWith creates modified copy', () {
      final base = AvatarPose.idle();
      final modified = base.copyWith(leftArmAngle: -1.0);
      expect(modified.leftArmAngle, closeTo(-1.0, 0.001));
      expect(modified.rightArmAngle, base.rightArmAngle);
    });
  });
}
