import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class BlueprintAdoptDialog extends StatefulWidget {
  final Blueprint blueprint;
  final Function(String? reminderTime) onAdopt;

  const BlueprintAdoptDialog({
    super.key,
    required this.blueprint,
    required this.onAdopt,
  });

  @override
  State<BlueprintAdoptDialog> createState() => _BlueprintAdoptDialogState();
}

class _BlueprintAdoptDialogState extends State<BlueprintAdoptDialog> {
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EmergeColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SET YOUR SCHEDULE',
              style: TextStyle(
                color: EmergeColors.teal,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const Gap(8),
            Text(
              'When will you commit?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            Text(
              'Apply this time to all ${widget.blueprint.habits.length} habits in this stack.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const Gap(24),
            _buildTimePicker(context),
            const Gap(32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      String? timeString;
                      if (_selectedTime != null) {
                        timeString =
                            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
                      }
                      widget.onAdopt(timeString);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EmergeColors.teal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ADOPT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: EmergeColors.teal,
                  onPrimary: Colors.black,
                  surface: EmergeColors.background,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedTime != null
                ? EmergeColors.teal.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: _selectedTime != null ? EmergeColors.teal : Colors.white54,
            ),
            const Gap(16),
            Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Select a time (Optional)',
              style: TextStyle(
                color: _selectedTime != null ? Colors.white : Colors.white54,
                fontSize: 16,
                fontWeight: _selectedTime != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (_selectedTime != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                onPressed: () => setState(() => _selectedTime = null),
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.white24,
              ),
          ],
        ),
      ),
    );
  }
}
