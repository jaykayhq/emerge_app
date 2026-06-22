import 'package:emerge_app/features/gamification/domain/models/avatar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Avatar', () {
    group('constructor', () {
      test('sets all fields with explicit values', () {
        final avatar = Avatar(
          bodyType: AvatarBodyType.feminine,
          skinTone: AvatarSkinTone.olive,
          hairStyle: AvatarHairStyle.pony,
          hairColor: AvatarHairColor.blonde,
          faceShape: AvatarFaceShape.oval,
          outfit: AvatarOutfit.athletic,
        );

        expect(avatar.bodyType, AvatarBodyType.feminine);
        expect(avatar.skinTone, AvatarSkinTone.olive);
        expect(avatar.hairStyle, AvatarHairStyle.pony);
        expect(avatar.hairColor, AvatarHairColor.blonde);
        expect(avatar.faceShape, AvatarFaceShape.oval);
        expect(avatar.outfit, AvatarOutfit.athletic);
      });

      test('uses default values when no arguments given', () {
        const avatar = Avatar();

        expect(avatar.bodyType, AvatarBodyType.masculine);
        expect(avatar.skinTone, AvatarSkinTone.fair);
        expect(avatar.hairStyle, AvatarHairStyle.short);
        expect(avatar.hairColor, AvatarHairColor.brown);
        expect(avatar.faceShape, AvatarFaceShape.square);
        expect(avatar.outfit, AvatarOutfit.casual);
      });
    });

    group('copyWith', () {
      test('overrides each field independently', () {
        const avatar = Avatar();

        final bodyTypeUpdated = avatar.copyWith(bodyType: AvatarBodyType.feminine);
        expect(bodyTypeUpdated.bodyType, AvatarBodyType.feminine);

        final skinToneUpdated = avatar.copyWith(skinTone: AvatarSkinTone.dark);
        expect(skinToneUpdated.skinTone, AvatarSkinTone.dark);

        final hairStyleUpdated = avatar.copyWith(hairStyle: AvatarHairStyle.bun);
        expect(hairStyleUpdated.hairStyle, AvatarHairStyle.bun);

        final hairColorUpdated = avatar.copyWith(hairColor: AvatarHairColor.pink);
        expect(hairColorUpdated.hairColor, AvatarHairColor.pink);

        final faceShapeUpdated = avatar.copyWith(faceShape: AvatarFaceShape.round);
        expect(faceShapeUpdated.faceShape, AvatarFaceShape.round);

        final outfitUpdated = avatar.copyWith(outfit: AvatarOutfit.robe);
        expect(outfitUpdated.outfit, AvatarOutfit.robe);
      });

      test('without arguments returns same values', () {
        const avatar = Avatar(
          bodyType: AvatarBodyType.feminine,
          skinTone: AvatarSkinTone.olive,
          hairStyle: AvatarHairStyle.pony,
          hairColor: AvatarHairColor.blonde,
          faceShape: AvatarFaceShape.oval,
          outfit: AvatarOutfit.athletic,
        );

        final copied = avatar.copyWith();

        expect(copied.bodyType, avatar.bodyType);
        expect(copied.skinTone, avatar.skinTone);
        expect(copied.hairStyle, avatar.hairStyle);
        expect(copied.hairColor, avatar.hairColor);
        expect(copied.faceShape, avatar.faceShape);
        expect(copied.outfit, avatar.outfit);
      });
    });

    group('toMap / fromMap', () {
      test('roundtrip with all values', () {
        const original = Avatar(
          bodyType: AvatarBodyType.feminine,
          skinTone: AvatarSkinTone.olive,
          hairStyle: AvatarHairStyle.pony,
          hairColor: AvatarHairColor.blonde,
          faceShape: AvatarFaceShape.oval,
          outfit: AvatarOutfit.athletic,
        );

        final map = original.toMap();
        final reconstructed = Avatar.fromMap(map);

        expect(reconstructed.bodyType, original.bodyType);
        expect(reconstructed.skinTone, original.skinTone);
        expect(reconstructed.hairStyle, original.hairStyle);
        expect(reconstructed.hairColor, original.hairColor);
        expect(reconstructed.faceShape, original.faceShape);
        expect(reconstructed.outfit, original.outfit);
      });

      test('fromMap with missing keys uses defaults', () {
        final map = <String, dynamic>{};

        final avatar = Avatar.fromMap(map);

        expect(avatar.bodyType, AvatarBodyType.masculine);
        expect(avatar.skinTone, AvatarSkinTone.fair);
        expect(avatar.hairStyle, AvatarHairStyle.short);
        expect(avatar.hairColor, AvatarHairColor.brown);
        expect(avatar.faceShape, AvatarFaceShape.square);
        expect(avatar.outfit, AvatarOutfit.casual);
      });

      test('fromMap with invalid enum values uses defaults', () {
        final map = <String, dynamic>{
          'bodyType': 'not_a_valid_type',
          'skinTone': 'not_a_valid_tone',
          'hairStyle': 'not_a_valid_style',
          'hairColor': 'not_a_valid_color',
          'faceShape': 'not_a_valid_shape',
          'outfit': 'not_a_valid_outfit',
        };

        final avatar = Avatar.fromMap(map);

        expect(avatar.bodyType, AvatarBodyType.masculine);
        expect(avatar.skinTone, AvatarSkinTone.fair);
        expect(avatar.hairStyle, AvatarHairStyle.short);
        expect(avatar.hairColor, AvatarHairColor.brown);
        expect(avatar.faceShape, AvatarFaceShape.square);
        expect(avatar.outfit, AvatarOutfit.casual);
      });

      test('toMap converts enum names correctly', () {
        const avatar = Avatar(
          bodyType: AvatarBodyType.feminine,
          skinTone: AvatarSkinTone.olive,
          hairStyle: AvatarHairStyle.pony,
          hairColor: AvatarHairColor.blonde,
          faceShape: AvatarFaceShape.oval,
          outfit: AvatarOutfit.athletic,
        );

        final map = avatar.toMap();

        expect(map['bodyType'], 'feminine');
        expect(map['skinTone'], 'olive');
        expect(map['hairStyle'], 'pony');
        expect(map['hairColor'], 'blonde');
        expect(map['faceShape'], 'oval');
        expect(map['outfit'], 'athletic');
      });
    });
  });
}
