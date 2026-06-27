/// Limb angles for an avatar figure pose.
///
/// Angles are in radians, expressing deviation from relaxed resting position.
/// Negative = forward/up, positive = back/down.
class AvatarPose {
  final double leftArmAngle;
  final double rightArmAngle;
  final double leftLegAngle;
  final double rightLegAngle;
  final double spineLean;
  final double headTilt;

  const AvatarPose({
    required this.leftArmAngle,
    required this.rightArmAngle,
    required this.leftLegAngle,
    required this.rightLegAngle,
    this.spineLean = 0,
    this.headTilt = 0,
  });

  factory AvatarPose.idle() => const AvatarPose(
        leftArmAngle: -0.15,
        rightArmAngle: 0.15,
        leftLegAngle: 0.1,
        rightLegAngle: -0.1,
        spineLean: 0,
        headTilt: 0,
      );

  factory AvatarPose.wave() => const AvatarPose(
        leftArmAngle: -1.2,
        rightArmAngle: 0.15,
        leftLegAngle: 0.1,
        rightLegAngle: -0.1,
        spineLean: 0.05,
        headTilt: -0.1,
      );

  factory AvatarPose.attack() => const AvatarPose(
        leftArmAngle: -1.5,
        rightArmAngle: -1.0,
        leftLegAngle: 0.3,
        rightLegAngle: -0.1,
        spineLean: 0.2,
        headTilt: 0,
      );

  AvatarPose copyWith({
    double? leftArmAngle,
    double? rightArmAngle,
    double? leftLegAngle,
    double? rightLegAngle,
    double? spineLean,
    double? headTilt,
  }) =>
      AvatarPose(
        leftArmAngle: leftArmAngle ?? this.leftArmAngle,
        rightArmAngle: rightArmAngle ?? this.rightArmAngle,
        leftLegAngle: leftLegAngle ?? this.leftLegAngle,
        rightLegAngle: rightLegAngle ?? this.rightLegAngle,
        spineLean: spineLean ?? this.spineLean,
        headTilt: headTilt ?? this.headTilt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarPose &&
          leftArmAngle == other.leftArmAngle &&
          rightArmAngle == other.rightArmAngle &&
          leftLegAngle == other.leftLegAngle &&
          rightLegAngle == other.rightLegAngle &&
          spineLean == other.spineLean &&
          headTilt == other.headTilt;

  @override
  int get hashCode =>
      Object.hash(leftArmAngle, rightArmAngle, leftLegAngle, rightLegAngle,
          spineLean, headTilt);
}
