import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Temporary stub — fully implemented in Task 6.
class AttributeDetailScreen extends StatelessWidget {
  final HabitAttribute attribute;
  const AttributeDetailScreen({super.key, required this.attribute});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(attribute.name)));
}
