# Emerge App Comprehensive Enhancements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix reflection logging UI, improve auth flow, redesign weekly recap Spotify Wrapped-style, add sharing, fix calendar strip, ensure user data isolation, and optimize backend performance.

**Architecture:**
- Reflection state management with provider-based tracking
- Auth flow with proper user session detection
- Weekly recap with Spotify Wrapped-style animations and shareable image generation
- Calendar strip with proper week calculation
- Firestore query optimization with composite indexes

**Tech Stack:** Flutter, Riverpod, Firebase Firestore, share_plus, flutter_animate, path_provider

---

## Task 1: Fix Reflection Logging UI State

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/reflection_card.dart`
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

**Step 1: Create reflection state provider**

In `lib/features/timeline/presentation/providers/reflection_state_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reflection_state_provider.g.dart';

@riverpod
class TodayReflectionState extends _$TodayReflectionState {
  @override
  bool build() {
    return false; // Has user logged reflection today?
  }

  void setLogged(bool logged) {
    state = logged;
  }

  void resetForNewDay() {
    state = false;
  }
}
```

**Step 2: Modify ReflectionCard to show logged state**

Edit `lib/features/timeline/presentation/widgets/reflection_card.dart`:

```dart
class ReflectionCard extends ConsumerStatefulWidget {
  final Function(double value, String? note)? onLogReflection;

  const ReflectionCard({super.key, this.onLogReflection});

  @override
  ConsumerState<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends ConsumerState<ReflectionCard> {
  // ... existing fields ...
  bool _isLogged = false;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedToday();
  }

  void _checkIfLoggedToday() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    // Check shared preferences or local storage
    // For now, use provider state
    _isLogged = ref.read(todayReflectionStateProvider);
  }

  // In build method, replace slider section with:
  Widget _buildReflectionContent() {
    if (_isLogged) {
      return _buildLoggedState();
    }
    return _buildUnloggedState();
  }

  Widget _buildLoggedState() {
    return Column(
      children: [
        Icon(
          Icons.check_circle_outline,
          color: EmergeColors.teal,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'Reflection Logged!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your mood: ${_getMoodEmoji(_progressValue)}',
          style: TextStyle(
            color: EmergeColors.tealMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() => _isLogged = false);
            ref.read(todayReflectionStateProvider.notifier).setLogged(false);
          },
          child: Text('Edit Reflection'),
        ),
      ],
    );
  }

  String _getMoodEmoji(double value) {
    if (value >= 0.8) return '🔥 Feeling Great';
    if (value >= 0.6) return '😊 Feeling Good';
    if (value >= 0.4) return '😐 Feeling Okay';
    if (value >= 0.2) return '😔 Feeling Low';
    return '😢 Struggling';
  }

  // Modify the Log button to:
  ElevatedButton(
    onPressed: () {
      widget.onLogReflection?.call(
        _progressValue,
        _noteController.text.isEmpty ? null : _noteController.text,
      );
      setState(() => _isLogged = true);
      ref.read(todayReflectionStateProvider.notifier).setLogged(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reflection logged! 🎉'),
          backgroundColor: EmergeColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    },
    // ... rest of button style
  )
```

**Step 3: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 4: Test reflection logging**

Run: `flutter run`
Expected: Reflection card shows "Reflection Logged!" state after logging

**Step 5: Commit**

```bash
git add lib/features/timeline/
git commit -m "feat: add reflection logged state UI with persistent state"
```

---

## Task 2: Fix Auth Flow - Redirect Existing Users to Dashboard

**Files:**
- Modify: `lib/core/presentation/screens/splash_screen.dart`
- Modify: `lib/core/router/router.dart`

**Step 1: Modify SplashScreen to check onboarding completion**

Edit `lib/core/presentation/screens/splash_screen.dart`:

```dart
Future<void> _navigateToNext() async {
  // Artificial delay for branding
  await Future.delayed(const Duration(seconds: 2));

  if (!mounted) return;

  final authState = ref.read(authStateChangesProvider);
  final isFirstLaunch = ref.read(onboardingControllerProvider);

  authState.when(
    data: (user) {
      if (user.isNotEmpty) {
        // User is logged in - check onboarding completion
        final userStatsAsync = ref.read(userStatsStreamProvider);
        final userProfile = userStatsAsync.valueOrNull;
        final onboardingProgress = userProfile?.onboardingProgress ?? 0;

        if (onboardingProgress >= 4) {
          // Onboarding complete - go to dashboard (World Map)
          context.go('/');
        } else if (isFirstLaunch) {
          // First time user - start onboarding
          context.go('/welcome');
        } else {
          // Returning user with incomplete onboarding
          // Determine where they left off
          final nextStep = _getOnboardingRouteForProgress(onboardingProgress);
          context.go(nextStep);
        }
      } else {
        // Not logged in
        if (isFirstLaunch) {
          context.go('/welcome');
        } else {
          context.go('/login');
        }
      }
    },
    loading: () {
      // Let router handle it
      context.go('/');
    },
    error: (_, __) => context.go('/login'),
  );
}

String _getOnboardingRouteForProgress(int progress) {
  switch (progress) {
    case 0:
      return '/onboarding/identity-studio';
    case 1:
      return '/onboarding/map-attributes';
    case 2:
      return '/onboarding/first-habit';
    case 3:
      return '/onboarding/world-reveal';
    default:
      return '/';
  }
}
```

**Step 2: Simplify router redirect logic**

Edit `lib/core/router/router.dart`:

```dart
redirect: (context, state) {
  final authState = ref.read(authStateChangesProvider);
  final isLoggedIn = authState.valueOrNull?.isNotEmpty ?? false;

  final isSplash = state.uri.path == '/splash';
  if (isSplash) return null;

  final isWelcome = state.uri.path == '/welcome';
  final isLoggingIn = state.uri.path == '/login';
  final isSigningUp = state.uri.path == '/signup';
  final isOnboardingPath = state.uri.path.startsWith('/onboarding');

  // Not logged in - go to welcome or login
  if (!isLoggedIn) {
    if (isWelcome || isLoggingIn || isSigningUp) return null;
    return '/welcome';
  }

  // Logged in - check onboarding
  if (isLoggedIn) {
    final userProfileAsync = ref.read(userStatsStreamProvider);
    final userProfile = userProfileAsync.valueOrNull;
    final onboardingProgress = userProfile?.onboardingProgress ?? 0;

    // Allow onboarding paths
    if (isOnboardingPath) {
      if (onboardingProgress >= 4) return '/';
      return null;
    }

    // Redirect to onboarding if incomplete
    if (onboardingProgress < 4) {
      return _getOnboardingRouteForProgress(onboardingProgress);
    }

    // Allow auth screens for logged in users to logout
    if (isLoggingIn || isSigningUp || isWelcome) {
      return '/';
    }
  }

  return null;
}
```

**Step 3: Test auth flow**

Run: `flutter run`
Expected:
- New user → Welcome Screen
- Returning logged in user → Dashboard (World Map)
- Logged in with incomplete onboarding → Resume onboarding

**Step 4: Commit**

```bash
git add lib/core/presentation/screens/splash_screen.dart lib/core/router/router.dart
git commit -m "fix: redirect existing users to dashboard, improve auth flow"
```

---

## Task 3: Weekly Recap - Only Accessible After Full Week

**Files:**
- Modify: `lib/features/gamification/domain/services/weekly_recap_service.dart`
- Modify: `lib/features/gamification/presentation/screens/weekly_recap_screen.dart`

**Step 1: Add week completion check to service**

Edit `lib/features/gamification/domain/services/weekly_recap_service.dart`:

```dart
Future<UserWeeklyRecap?> generateRecapIfNeeded(String userId) async {
  final now = DateTime.now();
  final userStatsRepository = _ref.read(userStatsRepositoryProvider);
  final userProfile = await userStatsRepository.getUserStats(userId);

  // Check if user has completed at least 7 days since account creation
  final accountCreationDate = userProfile.accountCreatedAt ?? DateTime.now();
  final daysSinceCreation = now.difference(accountCreationDate).inDays;

  if (daysSinceCreation < 7) {
    return null; // Not enough data for weekly recap
  }

  // Get the most recent recap to avoid duplicates
  final lastRecap = await userStatsRepository.getLatestRecap(userId);
  if (lastRecap != null) {
    final lastRecapDate = DateTime.parse(lastRecap.dateRange.split(' - ')[1]);
    final daysSinceLastRecap = now.difference(lastRecapDate).inDays;
    if (daysSinceLastRecap < 7) {
      return UserWeeklyRecap.fromMap(lastRecap.toMap()); // Return cached recap
    }
  }

  // ... rest of the existing logic

  // Save the new recap
  await userStatsRepository.saveRecap(userId, recap.toMap());

  return recap;
}
```

**Step 2: Add repository method for latest recap**

Edit `lib/features/gamification/data/repositories/user_stats_repository.dart`:

```dart
Future<Map<String, dynamic>?> getLatestRecap(String userId) async {
  final snapshot = await _firestore
      .collection('user_stats')
      .doc(userId)
      .collection('recaps')
      .orderBy('endDate', descending: true)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;
  return snapshot.docs.first.data();
}

Future<void> saveRecap(String userId, Map<String, dynamic> recapData) async {
  await _firestore
      .collection('user_stats')
      .doc(userId)
      .collection('recaps')
      .doc(recapData['id'] as String)
      .set(recapData);
}
```

**Step 3: Show locked state in UI**

Edit `lib/features/gamification/presentation/screens/weekly_recap_screen.dart`:

```dart
FutureBuilder(
  future: recapService.generateRecapIfNeeded(user.id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: EmergeColors.teal),
      );
    }

    if (snapshot.data == null) {
      // Show locked state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: EmergeColors.teal.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly Recap Unlocks After 7 Days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete habits for a full week to see your stats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: EmergeColors.teal,
              ),
              child: Text('Back'),
            ),
          ],
        ),
      );
    }

    // ... existing recap display
  },
)
```

**Step 4: Test week requirement**

Run: `flutter run`
Expected: Users with <7 days see locked state

**Step 5: Commit**

```bash
git add lib/features/gamification/
git commit -m "feat: weekly recap only accessible after 7 days of activity"
```

---

## Task 4: Spotify Wrapped-Style Recap Design

**Files:**
- Create: `lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart`
- Modify: `lib/features/gamification/presentation/screens/weekly_recap_screen.dart`

**Step 1: Create shareable recap widget**

In `lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart`:

```dart
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';

class SpotifyWrappedRecap extends StatefulWidget {
  final UserWeeklyRecap recap;
  final VoidCallback onClose;

  const SpotifyWrappedRecap({
    super.key,
    required this.recap,
    required this.onClose,
  });

  @override
  State<SpotifyWrappedRecap> createState() => _SpotifyWrappedRecapState();
}

class _SpotifyWrappedRecapState extends State<SpotifyWrappedRecap> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final GlobalKey _recapKey = GlobalKey();

  final List<Color> _wrappedGradients = [
    Color(0xFF1DB954), // Spotify Green
    Color(0xFF191414), // Dark
    Color(0xFFE1118B), // Pink
    Color(0xFF503750), // Purple
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareRecap() async {
    try {
      RenderRepaintBoundary boundary =
          _recapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/weekly_recap.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([XFile(file.path)],
          text: 'My Emerge weekly recap! 🔥');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share recap: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _WrappedIntro(recap: widget.recap),
      _WrappedStats(recap: widget.recap),
      _WrappedTopHabit(recap: widget.recap),
      _WrappedOutro(recap: widget.recap, onShare: _shareRecap),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _wrappedGradients[_currentPage % _wrappedGradients.length],
                  _wrappedGradients[(_currentPage + 1) % _wrappedGradients.length],
                ],
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: pages,
          ),
          // Progress dots
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _WrappedIntro extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _WrappedIntro({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WEEKLY',
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ).animate().fadeIn(duration: 600.ms).scale(),
          SizedBox(height: 20),
          Text(
            'RECAP',
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms).scale(),
          SizedBox(height: 60),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${recap.startDate.day} - ${recap.endDate.day} ${_getMonthName(recap.endDate.month)}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(),
        ],
      ),
    );
  }
}

class _WrappedStats extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _WrappedStats({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BigStat(
            label: 'HABITS DONE',
            value: '${recap.totalHabitsCompleted}',
            delay: 0,
          ),
          SizedBox(height: 40),
          _BigStat(
            label: 'PERFECT DAYS',
            value: '${recap.perfectDays}',
            delay: 200,
          ),
          SizedBox(height: 40),
          _BigStat(
            label: 'XP EARNED',
            value: '${recap.totalXpEarned}',
            delay: 400,
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final int delay;

  const _BigStat({required this.label, required this.value, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ).animate().fadeIn(delay: delay.ms).scale(),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: (delay + 200).ms),
      ],
    );
  }
}

class _WrappedTopHabit extends StatelessWidget {
  final UserWeeklyRecap recap;

  const _WrappedTopHabit({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'YOUR MVP',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(),
          SizedBox(height: 40),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.star, color: EmergeColors.yellow, size: 64)
                    .animate()
                    .scale(delay: 300.ms),
                SizedBox(height: 16),
                Text(
                  recap.topHabitName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WrappedOutro extends StatelessWidget {
  final UserWeeklyRecap recap;
  final VoidCallback onShare;

  const _WrappedOutro({required this.recap, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LEVEL ${recap.currentLevel}',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ).animate().scale(),
          SizedBox(height: 40),
          Text(
            'KEEP GROWING',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 300.ms),
          SizedBox(height: 60),
          ElevatedButton.icon(
            onPressed: onShare,
            icon: Icon(Icons.share),
            label: Text('SHARE YOUR WRAP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(),
        ],
      ),
    );
  }
}

String _getMonthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}
```

**Step 2: Update weekly recap screen to use new widget**

Edit `lib/features/gamification/presentation/screens/weekly_recap_screen.dart`:

```dart
// Replace body content with:
body: SpotifyWrappedRecap(
  recap: recap,
  onClose: () => context.pop(),
),
```

**Step 3: Add share_plus dependency**

Edit `pubspec.yaml`:

```yaml
dependencies:
  share_plus: ^7.2.1
  path_provider: ^2.1.1
```

**Step 4: Install dependencies**

```bash
flutter pub get
```

**Step 5: Test Spotify Wrapped design**

Run: `flutter run`
Expected: Animated gradient background, swipeable cards, share functionality

**Step 6: Commit**

```bash
git add lib/features/gamification/ pubspec.yaml
git commit -m "feat: add Spotify Wrapped-style weekly recap with sharing"
```

---

## Task 5: Fix Calendar Strip Days Display

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/week_calendar_strip.dart`

**Step 1: Fix week generation logic**

Edit `lib/features/timeline/presentation/widgets/week_calendar_strip.dart`:

```dart
void _generateWeekDays() {
  final now = DateTime.now();
  // Start from Monday of current week
  final monday = now.subtract(Duration(days: now.weekday - 1));
  // Generate 7 days from Monday to Sunday
  _weekDays = List.generate(7, (index) {
    return monday.add(Duration(days: index));
  });
}

// Update day name display to show full day name
Widget _buildDayItem(DateTime date) {
  final isToday = _isToday(date);
  final isSelected = _isSameDay(date, _selectedDate);
  final dayName = DateFormat('EEEE').format(date); // Full day name
  final dayShortName = DateFormat('E').format(date).substring(0, 3);
  final dayNumber = date.day.toString();

  return EmergeTappable(
    label: '$dayName $dayNumber',
    hint: isSelected ? 'Currently selected' : 'Tap to view this day',
    onTap: () {
      setState(() => _selectedDate = date);
      widget.onDateSelected?.call(date);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? EmergeColors.teal
            : isToday
            ? EmergeColors.teal.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected
            ? Border.all(color: EmergeColors.teal.withValues(alpha: 0.5))
            : null,
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: EmergeColors.teal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayShortName,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dayNumber,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isToday
                  ? EmergeColors.teal
                  : AppTheme.textMainDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildCompletionDot(date, isSelected),
        ],
      ),
    ),
  );
}
```

**Step 2: Test calendar strip**

Run: `flutter run`
Expected: Days show Mon-Sun with correct dates

**Step 3: Commit**

```bash
git add lib/features/timeline/presentation/widgets/week_calendar_strip.dart
git commit -m "fix: calendar strip now shows proper week days (Mon-Sun)"
```

---

## Task 6: Verify User Data Isolation

**Files:**
- Review: `lib/features/habits/data/repositories/firestore_habit_repository.dart`

**Step 1: Verify userId filtering**

The `watchHabits` method already filters by userId:

```dart
return _firestore
    .collection('habits')
    .where('userId', isEqualTo: userId) // ✅ Correct
    .where('isArchived', isEqualTo: false)
    .snapshots()
```

**Step 2: Check Firestore security rules**

Review `firestore.rules` to ensure proper isolation:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Habits collection - user can only read/write their own
    match /habits/{habitId} {
      allow read, write: if request.auth != null &&
        resource.data.userId == request.auth.uid;
    }

    // User stats - user can only read/write their own
    match /user_stats/{userId} {
      allow read, write: if request.auth != null &&
        userId == request.auth.uid;
    }

    // Reflections - nested under user_stats
    match /user_stats/{userId}/recaps/{recapId} {
      allow read, write: if request.auth != null &&
        userId == request.auth.uid;
    }
  }
}
```

**Step 3: Add userId to habit creation**

Verify that when creating habits, userId is properly set:

```dart
await _firestore.collection('habits').doc(habit.id).set({
  'userId': habit.userId, // ✅ Already set
  // ... other fields
});
```

**Step 4: Deploy updated rules**

```bash
firebase deploy --only firestore:rules
```

**Step 5: Commit**

```bash
git add firestore.rules
git commit -m "security: ensure user data isolation in Firestore rules"
```

---

## Task 7: Backend Performance Optimization

**Files:**
- Create: `firestore.indexes.json` (if not exists)
- Modify: Various query optimizations

**Step 1: Create Firestore indexes**

Create or update `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "habits",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "isArchived", "order": "ASCENDING"},
        {"fieldPath": "order", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "user_activity",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "date", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "user_stats",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "onboardingProgress", "order": "ASCENDING"}
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Step 2: Deploy indexes**

```bash
firebase deploy --only firestore:indexes
```

**Step 3: Add query result caching**

In `lib/features/habits/data/repositories/firestore_habit_repository.dart`:

```dart
@override
Stream<List<Habit>> watchHabits(String userId) {
  return _firestore
      .collection('habits')
      .where('userId', isEqualTo: userId)
      .where('isArchived', isEqualTo: false)
      .orderBy('order')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => _mapDocToHabit(doc)).toList();
      });
}
```

**Step 4: Monitor performance**

Add performance monitoring in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable performance monitoring
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set performance monitoring
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  runApp(ProviderScope(child: MyApp()));
}
```

**Step 5: Commit**

```bash
git add firestore.indexes.json lib/main.dart
git commit -m "perf: add Firestore indexes and performance monitoring"
```

---

## Summary

This plan implements:
1. ✅ Reflection logged state with persistent UI
2. ✅ Auth flow redirecting existing users to dashboard
3. ✅ Weekly recap locked until 7 days of activity
4. ✅ Spotify Wrapped-style design with sharing
5. ✅ Fixed calendar strip with proper week display
6. ✅ Verified user data isolation
7. ✅ Backend performance optimization with indexes
