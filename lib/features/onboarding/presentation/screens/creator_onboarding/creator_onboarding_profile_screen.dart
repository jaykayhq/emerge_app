import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_app_icon.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/creator_onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Step 2 of creator onboarding — bio + speciality tags.
///
/// The bio is a short paragraph (max 280 chars enforced by validator)
/// shown on the creator's public profile. Speciality tags are searchable
/// keywords that help users discover the creator in browse views.
class CreatorOnboardingProfileScreen extends ConsumerStatefulWidget {
  const CreatorOnboardingProfileScreen({super.key});

  @override
  ConsumerState<CreatorOnboardingProfileScreen> createState() =>
      _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends ConsumerState<CreatorOnboardingProfileScreen> {
  static const int _maxBioChars = 280;
  static const int _maxTags = 8;
  static const int _maxTagLength = 24;

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _bioController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final raw = _tagController.text.trim();
    if (raw.isEmpty) return;
    if (raw.length > _maxTagLength) return;
    ref.read(creatorOnboardingDraftControllerProvider.notifier).addTag(raw);
    _tagController.clear();
    setState(() {});
  }

  Future<void> _next() async {
    ref
        .read(creatorOnboardingDraftControllerProvider.notifier)
        .setBio(_bioController.text);
    try {
      await ref.read(saveCreatorOnboardingProgressProvider(progress: 2).future);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      return;
    }
    if (mounted) context.go('/onboarding/creator/reveal');
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(
      creatorOnboardingDraftControllerProvider.select(
        (s) => s.specialityTags,
      ),
    );
    final remaining = _maxBioChars - _bioController.text.length;

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.amber.withValues(alpha: 0.12),
                    EmergeColors.violet.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: EmergeAppIcon(size: 64)),
                  const Gap(16),
                  Text(
                    'Step 2 of 3',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'Tell us about your work',
                    style: GoogleFonts.splineSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(24),
                  Text(
                    'Bio',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Gap(8),
                  TextField(
                    controller: _bioController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    maxLength: _maxBioChars,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          'What do you teach? Who is it for? What makes your approach different?',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor:
                          EmergeColors.background.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: EmergeColors.hexLine,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: EmergeColors.hexLine,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.amber,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$remaining left',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: remaining < 20
                            ? Colors.orangeAccent
                            : Colors.white38,
                      ),
                    ),
                  ),
                  const Gap(24),
                  Text(
                    'Speciality tags (max $_maxTags)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          style: const TextStyle(color: Colors.white),
                          maxLength: _maxTagLength,
                          onSubmitted: (_) => _addTag(),
                          decoration: InputDecoration(
                            hintText: 'e.g. Strength, Mobility, Recovery',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: EmergeColors.background
                                .withValues(alpha: 0.6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: EmergeColors.hexLine,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: EmergeColors.hexLine,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                                width: 1.5,
                              ),
                            ),
                            counterText: '',
                          ),
                        ),
                      ),
                      const Gap(8),
                      IconButton(
                        onPressed: tags.length >= _maxTags ? null : _addTag,
                        icon: const Icon(Icons.add_circle, color: Colors.amber),
                        tooltip: 'Add tag',
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in tags)
                          Chip(
                            label: Text(t),
                            onDeleted: () {
                              ref
                                  .read(
                                    creatorOnboardingDraftControllerProvider
                                        .notifier,
                                  )
                                  .removeTag(t);
                              setState(() {});
                            },
                            backgroundColor:
                                Colors.amber.withValues(alpha: 0.15),
                            deleteIconColor: Colors.amber,
                            side: const BorderSide(color: Colors.amber),
                            labelStyle: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.05),
                  ],
                  const Gap(40),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),
                  const Gap(16),
                  TextButton(
                    onPressed: () => context.go('/onboarding/creator/reveal'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
