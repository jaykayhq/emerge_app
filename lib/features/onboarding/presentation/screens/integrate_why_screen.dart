import 'package:emerge_app/core/theme/app_theme.dart';
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
          onPressed: () => context.pop(),
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
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(onboardingStateProvider.notifier)
                        .update((state) => state.copyWith(why: null));
                    context.push('/onboarding/anchors');
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
                  color: _controller.text.isNotEmpty
                      ? AppTheme.primary
                      : Colors.grey[800],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _controller.text.isNotEmpty
                        ? () {
                            ref
                                .read(onboardingStateProvider.notifier)
                                .update(
                                  (state) =>
                                      state.copyWith(why: _controller.text),
                                );
                            context.push('/onboarding/anchors');
                          }
                        : null,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Text(
                        'Set My Motivation',
                        style: GoogleFonts.splineSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _controller.text.isNotEmpty
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
