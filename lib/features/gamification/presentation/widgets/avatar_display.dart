import 'package:emerge_app/features/gamification/domain/models/avatar.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/ready_player_me_avatar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AvatarDisplay extends StatelessWidget {
  final Avatar avatar;
  final double size;

  const AvatarDisplay({super.key, required this.avatar, this.size = 200});

  @override
  Widget build(BuildContext context) {
    if (avatar.modelUrl != null && avatar.modelUrl!.isNotEmpty) {
      return ReadyPlayerMeAvatar(
        modelUrl: avatar.modelUrl!,
        height: size,
        width: size,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Body / Skin
          Icon(Icons.person, size: size, color: _getSkinColor(avatar.skinTone)),

          // 2. Outfit (Overlay)
          Icon(
            _getOutfitIcon(avatar.outfit),
            size: size * 0.6,
            color: _getOutfitColor(avatar.outfit),
          ),

          // 3. Hair (Overlay - Top)
          Positioned(
            top: size * 0.05,
            child: Icon(
              _getHairIcon(avatar.hairStyle),
              size: size * 0.35,
              color: _getHairColor(avatar.hairColor),
            ),
          ),

          // 4. Face/Expression (Overlay)
          Positioned(
            top: size * 0.25,
            child: Icon(
              _getFaceIcon(avatar.faceShape),
              size: size * 0.2,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getOutfitIcon(AvatarOutfit outfit) {
    switch (outfit) {
      case AvatarOutfit.casual:
        return FontAwesomeIcons.shirt;
      case AvatarOutfit.athletic:
        return FontAwesomeIcons.personRunning;
      case AvatarOutfit.suit:
        return FontAwesomeIcons.userTie;
      case AvatarOutfit.armor:
        return FontAwesomeIcons.shieldHalved;
      case AvatarOutfit.robe:
        return FontAwesomeIcons.userAstronaut; // Placeholder for robe
    }
  }

  Color _getOutfitColor(AvatarOutfit outfit) {
    switch (outfit) {
      case AvatarOutfit.casual:
        return Colors.blueGrey;
      case AvatarOutfit.athletic:
        return Colors.orangeAccent;
      case AvatarOutfit.suit:
        return Colors.black87;
      case AvatarOutfit.armor:
        return Colors.amber;
      case AvatarOutfit.robe:
        return Colors.purple;
    }
  }

  IconData _getHairIcon(AvatarHairStyle style) {
    switch (style) {
      case AvatarHairStyle.short:
        return Icons.circle;
      case AvatarHairStyle.long:
        return Icons.waves;
      case AvatarHairStyle.bald:
        return Icons.circle_outlined;
      case AvatarHairStyle.buzz:
        return Icons.apps;
      case AvatarHairStyle.pony:
        return Icons.face_3; // Placeholder
      case AvatarHairStyle.bun:
        return Icons.face_2; // Placeholder
    }
  }

  IconData _getFaceIcon(AvatarFaceShape shape) {
    switch (shape) {
      case AvatarFaceShape.round:
        return Icons.sentiment_satisfied;
      case AvatarFaceShape.oval:
        return Icons.sentiment_neutral;
      case AvatarFaceShape.square:
        return Icons.sentiment_very_satisfied;
    }
  }

  Color _getSkinColor(AvatarSkinTone tone) {
    switch (tone) {
      case AvatarSkinTone.pale:
        return const Color(0xFFFFE0BD);
      case AvatarSkinTone.fair:
        return const Color(0xFFFFCD94);
      case AvatarSkinTone.tan:
        return const Color(0xFFEAC086);
      case AvatarSkinTone.olive:
        return const Color(0xFFFFAD60);
      case AvatarSkinTone.brown:
        return const Color(0xFF8D5524);
      case AvatarSkinTone.dark:
        return const Color(0xFF3B2219);
    }
  }

  Color _getHairColor(AvatarHairColor color) {
    switch (color) {
      case AvatarHairColor.black:
        return Colors.black;
      case AvatarHairColor.brown:
        return Colors.brown;
      case AvatarHairColor.blonde:
        return Colors.amber.shade200;
      case AvatarHairColor.red:
        return Colors.red.shade900;
      case AvatarHairColor.grey:
        return Colors.grey;
      case AvatarHairColor.white:
        return Colors.white;
      case AvatarHairColor.blue:
        return Colors.blue;
      case AvatarHairColor.pink:
        return Colors.pink;
    }
  }
}
