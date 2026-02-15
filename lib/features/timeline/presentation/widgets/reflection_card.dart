import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';

/// Card for logging daily reflections with a slider for mood/progress
class ReflectionCard extends StatefulWidget {
  final Function(double value, String? note)? onLogReflection;

  const ReflectionCard({super.key, this.onLogReflection});

  @override
  State<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<ReflectionCard> {
  double _progressValue = 0.5;
  bool _showTextField = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.hexLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: EmergeColors.yellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reflection',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textMainDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'How do you feel about your progress?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMainDark),
          ),
          const SizedBox(height: 12),
          // Slider with emoji indicators
          Row(
            children: [
              Text('😔', style: TextStyle(fontSize: 20)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _getSliderColor(),
                    inactiveTrackColor: _getSliderColor().withValues(
                      alpha: 0.2,
                    ),
                    thumbColor: _getSliderColor(),
                    overlayColor: _getSliderColor().withValues(alpha: 0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _progressValue,
                    onChanged: (value) {
                      setState(() => _progressValue = value);
                    },
                  ),
                ),
              ),
              Text('🔥', style: TextStyle(fontSize: 20)),
            ],
          ),

          // Optional note field
          if (_showTextField) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(color: AppTheme.textMainDark),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: TextStyle(color: AppTheme.textSecondaryDark),
                filled: true,
                fillColor: EmergeColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EmergeColors.hexLine),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EmergeColors.hexLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EmergeColors.teal),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              if (!_showTextField)
                TextButton.icon(
                  onPressed: () => setState(() => _showTextField = true),
                  icon: Icon(
                    Icons.add,
                    color: AppTheme.textSecondaryDark,
                    size: 18,
                  ),
                  label: Text(
                    'Add note',
                    style: TextStyle(color: AppTheme.textSecondaryDark),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  widget.onLogReflection?.call(
                    _progressValue,
                    _noteController.text.isEmpty ? null : _noteController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reflection logged! 🎉'),
                      backgroundColor: EmergeColors.teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Log'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSliderColor() {
    if (_progressValue < 0.33) {
      return EmergeColors.coral;
    } else if (_progressValue < 0.66) {
      return EmergeColors.yellow;
    } else {
      return EmergeColors.teal;
    }
  }
}
