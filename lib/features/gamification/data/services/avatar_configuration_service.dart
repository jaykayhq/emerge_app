import 'dart:convert';
import 'package:emerge_app/features/gamification/domain/models/enhanced_avatar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarConfigurationService {
  static const String _avatarKey = 'enhanced_avatar_config';
  static const String _avatarPresetsKey = 'avatar_presets';
  
  /// Saves the current avatar configuration to local storage
  Future<void> saveAvatarConfiguration(EnhancedAvatar avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, jsonEncode(avatar.toMap()));
  }

  /// Loads the avatar configuration from local storage
  Future<EnhancedAvatar?> loadAvatarConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_avatarKey);
    
    if (jsonString != null) {
      final map = jsonDecode(jsonString);
      return EnhancedAvatar.fromMap(map);
    }
    
    return null;
  }

  /// Resets the avatar configuration to default
  Future<void> resetAvatarConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarKey);
  }

  /// Saves an avatar preset with a name
  Future<void> saveAvatarPreset(String name, EnhancedAvatar avatar) async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getString(_avatarPresetsKey) ?? '{}';
    final presets = jsonDecode(presetsJson) as Map<String, dynamic>;
    
    presets[name] = avatar.toMap();
    await prefs.setString(_avatarPresetsKey, jsonEncode(presets));
  }

  /// Loads a named avatar preset
  Future<EnhancedAvatar?> loadAvatarPreset(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getString(_avatarPresetsKey) ?? '{}';
    final presets = jsonDecode(presetsJson) as Map<String, dynamic>;
    
    if (presets.containsKey(name)) {
      return EnhancedAvatar.fromMap(presets[name] as Map<String, dynamic>);
    }
    
    return null;
  }

  /// Gets all saved avatar preset names
  Future<List<String>> getAvatarPresetNames() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getString(_avatarPresetsKey) ?? '{}';
    final presets = jsonDecode(presetsJson) as Map<String, dynamic>;
    
    return presets.keys.toList();
  }

  /// Deletes a named avatar preset
  Future<void> deleteAvatarPreset(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getString(_avatarPresetsKey) ?? '{}';
    final presets = jsonDecode(presetsJson) as Map<String, dynamic>;
    
    presets.remove(name);
    await prefs.setString(_avatarPresetsKey, jsonEncode(presets));
  }

  /// Exports avatar configuration as a string (for sharing or backup)
  String exportAvatarConfiguration(EnhancedAvatar avatar) {
    return base64Encode(utf8.encode(jsonEncode(avatar.toMap())));
  }

  /// Imports avatar configuration from an exported string
  EnhancedAvatar? importAvatarConfiguration(String exportedString) {
    try {
      final decodedBytes = base64Decode(exportedString);
      final jsonString = utf8.decode(decodedBytes);
      final map = jsonDecode(jsonString);
      return EnhancedAvatar.fromMap(map as Map<String, dynamic>);
    } catch (e) {
      // Handle any errors during import
      return null;
    }
  }

  /// Gets a list of default avatar presets for users to choose from
  List<EnhancedAvatar> getDefaultPresets() {
    return [
      // Default casual avatar
      const EnhancedAvatar(
        bodyType: EnhancedAvatarBodyType.masculine,
        skinTone: EnhancedAvatarSkinTone.fair,
        hairStyle: EnhancedAvatarHairStyle.short,
        hairColor: EnhancedAvatarHairColor.brown,
        faceShape: EnhancedAvatarFaceShape.square,
        outfit: EnhancedAvatarOutfit.casual,
        expression: AvatarExpression.neutral,
        pose: AvatarPose.standing,
        outfitPrimaryColor: Color(0xFF0000FF), // Blue
        outfitSecondaryColor: Color(0xFF000000), // Black
      ),
      
      // Stylish avatar
      const EnhancedAvatar(
        bodyType: EnhancedAvatarBodyType.feminine,
        skinTone: EnhancedAvatarSkinTone.mediumBeige,
        hairStyle: EnhancedAvatarHairStyle.long,
        hairColor: EnhancedAvatarHairColor.blonde,
        faceShape: EnhancedAvatarFaceShape.oval,
        outfit: EnhancedAvatarOutfit.formal,
        expression: AvatarExpression.happy,
        pose: AvatarPose.standing,
        outfitPrimaryColor: Color(0xFFFF69B4), // Pink
        outfitSecondaryColor: Color(0xFFFFFFFF), // White
      ),
      
      // Athletic avatar
      const EnhancedAvatar(
        bodyType: EnhancedAvatarBodyType.athletic,
        skinTone: EnhancedAvatarSkinTone.brown,
        hairStyle: EnhancedAvatarHairStyle.buzz,
        hairColor: EnhancedAvatarHairColor.black,
        faceShape: EnhancedAvatarFaceShape.round,
        outfit: EnhancedAvatarOutfit.athletic,
        expression: AvatarExpression.neutral,
        pose: AvatarPose.standing,
        outfitPrimaryColor: Color(0xFFFF4500), // Orange
        outfitSecondaryColor: Color(0xFF0000FF), // Blue
      ),
      
      // Fantasy avatar
      const EnhancedAvatar(
        bodyType: EnhancedAvatarBodyType.androgynous,
        skinTone: EnhancedAvatarSkinTone.lightCool,
        hairStyle: EnhancedAvatarHairStyle.curly,
        hairColor: EnhancedAvatarHairColor.purple,
        faceShape: EnhancedAvatarFaceShape.heart,
        outfit: EnhancedAvatarOutfit.fantasy,
        expression: AvatarExpression.surprised,
        pose: AvatarPose.superhero,
        outfitPrimaryColor: Color(0xFF8A2BE2), // Purple
        outfitSecondaryColor: Color(0xFFFFD700), // Gold
      ),
    ];
  }
}