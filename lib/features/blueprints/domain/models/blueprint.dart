import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

enum BlueprintDifficulty { beginner, intermediate, advanced }

class BlueprintHabit extends Equatable {
  final String title;
  final String? timeOfDay; // 'Morning', 'Afternoon', 'Evening'
  final TimeOfDay? defaultTime;
  final HabitAttribute attribute;
  final String frequency;

  const BlueprintHabit({
    required this.title,
    this.timeOfDay,
    this.defaultTime,
    this.attribute = HabitAttribute.vitality,
    this.frequency = 'Daily',
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'timeOfDay': timeOfDay,
        'defaultTime': defaultTime != null
            ? '${defaultTime!.hour}:${defaultTime!.minute}'
            : null,
        'attribute': attribute.name,
        'frequency': frequency,
      };

  factory BlueprintHabit.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return BlueprintHabit(
      title: map['title'] ?? '',
      timeOfDay: map['timeOfDay'],
      defaultTime: parseTime(map['defaultTime']),
      attribute: HabitAttribute.values.firstWhere(
        (e) => e.name == map['attribute'],
        orElse: () => HabitAttribute.vitality,
      ),
      frequency: map['frequency'] ?? 'Daily',
    );
  }

  @override
  List<Object?> get props => [title, timeOfDay, defaultTime, attribute, frequency];
}

class Blueprint extends Equatable {
  final String id;
  final String creatorUserId;
  final String creatorName;
  final String creatorArchetype; // e.g. 'Scholar'
  final String title; // e.g. 'Morning Deep Work Stack'
  final String description;
  final List<BlueprintHabit> habits;
  final int adoptionCount;
  final DateTime createdAt;
  final String? imageUrl;
  final String category; // e.g. 'Athlete', 'Creator'
  final bool isPremium;
  final BlueprintDifficulty difficulty;

  const Blueprint({
    required this.id,
    required this.creatorUserId,
    required this.creatorName,
    required this.creatorArchetype,
    required this.title,
    required this.description,
    required this.habits,
    this.adoptionCount = 0,
    required this.createdAt,
    this.imageUrl,
    required this.category,
    this.isPremium = false,
    this.difficulty = BlueprintDifficulty.beginner,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'creatorUserId': creatorUserId,
        'creatorName': creatorName,
        'creatorArchetype': creatorArchetype,
        'title': title,
        'description': description,
        'habits': habits.map((h) => h.toMap()).toList(),
        'adoptionCount': adoptionCount,
        'createdAt': createdAt.toIso8601String(),
        'imageUrl': imageUrl,
        'category': category,
        'isPremium': isPremium,
        'difficulty': difficulty.name,
      };

  factory Blueprint.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {}
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    BlueprintDifficulty parseDifficulty(String? value) {
      return BlueprintDifficulty.values.firstWhere(
        (e) => e.name == value?.toLowerCase(),
        orElse: () => BlueprintDifficulty.beginner,
      );
    }

    return Blueprint(
      id: id,
      creatorUserId: map['creatorUserId'] as String? ?? 'system',
      creatorName: map['creatorName'] as String? ?? 'Emerge Official',
      creatorArchetype: map['creatorArchetype'] as String? ?? 'General',
      title: (map['title'] ?? map['blueprintName']) as String? ?? 'Untitled',
      description: map['description'] as String? ?? '',
      habits: (map['habits'] as List?)
              ?.map((h) => BlueprintHabit.fromMap(Map<String, dynamic>.from(h)))
              .toList() ??
          [],
      adoptionCount: (map['adoptionCount'] as int?) ?? 0,
      createdAt: parseCreatedAt(map['createdAt']),
      imageUrl: map['imageUrl'] as String?,
      category: (map['category'] ?? 'General') as String,
      isPremium: map['isPremium'] as bool? ?? false,
      difficulty: parseDifficulty(map['difficulty'] as String?),
    );
  }

  @override
  List<Object?> get props => [
        id,
        creatorUserId,
        creatorName,
        creatorArchetype,
        title,
        description,
        habits,
        adoptionCount,
        createdAt,
        imageUrl,
        category,
        isPremium,
        difficulty,
      ];
}
