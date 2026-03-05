import 'dart:ui';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class CreateSoloChallengeDialog extends ConsumerStatefulWidget {
  const CreateSoloChallengeDialog({super.key});

  @override
  ConsumerState<CreateSoloChallengeDialog> createState() =>
      _CreateSoloChallengeDialogState();
}

class _CreateSoloChallengeDialogState
    extends ConsumerState<CreateSoloChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  ChallengeCategory _category = ChallengeCategory.fitness;
  int _durationDays = 7;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Must be logged in to create a challenge'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final challengeId = const Uuid().v4();

      // Auto-generate some basic steps based on duration
      final steps = List.generate(
        _durationDays,
        (i) => ChallengeStep(
          day: i + 1,
          title: 'Day ${i + 1}',
          description: 'Complete today\'s challenge goal.',
        ),
      );

      final newChallenge = Challenge(
        id: challengeId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imageUrl:
            'assets/images/challenges/${_category.name}_custom.png', // Fallback or placeholder path
        reward: '${_durationDays * 10} XP',
        participants: 1, // You are the first participant
        daysLeft: _durationDays,
        totalDays: _durationDays,
        currentDay: 0,
        status: ChallengeStatus.active, // Auto-starts upon creation
        xpReward: _durationDays * 10,
        isFeatured: false,
        isTeamChallenge: false, // SOLO CHALLENGE CONSTRAINT
        buddyValidationRequired: false,
        steps: steps,
        category: _category,
      );

      await ref
          .read(challengeRepositoryProvider)
          .createSoloChallenge(user.uid, newChallenge);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo challenge forged!'),
          backgroundColor: EmergeColors.teal,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoryPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: EmergeColors.teal.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT CATEGORY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: ChallengeCategory.values
                  .where((c) => c != ChallengeCategory.all)
                  .map(
                    (category) => GestureDetector(
                      onTap: () {
                        setState(() => _category = category);
                        context.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _category == category
                              ? EmergeColors.teal
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _category == category
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          category.name.toUpperCase(),
                          style: TextStyle(
                            color: _category == category
                                ? Colors.black
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker() {
    HapticFeedback.selectionClick();
    final durations = [7, 14, 21, 30];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: EmergeColors.yellow.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT DURATION',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: durations.map((days) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _durationDays = days);
                    context.pop();
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _durationDays == days
                          ? EmergeColors.yellow
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _durationDays == days
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$days d',
                      style: TextStyle(
                        color: _durationDays == days
                            ? Colors.black
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMainDialog(context),
                  const SizedBox(height: 24),
                  _buildForgeButton(context),
                ],
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: EmergeColors.teal.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EmergeColors.teal.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDialog(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: EmergeColors.teal.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: EmergeColors.teal.withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: EmergeColors.teal, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'SOLO CHALLENGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'CHALLENGE NAME...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your personal challenge...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactInput(
                      icon: Icons.category,
                      label: _category.name.toUpperCase(),
                      color: EmergeColors.teal,
                      onTap: _showCategoryPicker,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactInput(
                      icon: Icons.timer,
                      label: '$_durationDays DAYS',
                      color: EmergeColors.yellow,
                      onTap: _showDurationPicker,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgeButton(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _createChallenge,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: EmergeColors.teal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: EmergeColors.teal.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'FORGE CHALLENGE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}
