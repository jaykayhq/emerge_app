import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly, specificDays }

enum HabitDifficulty { easy, medium, hard }

enum HabitImpact { positive, negative, neutral }

enum HabitAttribute { strength, intellect, vitality, creativity, focus, spirit }

enum TimeOfDayPreference { morning, afternoon, evening, anytime }

class Habit extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String cue;
  final String routine;
  final String reward;
  final HabitFrequency frequency;
  final List<int> specificDays; // 1 = Monday, 7 = Sunday
  final TimeOfDay? reminderTime;
  final HabitDifficulty difficulty;
  final bool isArchived;
  final DateTime createdAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final HabitImpact impact;
  final String? stackParentId;
  final String? twoMinuteVersion;
  final List<String> identityTags;
  final bool contractActive;
  final HabitAttribute attribute;
  final String? imageUrl;
  final TimeOfDayPreference? timeOfDayPreference;
  final String? anchorHabitId;
  final int order;
  final String? location;
  final int timerDurationMinutes; // Default: 2 (Two-Minute Rule)
  final List<String> customRules; // User-defined habit rules
  final List<String> environmentPriming; // Environment priming tasks

  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.cue = '',
    this.routine = '',
    this.reward = '',
    this.frequency = HabitFrequency.daily,
    this.specificDays = const [],
    this.reminderTime,
    this.difficulty = HabitDifficulty.medium,
    this.isArchived = false,
    required this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.impact = HabitImpact.neutral,
    this.stackParentId,
    this.twoMinuteVersion,
    this.identityTags = const [],
    this.contractActive = false,
    this.attribute = HabitAttribute.vitality,
    this.imageUrl,
    this.timeOfDayPreference,
    this.anchorHabitId,
    this.order = 0,
    this.location,
    this.timerDurationMinutes = 2,
    this.customRules = const [],
    this.environmentPriming = const [],
  });

  static Habit empty() {
    return Habit(id: '', userId: '', title: '', createdAt: DateTime.now());
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? cue,
    String? routine,
    String? reward,
    HabitFrequency? frequency,
    List<int>? specificDays,
    TimeOfDay? reminderTime,
    HabitDifficulty? difficulty,
    bool? isArchived,
    DateTime? createdAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    HabitImpact? impact,
    String? stackParentId,
    String? twoMinuteVersion,
    List<String>? identityTags,
    bool? contractActive,
    HabitAttribute? attribute,
    String? imageUrl,
    TimeOfDayPreference? timeOfDayPreference,
    String? anchorHabitId,
    int? order,
    String? location,
    int? timerDurationMinutes,
    List<String>? customRules,
    List<String>? environmentPriming,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      cue: cue ?? this.cue,
      routine: routine ?? this.routine,
      reward: reward ?? this.reward,
      frequency: frequency ?? this.frequency,
      specificDays: specificDays ?? this.specificDays,
      reminderTime: reminderTime ?? this.reminderTime,
      difficulty: difficulty ?? this.difficulty,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      impact: impact ?? this.impact,
      stackParentId: stackParentId ?? this.stackParentId,
      twoMinuteVersion: twoMinuteVersion ?? this.twoMinuteVersion,
      identityTags: identityTags ?? this.identityTags,
      contractActive: contractActive ?? this.contractActive,
      attribute: attribute ?? this.attribute,
      imageUrl: imageUrl ?? this.imageUrl,
      timeOfDayPreference: timeOfDayPreference ?? this.timeOfDayPreference,
      anchorHabitId: anchorHabitId ?? this.anchorHabitId,
      order: order ?? this.order,
      location: location ?? this.location,
      timerDurationMinutes: timerDurationMinutes ?? this.timerDurationMinutes,
      customRules: customRules ?? this.customRules,
      environmentPriming: environmentPriming ?? this.environmentPriming,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    cue,
    routine,
    reward,
    frequency,
    specificDays,
    reminderTime,
    difficulty,
    isArchived,
    createdAt,
    currentStreak,
    longestStreak,
    lastCompletedDate,
    impact,
    stackParentId,
    twoMinuteVersion,
    identityTags,
    contractActive,
    attribute,
    imageUrl,
    timeOfDayPreference,
    anchorHabitId,
    order,
    location,
    timerDurationMinutes,
    customRules,
    environmentPriming,
  ];
}
