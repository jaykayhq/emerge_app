import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class BlueprintBuilderScreen extends ConsumerStatefulWidget {
  const BlueprintBuilderScreen({super.key});

  @override
  ConsumerState<BlueprintBuilderScreen> createState() => _BlueprintBuilderScreenState();
}

class _BlueprintBuilderScreenState extends ConsumerState<BlueprintBuilderScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _category = 'General';
  BlueprintDifficulty _difficulty = BlueprintDifficulty.beginner;
  
  final List<BlueprintHabit> _habits = [];
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Morning', 'Productivity', 'Fitness', 'Mindfulness', 'Learning', 'General'
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addHabit() {
    showDialog(
      context: context,
      builder: (ctx) {
        final titleCtrl = TextEditingController();
        String frequency = 'Daily';
        String timeOfDay = 'Morning';
        int timerMinutes = 0;
        String selectedAttribute = 'vitality';
        String integrationType = 'none';
        
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: const Color(0xFF13081E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: EmergeColors.neonTeal.withValues(alpha: 0.3)),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.add_task_rounded, color: EmergeColors.neonTeal),
                    Gap(12),
                    Text('Forge Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GlassmorphicInput(
                        child: TextField(
                          controller: titleCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Action Title (e.g., Deep Work)',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const Gap(16),
                      _GlassmorphicInput(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: frequency,
                            dropdownColor: const Color(0xFF13081E),
                            style: const TextStyle(color: Colors.white),
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            items: ['Daily', 'Weekly', 'Monthly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (v) => setState(() => frequency = v!),
                          ),
                        ),
                      ),
                      const Gap(16),
                      _GlassmorphicInput(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: timeOfDay,
                            dropdownColor: const Color(0xFF13081E),
                            style: const TextStyle(color: Colors.white),
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            items: ['Morning', 'Afternoon', 'Evening', 'Anytime'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() => timeOfDay = v!),
                          ),
                        ),
                      ),
                      const Gap(16),
                      // Timer Duration
                      const Text('TIMER (MINUTES)', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
                      const Gap(8),
                      Wrap(
                        spacing: 6,
                        children: [0, 2, 5, 10, 15, 20].map((m) {
                          final isSelected = timerMinutes == m;
                          return GestureDetector(
                            onTap: () => setState(() => timerMinutes = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? EmergeColors.neonTeal : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? EmergeColors.neonTeal : Colors.white10),
                              ),
                              child: Text(
                                m == 0 ? 'Off' : '${m}M',
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Gap(16),
                      // Attribute Selector
                      const Text('ATTRIBUTE', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
                      const Gap(8),
                      _GlassmorphicInput(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedAttribute,
                            dropdownColor: const Color(0xFF13081E),
                            style: const TextStyle(color: Colors.white),
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            items: HabitAttribute.values.map((a) => DropdownMenuItem(value: a.name, child: Text(a.name.toUpperCase()))).toList(),
                            onChanged: (v) => setState(() => selectedAttribute = v!),
                          ),
                        ),
                      ),
                      const Gap(16),
                      // Health Integration
                      const Text('HEALTH INTEGRATION', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
                      const Gap(8),
                      _GlassmorphicInput(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: integrationType,
                            dropdownColor: const Color(0xFF13081E),
                            style: const TextStyle(color: Colors.white),
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            items: [
                              const DropdownMenuItem(value: 'none', child: Text('None')),
                              const DropdownMenuItem(value: 'healthSteps', child: Row(children: [Icon(Icons.directions_walk, size: 16, color: Colors.green), SizedBox(width: 8), Text('Health Steps')])),
                              const DropdownMenuItem(value: 'screenTimeLimit', child: Row(children: [Icon(Icons.phone_android, size: 16, color: Colors.orange), SizedBox(width: 8), Text('Screen Time Limit')])),
                            ],
                            onChanged: (v) => setState(() => integrationType = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: EmergeColors.neonTeal, 
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      if (titleCtrl.text.trim().isNotEmpty) {
                        this.setState(() {
                          _habits.add(BlueprintHabit(
                            title: titleCtrl.text.trim(),
                            frequency: frequency,
                            timeOfDay: timeOfDay == 'Anytime' ? null : timeOfDay,
                            timerDurationMinutes: timerMinutes,
                            attribute: HabitAttribute.values.firstWhere(
                              (a) => a.name == selectedAttribute,
                              orElse: () => HabitAttribute.vitality,
                            ),
                            integrationType: integrationType == 'none'
                                ? HabitIntegrationType.none
                                : HabitIntegrationType.values.firstWhere(
                                    (e) => e.name == integrationType),
                          ));
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('FORGE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A blueprint without actions is just a dream. Add a habit.'),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userAuth = FirebaseAuth.instance.currentUser;
      if (userAuth == null) throw Exception('Not authenticated');

      final userProfile = await ref.read(userStatsStreamProvider.future);

      final blueprint = Blueprint(
        id: '',
        creatorUserId: userAuth.uid,
        creatorName: userAuth.displayName ?? 'Creator',
        creatorArchetype: userProfile.archetype.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        habits: _habits,
        createdAt: DateTime.now(),
        category: _category,
        difficulty: _difficulty,
        isCreatorBlueprint: true,
      );

      final repo = ref.read(blueprintRepositoryProvider);
      await repo.createBlueprint(blueprint);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✨ Blueprint forged into reality.'),
            backgroundColor: EmergeColors.neonTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('The forge failed. Try again.'),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.cosmicVoidDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: EmergeColors.cosmicVoidDark,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('FORGE BLUEPRINT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      EmergeColors.neonTeal.withValues(alpha: 0.2),
                      EmergeColors.cosmicVoidDark,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.architecture_rounded, size: 64, color: Colors.white24),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: 'I. THE CONCEPT', icon: Icons.lightbulb_outline_rounded),
                    const Gap(16),
                    _GlassmorphicInput(
                      child: TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'Blueprint Name',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'Identity requires a name' : null,
                      ),
                    ),
                    const Gap(16),
                    _GlassmorphicInput(
                      child: TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white70, height: 1.5),
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe the philosophy and expected transformation behind this routine...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                        validator: (v) => v!.trim().isEmpty ? "Give your followers a 'why'" : null,
                      ),
                    ),
                    const Gap(24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CATEGORY', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                              const Gap(8),
                              _GlassmorphicInput(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _category,
                                    dropdownColor: const Color(0xFF1A0A2A),
                                    style: const TextStyle(color: Colors.white),
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (v) => setState(() => _category = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DIFFICULTY', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                              const Gap(8),
                              _GlassmorphicInput(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<BlueprintDifficulty>(
                                    value: _difficulty,
                                    dropdownColor: const Color(0xFF1A0A2A),
                                    style: const TextStyle(color: Colors.white),
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    items: BlueprintDifficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name.toUpperCase()))).toList(),
                                    onChanged: (v) => setState(() => _difficulty = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(48),

                    const _SectionHeader(title: 'II. THE ACTIONS', icon: Icons.list_alt_rounded),
                    const Gap(16),
                    
                    if (_habits.isEmpty)
                      GestureDetector(
                        onTap: _addHabit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 40, color: Colors.white24),
                              const Gap(12),
                              const Text('No actions forged yet.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                              const Gap(4),
                              Text('Tap to add your first habit', style: TextStyle(color: EmergeColors.neonTeal.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._habits.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final h = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: EmergeColors.neonTeal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text('${idx + 1}', style: const TextStyle(color: EmergeColors.neonTeal, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(h.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('${h.frequency} · ${h.timeOfDay ?? "Anytime"}', style: const TextStyle(color: Colors.white54)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white38),
                              onPressed: () => setState(() => _habits.removeAt(idx)),
                            ),
                          ),
                        );
                      }),
                    
                    if (_habits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('ADD ANOTHER ACTION'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _addHabit,
                        ),
                      ),
                    
                    const Gap(64),

                    // Primary CTA
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: EmergeColors.neonTeal.withValues(alpha: 0.2 * _pulseAnimation.value),
                                blurRadius: 20 * _pulseAnimation.value,
                                spreadRadius: 2 * _pulseAnimation.value,
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            icon: _isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.local_fire_department_rounded),
                            label: const Text('EMIT TO WORLD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
                            style: FilledButton.styleFrom(
                              backgroundColor: EmergeColors.neonTeal,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(64),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                        );
                      }
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: EmergeColors.neonTeal, size: 20),
        const Gap(12),
        Text(
          title, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 2
          )
        ),
      ],
    );
  }
}

class _GlassmorphicInput extends StatelessWidget {
  final Widget child;

  const _GlassmorphicInput({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}
