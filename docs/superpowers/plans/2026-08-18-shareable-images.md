# Shareable Images Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add branded 9:16 shareable image export — users export their weekly recap as branded PNGs, and creators export a tribe stat card — via one shared `ShareableCard` template and exporter.

**Architecture:** A pure `ShareableCardData` struct feeds a reusable `ShareableCard` 9:16 widget (cosmic gradient, Emerge logo, headline, stat rows). `ShareableImageExporter` renders it offscreen via an `OverlayEntry` + `RepaintBoundary.toImage(pixelRatio: 3.0)` (the `timeline_share_preview.dart` pattern), writes a temp file via `path_provider`, and shares via `share_plus`; on web it downloads the PNG. Pure functions map `UserWeeklyRecap` → cards and tribe stats → card. Video slideshow is scoped as a follow-up (needs an `ffmpeg_kit_flutter` decision) — not built here.

**Tech Stack:** Flutter, share_plus, path_provider, package:web (download fallback), fpdart not required.

**Spec:** `docs/superpowers/specs/2026-08-18-shareable-images-design.md`

---

## File Structure

**Create:**
- `lib/core/presentation/widgets/shareable/shareable_card_data.dart` — pure struct
- `lib/core/presentation/widgets/shareable/shareable_card.dart` — 9:16 branded card widget
- `lib/core/presentation/services/shareable_image_exporter.dart` — offscreen render → PNG → share/download
- `lib/features/gamification/presentation/services/recap_to_shareable_cards.dart` — pure mapping
- `lib/features/gamification/presentation/widgets/recap_share_sheet.dart` — recap export UI
- `lib/features/social/presentation/services/tribe_to_shareable_card.dart` — pure mapping
- `lib/features/social/presentation/widgets/creator_tribe_share_card.dart` — tribe card export UI
- `test/core/presentation/widgets/shareable/shareable_card_test.dart`
- `test/core/presentation/services/shareable_image_exporter_test.dart`
- `test/features/gamification/presentation/services/recap_to_shareable_cards_test.dart`
- `test/features/social/presentation/services/tribe_to_shareable_card_test.dart`
- `test/features/gamification/presentation/widgets/recap_share_sheet_test.dart`

**Modify:**
- `lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart` — share button opens the share sheet
- `lib/features/social/presentation/screens/creator/creator_analytics_tab.dart` — add "Share tribe card" action

---

### Task 1: `ShareableCardData` pure struct

**Files:**
- Create: `lib/core/presentation/widgets/shareable/shareable_card_data.dart`
- Test: `test/core/presentation/widgets/shareable/shareable_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/presentation/widgets/shareable/shareable_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

void main() {
  test('ShareableCardData carries headline and stats', () {
    const data = ShareableCardData(
      headline: 'MY WEEK IN EMERGE',
      subheadline: 'Week of Aug 10 – 16',
      stats: [
        ShareableStat(label: 'Habits', value: '42', color: Color(0xFF2BEE79)),
        ShareableStat(label: 'XP', value: '+500', color: Color(0xFFFFD700)),
      ],
      footer: 'Built with Emerge',
    );
    expect(data.headline, 'MY WEEK IN EMERGE');
    expect(data.stats.length, 2);
    expect(data.stats.first.value, '42');
    expect(data.footer, 'Built with Emerge');
  });

  test('defaults stats to empty list', () {
    const data = ShareableCardData(headline: 'X');
    expect(data.stats, isEmpty);
    expect(data.subheadline, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/widgets/shareable/shareable_card_test.dart`
Expected: FAIL — class not defined.

- [ ] **Step 3: Implement the struct**

```dart
// lib/core/presentation/widgets/shareable/shareable_card_data.dart
import 'package:flutter/material.dart';

/// One stat row rendered on a [ShareableCard].
class ShareableStat {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const ShareableStat({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

/// Pure data for the branded 9:16 share card. No Flutter rendering here —
/// unit-testable without a widget tree.
class ShareableCardData {
  final String headline;
  final String? subheadline;
  final List<ShareableStat> stats;
  final String? footer;

  const ShareableCardData({
    required this.headline,
    this.subheadline,
    this.stats = const [],
    this.footer,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/widgets/shareable/shareable_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/shareable/shareable_card_data.dart test/core/presentation/widgets/shareable/shareable_card_test.dart
git commit -m "feat(share): add ShareableCardData pure struct"
```

---

### Task 2: `ShareableCard` widget

**Files:**
- Create: `lib/core/presentation/widgets/shareable/shareable_card.dart`
- Test: `test/core/presentation/widgets/shareable/shareable_card_test.dart` (append)

- [ ] **Step 1: Write the failing widget test**

```dart
// append to test/core/presentation/widgets/shareable/shareable_card_test.dart
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card.dart';

// inside main() add:
group('ShareableCard widget', () {
  testWidgets('renders headline, stats, footer at 9:16', (tester) async {
    const data = ShareableCardData(
      headline: 'MY WEEK',
      subheadline: 'Aug 10 – 16',
      stats: [
        ShareableStat(label: 'Habits', value: '42', color: Color(0xFF2BEE79)),
        ShareableStat(label: 'XP', value: '+500', color: Color(0xFFFFD700)),
      ],
      footer: 'Built with Emerge',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AspectRatio(aspectRatio: 9 / 16, child: ShareableCard(data: data))),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('MY WEEK'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('+500'), findsOneWidget);
    expect(find.text('Built with Emerge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles empty stats without overflow', (tester) async {
    const data = ShareableCardData(headline: 'HEADLINE', footer: 'Footer');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AspectRatio(aspectRatio: 9 / 16, child: ShareableCard(data: data))),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('HEADLINE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/widgets/shareable/shareable_card_test.dart`
Expected: FAIL — `ShareableCard` not defined.

- [ ] **Step 3: Implement the card**

```dart
// lib/core/presentation/widgets/shareable/shareable_card.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/presentation/widgets/animated_flame_logo.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

/// Branded 9:16 share card. Rendered inside a [RepaintBoundary] by
/// [ShareableImageExporter] for export, or shown as a live preview.
class ShareableCard extends StatelessWidget {
  final ShareableCardData data;

  const ShareableCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EmergeColors.cosmicVoidDark, EmergeColors.cosmicVoidCenter, EmergeColors.cosmicBlue],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand mark
          const SizedBox(height: 8, width: 40, child: AnimatedFlameLogo(size: 40)),
          const Spacer(),
          // Headline
          Text(
            data.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              height: 1.1,
            ),
          ),
          if (data.subheadline != null) ...[
            const Gap(8),
            Text(
              data.subheadline!,
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
          const Gap(24),
          // Stats
          for (final stat in data.stats) _StatRow(stat: stat),
          const Spacer(),
          // Footer
          if (data.footer != null)
            Text(
              data.footer!,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          const Gap(12),
          const Text(
            'EMERGE',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final ShareableStat stat;
  const _StatRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon ?? Icons.star_rounded, color: stat.color, size: 22),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              stat.label.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
            ),
          ),
          Text(
            stat.value,
            style: TextStyle(
              color: stat.color,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/widgets/shareable/shareable_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/shareable/shareable_card.dart test/core/presentation/widgets/shareable/shareable_card_test.dart
git commit -m "feat(share): add ShareableCard 9:16 branded widget"
```

---

### Task 3: `ShareableImageExporter`

**Files:**
- Create: `lib/core/presentation/services/shareable_image_exporter.dart`
- Test: `test/core/presentation/services/shareable_image_exporter_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/presentation/services/shareable_image_exporter_test.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

void main() {
  testWidgets('renderPng returns valid PNG bytes', (tester) async {
    const data = ShareableCardData(
      headline: 'TEST',
      stats: [ShareableStat(label: 'A', value: '1', color: Color(0xFF2BEE79))],
    );
    Uint8List? bytes;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            // Trigger capture after first frame so the Overlay exists.
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              bytes = await ShareableImageExporter.renderPng(context, data);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(bytes, isNotNull);
    // PNG magic header: 89 50 4E 47 0D 0A 1A 0A
    expect(bytes!.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/services/shareable_image_exporter_test.dart`
Expected: FAIL — class not defined.

- [ ] **Step 3: Implement the exporter**

```dart
// lib/core/presentation/services/shareable_image_exporter.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

/// Renders a [ShareableCardData] offscreen to PNG bytes.
///
/// The card is inserted into the app's [Overlay] at opacity 0 (invisible,
/// never flashes), captured via [RenderRepaintBoundary.toImage], then removed.
/// Mirrors the `timeline_share_preview.dart` pattern.
class ShareableImageExporter {
  static Future<Uint8List?> renderPng(
    BuildContext context,
    ShareableCardData data, {
    double pixelRatio = 3.0,
  }) async {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return null;

    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: RepaintBoundary(
            key: boundaryKey,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ShareableCard(data: data),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      // Let the entry lay out and paint (a frame boundary).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/services/shareable_image_exporter_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/services/shareable_image_exporter.dart test/core/presentation/services/shareable_image_exporter_test.dart
git commit -m "feat(share): add ShareableImageExporter offscreen PNG renderer"
```

---

### Task 4: Pure mapping — recap → cards

**Files:**
- Create: `lib/features/gamification/presentation/services/recap_to_shareable_cards.dart`
- Test: `test/features/gamification/presentation/services/recap_to_shareable_cards_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/gamification/presentation/services/recap_to_shareable_cards_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/services/recap_to_shareable_cards.dart';

void main() {
  final recap = UserWeeklyRecap(
    id: 'r1',
    userId: 'u1',
    startDate: DateTime(2026, 8, 10),
    endDate: DateTime(2026, 8, 16),
    totalHabitsCompleted: 42,
    perfectDays: 5,
    totalXpEarned: 500,
    topHabitName: 'Read',
    currentLevel: 7,
    worldGrowthPercentage: 0.4,
    dominantIdentityThisWeek: 'Writer',
    identityHeadline: 'Consistent and focused',
  );

  test('produces stats, top habit, and identity cards', () {
    final cards = recapToShareableCards(recap);
    expect(cards, isNotEmpty);
    expect(cards.length, greaterThanOrEqualTo(3));

    final stats = cards.firstWhere((c) => c.headline.contains('NUMBERS'));
    expect(stats.stats.any((s) => s.value == '42'), isTrue);
    expect(stats.stats.any((s) => s.value == '+500'), isTrue);

    final mvp = cards.firstWhere((c) => c.headline.contains('MVP'));
    expect(mvp.stats.first.value, 'READ');
  });

  test('includes identity card only when identity present', () {
    final bare = UserWeeklyRecap(
      id: 'r2',
      userId: 'u1',
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 16),
      totalHabitsCompleted: 1,
      perfectDays: 0,
      totalXpEarned: 10,
      topHabitName: 'Run',
      currentLevel: 1,
      worldGrowthPercentage: 0,
    );
    final cards = recapToShareableCards(bare);
    expect(cards.any((c) => c.headline.contains('IDENTITY')), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/gamification/presentation/services/recap_to_shareable_cards_test.dart`
Expected: FAIL — function not defined.

- [ ] **Step 3: Implement the mapping**

```dart
// lib/features/gamification/presentation/services/recap_to_shareable_cards.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';

/// Maps a weekly recap into branded share cards (9:16).
/// Pure — no Flutter rendering; unit-testable.
List<ShareableCardData> recapToShareableCards(UserWeeklyRecap recap) {
  final df = DateFormat('MMM dd');
  final range = '${df.format(recap.startDate)} – ${df.format(recap.endDate)}';
  final cards = <ShareableCardData>[];

  // Stats card
  cards.add(
    ShareableCardData(
      headline: 'MY WEEK IN NUMBERS',
      subheadline: range,
      stats: [
        ShareableStat(
          label: 'Habits Completed',
          value: '${recap.totalHabitsCompleted}',
          color: EmergeColors.teal,
          icon: Icons.check_circle_outline_rounded,
        ),
        ShareableStat(
          label: 'Perfect Days',
          value: '${recap.perfectDays}',
          color: EmergeColors.warmGold,
          icon: Icons.whatshot_rounded,
        ),
        ShareableStat(
          label: 'XP Earned',
          value: '+${recap.totalXpEarned}',
          color: EmergeColors.violet,
          icon: Icons.stars_rounded,
        ),
      ],
      footer: 'Level ${recap.currentLevel}',
    ),
  );

  // Top habit card
  cards.add(
    ShareableCardData(
      headline: 'MY MVP',
      subheadline: 'Most consistent habit',
      stats: [
        ShareableStat(
          label: 'Top Habit',
          value: recap.topHabitName.toUpperCase(),
          color: EmergeColors.warmGold,
          icon: Icons.emoji_events_rounded,
        ),
      ],
      footer: 'Built with Emerge',
    ),
  );

  // Identity card (only when available)
  final identity = recap.dominantIdentityThisWeek;
  if (identity != null && identity.isNotEmpty) {
    cards.add(
      ShareableCardData(
        headline: 'THIS WEEK I WAS A',
        subheadline: recap.identityHeadline,
        stats: [
          ShareableStat(
            label: 'Identity',
            value: identity.toUpperCase(),
            color: EmergeColors.neonTeal,
            icon: Icons.auto_awesome_rounded,
          ),
        ],
        footer: 'Every habit counts toward building your identity',
      ),
    );
  }

  return cards;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/gamification/presentation/services/recap_to_shareable_cards_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/gamification/presentation/services/recap_to_shareable_cards.dart test/features/gamification/presentation/services/recap_to_shareable_cards_test.dart
git commit -m "feat(share): add recapToShareableCards pure mapping"
```

---

### Task 5: `RecapShareSheet`

**Files:**
- Create: `lib/features/gamification/presentation/widgets/recap_share_sheet.dart`
- Modify: `lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart`
- Test: `test/features/gamification/presentation/widgets/recap_share_sheet_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/gamification/presentation/widgets/recap_share_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/recap_share_sheet.dart';

void main() {
  final recap = UserWeeklyRecap(
    id: 'r1',
    userId: 'u1',
    startDate: DateTime(2026, 8, 10),
    endDate: DateTime(2026, 8, 16),
    totalHabitsCompleted: 42,
    perfectDays: 5,
    totalXpEarned: 500,
    topHabitName: 'Read',
    currentLevel: 7,
    worldGrowthPercentage: 0.4,
  );

  testWidgets('shows both share options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => RecapShareSheet(recap: recap, currentIndex: 1),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Share current slide'), findsOneWidget);
    expect(find.text('Share all slides'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/gamification/presentation/widgets/recap_share_sheet_test.dart`
Expected: FAIL — `RecapShareSheet` not defined.

- [ ] **Step 3: Implement the share sheet**

```dart
// lib/features/gamification/presentation/widgets/recap_share_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/services/recap_to_shareable_cards.dart';

/// Lets the user export the current recap slide or all slides as branded
/// PNGs, then share them (native share sheet / web download).
class RecapShareSheet extends StatefulWidget {
  final UserWeeklyRecap recap;
  final int currentIndex;

  const RecapShareSheet({
    super.key,
    required this.recap,
    required this.currentIndex,
  });

  @override
  State<RecapShareSheet> createState() => _RecapShareSheetState();
}

class _RecapShareSheetState extends State<RecapShareSheet> {
  bool _busy = false;

  Future<void> _export({required bool all}) async {
    setState(() => _busy = true);
    try {
      final cards = recapToShareableCards(widget.recap);
      final selected = all
          ? cards
          : [
              cards[(widget.currentIndex).clamp(0, cards.length - 1)],
            ];
      final files = <XFile>[];
      for (final card in selected) {
        final bytes = await ShareableImageExporter.renderPng(context, card);
        if (bytes == null) continue;
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/emerge_recap_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path));
      }
      if (files.isEmpty) {
        _toast('Could not render the recap image.');
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: 'My Emerge Weekly Recap 🌟 #EmergeApp',
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('Sharing failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EmergeColors.coral,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share your recap',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.image_rounded,
              title: 'Share current slide',
              subtitle: 'Export this card as a branded 9:16 image',
              onTap: _busy ? null : () => _export(all: false),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.collections_rounded,
              title: 'Share all slides',
              subtitle: 'Export the full recap as a set of images',
              onTap: _busy ? null : () => _export(all: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: EmergeColors.neonTeal, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the recap's share button to the sheet**

In `spotify_wrapped_recap.dart`, replace the `_shareRecap` body's text-only share with opening the sheet. The outro's `onShare` callback (`_ShareButton`) is wired to `_shareRecap`. Change:

```dart
void _openShareSheet() {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => RecapShareSheet(
      recap: widget.recap,
      currentIndex: _currentPage,
    ),
  );
}
```

and pass `_openShareSheet` to `_WrappedOutro(onShare: _openShareSheet)`. Add `import 'package:emerge_app/features/gamification/presentation/widgets/recap_share_sheet.dart';`. Remove the now-unused `_shareRecap` text-share method and the `share_plus` import (nothing else in the file uses `Share`). **Keep the `intl` import** — `_WrappedIntro` still uses `DateFormat` for the date range.

- [ ] **Step 5: Run the tests**

Run: `flutter test test/features/gamification/presentation/widgets/recap_share_sheet_test.dart`
Run: `dart analyze lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart lib/features/gamification/presentation/widgets/recap_share_sheet.dart`
Expected: PASS / no analyzer errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/gamification/presentation/widgets/recap_share_sheet.dart lib/features/gamification/presentation/widgets/spotify_wrapped_recap.dart test/features/gamification/presentation/widgets/recap_share_sheet_test.dart
git commit -m "feat(share): add recap share sheet + wire into recap hub"
```

---

### Task 6: Pure mapping — tribe → card

**Files:**
- Create: `lib/features/social/presentation/services/tribe_to_shareable_card.dart`
- Test: `test/features/social/presentation/services/tribe_to_shareable_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/social/presentation/services/tribe_to_shareable_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/presentation/services/tribe_to_shareable_card.dart';

void main() {
  test('maps tribe stats into a share card', () {
    final card = tribeToShareableCard(
      tribeName: 'The Forge',
      creatorName: 'Ada',
      memberCount: 25,
      totalXp: 120000,
      totalHabitsCompleted: 900,
      totalChallengesCompleted: 12,
    );
    expect(card.headline, 'THE FORGE');
    expect(card.subheadline, 'by Ada');
    final values = card.stats.map((s) => s.value).toList();
    expect(values, contains('25'));
    expect(values, contains('120.0K'));
    expect(values, contains('900'));
    expect(values, contains('12'));
    expect(card.footer, 'Join my tribe on Emerge');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/services/tribe_to_shareable_card_test.dart`
Expected: FAIL — function not defined.

- [ ] **Step 3: Implement the mapping**

```dart
// lib/features/social/presentation/services/tribe_to_shareable_card.dart
import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

/// Maps a creator's tribe stats into a branded share card (9:16).
/// Pure — unit-testable.
ShareableCardData tribeToShareableCard({
  required String tribeName,
  required String creatorName,
  required int memberCount,
  required int totalXp,
  required int totalHabitsCompleted,
  required int totalChallengesCompleted,
}) {
  String formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return xp.toString();
  }

  return ShareableCardData(
    headline: tribeName.toUpperCase(),
    subheadline: 'by $creatorName',
    stats: [
      ShareableStat(
        label: 'Members',
        value: '$memberCount',
        color: EmergeColors.neonTeal,
        icon: Icons.groups_rounded,
      ),
      ShareableStat(
        label: 'Tribe XP',
        value: formatXp(totalXp),
        color: EmergeColors.warmGold,
        icon: Icons.bolt_rounded,
      ),
      ShareableStat(
        label: 'Habits Done',
        value: '$totalHabitsCompleted',
        color: EmergeColors.blue,
        icon: Icons.check_circle_outline_rounded,
      ),
      ShareableStat(
        label: 'Challenges',
        value: '$totalChallengesCompleted',
        color: EmergeColors.purple,
        icon: Icons.emoji_events_rounded,
      ),
    ],
    footer: 'Join my tribe on Emerge',
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/social/presentation/services/tribe_to_shareable_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/social/presentation/services/tribe_to_shareable_card.dart test/features/social/presentation/services/tribe_to_shareable_card_test.dart
git commit -m "feat(share): add tribeToShareableCard pure mapping"
```

---

### Task 7: Creator tribe share card UI + wiring

**Files:**
- Create: `lib/features/social/presentation/widgets/creator_tribe_share_card.dart`
- Modify: `lib/features/social/presentation/screens/creator/creator_analytics_tab.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/social/presentation/widgets/creator_tribe_share_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/presentation/widgets/creator_tribe_share_card.dart';

void main() {
  testWidgets('shares the tribe card on tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreatorTribeShareCard(
            tribeName: 'The Forge',
            creatorName: 'Ada',
            memberCount: 25,
            totalXp: 120000,
            totalHabitsCompleted: 900,
            totalChallengesCompleted: 12,
            onExport: () async => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Share tribe card'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/social/presentation/widgets/creator_tribe_share_card_test.dart`
Expected: FAIL — widget not defined.

- [ ] **Step 3: Implement the widget**

```dart
// lib/features/social/presentation/widgets/creator_tribe_share_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/services/tribe_to_shareable_card.dart';

/// Exports the creator's tribe stats as a branded 9:16 card and shares it.
class CreatorTribeShareCard extends StatelessWidget {
  final String tribeName;
  final String creatorName;
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final Future<void> Function()? onExport; // test seam

  const CreatorTribeShareCard({
    super.key,
    required this.tribeName,
    required this.creatorName,
    required this.memberCount,
    required this.totalXp,
    required this.totalHabitsCompleted,
    required this.totalChallengesCompleted,
    this.onExport,
  });

  Future<void> _export(BuildContext context) async {
    if (onExport != null) return onExport!();
    try {
      final card = tribeToShareableCard(
        tribeName: tribeName,
        creatorName: creatorName,
        memberCount: memberCount,
        totalXp: totalXp,
        totalHabitsCompleted: totalHabitsCompleted,
        totalChallengesCompleted: totalChallengesCompleted,
      );
      final bytes = await ShareableImageExporter.renderPng(context, card);
      if (bytes == null) {
        _toast(context, 'Could not render the tribe card.');
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/emerge_tribe_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Join my tribe on Emerge!'),
      );
    } catch (e) {
      _toast(context, 'Sharing failed: $e');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EmergeColors.coral,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _export(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.ios_share_rounded, color: EmergeColors.neonTeal, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Share tribe card',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire into `creator_analytics_tab.dart`**

In `_AnalyticsView`, add below the KPI cards (after the second `Row` of cards, before `MEMBER GROWTH`):

```dart
const Gap(16),
CreatorTribeShareCard(
  tribeName: analytics.tribeName,
  creatorName: 'Your Tribe',
  memberCount: analytics.memberCount,
  totalXp: analytics.totalXp,
  totalHabitsCompleted: analytics.totalHabitsCompleted,
  totalChallengesCompleted: analytics.totalChallengesCompleted,
),
```

Add `import 'package:emerge_app/features/social/presentation/widgets/creator_tribe_share_card.dart';`.

- [ ] **Step 5: Run the tests + analyzer**

Run: `flutter test test/features/social/presentation/widgets/creator_tribe_share_card_test.dart`
Run: `dart analyze lib/features/social/presentation/screens/creator/creator_analytics_tab.dart lib/features/social/presentation/widgets/creator_tribe_share_card.dart`
Expected: PASS / no analyzer errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/presentation/widgets/creator_tribe_share_card.dart lib/features/social/presentation/screens/creator/creator_analytics_tab.dart test/features/social/presentation/widgets/creator_tribe_share_card_test.dart
git commit -m "feat(share): add creator tribe share card to analytics tab"
```

---

## Plan Self-Review

- **Spec coverage:** Shared `ShareableCardData` + `ShareableCard` (Tasks 1-2), exporter reusing RepaintBoundary→PNG→share (Task 3), recap export "Current slide / All slides" (Tasks 4-5), creator tribe card (Tasks 6-7), web fallback noted (Task 3 via `package:web` download — if `Share.shareXFiles` is insufficient on web, add a `kIsWeb` branch writing a blob download; the exporter returns bytes so both paths share it), error handling via snackbars (Tasks 5, 7), empty-stats handling (Task 2 test), video slideshow explicitly out of scope (documented in spec).
- **Placeholder scan:** No TBDs; every code step shows full code.
- **Type consistency:** `ShareableCardData`/`ShareableStat` match across Tasks 1-7; `recapToShareableCards` and `tribeToShareableCard` signatures consistent with their tests; `ShareableImageExporter.renderPng(context, data)` used identically in Tasks 3, 5, 7.
