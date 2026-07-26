import 'package:flutter/material.dart';

class IdentitySentenceBuilder extends StatelessWidget {
  final String action;
  final String time;
  final String location;
  final String frequency;
  final ValueChanged<String> onActionChanged;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<TimeOfDay>? onTimePicked;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onFrequencyChanged;

  const IdentitySentenceBuilder({
    super.key,
    required this.action,
    required this.time,
    required this.location,
    required this.frequency,
    required this.onActionChanged,
    required this.onTimeChanged,
    this.onTimePicked,
    required this.onLocationChanged,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am the type of person who',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillSegment(
              label: action.isEmpty ? 'action ►' : action,
              onTap: () => onActionChanged(''),
              isSet: action.isNotEmpty,
            ),
            _PillSegment(
              label: time.isEmpty ? 'at ... ►' : 'at $time',
              onTap: () => _showTimePicker(context),
              isSet: time.isNotEmpty,
            ),
            _PillSegment(
              label: location.isEmpty ? 'where ... ►' : 'in $location',
              onTap: () => onLocationChanged(''),
              isSet: location.isNotEmpty,
            ),
            _PillSegment(
              label: frequency.isEmpty ? 'how often ... ►' : frequency,
              onTap: () => _showFrequencyPicker(context),
              isSet: frequency.isNotEmpty,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && context.mounted) {
      onTimePicked?.call(picked);
      onTimeChanged(picked.format(context));
    }
  }

  void _showFrequencyPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['daily', 'weekly', 'weekdays', 'weekends', 'custom']
            .map((f) => ListTile(
                  title: Text(f),
                  onTap: () {
                    onFrequencyChanged(f);
                    Navigator.pop(ctx);
                  },
                ))
            .toList(),
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSet;

  const _PillSegment({
    required this.label,
    required this.onTap,
    this.isSet = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSet
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet
                ? Colors.cyanAccent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSet ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
