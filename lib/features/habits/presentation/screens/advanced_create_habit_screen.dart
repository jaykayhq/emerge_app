import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_template_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class AdvancedCreateHabitScreen extends ConsumerStatefulWidget {
  const AdvancedCreateHabitScreen({super.key});

  @override
  ConsumerState<AdvancedCreateHabitScreen> createState() =>
      _AdvancedCreateHabitScreenState();
}

class _AdvancedCreateHabitScreenState
    extends ConsumerState<AdvancedCreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  HabitFrequency _frequency = HabitFrequency.daily;
  final List<int> _specificDays = [];
  TimeOfDayPreference _timeOfDay = TimeOfDayPreference.morning;
  TimeOfDay? _specificTime;
  String? _anchorHabitId;
  HabitAttribute _attribute = HabitAttribute.vitality;
  String _identityStatement = "I will...";

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateIdentityStatement);
    _locationController.addListener(_updateIdentityStatement);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _updateIdentityStatement() {
    // Logic to construct statement: "I will [BEHAVIOR] at [TIME] in [LOCATION] to become [IDENTITY]"
    final behavior = _titleController.text.isEmpty
        ? '...'
        : _titleController.text;

    String timeString = "";
    if (_specificTime != null) {
      timeString = " at ${_specificTime!.format(context)}";
    } else {
      timeString = " in the ${_timeOfDay.name}";
    }

    final location = _locationController.text.isEmpty
        ? ""
        : " in ${_locationController.text}";

    setState(() {
      _identityStatement =
          "I will $behavior$timeString$location to become more ${_attribute.name}.";
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _specificTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _specificTime) {
      setState(() {
        _specificTime = picked;
        _updateIdentityStatement();
      });
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        }
        return;
      }

      final newHabit = Habit(
        id: const Uuid().v4(),
        userId: user.uid,
        title: _titleController.text,
        frequency: _frequency,
        specificDays: _specificDays,
        timeOfDayPreference: _timeOfDay,
        reminderTime: _specificTime,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        anchorHabitId: _anchorHabitId,
        attribute: _attribute,
        createdAt: DateTime.now(),
        difficulty: HabitDifficulty.medium,
      );

      try {
        // Use the createHabit provider which connects to gamification system
        await ref.read(createHabitProvider(newHabit).future);

        AppLogger.i(
          'Successfully created habit from Advanced Create: ${newHabit.id}',
        );

        // Store context reference to avoid async gap issues
        if (context.mounted) {
          final contextRef = context;

          // Show success toast
          if (contextRef.mounted) {
            ScaffoldMessenger.of(contextRef).showSnackBar(
              const SnackBar(content: Text('Habit created successfully!')),
            );
          }
          contextRef.pop(); // Return to previous screen
        }
      } catch (e, s) {
        AppLogger.e('Error creating habit from Advanced Create', e, s);
        if (context.mounted) {
          final contextRef = context;
          ScaffoldMessenger.of(
            contextRef,
          ).showSnackBar(SnackBar(content: Text('Error creating habit: $e')));
        }
      }
    }
  }

  void _applyTemplate(HabitTemplate template) {
    setState(() {
      _titleController.text = template.title;
      // Map time of day
      switch (template.timeOfDay.toLowerCase()) {
        case 'morning':
          _timeOfDay = TimeOfDayPreference.morning;
          break;
        case 'afternoon':
          _timeOfDay = TimeOfDayPreference.afternoon;
          break;
        case 'evening':
          _timeOfDay = TimeOfDayPreference.evening;
          break;
        case 'night':
          _timeOfDay = TimeOfDayPreference.evening;
          break;
        default:
          _timeOfDay = TimeOfDayPreference.anytime;
      }
      // Map frequency
      if (template.frequency.toLowerCase() == 'weekly') {
        _frequency = HabitFrequency.weekly;
      } else {
        _frequency = HabitFrequency.daily;
      }
      _updateIdentityStatement();
    });
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied "${template.title}" template'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Habit'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Identity Statement Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _identityStatement,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Habit Templates Carousel
            Builder(
              builder: (context) {
                final userProfile = ref
                    .watch(userStatsStreamProvider)
                    .valueOrNull;
                final archetype = userProfile?.archetype ?? UserArchetype.none;
                return HabitTemplateCarousel(
                  archetype: archetype,
                  onTemplateSelected: _applyTemplate,
                );
              },
            ),
            const SizedBox(height: 24),

            // Habit Name
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g., Read 10 pages',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a habit name'
                  : null,
            ),
            const SizedBox(height: 24),

            // Frequency
            _buildSectionHeader('Frequency'),
            SegmentedButton<HabitFrequency>(
              segments: const [
                ButtonSegment(
                  value: HabitFrequency.daily,
                  label: Text('Daily'),
                ),
                ButtonSegment(
                  value: HabitFrequency.weekly,
                  label: Text('Weekly'),
                ),
                ButtonSegment(
                  value: HabitFrequency.specificDays,
                  label: Text('Specific'),
                ),
              ],
              selected: {_frequency},
              onSelectionChanged: (Set<HabitFrequency> newSelection) {
                setState(() {
                  _frequency = newSelection.first;
                });
              },
            ),
            if (_frequency == HabitFrequency.specificDays) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _specificDays.contains(day);
                  return FilterChip(
                    label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _specificDays.add(day);
                        } else {
                          _specificDays.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 24),

            // Time & Location (Implementation Intentions)
            _buildSectionHeader('Implementation Intentions'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _specificTime != null
                            ? _specificTime!.format(context)
                            : 'Set Time',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g., Bedroom',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.place),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: TimeOfDayPreference.values.map((time) {
                return ChoiceChip(
                  label: Text(time.name.toUpperCase()),
                  selected: _timeOfDay == time && _specificTime == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _timeOfDay = time;
                        _specificTime =
                            null; // Clear specific time if general preference selected
                        _updateIdentityStatement();
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Anchor Habit
            _buildSectionHeader('Anchor Habit (Optional)'),
            habitsAsync.when(
              data: (habits) {
                return DropdownButtonFormField<String>(
                  initialValue: _anchorHabitId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select an existing habit',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...habits.map(
                      (habit) => DropdownMenuItem(
                        value: habit.id,
                        child: Text(habit.title),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _anchorHabitId = value;
                      // Logic for anchor habit in identity statement could be added here
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error loading habits: $err'),
            ),
            const SizedBox(height: 24),

            // Identity Attribute
            _buildSectionHeader('Identity Attribute'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitAttribute.values.map((attr) {
                return ChoiceChip(
                  label: Text(attr.name.toUpperCase()),
                  selected: _attribute == attr,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _attribute = attr;
                        _updateIdentityStatement();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveHabit,
                child: const Text('Create Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
