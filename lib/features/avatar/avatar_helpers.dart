import 'dart:ui';

import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';

/// Create a default hero avatar at level 1.
AvatarData generateDefaultAvatar() => AvatarData.defaultAvatar();

/// Convert a [Color] to a hex string like `#FF6B35`.
///
/// Strips the alpha channel (assumes fully opaque).
String colorToHex(Color color) {
  final hex = color.value.toRadixString(16).substring(2).toUpperCase();
  return '#$hex';
}
