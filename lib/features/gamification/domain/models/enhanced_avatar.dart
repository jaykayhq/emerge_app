import 'dart:ui';

// Enhanced enums with more options
enum EnhancedAvatarBodyType {
  masculine,
  feminine,
  androgynous,
  child,
  heavyset,
  athletic,
  thin,
}

enum EnhancedAvatarSkinTone {
  pale,
  fair,
  tan,
  olive,
  brown,
  dark,
  lightBeige,
  mediumBeige,
  darkBeige,
  lightWarm,
  mediumWarm,
  darkWarm,
  lightCool,
  mediumCool,
  darkCool,
}

enum EnhancedAvatarHairStyle {
  short,
  long,
  buzz,
  bald,
  pony,
  bun,
  afro,
  curly,
  wavy,
  straight,
  spiky,
  mohawk,
  bob,
  pixie,
  dreadlocks,
  braids,
}

enum EnhancedAvatarHairColor {
  black,
  brown,
  blonde,
  red,
  white,
  grey,
  blue,
  pink,
  purple,
  green,
  orange,
  auburn,
  chestnut,
  golden,
  silver,
  rainbow,
}

enum EnhancedAvatarFaceShape { round, square, oval, heart, diamond, oblong }

enum EnhancedAvatarOutfit {
  casual,
  athletic,
  robe,
  armor,
  suit,
  formal,
  business,
  beach,
  winter,
  summer,
  fantasy,
  sciFi,
  medieval,
}

// New enums for enhanced features
enum AvatarExpression {
  neutral,
  happy,
  sad,
  surprised,
  angry,
  winking,
  laughing,
  tongueOut,
}

enum AvatarPose {
  standing,
  sitting,
  walking,
  running,
  dancing,
  waving,
  thumbsUp,
  superhero,
}

enum AvatarAccessory {
  none,
  glasses,
  sunglasses,
  readingGlasses,
  earrings,
  necklace,
  hat,
  cap,
  crown,
  headphones,
  mask,
  beard,
  mustache,
}

// Base class for customizable colors
class AvatarColor {
  final Color color;
  final String name;

  const AvatarColor(this.color, this.name);

  static const List<AvatarColor> skinTones = [
    AvatarColor(Color(0xFFFFE0BD), 'Pale'),
    AvatarColor(Color(0xFFFFCD94), 'Fair'),
    AvatarColor(Color(0xFFEAC086), 'Tan'),
    AvatarColor(Color(0xFFFFAD60), 'Olive'),
    AvatarColor(Color(0xFF8D5524), 'Brown'),
    AvatarColor(Color(0xFF3B2219), 'Dark'),
    AvatarColor(Color(0xFFF1C27D), 'Light Beige'),
    AvatarColor(Color(0xFFE0AC69), 'Medium Beige'),
    AvatarColor(Color(0xFFC68642), 'Dark Beige'),
    AvatarColor(Color(0xFF8D5524), 'Light Warm'),
    AvatarColor(Color(0xFF6B4423), 'Medium Warm'),
    AvatarColor(Color(0xFF4D291C), 'Dark Warm'),
    AvatarColor(Color(0xFFCA8546), 'Light Cool'),
    AvatarColor(Color(0xFFA46A29), 'Medium Cool'),
    AvatarColor(Color(0xFF704214), 'Dark Cool'),
  ];

  static const List<AvatarColor> hairColors = [
    AvatarColor(Color(0xFF000000), 'Black'),
    AvatarColor(Color(0xFF3B2219), 'Brown'),
    AvatarColor(Color(0xFFFFD700), 'Blonde'),
    AvatarColor(Color(0xFFB22222), 'Red'),
    AvatarColor(Color(0xFFFFFFFF), 'White'),
    AvatarColor(Color(0xFF808080), 'Grey'),
    AvatarColor(Color(0xFF0000FF), 'Blue'),
    AvatarColor(Color(0xFFFF69B4), 'Pink'),
    AvatarColor(Color(0xFF800080), 'Purple'),
    AvatarColor(Color(0xFF008000), 'Green'),
    AvatarColor(Color(0xFFFFA500), 'Orange'),
    AvatarColor(Color(0xFFDC143C), 'Auburn'),
    AvatarColor(Color(0xFFD2691E), 'Chestnut'),
    AvatarColor(Color(0xFFFFD700), 'Golden'),
    AvatarColor(Color(0xFFC0C0C0), 'Silver'),
    AvatarColor(Color(0xFFFF00FF), 'Rainbow'),
  ];

  static const List<AvatarColor> outfitColors = [
    AvatarColor(Color(0xFF0000FF), 'Blue'),
    AvatarColor(Color(0xFFFF0000), 'Red'),
    AvatarColor(Color(0xFF008000), 'Green'),
    AvatarColor(Color(0xFF000000), 'Black'),
    AvatarColor(Color(0xFFFFFFFF), 'White'),
    AvatarColor(Color(0xFFFFA500), 'Orange'),
    AvatarColor(Color(0xFF800080), 'Purple'),
    AvatarColor(Color(0xFF000080), 'Navy'),
    AvatarColor(Color(0xFFA52A2A), 'Brown'),
    AvatarColor(Color(0xFFFFD700), 'Gold'),
    AvatarColor(Color(0xFFC0C0C0), 'Silver'),
    AvatarColor(Color(0xFF800000), 'Maroon'),
    AvatarColor(Color(0xFF00FFFF), 'Cyan'),
    AvatarColor(Color(0xFFFF00FF), 'Magenta'),
    AvatarColor(Color(0xFF808000), 'Olive'),
    AvatarColor(Color(0xFF808080), 'Gray'),
  ];
}

// Enhanced avatar model with advanced customization
class EnhancedAvatar {
  // Basic avatar properties (extended)
  final String? modelUrl;
  final EnhancedAvatarBodyType bodyType;
  final EnhancedAvatarSkinTone skinTone;
  final EnhancedAvatarHairStyle hairStyle;
  final EnhancedAvatarHairColor hairColor;
  final EnhancedAvatarFaceShape faceShape;
  final EnhancedAvatarOutfit outfit;

  // Enhanced features
  final AvatarExpression expression;
  final AvatarPose pose;
  final double bodyScale; // Overall body size (1.0 = normal)
  final double headScale; // Head size relative to body (1.0 = normal)
  final double limbScale; // Arm/leg length (1.0 = normal)
  final List<AvatarAccessory> accessories;
  final Color outfitPrimaryColor;
  final Color outfitSecondaryColor;
  final double hairLength; // For longer/shorter hair (0.5 = normal)
  final double facialHairGrowth; // For beard/mustache growth (0.0-1.0)

  // Animation properties
  final bool isAnimated; // Whether the avatar uses subtle animations
  final double animationSpeed; // Speed of any animations (0.0-2.0)

  // Clothing layers
  final String? topLayerUrl; // For complex clothing textures
  final String? bottomLayerUrl;
  final String? accessoryLayerUrl;

  const EnhancedAvatar({
    this.modelUrl,
    this.bodyType = EnhancedAvatarBodyType.masculine,
    this.skinTone = EnhancedAvatarSkinTone.fair,
    this.hairStyle = EnhancedAvatarHairStyle.short,
    this.hairColor = EnhancedAvatarHairColor.brown,
    this.faceShape = EnhancedAvatarFaceShape.square,
    this.outfit = EnhancedAvatarOutfit.casual,
    this.expression = AvatarExpression.neutral,
    this.pose = AvatarPose.standing,
    this.bodyScale = 1.0,
    this.headScale = 1.0,
    this.limbScale = 1.0,
    this.accessories = const [],
    this.outfitPrimaryColor = const Color(0xFF0000FF), // Blue
    this.outfitSecondaryColor = const Color(0xFF000000), // Black
    this.hairLength = 1.0,
    this.facialHairGrowth = 0.0,
    this.isAnimated = false,
    this.animationSpeed = 1.0,
    this.topLayerUrl,
    this.bottomLayerUrl,
    this.accessoryLayerUrl,
  });

  EnhancedAvatar copyWith({
    String? modelUrl,
    EnhancedAvatarBodyType? bodyType,
    EnhancedAvatarSkinTone? skinTone,
    EnhancedAvatarHairStyle? hairStyle,
    EnhancedAvatarHairColor? hairColor,
    EnhancedAvatarFaceShape? faceShape,
    EnhancedAvatarOutfit? outfit,
    AvatarExpression? expression,
    AvatarPose? pose,
    double? bodyScale,
    double? headScale,
    double? limbScale,
    List<AvatarAccessory>? accessories,
    Color? outfitPrimaryColor,
    Color? outfitSecondaryColor,
    double? hairLength,
    double? facialHairGrowth,
    bool? isAnimated,
    double? animationSpeed,
    String? topLayerUrl,
    String? bottomLayerUrl,
    String? accessoryLayerUrl,
  }) {
    return EnhancedAvatar(
      modelUrl: modelUrl ?? this.modelUrl,
      bodyType: bodyType ?? this.bodyType,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      faceShape: faceShape ?? this.faceShape,
      outfit: outfit ?? this.outfit,
      expression: expression ?? this.expression,
      pose: pose ?? this.pose,
      bodyScale: bodyScale ?? this.bodyScale,
      headScale: headScale ?? this.headScale,
      limbScale: limbScale ?? this.limbScale,
      accessories: accessories ?? this.accessories,
      outfitPrimaryColor: outfitPrimaryColor ?? this.outfitPrimaryColor,
      outfitSecondaryColor: outfitSecondaryColor ?? this.outfitSecondaryColor,
      hairLength: hairLength ?? this.hairLength,
      facialHairGrowth: facialHairGrowth ?? this.facialHairGrowth,
      isAnimated: isAnimated ?? this.isAnimated,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      topLayerUrl: topLayerUrl ?? this.topLayerUrl,
      bottomLayerUrl: bottomLayerUrl ?? this.bottomLayerUrl,
      accessoryLayerUrl: accessoryLayerUrl ?? this.accessoryLayerUrl,
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
      'expression': expression.name,
      'pose': pose.name,
      'bodyScale': bodyScale,
      'headScale': headScale,
      'limbScale': limbScale,
      'accessories': accessories.map((a) => a.name).toList(),
      'outfitPrimaryColor': outfitPrimaryColor.toARGB32(),
      'outfitSecondaryColor': outfitSecondaryColor.toARGB32(),
      'hairLength': hairLength,
      'facialHairGrowth': facialHairGrowth,
      'isAnimated': isAnimated,
      'animationSpeed': animationSpeed,
      'topLayerUrl': topLayerUrl,
      'bottomLayerUrl': bottomLayerUrl,
      'accessoryLayerUrl': accessoryLayerUrl,
    };
  }

  factory EnhancedAvatar.fromMap(Map<String, dynamic> map) {
    return EnhancedAvatar(
      modelUrl: map['modelUrl'] as String?,
      bodyType: EnhancedAvatarBodyType.values.firstWhere(
        (e) => e.name == map['bodyType'],
        orElse: () => EnhancedAvatarBodyType.masculine,
      ),
      skinTone: EnhancedAvatarSkinTone.values.firstWhere(
        (e) => e.name == map['skinTone'],
        orElse: () => EnhancedAvatarSkinTone.fair,
      ),
      hairStyle: EnhancedAvatarHairStyle.values.firstWhere(
        (e) => e.name == map['hairStyle'],
        orElse: () => EnhancedAvatarHairStyle.short,
      ),
      hairColor: EnhancedAvatarHairColor.values.firstWhere(
        (e) => e.name == map['hairColor'],
        orElse: () => EnhancedAvatarHairColor.brown,
      ),
      faceShape: EnhancedAvatarFaceShape.values.firstWhere(
        (e) => e.name == map['faceShape'],
        orElse: () => EnhancedAvatarFaceShape.square,
      ),
      outfit: EnhancedAvatarOutfit.values.firstWhere(
        (e) => e.name == map['outfit'],
        orElse: () => EnhancedAvatarOutfit.casual,
      ),
      expression: AvatarExpression.values.firstWhere(
        (e) => e.name == map['expression'],
        orElse: () => AvatarExpression.neutral,
      ),
      pose: AvatarPose.values.firstWhere(
        (e) => e.name == map['pose'],
        orElse: () => AvatarPose.standing,
      ),
      bodyScale: (map['bodyScale'] as num?)?.toDouble() ?? 1.0,
      headScale: (map['headScale'] as num?)?.toDouble() ?? 1.0,
      limbScale: (map['limbScale'] as num?)?.toDouble() ?? 1.0,
      accessories:
          (map['accessories'] as List<dynamic>?)
              ?.map(
                (e) => AvatarAccessory.values.firstWhere(
                  (a) => a.name == e.toString(),
                  orElse: () => AvatarAccessory.none,
                ),
              )
              .toList() ??
          const [],
      outfitPrimaryColor: Color(
        map['outfitPrimaryColor'] as int? ?? 0xFF0000FF,
      ),
      outfitSecondaryColor: Color(
        map['outfitSecondaryColor'] as int? ?? 0xFF000000,
      ),
      hairLength: (map['hairLength'] as num?)?.toDouble() ?? 1.0,
      facialHairGrowth: (map['facialHairGrowth'] as num?)?.toDouble() ?? 0.0,
      isAnimated: map['isAnimated'] as bool? ?? false,
      animationSpeed: (map['animationSpeed'] as num?)?.toDouble() ?? 1.0,
      topLayerUrl: map['topLayerUrl'] as String?,
      bottomLayerUrl: map['bottomLayerUrl'] as String?,
      accessoryLayerUrl: map['accessoryLayerUrl'] as String?,
    );
  }
}
