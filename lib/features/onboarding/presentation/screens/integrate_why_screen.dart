import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class IntegrateWhyScreen extends ConsumerStatefulWidget {
  const IntegrateWhyScreen({super.key});

  @override
  ConsumerState<IntegrateWhyScreen> createState() => _IntegrateWhyScreenState();
}

class _IntegrateWhyScreenState extends ConsumerState<IntegrateWhyScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnalyzing = false;

  final List<String> _suggestions = [
    "To feel more in control",
    "To build a legacy",
    "To find inner peace",
    "To maximize my potential",
    "To be a better leader",
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isAnalyzing ? null : () => context.pop(),
        ),
        title: Text(
          'Step 3 of 5',
          style: GoogleFonts.splineSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 3 / 5, // Step 3 of 5
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.vitalityGreen,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Source of Your Power',
                style: GoogleFonts.splineSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Why are you here? What drives you?',
                style: GoogleFonts.splineSans(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                maxLines: 5,
                enabled: !_isAnalyzing,
                style: GoogleFonts.splineSans(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'I want to build habits because...',
                  hintStyle: GoogleFonts.splineSans(color: Colors.grey[600]),
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              if (_isAnalyzing)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'AI is crystalizing your intent...',
                        style: GoogleFonts.splineSans(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Suggestions:',
                  style: GoogleFonts.splineSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((suggestion) {
                    return ActionChip(
                      label: Text(
                        suggestion,
                        style: GoogleFonts.splineSans(color: Colors.white),
                      ),
                      backgroundColor: AppTheme.surfaceDark,
                      onPressed: () {
                        _controller.text = suggestion;
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: _isAnalyzing
                      ? null
                      : () async {
                          ref
                              .read(onboardingStateProvider.notifier)
                              .update((state) => state.copyWith(why: null));
                          await ref
                              .read(onboardingControllerProvider.notifier)
                              .skipMilestone(2);
                          if (context.mounted) {
                            context.push('/onboarding/anchors');
                          }
                        },
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.splineSans(
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: _controller.text.isNotEmpty && !_isAnalyzing
                      ? AppTheme.primary
                      : Colors.grey[800],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_controller.text.isNotEmpty && !_isAnalyzing)
                        ? () async {
                            setState(() {
                              _isAnalyzing = true;
                            });

                            // 1. Get Enhanced Why from AI
                            final userWhy = _controller.text;
                            final aiService = ref.read(
                              aiPersonalizationServiceProvider,
                            );

                            // Fetch Identity Context
                            final onboardingState = ref.read(
                              onboardingStateProvider,
                            );
                            final archetype =
                                onboardingState.selectedArchetype?.name;
                            final attributes = onboardingState.attributes;

                            final enhancedWhy = await aiService.enhanceUserWhy(
                              userWhy,
                              archetype: archetype,
                              attributes: attributes,
                            );

                            // 2. Save to State
                            ref
                                .read(onboardingStateProvider.notifier)
                                .update(
                                  (state) => state.copyWith(why: enhancedWhy),
                                );

                            // 3. Complete Step
                            await ref
                                .read(onboardingControllerProvider.notifier)
                                .completeMilestone(2);

                            if (context.mounted) {
                              setState(() {
                                _isAnalyzing = false;
                              });
                              // Optional: Maybe show a dialog/flash message with the enhanced why?
                              // For now, proceed to Anchors
                              context.push('/onboarding/anchors');
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Text(
                        _isAnalyzing ? 'Analyzing...' : 'Set My Motivation',
                        style: GoogleFonts.splineSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (_controller.text.isNotEmpty && !_isAnalyzing)
                              ? AppTheme.backgroundDark
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
