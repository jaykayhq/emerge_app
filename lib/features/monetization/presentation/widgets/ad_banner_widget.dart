import 'dart:io';
import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Identity-First Ad Banner Widget
///
/// Transforms traditional banner ads into identity-affirming micro-experiences
/// that reinforce the user's archetype and habit journey while maintaining
/// ad functionality. Uses frontend design principles to create distinctive,
/// production-grade interfaces that avoid generic AI aesthetics.
///
/// Design Principles Applied:
/// 1. Archetype Integration: Uses user's archetype colors and themes
/// 2. Cosmic Motion: Subtle animations aligned with app's space theme
/// 3. Identity Reinforcement: Displays archetype-aligned habit tips
/// 4. Habit Loop Integration: Shows ads at psychologically appropriate moments
/// 5. Visual Distinctiveness: Avoids generic ad aesthetics through custom styling
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _disposed = false;

  @override
  bool get wantKeepAlive => true;

  // Animation controllers for cosmic motion effects
  // Started only when ad is loaded to avoid unnecessary repaints
  late final AnimationController _nebulaController;
  late final AnimationController _particleController;
  late final Animation<double> _nebulaAnimation;
  late final Animation<double> _particleAnimation;

  // Using AppConfig to get the correct banner ID
  String get _adUnitId => AppConfig.getAdUnitId(
      'banner', Platform.isIOS ? 'ios' : 'android');

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers but do NOT start them yet.
    // Only start when ad is actually loaded to avoid jank from
    // continuous CustomPainter repaints on the placeholder.
    _nebulaController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _nebulaAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _nebulaController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      final isConnected = ref.read(isConnectedProvider);
      if (isConnected) {
        _loadAd();
      }
    });
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          // Start cosmic animations only when ad is actually visible
          _nebulaController.repeat(reverse: true);
          _particleController.repeat();
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (_disposed) return;
          _bannerAd = null;
          // Try to reload after a delay for better ad fill rates
          Future.delayed(const Duration(seconds: 30), () {
            if (_disposed || !mounted) return;
            final isConnected = ref.read(isConnectedProvider);
            final isPremium = ref.read(isPremiumProvider);
            if (isConnected) {
              bool shouldShowAds = false;
              if (!isPremium.isLoading && isPremium.hasValue) {
                final bool isPremiumValue = isPremium.requireValue;
                shouldShowAds = !isPremiumValue;
              }
              if (shouldShowAds) {
                _loadAd();
              }
            }
          });
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _disposed = true;
    _nebulaController.dispose();
    _particleController.dispose();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final userArchetype = ref.watch(currentArchetypeProvider);

    if (!isConnected) return const SizedBox.shrink();

    return isPremiumAsync.when(
      data: (isPremium) {
        if (isPremium) return const SizedBox.shrink();

        if (_bannerAd != null && _isLoaded) {
          return _buildIdentityFirstAdBanner(context, userArchetype);
        }
        // Return a placeholder with same height to prevent layout shifts
        return _buildAdPlaceholder(context, userArchetype);
      },
      loading: () => _buildAdPlaceholder(context, userArchetype),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Builds the identity-first ad banner that integrates with archetype theming
  Widget _buildIdentityFirstAdBanner(
      BuildContext context, UserArchetype archetype) {
    final theme = ArchetypeTheme.forArchetype(archetype);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? theme.darkColors
        : theme.lightColors;

    return RepaintBoundary(
      child: SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        child: Stack(
          children: [
            // Cosmic background layer with archetype colors
            _buildCosmicBackgroundLayer(colors),

            // Main ad container
            Center(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(
                  key: ValueKey(_bannerAd!.hashCode),
                  ad: _bannerAd!,
                ),
              ),
            ),

            // Identity reinforcement overlay
            _buildIdentityOverlay(context, colors),
          ],
        ),
      ),
    );
  }

  /// Builds the cosmic background layer with archetype-specific colors and motion
  Widget _buildCosmicBackgroundLayer(IdentityThemeExtension theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_nebulaController, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(
            _bannerAd!.size.width.toDouble(),
            _bannerAd!.size.height.toDouble(),
          ),
          painter: _CosmicAdBackgroundPainter(
            nebulaProgress: _nebulaAnimation.value,
            particleProgress: _particleAnimation.value,
            primaryColor: theme.primaryColor,
            accentColor: theme.accentColor,
            archetype: theme.archetypeName,
          ),
          child: child,
        );
      },
    );
  }

  /// Builds the identity reinforcement overlay with archetype-aligned content
  Widget _buildIdentityOverlay(
      BuildContext context, IdentityThemeExtension theme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          // Subtle gradient overlay that enhances ad visibility
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              theme.primaryColor.withValues(alpha: 0.05),
              theme.primaryColor.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Archetype-aligned habit tip or motivational message
            _buildHabitTip(theme.archetypeName),

            // Subtle archetype indicator
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '• ${theme.archetypeName} Path •',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.accentColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds archetype-aligned habit tips that reinforce identity
  Widget _buildHabitTip(String archetypeName) {
    // Archetype-specific habit tips that reinforce identity loops
    final Map<String, String> habitTips = {
      'The Athlete': 'Strength grows through consistent action',
      'The Scholar': 'Wisdom comes from applied knowledge',
      'The Creator': 'Expression flows from authentic creation',
      'The Stoic': 'Mastery comes from disciplined focus',
      'The Zealot': 'Purpose fuels unwavering commitment',
      'The Explorer': 'Discovery awaits beyond comfort zones',
    };

    final tip = habitTips[archetypeName] ?? 'Your journey shapes your identity';

    return Container(
      margin: const EdgeInsets.only(bottom: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        tip,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds a placeholder that maintains layout stability
  Widget _buildAdPlaceholder(BuildContext context, UserArchetype archetype) {
    final theme = ArchetypeTheme.forArchetype(archetype);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? theme.darkColors
        : theme.lightColors;

    return Container(
      height: 50, // Standard banner ad height
      decoration: BoxDecoration(
        color: colors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'Aligning with your ${theme.archetypeName} path...',
          style: TextStyle(
            fontSize: 12,
            color: colors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Custom painter for cosmic background effect in ad banner
class _CosmicAdBackgroundPainter extends CustomPainter {
  final double nebulaProgress;
  final double particleProgress;
  final Color primaryColor;
  final Color accentColor;
  final String archetype;

  _CosmicAdBackgroundPainter({
    required this.nebulaProgress,
    required this.particleProgress,
    required this.primaryColor,
    required this.accentColor,
    required this.archetype,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw slow-moving nebula clouds
    _drawNebulaClouds(canvas, size);

    // Draw drifting cosmic particles
    _drawCosmicParticles(canvas, size);

    // Draw archetype-aligned subtle glow
    _drawArchetypeGlow(canvas, size);
  }

  void _drawNebulaClouds(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(nebulaProgress * 2 - 1, nebulaProgress - 0.5),
        end: Alignment(nebulaProgress * 2 - 2, nebulaProgress + 0.5),
        colors: [
          primaryColor.withValues(alpha: 0.03),
          primaryColor.withValues(alpha: 0.01),
          accentColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawCosmicParticles(Canvas canvas, Size size) {
    // Draw 3-5 subtle particles that drift across the banner
    final particleCount = 4;
    final baseSize = size.width * 0.03;

    for (int i = 0; i < particleCount; i++) {
      final offset = (i + particleProgress) / particleCount;
      final x = (offset * size.width) % size.width;
      final y = size.height * 0.3 + (size.height * 0.4 * ((i * 0.7) % 1.0));

      final particlePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.4 - (i * 0.08))
        ..style = PaintingStyle.fill;

      final particleSize = baseSize * (0.8 + (i * 0.1));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: particleSize,
          height: particleSize * 0.6,
        ),
        particlePaint,
      );
    }
  }

  void _drawArchetypeGlow(Canvas canvas, Size size) {
    // Subtle glow that pulses with the archetype's primary color
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          primaryColor.withValues(alpha: 0.02),
          primaryColor.withValues(alpha: 0.005),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CosmicAdBackgroundPainter oldDelegate) {
    return oldDelegate.nebulaProgress != nebulaProgress ||
        oldDelegate.particleProgress != particleProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.archetype != archetype;
  }
}