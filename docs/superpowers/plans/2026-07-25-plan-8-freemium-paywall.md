# Plan 8: Psychology-Driven Freemium Model + Paywall Redesign

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement scarcity-based gating (5 habits max, 1 club max for free users), redesign the premium limit dialog with aspiration + social proof + loss aversion, and redesign the paywall screen with "Go Beyond the 5" headline, hyperbolic discounting pricing, gold shimmer CTA, and animated cosmic background.

**Architecture:** Gate habit creation at 5 in the habit provider, gate club joins at 1 in the tribes provider, rewrite `premium_limit_dialog.dart` and `paywall_screen.dart`, create `premium_badge.dart` (gold shimmer badge), and `premium_theme_preview.dart` (blurred preview for curiosity gap). All gating reads from `isPremiumProvider`.

**Tech Stack:** Flutter, Riverpod, RevenueCat, `subscription_provider.dart`, `habit_providers.dart`, `tribes_provider.dart`, `paywall_screen.dart`, `premium_limit_dialog.dart`.

**State: Pending Implementation**

---

### Task 1: Gate habit creation at 5 for free users

**Files:**
- Modify: `lib/features/habits/presentation/providers/habit_providers.dart` (or wherever habit creation is handled)

- [ ] **Step 1: Read current habit creation logic**

Find the provider/method that handles creating a new habit.

- [ ] **Step 2: Add free-tier gate**

```dart
// Before creating a habit:
final isPremium = ref.read(isPremiumProvider).valueOrNull ?? false;
if (!isPremium) {
  final habitCount = ref.read(activeHabitsCountProvider);
  if (habitCount >= 5) {
    // Show premium limit dialog
    _showPremiumLimitDialog(context, 'habit');
    return;
  }
}
// Proceed with creation...
```

- [ ] **Step 3: Create activeHabitsCountProvider**

```dart
@riverpod
int activeHabitsCount(Ref ref) {
  final habits = ref.watch(todayHabitsProvider);
  return habits.length;
}
```

- [ ] **Step 4: Write the test**

```dart
test('blocks habit creation at 5 for free users', () async {
  // Arrange: mock habits with count 5, isPremium = false
  // Act: attempt to create habit
  // Assert: premium limit dialog shown, habit not created
});
```

- [ ] **Step 5: Run test → pass**

- [ ] **Step 6: Commit**

```bash
git add lib/features/habits/presentation/providers/
git commit -m "feat(monetization): gate habit creation at 5 for free users"
```

---

### Task 2: Gate club joins at 1 for free users

**Files:**
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`

- [ ] **Step 1: Read current club join logic**

- [ ] **Step 2: Add free-tier gate**

```dart
// Before joining a club:
final isPremium = ref.read(isPremiumProvider).valueOrNull ?? false;
if (!isPremium) {
  final currentClubCount = ref.read(userClubCountProvider);
  if (currentClubCount >= 1) {
    _showPremiumLimitDialog(context, 'club');
    return;
  }
}
```

- [ ] **Step 3: Write test**

- [ ] **Step 4: Commit**

```bash
git add lib/features/social/presentation/providers/
git commit -m "feat(monetization): gate club joins at 1 for free users"
```

---

### Task 3: Premium Limit Dialog redesign

**Files:**
- Rewrite: `lib/features/monetization/presentation/widgets/premium_limit_dialog.dart`

- [ ] **Step 1: Write the widget test**

```dart
testWidgets('shows aspiration message and social proof', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showPremiumLimitDialog(context, limitType: 'habit'),
          child: const Text('Show'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();
  expect(find.text("You've created 5 habits."), findsOneWidget);
  expect(find.text("That's the free limit"), findsOneWidget);
  expect(find.text('SHOW ME WHAT I\'M MISSING'), findsOneWidget);
  expect(find.text('Stay focused for now'), findsOneWidget);
});
```

- [ ] **Step 2: Rewrite PremiumLimitDialog**

```dart
class PremiumLimitDialog extends StatelessWidget {
  final String limitType; // 'habit' or 'club'

  const PremiumLimitDialog({super.key, required this.limitType});

  @override
  Widget build(BuildContext context) {
    final (title, message) = limitType == 'habit'
        ? ("You've created 5 habits.", "That's the free limit — a focused start. But your potential goes further.\n\nPremium users average 8 habits and 2x faster streak growth.")
        : ("You've joined 1 club.", "That's the free limit. Premium users join unlimited clubs and unlock exclusive communities.");

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.amber, size: 36),
                ),
                const Gap(16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(12),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push('/paywall');
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('SHOW ME WHAT I\'M MISSING'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const Gap(8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Stay focused for now',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Utility function to show the dialog
void showPremiumLimitDialog(BuildContext context, {required String limitType}) {
  showDialog(
    context: context,
    builder: (_) => PremiumLimitDialog(limitType: limitType),
  );
}
```

- [ ] **Step 3: Run test → pass**

- [ ] **Step 4: Commit**

```bash
git add lib/features/monetization/presentation/widgets/premium_limit_dialog.dart
git commit -m "feat(monetization): redesign premium limit dialog with aspiration + social proof"
```

---

### Task 4: Premium badge widget (Von Restorff)

**Files:**
- Create: `lib/features/monetization/presentation/widgets/premium_badge.dart`

- [ ] **Step 1: Implement gold shimmer badge**

```dart
class PremiumBadge extends StatefulWidget {
  final double size;
  final bool showShimmer;

  const PremiumBadge({super.key, this.size = 20, this.showShimmer = true});

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              const Color(0xFFFFD700),
              const Color(0xFFFFA500),
              const Color(0xFFFFD700),
              Colors.white,
              const Color(0xFFFFD700),
            ],
            transform: GradientRotation(_controller.value * 2 * 3.14159),
          ),
          boxShadow: widget.showShimmer
              ? [BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4 * _controller.value),
                  blurRadius: 6,
                  spreadRadius: 1,
                )]
              : null,
        ),
        child: const Icon(Icons.star, color: Colors.black87, size: 12),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/monetization/presentation/widgets/premium_badge.dart
git commit -m "feat(monetization): add gold shimmer premium badge (Von Restorff)"
```

---

### Task 5: Premium theme preview widget (Curiosity Gap)

**Files:**
- Create: `lib/features/monetization/presentation/widgets/premium_theme_preview.dart`

- [ ] **Step 1: Implement blurred preview widget**

```dart
class PremiumThemePreview extends StatelessWidget {
  final String themeName;
  final String description;

  const PremiumThemePreview({
    super.key,
    required this.themeName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPreview(context),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A1A2E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            // Blurred preview content
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyanAccent.withValues(alpha: 0.3),
                        Colors.purple.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Lock overlay
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(themeName, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                  )),
                  Text("Tap to preview", style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context) {
    // Show 3-second animated preview, then paywall
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(themeName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/paywall');
              },
              child: const Text('Unlock Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/monetization/presentation/widgets/premium_theme_preview.dart
git commit -m "feat(monetization): add premium theme preview widget for curiosity gap"
```

---

### Task 6: Paywall Screen redesign

**Files:**
- Rewrite: `lib/features/monetization/presentation/screens/paywall_screen.dart`

- [ ] **Step 1: Write the widget test**

```dart
testWidgets('shows Go Beyond the 5 headline and premium benefits', (tester) async {
  await tester.pumpWidget(MaterialApp(home: PaywallScreen()));
  await tester.pumpAndSettle();
  expect(find.text('Go Beyond the 5'), findsOneWidget);
  expect(find.text('UNLOCK YOUR POTENTIAL'), findsOneWidget);
  expect(find.text('UNLIMITED'), findsOneWidget);
  expect(find.text('PREMIUM INSIGHTS'), findsOneWidget);
  expect(find.text('EXCLUSIVE STYLE'), findsOneWidget);
});
```

- [ ] **Step 2: Rewrite PaywallScreen**

```dart
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final price = ref.watch(premiumPriceStringProvider) ?? '\$5.99';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Animated cosmic background
          _buildCosmicBackground(),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Headline
                const Text(
                  'Go Beyond the 5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You've built your foundation.\nNow unlock what's waiting.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Benefit blocks
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _BenefitBlock(
                        icon: Icons.lock_open,
                        title: 'UNLIMITED',
                        subtitle: 'Habits, clubs, themes',
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(height: 12),
                      _BenefitBlock(
                        icon: Icons.insights,
                        title: 'PREMIUM INSIGHTS',
                        subtitle: 'Full evolution graphs & analytics',
                        color: Colors.purpleAccent,
                      ),
                      const SizedBox(height: 12),
                      _BenefitBlock(
                        icon: Icons.auto_awesome,
                        title: 'EXCLUSIVE STYLE',
                        subtitle: 'Gold nameplate, shimmer badge & more',
                        color: const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Pricing
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'less than a coffee per day',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPremiumCta(price),
                ),
                const SizedBox(height: 16),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _restorePurchases(),
                      child: Text('Restore',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => _openTerms(),
                      child: Text('Terms & Privacy',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmicBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => CustomPaint(
        painter: _CosmicPainter(
          progress: _particleController.value,
          color: Colors.cyanAccent,
        ),
        size: MediaQuery.of(context).size,
      ),
    );
  }

  Widget _buildPremiumCta(String price) {
    return _GoldShimmerButton(
      onPressed: () => _purchasePremium(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.black87, size: 20),
          const SizedBox(width: 8),
          Text(
            'UNLOCK YOUR POTENTIAL',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _purchasePremium() async {
    final repo = ref.read(monetizationRepositoryProvider);
    final result = await repo.purchasePremium();
    result.fold(
      (error) => AppLogger.e('Purchase failed', error: error),
      (success) {
        if (success && mounted) {
          ref.invalidate(isPremiumProvider);
          context.pop();
        }
      },
    );
  }

  void _restorePurchases() async {
    final repo = ref.read(monetizationRepositoryProvider);
    await repo.restorePurchases();
  }

  void _openTerms() {
    launchUrl(Uri.parse('https://emerge.app/terms'));
  }

  // Requires: import 'package:url_launcher/url_launcher.dart';
}

class _BenefitBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16,
              )),
              Text(subtitle, style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldShimmerButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  @override
  State<_GoldShimmerButton> createState() => _GoldShimmerButtonState();

  // ...
}

class _GoldShimmerButtonState extends State<_GoldShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: SweepGradient(
            colors: [
              const Color(0xFFFFD700),
              const Color(0xFFFFA500),
              const Color(0xFFFFD700),
              Colors.white70,
              const Color(0xFFFFD700),
            ],
            transform: GradientRotation(_controller.value * 2 * 3.14159),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Simple cosmic particle painter
class _CosmicPainter extends CustomPainter {
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    for (int i = 0; i < 20; i++) {
      final x = (i * 97 + progress * 50) % size.width;
      final y = (i * 131 + progress * 30) % size.height;
      final radius = 20 + (progress * 10);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter old) => old.progress != progress;
}
```

- [ ] **Step 3: Run test → pass**

- [ ] **Step 4: Commit**

```bash
git add lib/features/monetization/presentation/screens/paywall_screen.dart
git commit -m "feat(monetization): redesign paywall with Go Beyond the 5 headline, gold shimmer CTA, cosmic background"
```

---

### Task 7: Daily login bonus state in subscription provider

**Files:**
- Modify: `lib/features/monetization/presentation/providers/subscription_provider.dart`

- [ ] **Step 1: Add daily login bonus check**

```dart
@riverpod
class DailyLoginBonus extends _$DailyLoginBonus {
  @override
  Future<bool> build() async {
    final isPremium = await ref.watch(isPremiumProvider.future);
    if (!isPremium) return false;

    // Check if already claimed today
    final prefs = await SharedPreferences.getInstance();
    final lastClaim = prefs.getString('last_daily_bonus_claim');
    if (lastClaim == DateTime.now().toIso8601String().substring(0, 10)) {
      return false; // Already claimed today
    }

    return true; // Bonus available
  }

  Future<void> claimBonus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_daily_bonus_claim', DateTime.now().toIso8601String().substring(0, 10));
    state = const AsyncValue.data(false);
    // Add +5 XP logic here
  }
}
```

- [ ] **Step 2: Run build_runner**

- [ ] **Step 3: Commit**

```bash
git add lib/features/monetization/presentation/providers/subscription_provider.dart
git commit -m "feat(monetization): add daily login bonus provider for premium users"
```

---

### Task 8: Full verification

- [ ] **Step 1: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run analyze + test**

```bash
flutter analyze
flutter test
```
Expected: No new warnings, all tests pass.

- [ ] **Step 3: Verify free-tier gating manually (or add integration tests)**

Check that:
- Free user with 5 habits cannot create a 6th
- Free user with 1 club cannot join another
- Premium user has no limits
- After purchase, gates lift immediately (verify `ref.invalidate(isPremiumProvider)` is called)

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(freemium): verify all freemium gating and paywall redesign"
```
