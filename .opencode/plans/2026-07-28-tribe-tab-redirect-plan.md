# Tribe Tab Redirect & Emblem Headers — Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or executing-plans to implement.

**Goal:** Redirect tribe members from PulseFeedScreen to their tribe lobby, and replace text filter chips with emblem images.

**Architecture:** A `SocialHubScreen` wrapper at `/social` auto-redirects tribe members to `/social/tribe/:id` on first entry. Filter chips in tribe discovery swap text for emblem images.

**Tech Stack:** Flutter, Riverpod, GoRouter

---

### Task 1: Create SocialHubScreen wrapper

**Files:**
- Create: `lib/features/social/presentation/screens/social_hub_screen.dart`

**Interfaces:**
- Produces: `class SocialHubScreen extends ConsumerStatefulWidget` — replaces `PulseFeedScreen` as the `/social` builder
- Consumes providers: `hasClubProvider`, `currentArchetypeProvider`, `userClubProvider`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';

class SocialHubScreen extends ConsumerStatefulWidget {
  const SocialHubScreen({super.key});

  @override
  ConsumerState<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends ConsumerState<SocialHubScreen> {
  bool _navigatedToTribe = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(hasClubProvider, (prev, next) {
      next.whenOrNull(data: (hasClub) {
        if (hasClub && !_navigatedToTribe) {
          _navigatedToTribe = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToUserTribe();
          });
        } else if (!hasClub) {
          _navigatedToTribe = false;
        }
      });
    });

    return const PulseFeedScreen();
  }

  void _navigateToUserTribe() {
    final archetype = ref.read(currentArchetypeProvider);
    if (archetype == null) return;
    final tribe = ref.read(userClubProvider(archetype.name)).valueOrNull;
    if (tribe != null && context.mounted) {
      context.go('/social/tribe/${tribe.id}');
    }
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `dart analyze lib/features/social/presentation/screens/social_hub_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/social_hub_screen.dart
git commit -m "feat: add SocialHubScreen wrapper for tribe auto-redirect"
```

---

### Task 2: Update router to use SocialHubScreen

**Files:**
- Modify: `lib/core/router/router.dart:499-504`

**Interfaces:**
- Consumes: `SocialHubScreen` (from Task 1)

- [ ] **Step 1: Change the `/social` builder**

In `lib/core/router/router.dart`, change line ~503 from:
```dart
builder: (context, state) => const PulseFeedScreen(),
```
to:
```dart
builder: (context, state) => const SocialHubScreen(),
```

And add the import at the top:
```dart
import 'package:emerge_app/features/social/presentation/screens/social_hub_screen.dart';
```

- [ ] **Step 2: Verify router compiles**

Run: `dart analyze lib/core/router/router.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/core/router/router.dart
git commit -m "feat: wire SocialHubScreen into /social route"
```

---

### Task 3: Update filter chips to use tribe emblem images

**Files:**
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart:296-321`

- [ ] **Step 1: Update `_buildFilterChips` to use emblem images**

The current filter chips are text-only. Change them to show tribe emblem images alongside/behind the text. The `clubEmblemImageUrl()` helper already provides deterministic emblems per archetype.

Replace the existing `_buildFilterChips` method with one that renders small emblem thumbnails (24x24) next to each chip label. For "All" use a neutral icon. For "By Archetype" show the archetype emblem. For "Creator" show a creator emblem.

```dart
Widget _buildFilterChips() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        _FilterChip(
          label: 'All',
          selected: _selectedFilter == 'All',
          onSelected: () => setState(() => _selectedFilter = 'All'),
          icon: Icons.explore,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Archetype',
          selected: _selectedFilter == 'By Archetype',
          onSelected: () => setState(() => _selectedFilter = 'By Archetype'),
          icon: Icons.auto_awesome,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Creator',
          selected: _selectedFilter == 'Creator',
          onSelected: () => setState(() => _selectedFilter = 'Creator'),
          icon: Icons.person,
        ),
      ],
    ),
  );
}
```

Also update the `_FilterChip` class to accept an optional `IconData` parameter:

```dart
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EmergeColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compiles**

Run: `dart analyze lib/features/social/presentation/screens/tribe_tab_content.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/social/presentation/screens/tribe_tab_content.dart
git commit -m "feat: add icons to tribe filter chips for visual sorting"
```
