import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a single onboarding milestone step in the Timeline of Cues
///
/// These milestones appear as special "Next Action" cards in the dashboard
/// timeline for new users, guiding them through the 3-step onboarding flow:
/// 1. Choose archetype
/// 2. Select anchors
/// 3. Build personalized stacks
class OnboardingMilestone extends Equatable {
  /// Order of milestone in sequence (1-3)
  final int order;

  /// Display title for the milestone card
  final String title;

  /// Contextual description explaining what this step accomplishes
  final String description;

  /// Route path to navigate when user taps "Begin This Step"
  final String routePath;

  /// Icon to display in the milestone card badge
  final IconData icon;

  /// Whether user has completed this milestone
  final bool isCompleted;

  /// Whether this milestone can be skipped by the user
  final bool canSkip;

  /// Optional background image URL for hero card
  final String? backgroundImageUrl;

  const OnboardingMilestone({
    required this.order,
    required this.title,
    required this.description,
    required this.routePath,
    required this.icon,
    this.isCompleted = false,
    this.canSkip = true,
    this.backgroundImageUrl,
  });

  OnboardingMilestone copyWith({
    int? order,
    String? title,
    String? description,
    String? routePath,
    IconData? icon,
    bool? isCompleted,
    bool? canSkip,
    String? backgroundImageUrl,
  }) {
    return OnboardingMilestone(
      order: order ?? this.order,
      title: title ?? this.title,
      description: description ?? this.description,
      routePath: routePath ?? this.routePath,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      canSkip: canSkip ?? this.canSkip,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
    );
  }

  @override
  List<Object?> get props => [
    order,
    title,
    description,
    routePath,
    icon,
    isCompleted,
    canSkip,
    backgroundImageUrl,
  ];
}
