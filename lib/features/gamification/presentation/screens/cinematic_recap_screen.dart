import 'package:confetti/confetti.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CinematicRecapScreen extends StatefulWidget {
  final int newLevel;
  final String userArchetype; // e.g., 'Warrior', 'Sage'
  final VoidCallback onDismiss;

  const CinematicRecapScreen({
    super.key,
    required this.newLevel,
    required this.userArchetype,
    required this.onDismiss,
  });

  @override
  State<CinematicRecapScreen> createState() => _CinematicRecapScreenState();
}

class _CinematicRecapScreenState extends State<CinematicRecapScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          // Background Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    EmergeColors.teal.withValues(alpha: 0.2),
                    EmergeColors.background.withValues(alpha: 0.8),
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // Main Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Animation
              const SizedBox(
                height: 120,
                width: 120,
                child: EmergeLogoWidget(size: 120),
              ),
              const SizedBox(height: 32),

              Text(
                'LEVEL UP!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: EmergeColors.teal,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'You are now a',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Level ${widget.newLevel} ${widget.userArchetype}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textMainDark,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 48),

              // Stats Summary (Placeholder)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EmergeColors.hexLine),
                ),
                child: Column(
                  children: [
                    _buildStatRow(context, 'Strength', '+5'),
                    _buildStatRow(context, 'Focus', '+3'),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [EmergeColors.teal, EmergeColors.violet],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EmergeColors.teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'CONTINUE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                EmergeColors.teal,
                EmergeColors.violet,
                EmergeColors.coral,
                EmergeColors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: EmergeColors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
