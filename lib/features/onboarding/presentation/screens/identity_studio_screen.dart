import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class IdentityStudioScreen extends ConsumerStatefulWidget {
  const IdentityStudioScreen({super.key});

  @override
  ConsumerState<IdentityStudioScreen> createState() =>
      _IdentityStudioScreenState();
}

class _IdentityStudioScreenState extends ConsumerState<IdentityStudioScreen> {
  // Page 0: Archetype Selection, Page 1: Motive Selection
  final PageController _stepController = PageController();

  // Carousel controller for Archetypes
  final PageController _carouselController = PageController(
    viewportFraction: 0.75,
  );

  int _currentStep = 0;
  int _focusedArchetypeIndex = 0;

  UserArchetype? _selectedArchetype;
  String? _selectedMotive;
  final TextEditingController _customMotiveController = TextEditingController();
  bool _isCustomMotive = false;
  UserArchetype? _revealingArchetype;

  final List<ArchetypeTheme> _themes = ArchetypeTheme.allThemes;

  @override
  void dispose() {
    _stepController.dispose();
    _carouselController.dispose();
    _customMotiveController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedArchetype != null) {
        _stepController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic, // Ultra-smooth curve
        );
        setState(() => _currentStep = 1);
      }
    } else {
      _completeIdentityStudio();
    }
  }

  void _previousStep() {
    if (_currentStep == 1) {
      _stepController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep = 0);
    }
  }

  void _completeIdentityStudio() {
    final motiveToSave = _isCustomMotive
        ? _customMotiveController.text.trim()
        : _selectedMotive;

    if (_selectedArchetype == null ||
        (motiveToSave == null && !_isCustomMotive) ||
        (_isCustomMotive && motiveToSave!.isEmpty)) {
      return;
    }

    // Update onboarding state
    final state = ref.read(onboardingStateProvider);
    ref.read(onboardingStateProvider.notifier).state = state.copyWith(
      selectedArchetype: _selectedArchetype,
      motive: motiveToSave,
    );

    // PERSIST PROGRESS: Complete the first milestone (Archetype/Motive)
    ref.read(onboardingControllerProvider.notifier).completeMilestone(0);

    // Navigate to map attributes screen
    context.push('/onboarding/map-attributes');
  }

  void _showArchetypeDetails(ArchetypeTheme theme) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A).withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2BEE79).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    theme.journeyIcon,
                    color: const Color(0xFF2BEE79),
                    size: 28,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.archetypeName.toUpperCase(),
                        style: GoogleFonts.splineSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        theme.tagline,
                        style: GoogleFonts.splineSans(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(32),
            _buildInfoSection('CORE STRENGTHS', theme.strengths),
            const Gap(24),
            _buildInfoSection('THE CHALLENGE', theme.weaknesses),
            const Gap(24),
            Text(
              'IDENTITY RITUAL',
              style: GoogleFonts.splineSans(
                color: const Color(0xFF2BEE79),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                theme.habitLoop,
                style: GoogleFonts.splineSans(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const Gap(48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'CLOSE',
                  style: GoogleFonts.splineSans(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cosmic purple background
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A1A), // cosmicVoidDark
              Color(0xFF1A0A2A), // cosmicVoidCenter
              Color(0xFF2A1A3A), // cosmicMidPurple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Progress / Back Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                        ),
                        onPressed: _previousStep,
                      )
                    else
                      const SizedBox(width: 48), // Spacer

                    const Spacer(),
                    // Subtle progress indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        'STEP ${_currentStep + 1} OF 4',
                        style: GoogleFonts.splineSans(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _stepController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildArchetypeCarousel(),
                    _buildMotiveSelection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 1: ARCHETYPE CAROUSEL
  // ===========================================================================
  Widget _buildArchetypeCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Gap(20),
        Text(
          'Select Your Identity',
          style: GoogleFonts.splineSans(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0),

        const Gap(8),

        Text(
          'Which path calls to you?',
          style: GoogleFonts.splineSans(color: Colors.white54, fontSize: 16),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

        const Gap(40),

        // The Carousel
        Expanded(
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _themes.length,
            onPageChanged: (index) {
              setState(() {
                _focusedArchetypeIndex = index;
                _selectedArchetype = _themes[index].archetype;
              });
              HapticFeedback.selectionClick();
            },
            itemBuilder: (context, index) {
              final theme = _themes[index];
              return AnimatedBuilder(
                animation: _carouselController,
                builder: (context, child) {
                  // Calculate scale/opacity for parallax/focus effect
                  double pageOffset = 0;
                  try {
                    pageOffset = _carouselController.page! - index;
                  } catch (e) {
                    pageOffset = _focusedArchetypeIndex.toDouble() - index;
                  }

                  final scale = (1 - (pageOffset.abs() * 0.2)).clamp(0.8, 1.0);
                  final opacity = (1 - (pageOffset.abs() * 0.5)).clamp(
                    0.3,
                    1.0,
                  );

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: GestureDetector(
                        onLongPress: () {
                          setState(() => _revealingArchetype = theme.archetype);
                          HapticFeedback.heavyImpact();
                        },
                        onLongPressEnd: (_) {
                          setState(() => _revealingArchetype = null);
                        },
                        onTap: () {
                          _carouselController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                          setState(() => _selectedArchetype = theme.archetype);
                        },
                        child: _buildArchetypeCard(theme),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const Gap(16),

        // Tap to learn more (Fixed below carousel)
        GestureDetector(
          onTap: () => _showArchetypeDetails(_themes[_focusedArchetypeIndex]),
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: 0.6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF2BEE79),
                  size: 16,
                ),
                const Gap(8),
                Text(
                  'Tap to learn more',
                  style: GoogleFonts.splineSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const Gap(16),

        // Continue Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedArchetype != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BEE79), // Neon Teal
                foregroundColor: const Color(0xFF05100B), // Dark text
                disabledBackgroundColor: Colors.white10,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'THIS IS ME',
                style: GoogleFonts.splineSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildArchetypeCard(ArchetypeTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: _selectedArchetype == theme.archetype
            ? Border.all(color: const Color(0xFF2BEE79), width: 2)
            : Border.all(color: Colors.white10),
        boxShadow: [
          if (_selectedArchetype == theme.archetype)
            BoxShadow(
              color: const Color(0xFF2BEE79).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
        ],
        image: DecorationImage(
          image: AssetImage(theme.assetPath),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(
            Colors.black26, // Dim background slightly for text pop
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay for Text Readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(theme.journeyIcon, color: Colors.white, size: 14),
                      const Gap(6),
                      Text(
                        theme.archetypeName.toUpperCase(),
                        style: GoogleFonts.splineSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Text(
                  theme.tagline,
                  style: GoogleFonts.splineSans(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const Gap(8),
                Text(
                  '"${theme.dailyMantra}"',
                  style: GoogleFonts.splineSans(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Info Overlay (Revealed on Long Press)
          if (_revealingArchetype == theme.archetype)
            Positioned.fill(
              child:
                  Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black.withValues(alpha: 0.85),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.1),
                              BlendMode.dst,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IDENTITY DETAILS',
                                    style: GoogleFonts.splineSans(
                                      color: const Color(0xFF2BEE79),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const Gap(16),
                                  _buildInfoSection(
                                    'STRENGTHS',
                                    theme.strengths,
                                  ),
                                  const Gap(16),
                                  _buildInfoSection(
                                    'CHALLENGES',
                                    theme.weaknesses,
                                  ),
                                  const Gap(16),
                                  Text(
                                    'HABIT LOOP',
                                    style: GoogleFonts.splineSans(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    theme.habitLoop,
                                    style: GoogleFonts.splineSans(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                      ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.splineSans(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const Gap(4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF2BEE79))),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.splineSans(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: MOTIVE SELECTION
  // ===========================================================================
  Widget _buildMotiveSelection() {
    final theme = ArchetypeTheme.forArchetype(
      _selectedArchetype ?? UserArchetype.athlete,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // Elastic scroll
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(20),
          Text(
            'What drives you?',
            style: GoogleFonts.splineSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn().moveY(begin: 10, end: 0),

          const Gap(8),

          Text(
            'Choose a motive or define your own.',
            style: GoogleFonts.splineSans(color: Colors.white54, fontSize: 16),
          ).animate().fadeIn(delay: 100.ms),

          const Gap(32),

          // Defined Motives
          ...theme.suggestedMotives.map((motive) {
            final isSelected = _selectedMotive == motive && !_isCustomMotive;
            return _buildMotiveCard(
              title: motive,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedMotive = motive;
                  _isCustomMotive = false;
                  _customMotiveController.clear();
                });
                HapticFeedback.lightImpact();
              },
            );
          }),

          // Custom Motive
          AnimatedContainer(
            duration: 300.ms,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _isCustomMotive
                  ? const Color(0xFF1A2C24)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCustomMotive
                    ? const Color(0xFF2BEE79)
                    : Colors.white10,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customMotiveController,
                    style: GoogleFonts.splineSans(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write my own...',
                      hintStyle: GoogleFonts.splineSans(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onTap: () {
                      setState(() {
                        _isCustomMotive = true;
                        _selectedMotive = null;
                      });
                    },
                    onChanged: (val) {
                      setState(() {}); // Rebuild to enable button
                    },
                  ),
                ),
                if (_isCustomMotive)
                  const Icon(Icons.edit, color: Color(0xFF2BEE79), size: 20)
                else
                  const Icon(Icons.edit, color: Colors.white30, size: 20),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const Gap(24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  (_selectedMotive != null ||
                      (_isCustomMotive &&
                          _customMotiveController.text.isNotEmpty))
                  ? _nextStep
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BEE79),
                foregroundColor: const Color(0xFF05100B),
                disabledBackgroundColor: Colors.white10,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'CONTINUE',
                style: GoogleFonts.splineSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const Gap(40), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildMotiveCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1A2C24) // Dark Green tint
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2BEE79)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.splineSans(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2BEE79),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).moveX(begin: 10, end: 0);
  }
}
