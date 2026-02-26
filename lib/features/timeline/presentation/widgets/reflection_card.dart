import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/features/timeline/presentation/providers/reflection_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card for logging daily reflections with a slider for mood/progress
class ReflectionCard extends ConsumerStatefulWidget {
  final Function(double value, String? note)? onLogReflection;

  const ReflectionCard({super.key, this.onLogReflection});

  @override
  ConsumerState<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends ConsumerState<ReflectionCard> {
  double _progressValue = 0.5;
  bool _showTextField = false;
  bool _isLogged = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfLoggedToday();
  }

  void _checkIfLoggedToday() {
    final loggedState = ref.read(todayReflectionStateProvider);
    setState(() {
      _isLogged = loggedState;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      glowColor: EmergeColors.yellow,
      child: _isLogged ? _buildLoggedState() : _buildUnloggedState(),
    );
  }

  Widget _buildUnloggedState() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: EmergeColors.yellow, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reflection',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Close the loop on your day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EmergeColors.tealMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'How do you feel about your progress?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
                  setState(() => _isLogged = true);
                  ref.read(todayReflectionStateProvider.notifier).setLogged(true);
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

  Widget _buildLoggedState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: EmergeColors.teal,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Reflection Logged!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getMoodEmoji(_progressValue),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              setState(() => _isLogged = false);
              ref.read(todayReflectionStateProvider.notifier).setLogged(false);
            },
            icon: Icon(
              Icons.edit,
              color: EmergeColors.teal,
              size: 18,
            ),
            label: Text(
              'Edit Reflection',
              style: TextStyle(color: EmergeColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(double value) {
    if (value >= 0.8) return '🔥 Feeling Great';
    if (value >= 0.6) return '😊 Feeling Good';
    if (value >= 0.4) return '😐 Feeling Okay';
    if (value >= 0.2) return '😔 Feeling Low';
    return '😢 Struggling';
  }
}
