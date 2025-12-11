import 'package:equatable/equatable.dart';

class OnboardingConfig extends Equatable {
  final List<ArchetypeConfig> archetypes;
  final List<AttributeConfig> attributes;
  final List<HabitSuggestion> habitSuggestions;

  const OnboardingConfig({
    required this.archetypes,
    required this.attributes,
    required this.habitSuggestions,
  });

  @override
  List<Object?> get props => [archetypes, attributes, habitSuggestions];
}

class ArchetypeConfig extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  const ArchetypeConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  factory ArchetypeConfig.fromJson(Map<String, dynamic> json) {
    return ArchetypeConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  @override
  List<Object?> get props => [id, title, description, imageUrl];
}

class AttributeConfig extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;

  const AttributeConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory AttributeConfig.fromJson(Map<String, dynamic> json) {
    return AttributeConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
    );
  }

  @override
  List<Object?> get props => [id, title, description, icon, color];
}

class HabitSuggestion extends Equatable {
  final String id;
  final String title;
  final String icon;

  const HabitSuggestion({
    required this.id,
    required this.title,
    required this.icon,
  });

  factory HabitSuggestion.fromJson(Map<String, dynamic> json) {
    return HabitSuggestion(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String,
    );
  }

  @override
  List<Object?> get props => [id, title, icon];
}
