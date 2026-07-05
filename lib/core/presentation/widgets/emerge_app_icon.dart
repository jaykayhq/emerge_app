import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Emerge App Icon Widget - displays the new stylized flame app icon with a sleek rounded rectangle clip
/// or the user's archetype emoji for identity-first branding.
class EmergeAppIcon extends StatelessWidget {
  final double size;
  final UserArchetype? archetype;

  const EmergeAppIcon({super.key, this.size = 80, this.archetype});

  @override
  Widget build(BuildContext context) {
    if (archetype != null) {
      final theme = ArchetypeTheme.forArchetype(archetype!);
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Text(theme.emoji, style: TextStyle(fontSize: size * 0.6)),
      );
    }

    return Padding(
      padding: EdgeInsets.all(
        size * 0.15,
      ), // Make icon smaller within its bounds
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain, // Better for free-floating icons
      ),
    );
  }
}
