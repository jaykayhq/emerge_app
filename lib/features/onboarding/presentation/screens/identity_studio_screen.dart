import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Combined archetype selection + motive screen
/// Replaces: onboarding_archetype_screen, identity_attributes_screen, integrate_why_screen
class IdentityStudioScreen extends ConsumerStatefulWidget {
  const IdentityStudioScreen({super.key});

  @override
  ConsumerState<IdentityStudioScreen> createState() =>
      _IdentityStudioScreenState();
}

class _IdentityStudioScreenState extends ConsumerState<IdentityStudioScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  UserArchetype? _selectedArchetype;
  String? _selectedMotive;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeIdentityStudio();
    }
  }

  void _completeIdentityStudio() {
    if (_selectedArchetype == null) return;

    // Update onboarding state
    final state = ref.read(onboardingStateProvider);
    ref.read(onboardingStateProvider.notifier).state = state.copyWith(
      selectedArchetype: _selectedArchetype,
      motive: _selectedMotive,
    );

    // Navigate to first habit screen
    context.push('/onboarding/first-habit');
  }

  ArchetypeTheme? get _currentTheme => _selectedArchetype != null
      ? ArchetypeTheme.forArchetype(_selectedArchetype!)
      : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          // Animated background based on selected archetype
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    _currentTheme?.backgroundGradient ??
                    [EmergeColors.background, const Color(0xFF16213E)],
              ),
            ),
          ),

          // Hex mesh overlay
          const Positioned.fill(child: HexMeshBackground()),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _currentPage == 0 ? Icons.close : Icons.arrow_back,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          if (_currentPage == 0) {
                            context.pop();
                          } else {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(2, (index) {
                            return Container(
                              width: index == _currentPage ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: index == _currentPage
                                    ? _currentTheme?.primaryColor ??
                                          EmergeColors.teal
                                    : Colors.white24,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance back button
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _buildArchetypeSelectionPage(),
                      _buildMotiveSelectionPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchetypeSelectionPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Who do you wish\nto become?',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your identity path',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 32),

          // Archetype grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: ArchetypeTheme.allThemes.length,
              itemBuilder: (context, index) {
                final theme = ArchetypeTheme.allThemes[index];
                final isSelected = _selectedArchetype == theme.archetype;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedArchetype = theme.archetype);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.primaryColor : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? theme.primaryColor.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            theme.journeyIcon,
                            color: theme.primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          theme.archetypeName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            theme.tagline,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedArchetype != null ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _currentTheme?.primaryColor ?? EmergeColors.teal,
                  disabledBackgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotiveSelectionPage() {
    final theme = _currentTheme;
    if (theme == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      theme.journeyIcon,
                      color: theme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      theme.archetypeName,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'What drives you?',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Understanding your "why" keeps you going',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 32),

          // Motive options
          Expanded(
            child: ListView.separated(
              itemCount: theme.suggestedMotives.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final motive = theme.suggestedMotives[index];
                final isSelected = _selectedMotive == motive;

                return GestureDetector(
                  onTap: () => setState(() => _selectedMotive = motive),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? theme.primaryColor : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            motive,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedMotive != null ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  disabledBackgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
