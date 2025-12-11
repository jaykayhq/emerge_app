import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class DownsizingWizard extends StatefulWidget {
  final String originalHabitTitle;

  const DownsizingWizard({super.key, required this.originalHabitTitle});

  @override
  State<DownsizingWizard> createState() => _DownsizingWizardState();
}

class _DownsizingWizardState extends State<DownsizingWizard> {
  String? _selectedOption;
  final _customController = TextEditingController();

  // Simple rule-based templates
  List<String> _getSuggestions(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('read')) {
      return ['Read 1 page', 'Read for 2 minutes', 'Open the book'];
    } else if (lowerTitle.contains('run') || lowerTitle.contains('jog')) {
      return ['Put on running shoes', 'Walk to the door', 'Run for 2 minutes'];
    } else if (lowerTitle.contains('meditate')) {
      return [
        'Take 3 deep breaths',
        'Sit on the cushion',
        'Meditate for 1 minute',
      ];
    } else if (lowerTitle.contains('write')) {
      return ['Write 1 sentence', 'Open the notebook', 'Write for 2 minutes'];
    } else if (lowerTitle.contains('gym') || lowerTitle.contains('workout')) {
      return ['Do 5 pushups', 'Pack gym bag', 'Drive to gym'];
    }
    return ['Do it for 2 minutes', 'Just start', 'Prepare the environment'];
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions(widget.originalHabitTitle);

    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Downsize to 2 Minutes',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          Text(
            'Make "${widget.originalHabitTitle}" so easy you can\'t say no.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Gap(24),
          Text('Suggestions:', style: Theme.of(context).textTheme.titleSmall),
          const Gap(8),
          ...suggestions.map((suggestion) {
            final isSelected = _selectedOption == suggestion;
            return ListTile(
              title: Text(suggestion),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                setState(() {
                  _selectedOption = suggestion;
                  _customController.clear();
                });
              },
            );
          }),
          const Gap(16),
          TextField(
            controller: _customController,
            decoration: const InputDecoration(
              labelText: 'Or write your own 2-minute version',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _selectedOption = value;
              });
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedOption != null && _selectedOption!.isNotEmpty
                  ? () {
                      context.pop(_selectedOption);
                    }
                  : null,
              child: const Text('Use This Version'),
            ),
          ),
        ],
      ),
    );
  }
}
