# Plan 5: Onboarding Housekeeping + Endowment + Club Redesign + Tribes Discovery

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove motive step, compact interests, add goal progress bar, endowment interstitial, club screen redesign (box cards with micro-info + preview sheet, skippable), world reveal escape hatch, and tribes tab discovery view for users without clubs.

**Architecture:** This is the largest plan — touches IdentityStudioScreen, InterestScreen, ClubScreen, FirstHabitsScreen, WorldRevealScreen, and TribeTabContent. Each task is a self-contained change. The progress bar is a shared widget injected via the onboarding shell.

**Tech Stack:** Flutter, Riverpod, `onboarding/` screens, `social/` TribeTabContent, SharedPreferences (endowment flag).

**State: Pending Implementation**

---

### Task 1: Remove motive step from IdentityStudioScreen

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/identity_studio_screen.dart`

- [ ] **Step 1: Read current file**

Read full `identity_studio_screen.dart` to understand the two-page structure (archetype carousel + motive selection).

- [ ] **Step 2: Delete motive-related elements**

Remove:
- `_buildMotiveSelection()` method
- `_buildMotiveCard()` method
- `_customMotiveController` field
- `_selectedMotive` field
- `_isCustomMotive` field
- `_stepController` (the 2-page PageController — no longer needed)
- Any motive-related imports

The screen becomes a single-page archetype carousel only.

- [ ] **Step 3: Clean up navigation**

The screen should no longer expect a `PageView`. Convert to a single `CustomScrollView` or `SingleChildScrollView` with just the archetype carousel + continue button.

- [ ] **Step 4: Run analyze**

```bash
dart analyze lib/features/onboarding/presentation/screens/identity_studio_screen.dart
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/screens/identity_studio_screen.dart
git commit -m "fix(onboarding): remove motive step from identity studio"
```

---

### Task 2: Compact color-coded interest grid

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/interest_screen.dart` (or wherever interest chips are)

- [ ] **Step 1: Read current interest screen**

- [ ] **Step 2: Replace with compact color-coded grid**

```dart
// Category color map
const _categoryColors = {
  'Mind & Body': Color(0xFF2BEE79),  // green
  'Creative': Color(0xFF9C27B0),     // purple
  'Social': Color(0xFF2196F3),       // blue
  'Career': Color(0xFFFFC107),       // amber
  'Lifestyle': Color(0xFFFF6B6B),    // coral
  'Learning': Color(0xFF009688),     // teal
};

Widget _buildInterestChip(String label, String category, bool selected) {
  final color = _categoryColors[category] ?? Colors.white;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : color,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: color,
      checkmarkColor: Colors.black,
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      onSelected: (val) => _toggleInterest(label, val),
    ),
  );
}
```

Use a `Wrap` widget with spacing 4 to minimize vertical space. No category section headers — category is communicated purely through color.

- [ ] **Step 3: Remove category section headers**

Delete any `Text` headers like "Mind & Body", "Creative" etc. that act as section headers.

- [ ] **Step 4: Run analyze and visual check**

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/screens/interest_screen.dart
git commit -m "fix(onboarding): compact color-coded interest grid without section headers"
```

---

### Task 3: Goal progress bar widget

**Files:**
- Create: `lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart`

- [ ] **Step 1: Write the widget test**

```dart
testWidgets('shows correct progress percentage and label', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: OnboardingProgressBar(progress: 0.4, label: 'Your archetype is set. What shapes you?'),
  ));
  expect(find.text('40%'), findsOneWidget);
  expect(find.text('Your archetype is set. What shapes you?'), findsOneWidget);
});
```

- [ ] **Step 2: Implement OnboardingProgressBar**

```dart
class OnboardingProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final String label;

  const OnboardingProgressBar({
    super.key,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create the progress mapping**

```dart
// In a shared constant or utility file
const onboardingProgressLabels = {
  0.2: "You've begun. Now define yourself.",
  0.4: "Your archetype is set. What shapes you?",
  0.6: "Good. Your interests give texture.",
  0.8: "Almost forged. Choose your company.",
  1.0: "Ready to emerge.",
};
```

- [ ] **Step 4: Integrate into all onboarding screens**

Each screen (`IdentityStudioScreen`, `InterestScreen`, `ClubScreen`, `FirstHabitsScreen`, `WorldRevealScreen`) wraps its content with a `Column` that includes `OnboardingProgressBar` at the top. Progress value is determined by which step the user is on.

Use a shared provider or inherited widget to track the current step index.

- [ ] **Step 5: Run test → pass**

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart
git commit -m "feat(onboarding): add goal progress bar with milestone labels"
```

---

### Task 4: Endowment interstitial after sign-up

**Files:**
- Create: `lib/features/onboarding/presentation/screens/endowment_interstitial_screen.dart`

- [ ] **Step 1: Write the widget test**

```dart
testWidgets('shows welcome message and starter items', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: EndowmentInterstitialScreen(userName: 'Alex'),
  ));
  expect(find.text('Welcome, Alex'), findsWidgets);
  expect(find.text('Starter habit pack'), findsOneWidget);
  expect(find.text('Archetype tribe'), findsOneWidget);
  expect(find.text('Your world map'), findsOneWidget);
  expect(find.text('BEGIN FORGING →'), findsOneWidget);
});
```

- [ ] **Step 2: Implement EndowmentInterstitialScreen**

```dart
class EndowmentInterstitialScreen extends StatelessWidget {
  final String userName;
  const EndowmentInterstitialScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 48)),
              const Gap(16),
              Text(
                'Welcome, $userName',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Gap(8),
              Text(
                'Your world seed is planted.\nHere\'s what you already have:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
              ),
              const Gap(32),
              _EndowmentItem(emoji: '🎁', title: 'Starter habit pack', subtitle: 'reserved for you'),
              const Gap(12),
              _EndowmentItem(emoji: '🏟️', title: 'Archetype tribe', subtitle: 'waiting for you'),
              const Gap(12),
              _EndowmentItem(emoji: '🌍', title: 'Your world map', subtitle: 'ready to grow'),
              const Gap(40),
              ElevatedButton(
                onPressed: () => context.go('/onboarding/archetype'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text('BEGIN FORGING →', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Track shown status with SharedPreferences**

```dart
const _endowmentSeenKey = 'endowment_interstitial_seen';

Future<bool> hasSeenEndowment() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_endowmentSeenKey) ?? false;
}

Future<void> markEndowmentSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_endowmentSeenKey, true);
}
```

- [ ] **Step 4: Add route in router**

Insert the endowment interstitial as the first onboarding route, before archetype selection.

- [ ] **Step 5: Run test → pass**

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/presentation/screens/endowment_interstitial_screen.dart
git commit -m "feat(onboarding): add endowment interstitial after sign-up"
```

---

### Task 5: World reveal escape hatch

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/world_reveal_screen.dart`

- [ ] **Step 1: Read current world_reveal_screen.dart**

- [ ] **Step 2: Add "Skip" button in top-right**

```dart
AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.pop(),
  ),
  actions: [
    TextButton(
      onPressed: () => _skipToEnterWorld(context),
      child: const Text('Skip'),
    ),
  ],
),
```

`_skipToEnterWorld` jumps to the "Enter Your World" button state (completes the reveal).

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/presentation/screens/world_reveal_screen.dart
git commit -m "feat(onboarding): add skip and back buttons to world reveal"
```

---

### Task 6: Club screen redesign — box cards + micro-info + preview sheet

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/club_screen.dart`
- Create: `lib/features/onboarding/presentation/widgets/club_box_card.dart`
- Create: `lib/features/onboarding/presentation/widgets/club_preview_sheet.dart`

- [ ] **Step 1: Read current club_screen.dart**

- [ ] **Step 2: Create ClubBoxCard widget**

```dart
class ClubBoxCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final int memberCount;
  final String activityStatus; // "🔥 Active" or "🌙 Quiet"
  final String typeTag; // "ARCHETYPE" or "CREATOR"
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A1A2E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emblem/image area (top 60%)
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.cyanAccent.withValues(alpha: 0.3), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(Icons.emoji_events, size: 40, color: Colors.cyanAccent),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
                  )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$memberCount', style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 11,
                      )),
                      const SizedBox(width: 4),
                      Text(activityStatus, style: TextStyle(
                        color: activityStatus.contains('Active') ? Colors.greenAccent : Colors.grey,
                        fontSize: 11,
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeTag == 'ARCHETYPE'
                          ? Colors.cyanAccent.withValues(alpha: 0.2)
                          : Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(typeTag, style: TextStyle(
                      color: typeTag == 'ARCHETYPE' ? Colors.cyanAccent : Colors.purpleAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create ClubPreviewSheet**

```dart
class ClubPreviewSheet extends StatelessWidget {
  final String title;
  final String description;
  final List<String> benefits;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const Gap(20),
          Text(title, style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
          )),
          const Gap(12),
          Text(description, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5,
          )),
          const Gap(16),
          ...benefits.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.check_circle, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(b, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            ]),
          )),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { onJoin(); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('JOIN CLUB', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rewrite club_screen.dart layout**

Replace the full-width list with:
- A 3-column `GridView` of `ClubBoxCard` widgets (4-column on tablets)
- Initially show 6 clubs, "See more clubs →" expands to ~15
- "Skip" link in header
- Tap opens `ClubPreviewSheet`

- [ ] **Step 5: Run analyze**

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/presentation/screens/club_screen.dart lib/features/onboarding/presentation/widgets/
git commit -m "feat(onboarding): redesign club screen with box cards, micro-info, preview sheet, skippable"
```

---

### Task 7: Tribes tab — empty state + club discovery grid

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart`

- [ ] **Step 1: Read current tribe_tab_content.dart**

- [ ] **Step 2: Add no-club detection**

```dart
// At top of build method
final userHasClub = ref.watch(hasClubProvider);
if (!userHasClub) {
  return _buildDiscoveryView(context);
} else {
  return _buildClubTabs(context);
}
```

- [ ] **Step 3: Build discovery view**

```dart
Widget _buildDiscoveryView(BuildContext context) {
  return CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: _buildSearchBar()),
      SliverToBoxAdapter(child: _buildFilterChips()),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => ClubBoxCard(
              title: clubs[index].title,
              memberCount: clubs[index].memberCount,
              activityStatus: clubs[index].isActive ? "🔥 Active" : "🌙 Quiet",
              typeTag: clubs[index].isCreator ? "CREATOR" : "ARCHETYPE",
              onTap: () => _showPreviewSheet(context, clubs[index]),
            ),
            childCount: filteredClubs.length,
          ),
        ),
      ),
    ],
  );
}
```

- [ ] **Step 4: Add search and filter chips**

```dart
Widget _buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      decoration: InputDecoration(
        hintText: '🔍 Search clubs...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) => _searchQuery = val,
    ),
  );
}

Widget _buildFilterChips() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        _FilterChip(label: 'All', selected: _selectedFilter == 'All'),
        const SizedBox(width: 8),
        _FilterChip(label: 'By Archetype', selected: _selectedFilter == 'By Archetype'),
        const SizedBox(width: 8),
        _FilterChip(label: 'Creator', selected: _selectedFilter == 'Creator'),
      ],
    ),
  );
}
```

- [ ] **Step 5: Add "SEE ALL TRIBES" button for users WITH a club**

```dart
// In the existing club view, add to header area:
TextButton.icon(
  onPressed: () => _showDiscoveryView(context),
  icon: const Icon(Icons.explore, size: 18),
  label: const Text('SEE ALL TRIBES'),
)
```

- [ ] **Step 6: Run analyze**

- [ ] **Step 7: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_tab_content.dart
git commit -m "feat(social): add club discovery view for users without clubs + search/filters"
```

---

### Task 8: Full onboarding flow integration

- [ ] **Step 1: Wire endowment interstitial into router**

```dart
// In router.dart onboarding routes:
GoRoute(
  path: '/onboarding/endowment',
  builder: (context, state) => EndowmentInterstitialScreen(
    userName: state.extra as String? ?? '',
  ),
),
```

- [ ] **Step 2: Update onboarding progress tracking**

Create a simple provider:

```dart
enum OnboardingStep { endowment, archetype, interests, club, firstHabits, worldReveal }

@riverpod
OnboardingStep currentOnboardingStep(Ref ref) {
  // Determined by the current route
}

double progressForStep(OnboardingStep step) {
  switch (step) {
    case OnboardingStep.endowment: return 0.2;
    case OnboardingStep.archetype: return 0.4;
    case OnboardingStep.interests: return 0.6;
    case OnboardingStep.club: return 0.6; // catches up to 0.8 if joined
    case OnboardingStep.firstHabits: return 0.8;
    case OnboardingStep.worldReveal: return 1.0;
  }
}
```

- [ ] **Step 3: Run full test suite**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(onboarding): verify complete onboarding redesign passes analyze and tests"
```
