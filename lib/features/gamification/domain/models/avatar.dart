enum AvatarBodyType { masculine, feminine }

enum AvatarSkinTone { pale, fair, tan, olive, brown, dark }

enum AvatarHairStyle { short, long, buzz, bald, pony, bun }

enum AvatarHairColor { black, brown, blonde, red, white, grey, blue, pink }

enum AvatarFaceShape { round, square, oval }

enum AvatarOutfit { casual, athletic, robe, armor, suit }

class Avatar {
  final String? modelUrl; // URL for the 3D GLB model
  final AvatarBodyType bodyType;
  final AvatarSkinTone skinTone;
  final AvatarHairStyle hairStyle;
  final AvatarHairColor hairColor;
  final AvatarFaceShape faceShape;
  final AvatarOutfit outfit;

  const Avatar({
    this.modelUrl,
    this.bodyType = AvatarBodyType.masculine,
    this.skinTone = AvatarSkinTone.fair,
    this.hairStyle = AvatarHairStyle.short,
    this.hairColor = AvatarHairColor.brown,
    this.faceShape = AvatarFaceShape.square,
    this.outfit = AvatarOutfit.casual,
  });

  Avatar copyWith({
    String? modelUrl,
    AvatarBodyType? bodyType,
    AvatarSkinTone? skinTone,
    AvatarHairStyle? hairStyle,
    AvatarHairColor? hairColor,
    AvatarFaceShape? faceShape,
    AvatarOutfit? outfit,
  }) {
    return Avatar(
      modelUrl: modelUrl ?? this.modelUrl,
      bodyType: bodyType ?? this.bodyType,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      faceShape: faceShape ?? this.faceShape,
      outfit: outfit ?? this.outfit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelUrl': modelUrl,
      'bodyType': bodyType.name,
      'skinTone': skinTone.name,
      'hairStyle': hairStyle.name,
      'hairColor': hairColor.name,
      'faceShape': faceShape.name,
      'outfit': outfit.name,
    };
  }

  factory Avatar.fromMap(Map<String, dynamic> map) {
    return Avatar(
      modelUrl: map['modelUrl'] as String?,
      bodyType: AvatarBodyType.values.firstWhere(
        (e) => e.name == map['bodyType'],
        orElse: () => AvatarBodyType.masculine,
      ),
      skinTone: AvatarSkinTone.values.firstWhere(
        (e) => e.name == map['skinTone'],
        orElse: () => AvatarSkinTone.fair,
      ),
      hairStyle: AvatarHairStyle.values.firstWhere(
        (e) => e.name == map['hairStyle'],
        orElse: () => AvatarHairStyle.short,
      ),
      hairColor: AvatarHairColor.values.firstWhere(
        (e) => e.name == map['hairColor'],
        orElse: () => AvatarHairColor.brown,
      ),
      faceShape: AvatarFaceShape.values.firstWhere(
        (e) => e.name == map['faceShape'],
        orElse: () => AvatarFaceShape.square,
      ),
      outfit: AvatarOutfit.values.firstWhere(
        (e) => e.name == map['outfit'],
        orElse: () => AvatarOutfit.casual,
      ),
    );
  }
}
