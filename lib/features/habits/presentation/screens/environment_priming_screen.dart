import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class EnvironmentPrimingScreen extends StatefulWidget {
  const EnvironmentPrimingScreen({super.key});

  @override
  State<EnvironmentPrimingScreen> createState() =>
      _EnvironmentPrimingScreenState();
}

class _EnvironmentPrimingScreenState extends State<EnvironmentPrimingScreen> {
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Lay out workout clothes', 'checked': false},
    {'title': 'Fill water bottle', 'checked': false},
    {'title': 'Place book on nightstand', 'checked': false},
    {'title': 'Clear desk surface', 'checked': false},
    {'title': 'Pack bag for tomorrow', 'checked': false},
    {'title': 'Set alarm for 6:00 AM', 'checked': false},
  ];

  double get _progress =>
      _tasks.where((t) => t['checked'] as bool).length / _tasks.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Prepare for Tomorrow'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header / Progress
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Evening Quest',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Text(
                  'Prime your environment for success.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const Gap(24),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const Gap(8),
                Text(
                  '${(_progress * 100).toInt()}% Ready',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Checklist
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tasks.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final isChecked = task['checked'] as bool;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      task['checked'] = !isChecked;
                    });
                  },
                  child: AnimatedContainer(
                    duration: 300.ms,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChecked
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isChecked
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isChecked ? AppTheme.primary : Colors.grey,
                        ),
                        const Gap(16),
                        Text(
                          task['title'] as String,
                          style: TextStyle(
                            color: isChecked ? Colors.white : Colors.white70,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX();
              },
            ),
          ),

          // Complete Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _progress == 1.0
                    ? () {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You are ready to conquer tomorrow!'),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white38,
                ),
                child: const Text(
                  'Complete Evening Ritual',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
