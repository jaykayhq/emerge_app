import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';

/// A premium visualizer that swaps between high-fidelity Growth and Decay screens
/// based on the user's premium status and habit-driven world entropy.
class ProWorldVisualizer extends ConsumerWidget {
  final String theme; // 'city' or 'forest'
  final double entropy;
  final int level;

  const ProWorldVisualizer({
    super.key,
    required this.theme,
    required this.entropy,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return isPremiumAsync.when(
      data: (isPremium) {
        if (!isPremium) {
          // Fallback to standard WorldVisualizer logic or a standard representation
          return _buildStandardView();
        }

        // Premium: Determine Growth vs Decay based on entropy (threshold: 0.3)
        final isDecay = entropy > 0.3;

        if (theme == 'city') {
          return isDecay ? _buildCityDecay() : _buildCityGrowth();
        } else if (theme == 'sanctuary') {
          return isDecay ? _buildForestDecay() : _buildForestGrowth();
        } else if (theme == 'cosmic') {
          return isDecay ? _buildCityDecay() : _buildCityDecay();
        } else {
          return isDecay ? _buildForestDecay() : _buildForestGrowth();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildStandardView(),
    );
  }

  Widget _buildStandardView() {
    // Current standard WorldVisualizer logic basically
    final safeStage = level.clamp(1, 5);
    final imagePath = 'assets/images/forest_stage_$safeStage.png';
    
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: theme == 'city' ? const Color(0xFF1a1a2e) : const Color(0xFF1a472a),
      ),
    );
  }

  // NOTE: In a real app, these would be local assets or networked images.
  // For this implementation, I'm using the screenshot URLs from Stitch as constants.
  
  Widget _buildCityGrowth() {
    return CachedNetworkImage(
      imageUrl: 'https://lh3.googleusercontent.com/aida/ADBb0ui5zB7TcLh1B-6jrCkYqx-1M3vLH3ICURZJ_0etZUt9xfZWw0tjRFTiVO5RwTVp95XgeXyKFh13TukO-QN6j-TzplsgrPxj0I6PDtf-8bGgD7pFOCF4BaMpfMRqey3GPpPtM6WT2qPLlL8C1gfmJnXEou_8_MRqFXMtCNB994ampAD2wReiqR6caqIhd7yRsNmGTyjN3N94MonHFw52vZ11tJnqJrBl6EYbCZoJiIUHLqKdVwtbxJMjTZg',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: const Color(0xFF1a1a2e)),
      errorWidget: (context, url, error) => _buildStandardView(),
    );
  }

  Widget _buildCityDecay() {
    return CachedNetworkImage(
      imageUrl: 'https://lh3.googleusercontent.com/aida/ADBb0uh3-kR5Kg1MriZcMv_LClIrAyb6QkcFhQZ7MYka83simow6NYJxEiEbOpYwncgU6FuGOCwqeID6cxt-JTXMfx_ZE1BQOK70Y0ZOORCZotmx-_0CCwTDihwbDmtRb8SBFsyb0Mfmn51CNRnaECGIcYCqwgsZzEgcZwas92L0id4NyCKw_M8T5kWYnt5sivPzCrm75jQBkY4VHnOcI8jJjCaF5qn77Hi6xKaqTO5z4NkBbQGAYC9S6WKRC0I',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: const Color(0xFF1a1a2e)),
      errorWidget: (context, url, error) => _buildStandardView(),
    );
  }

  Widget _buildForestGrowth() {
    return CachedNetworkImage(
      imageUrl: 'https://lh3.googleusercontent.com/aida/ADBb0uiF1i49zaayajxjry382z3cZCSxiqNjn7W4ETqCSF9rYbAVXLCAs3-r24PEZQmkU2pgisHiUBKW76ykFECnFE9QrXBCoyNsI6TOUeEcGUbV5gmZZCdXdxpvxP73OEqsrkx7L5DaHSNsehsCgCXH5qxCC-gkKcwCrFKfqTzuWTwqdfN8aOmJ3reE4vS8ypPpI9WFhAYhAy_LYj1iOV4g71_zzYP-zjAx_9p66HFs_LSVydj82UT42uUDDbI',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: const Color(0xFF1a472a)),
      errorWidget: (context, url, error) => _buildStandardView(),
    );
  }

  Widget _buildForestDecay() {
    return CachedNetworkImage(
      imageUrl: 'https://lh3.googleusercontent.com/aida/ADBb0ujm9aewspnNjtaqdSGsTIUoTs5ePoGloxT4hZ5p_W16hbGzg63kqLVw9BMmMrGag0nVV3EYClzPvKUbO5Oh4TW-vb1JdiiM0O7e1_qZjfOsCTtNcdfySO_BZ4WnYllGuzMIUuImxIUK2Ud_87sv3xUATvnwyPDP9jeJYUUEdA1rPQcrvZvA_DSubbRqqf6t-jsudXwVW-Feqet-RvGj__t5aKUEf7-4_wMk2_NhxeMB-q1Yf7abhhNLnD0',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: const Color(0xFF1a472a)),
      errorWidget: (context, url, error) => _buildStandardView(),
    );
  }
}
