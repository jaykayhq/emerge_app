import 'package:flutter/material.dart';

class PersonaConfig {
  final String name;
  final String avatarAsset;
  final Color accentColor;
  final String systemPrompt;
  final String greetingTemplate;

  const PersonaConfig({
    required this.name,
    required this.avatarAsset,
    required this.accentColor,
    required this.systemPrompt,
    required this.greetingTemplate,
  });
}
