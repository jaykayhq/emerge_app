import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class AiReflectionsScreen extends ConsumerStatefulWidget {
  const AiReflectionsScreen({super.key});

  @override
  ConsumerState<AiReflectionsScreen> createState() =>
      _AiReflectionsScreenState();
}

class _AiReflectionsScreenState extends ConsumerState<AiReflectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final aiService = ref.watch(aiServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'AI Reflections',
          style: GoogleFonts.splineSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Identity Affirmation',
              Icons.fingerprint,
            ),
            const Gap(16),
            FutureBuilder<String>(
              future: aiService.getIdentityAffirmation('context'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _InsightCard(
                  text: snapshot.data ?? 'Analyzing...',
                  color: Colors.purpleAccent,
                  icon: Icons.psychology,
                ).animate().fadeIn().slideX();
              },
            ),
            const Gap(32),
            _buildSectionHeader(context, 'Pattern Recognition', Icons.timeline),
            const Gap(16),
            FutureBuilder<String>(
              future: aiService.getPatternRecognition([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _InsightCard(
                  text: snapshot.data ?? 'Analyzing patterns...',
                  color: Colors.blueAccent,
                  icon: Icons.insights,
                ).animate().fadeIn(delay: 200.ms).slideX();
              },
            ),
            const Gap(32),
            _buildSectionHeader(context, 'Personalized Challenges', Icons.flag),
            const Gap(16),
            FutureBuilder<List<String>>(
              future: aiService.getPersonalizedChallenges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final challenges = snapshot.data ?? [];
                return Column(
                  children: challenges
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InsightCard(
                            text: c,
                            color: Colors.orangeAccent,
                            icon: Icons.star,
                          ),
                        ),
                      )
                      .toList(),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const Gap(12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _InsightCard({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
