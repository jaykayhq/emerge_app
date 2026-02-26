# Gamification & Level Progression Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a cohesive gamification system with standardized 5-level archetype stages, unified colors, attribute-specific XP tracking, mission soft-gates, level-up triggers, and expanded synergy cards.

**Architecture:** Three-tier XP system (Node → Attribute → Total Level), unified archetype theming, soft-gated node progression, state-driven level-up detection.

**Tech Stack:** Flutter, Dart, Riverpod (state management), Go Router (navigation), Firebase Firestore (data persistence)

---

## Phase 1: Foundation (Colors & XP Model)

### Task 1.1: Unified Archetype Color System

**Files:**
- Modify: `lib/core/theme/archetype_theme.dart`
- Modify: `lib/features/profile/presentation/widgets/synergy_status_card.dart`

**Step 1: Add ArchetypeColors class to archetype_theme.dart**

Open `lib/core/theme/archetype_theme.dart` and add after the existing color definitions:

```dart
/// Unified color system for archetypes
/// Used across world map, profile, and synergy cards
class ArchetypeColors {
  const ArchetypeColors({
    required this.primary,
    required this.accent,
    required this.attributes,
  });

  final Color primary;
  final Color accent;
  final List<String> attributes; // Attribute names that use this archetype's theming

  static const Map<String, ArchetypeColors> all = {
    'athlete': ArchetypeColors(
      primary: Color(0xFFFF5252),
      accent: Color(0xFFFF8A80),
      attributes: ['strength', 'vitality'],
    ),
    'scholar': ArchetypeColors(
      primary: Color(0xFFE040FB),
      accent: Color(0xFFEA80FC),
      attributes: ['intellect', 'focus'],
    ),
    'creator': ArchetypeColors(
      primary: Color(0xFF76FF03),
      accent: Color(0xFFB0FF57),
      attributes: ['creativity', 'vitality'],
    ),
    'stoic': ArchetypeColors(
      primary: Color(0xFF00E5FF),
      accent: Color(0xFF80D8FF),
      attributes: ['focus', 'spirit'],
    ),
    'zealot': ArchetypeColors(
      primary: Color(0xFFFFAB00),
      accent: Color(0xFFFFD54F),
      attributes: ['spirit', 'strength'],
    ),
    'explorer': ArchetypeColors(
      primary: Color(0xFF2BEE79),
      accent: Color(0xFF7EFFAC),
      attributes: ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'],
    ),
  };

  /// Get colors for an archetype key
  static ArchetypeColors forKey(String key) {
    return all[key.toLowerCase()] ?? all['explorer']!;
  }

  /// Get color for a specific attribute
  static Color forAttribute(String attribute) {
    for (final colors in all.values) {
      if (colors.attributes.contains(attribute.toLowerCase())) {
        return colors.primary;
      }
    }
    return all['explorer']!.primary;
  }
}
```

**Step 2: Update synergy card to use archetype colors**

Open `lib/features/profile/presentation/widgets/synergy_status_card.dart`

Replace the hardcoded color map with:

```dart
// At the top, add import if not present:
import 'package:emerge_app/core/theme/archetype_theme.dart';

// In the widget, replace color selection logic with:
Color _getAttributeColor(String attribute) {
  return ArchetypeColors.forAttribute(attribute);
}
```

**Step 3: Commit**

```bash
git add lib/core/theme/archetype_theme.dart lib/features/profile/presentation/widgets/synergy_status_card.dart
git commit -m "feat: add unified archetype color system"
```

---

### Task 1.2: Extend UserAvatarStats with Per-Attribute XP

**Files:**
- Modify: `lib/features/auth/domain/entities/user_extension.dart`

**Step 1: Add attribute XP map to UserAvatarStats**

Open `lib/features/auth/domain/entities/user_extension.dart`

Find the `UserAvatarStats` class and add the `attributeXp` field:

```dart
class UserAvatarStats {
  final int level;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final String? characterClass;
  final Map<String, int> attributeXp; // ADD THIS

  const UserAvatarStats({
    required this.level,
    required this.totalXp,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.characterClass,
    this.attributeXp = const {}, // ADD THIS
  });

  // Update copyWith
  UserAvatarStats copyWith({
    int? level,
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    String? characterClass,
    Map<String, int>? attributeXp,
  }) {
    return UserAvatarStats(
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      characterClass: characterClass ?? this.characterClass,
      attributeXp: attributeXp ?? this.attributeXp,
    );
  }

  // Update fromMap
  factory UserAvatarStats.fromMap(Map<String, dynamic> map) {
    return UserAvatarStats(
      level: map['level'] as int? ?? 1,
      totalXp: map['totalXp'] as int? ?? 0,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      characterClass: map['characterClass'] as String?,
      attributeXp: Map<String, dynamic>.from(
        map['attributeXp'] as Map? ?? {}
      ).map((key, value) => MapEntry(key, value as int? ?? 0)),
    );
  }

  // Update toMap
  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'totalXp': totalXp,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'characterClass': characterClass,
      'attributeXp': attributeXp,
    };
  }

  // ADD: Helper to get XP for specific attribute
  int getAttributeXp(String attribute) {
    return attributeXp[attribute.toLowerCase()] ?? 0;
  }

  // ADD: Add XP to specific attribute
  UserAvatarStats addAttributeXp(String attribute, int amount) {
    final key = attribute.toLowerCase();
    final currentXp = attributeXp[key] ?? 0;
    final newAttributeXp = Map<String, int>.from(attributeXp);
    newAttributeXp[key] = currentXp + amount;
    return copyWith(
      attributeXp: newAttributeXp,
      totalXp: totalXp + amount,
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/auth/domain/entities/user_extension.dart
git commit -m "feat: add per-attribute XP tracking to UserAvatarStats"
```

---

### Task 1.3: Update World Node Model with Attributes

**Files:**
- Modify: `lib/features/world_map/domain/models/world_node.dart`

**Step 1: Add attribute tracking to WorldNode**

Open `lib/features/world_map/domain/models/world_node.dart`

Add the following fields to the `WorldNode` class:

```dart
class WorldNode {
  final String id;
  final String title;
  final String description;
  final NodeType type;
  final int requiredLevel;
  final List<String> connectedNodeIds;
  final String? archetype;
  final int stage; // ADD: Stage number (1, 2, 3...)
  final int levelInStage; // ADD: Level within stage (1-5)
  final List<String> primaryAttributes; // ADD: Attributes this node affects
  final int nodeXp; // ADD: Current XP toward node completion
  final int nodeXpRequired; // ADD: XP required to complete node (default 100)
  final bool missionCompleted; // ADD: Has the mission been completed?

  // Existing constructor... update to include new fields
  const WorldNode({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.requiredLevel,
    this.connectedNodeIds = const [],
    this.archetype,
    this.stage = 1,
    this.levelInStage = 1,
    this.primaryAttributes = const [],
    this.nodeXp = 0,
    this.nodeXpRequired = 100,
    this.missionCompleted = false,
  });

  // Update copyWith
  WorldNode copyWith({
    String? id,
    String? title,
    String? description,
    NodeType? type,
    int? requiredLevel,
    List<String>? connectedNodeIds,
    String? archetype,
    int? stage,
    int? levelInStage,
    List<String>? primaryAttributes,
    int? nodeXp,
    int? nodeXpRequired,
    bool? missionCompleted,
  }) {
    return WorldNode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      connectedNodeIds: connectedNodeIds ?? this.connectedNodeIds,
      archetype: archetype ?? this.archetype,
      stage: stage ?? this.stage,
      levelInStage: levelInStage ?? this.levelInStage,
      primaryAttributes: primaryAttributes ?? this.primaryAttributes,
      nodeXp: nodeXp ?? this.nodeXp,
      nodeXpRequired: nodeXpRequired ?? this.nodeXpRequired,
      missionCompleted: missionCompleted ?? this.missionCompleted,
    );
  }

  // Update fromJson
  factory WorldNode.fromJson(Map<String, dynamic> json) {
    return WorldNode(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: NodeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NodeType.waypoint,
      ),
      requiredLevel: json['requiredLevel'] as int? ?? 1,
      connectedNodeIds: (json['connectedNodeIds'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      archetype: json['archetype'] as String?,
      stage: json['stage'] as int? ?? 1,
      levelInStage: json['levelInStage'] as int? ?? 1,
      primaryAttributes: (json['primaryAttributes'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      nodeXp: json['nodeXp'] as int? ?? 0,
      nodeXpRequired: json['nodeXpRequired'] as int? ?? 100,
      missionCompleted: json['missionCompleted'] as bool? ?? false,
    );
  }

  // Update toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'requiredLevel': requiredLevel,
      'connectedNodeIds': connectedNodeIds,
      'archetype': archetype,
      'stage': stage,
      'levelInStage': levelInStage,
      'primaryAttributes': primaryAttributes,
      'nodeXp': nodeXp,
      'nodeXpRequired': nodeXpRequired,
      'missionCompleted': missionCompleted,
    };
  }

  // ADD: Helper to check if node is complete
  bool get isComplete => nodeXp >= nodeXpRequired;

  // ADD: Helper to get completion percentage
  double get completionPercent => nodeXp / nodeXpRequired;
}
```

**Step 2: Commit**

```bash
git add lib/features/world_map/domain/models/world_node.dart
git commit -m "feat: add stage, attributes, and XP tracking to WorldNode"
```

---

## Phase 2: Node Display & Mission Gates

### Task 2.1: Create Node State Calculator

**Files:**
- Create: `lib/features/world_map/domain/services/node_state_service.dart`

**Step 1: Create node state service**

Create new file `lib/features/world_map/domain/services/node_state_service.dart`:

```dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';

/// Node states for UI rendering
enum NodeState {
  locked,
  active,
  completed,
}

/// Service to calculate node states based on user progress
class NodeStateService {
  /// Calculate the state of a node based on user progress
  static NodeState calculateState(
    WorldNode node,
    UserProfile userProfile,
    List<String> completedNodeIds,
  ) {
    // If mission is explicitly completed, it's done
    if (node.missionCompleted || completedNodeIds.contains(node.id)) {
      return NodeState.completed;
    }

    // Check if user level meets requirement
    final userLevel = userProfile.avatarStats.level;
    if (userLevel < node.requiredLevel) {
      return NodeState.locked;
    }

    // Check if previous node in sequence is complete
    // For linear progression, find the node with lower level in same stage
    // This is a simplified check - in practice, you'd traverse the node graph
    if (node.levelInStage > 1) {
      // Assuming nodes are ordered by levelInStage in the stage
      // Previous node would have levelInStage - 1
      // This requires the node list to check against
    }

    // If we pass all checks, node is active
    return NodeState.active;
  }

  /// Get lock reason for display
  static String getLockReason(
    WorldNode node,
    UserProfile userProfile,
  ) {
    final userLevel = userProfile.avatarStats.level;

    if (userLevel < node.requiredLevel) {
      return 'Reach level ${node.requiredLevel} to unlock this node';
    }

    return 'Complete the previous mission to unlock this node';
  }

  /// Get completed node IDs from user profile
  static List<String> getCompletedNodeIds(UserProfile profile) {
    return profile.worldState?['completedNodeIds'] as List<dynamic>? ??
            [];
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/world_map/domain/services/node_state_service.dart
git commit -m "feat: add node state calculator service"
```

---

### Task 2.2: Update Structure Node Widget

**Files:**
- Modify: `lib/features/world_map/presentation/widgets/structure_node.dart`

**Step 1: Add node XP display to structure node**

Open `lib/features/world_map/presentation/widgets/structure_node.dart`

Update the node display to show XP progress:

```dart
// In the _StructureNodePainter build method, add XP display:

// Add inside the node content area:
if (nodeState != NodeState.locked) {
  // XP Progress Bar
  final xpProgress = node.completionPercent;
  final xpText = '${node.nodeXp}/${node.nodeXpRequired}';

  // Draw progress bar background
  final progressRect = Rect.fromLTWH(
    nodeBounds.left + 8,
    nodeBounds.bottom - 24,
    nodeBounds.width - 16,
    6,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(progressRect, Radius.circular(3)),
    Paint()..color = Colors.white.withValues(alpha: 0.2),
  );

  // Draw progress fill
  final fillRect = Rect.fromLTWH(
    progressRect.left,
    progressRect.top,
    progressRect.width * xpProgress.clamp(0.0, 1.0),
    progressRect.height,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(fillRect, Radius.circular(3)),
    Paint()..color = ArchetypeColors.forAttribute(node.primaryAttributes.firstOrNull ?? 'strength'),
  );

  // Draw XP text
  final textPainter = TextPainter(
    text: TextSpan(
      text: xpText,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      nodeBounds.center.dx - textPainter.width / 2,
      progressRect.top - 14,
    ),
  );
}

// Add lock icon for locked nodes
if (nodeState == NodeState.locked) {
  final lockIcon = Icons.lock;
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(lockIcon.codePoint),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 24,
        fontFamily: lockIcon.fontFamily,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      nodeBounds.center.dx - textPainter.width / 2,
      nodeBounds.center.dy - textPainter.height / 2,
    ),
  );
}
```

**Step 2: Add tap handler with soft gate**

```dart
// In StructureNode widget, update GestureDetector:
onTap: () {
  final nodeState = NodeStateService.calculateState(
    node,
    userProfile,
    completedNodeIds,
  );

  if (nodeState == NodeState.locked) {
    // Show soft gate message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(NodeStateService.getLockReason(node, userProfile)),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  // Navigate to node detail or show mission
  context.push('/node/${node.id}');
},
```

**Step 3: Commit**

```bash
git add lib/features/world_map/presentation/widgets/structure_node.dart
git commit -m "feat: add XP display and soft gate to structure nodes"
```

---

## Phase 3: Level-Up System

### Task 3.1: Fix Level-Up Listener

**Files:**
- Modify: `lib/features/gamification/presentation/widgets/level_up_listener.dart`

**Step 1: Update level detection logic**

Open `lib/features/gamification/presentation/widgets/level_up_listener.dart`

```dart
class LevelUpListener extends StateNotifier<LevelUpListenerState> {
  // ... existing code ...

  void _checkForLevelUp(UserProfile newProfile) {
    final currentLevel = newProfile.avatarStats.level;

    // Get last celebrated level from prefs
    final lastCelebrated = _prefs.getInt('last_celebrated_level') ?? 0;

    // Check if we've gained any levels since last celebration
    if (currentLevel > lastCelebrated) {
      // Celebrate each level we haven't celebrated yet
      for (int level = lastCelebrated + 1; level <= currentLevel; level++) {
        // Trigger level-up screen
        _navigationKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => LevelUpRewardScreen(level: level),
          ),
        );
      }

      // Store the new celebrated level
      _prefs.setInt('last_celebrated_level', currentLevel);
    }
  }

  // In the listener callback, update to track previous level:
  UserProfile? _previousProfile;

  void _onProfileChanged(UserProfile? profile) {
    if (profile == null) return;

    final previousLevel = _previousProfile?.avatarStats.level ?? 0;
    final currentLevel = profile.avatarStats.level;

    if (currentLevel > previousLevel) {
      _checkForLevelUp(profile);
    }

    _previousProfile = profile;
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/gamification/presentation/widgets/level_up_listener.dart
git commit -m "fix: trigger level-up screen for every level increase"
```

---

## Phase 4: Synergy Card Expansion

### Task 4.1: Update Synergy Status Card

**Files:**
- Modify: `lib/features/profile/presentation/widgets/synergy_status_card.dart`

**Step 1: Update card to show 2 attributes**

Open `lib/features/profile/presentation/widgets/synergy_status_card.dart`

```dart
// Update the card content to display 2 attributes side by side:

Widget _buildCardContent(BuildContext context, UserProfile profile) {
  final attributeXp = profile.avatarStats.attributeXp;
  final attributes = ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'];

  // Sort by XP descending, take top 2
  final sortedAttrs = attributes
      .where((a) => attributeXp.containsKey(a))
      .toList()
      ..sort((a, b) => (attributeXp[b] ?? 0).compareTo(attributeXp[a] ?? 0));

  final topAttrs = sortedAttrs.take(2).toList();

  return Column(
    children: [
      // Two attributes side by side
      Row(
        children: topAttrs.map((attr) => Expanded(
          child: _AttributeDisplay(
            attribute: attr,
            xp: attributeXp[attr] ?? 0,
            habits: _getHabitsForAttribute(attr),
          ),
        )).toList(),
      ),

      SizedBox(height: 12),

      // See More button
      if (sortedAttrs.length > 2)
        GestureDetector(
          onTap: () => _showAttributeBreaksheet(context, profile),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${sortedAttrs.length - 2} See More',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.expand_more, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
    ],
  );
}

class _AttributeDisplay extends StatelessWidget {
  final String attribute;
  final int xp;
  final List<Habit> habits;

  const _AttributeDisplay({
    required this.attribute,
    required this.xp,
    required this.habits,
  });

  @override
  Widget build(BuildContext context) {
    final color = ArchetypeColors.forAttribute(attribute);
    final icon = _getAttributeIcon(attribute);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            attribute.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '$xp XP',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (habits.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              '+${habits.first.impact} from ${habits.first.title}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
```

**Step 2: Create Attribute Breakdown Sheet**

```dart
// Add to synergy_status_card.dart:

void _showAttributeBreaksheet(BuildContext context, UserProfile profile) {
  final attributeXp = profile.avatarStats.attributeXp;
  final attributes = ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'];
  final sortedAttrs = attributes
      .where((a) => attributeXp.containsKey(a))
      .toList()
      ..sort((a, b) => (attributeXp[b] ?? 0).compareTo(attributeXp[a] ?? 0));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'All Attribute Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Total level
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Total Level: ${profile.avatarStats.level}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.1)),

          // Attribute list
          ...sortedAttrs.map((attr) => ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ArchetypeColors.forAttribute(attr).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAttributeIcon(attr),
                color: ArchetypeColors.forAttribute(attr),
              ),
            ),
            title: Text(
              attr.toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '${attributeXp[attr] ?? 0} XP',
              style: TextStyle(
                color: ArchetypeColors.forAttribute(attr),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )),

          SizedBox(height: 24),
        ],
      ),
    ),
  );
}

IconData _getAttributeIcon(String attribute) {
  switch (attribute.toLowerCase()) {
    case 'strength': return Icons.fitness_center;
    case 'intellect': return Icons.psychology;
    case 'vitality': return Icons.favorite;
    case 'creativity': return Icons.palette;
    case 'focus': return Icons.center_focus_strong;
    case 'spirit': return Icons.auto_awesome;
    default: return Icons.stars;
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/profile/presentation/widgets/synergy_status_card.dart
git commit -m "feat: expand synergy cards to 2 attrs + breakdown sheet"
```

---

## Phase 5: Archetype Maps & Zealot Content

### Task 5.1: Update Archetype Maps Catalog

**Files:**
- Modify: `lib/features/world_map/domain/models/archetype_maps_catalog.dart`

**Step 1: Add Zealot archetype definition**

Open `lib/features/world_map/domain/models/archetype_maps_catalog.dart`

Add the complete Zealot archetype:

```dart
/// Zealot archetype - devotion and spiritual strength
class ZealotArchetype {
  static const String archetypeKey = 'zealot';

  static List<WorldNode> getNodes() {
    return [
      // STAGE 1: SHRINE (Levels 1-5)
      WorldNode(
        id: 'zealot_1_1',
        title: 'First Flame',
        description: 'Light your first flame of devotion',
        type: NodeType.waypoint,
        requiredLevel: 1,
        stage: 1,
        levelInStage: 1,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_1_2'],
      ),
      WorldNode(
        id: 'zealot_1_2',
        title: 'Inner Fire',
        description: 'Complete 3 devotional habits',
        type: NodeType.resource,
        requiredLevel: 2,
        stage: 1,
        levelInStage: 2,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_1_3'],
      ),
      WorldNode(
        id: 'zealot_1_3',
        title: 'Trial of Devotion',
        description: 'Maintain a 5-day streak and complete a strength workout',
        type: NodeType.challenge,
        requiredLevel: 3,
        stage: 1,
        levelInStage: 3,
        archetype: archetypeKey,
        primaryAttributes: ['spirit', 'strength'],
        connectedNodeIds: ['zealot_1_4'],
      ),
      WorldNode(
        id: 'zealot_1_4',
        title: 'Burning Focus',
        description: 'Practice morning ritual for 7 days',
        type: NodeType.resource,
        requiredLevel: 4,
        stage: 1,
        levelInStage: 4,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_1_5'],
      ),
      WorldNode(
        id: 'zealot_1_5',
        title: 'Flame Unleashed',
        description: 'Complete Stage 1 of the Zealot path',
        type: NodeType.milestone,
        requiredLevel: 5,
        stage: 1,
        levelInStage: 5,
        archetype: archetypeKey,
        primaryAttributes: ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'],
        connectedNodeIds: ['zealot_2_1'],
      ),

      // STAGE 2: CONCLAVE (Levels 6-10)
      WorldNode(
        id: 'zealot_2_1',
        title: 'Conclave Entry',
        description: 'Enter the sacred gathering',
        type: NodeType.waypoint,
        requiredLevel: 6,
        stage: 2,
        levelInStage: 1,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_2_2'],
      ),
      WorldNode(
        id: 'zealot_2_2',
        title: 'Devotional Chant',
        description: 'Complete 5 devotional habits in one week',
        type: NodeType.resource,
        requiredLevel: 7,
        stage: 2,
        levelInStage: 2,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_2_3'],
      ),
      WorldNode(
        id: 'zealot_2_3',
        title: 'Trial of Faith',
        description: '10-day streak with strength and spirit habits',
        type: NodeType.challenge,
        requiredLevel: 8,
        stage: 2,
        levelInStage: 3,
        archetype: archetypeKey,
        primaryAttributes: ['spirit', 'strength'],
        connectedNodeIds: ['zealot_2_4'],
      ),
      WorldNode(
        id: 'zealot_2_4',
        title: 'Sacred Ritual',
        description: 'Establish a 14-day meditation practice',
        type: NodeType.resource,
        requiredLevel: 9,
        stage: 2,
        levelInStage: 4,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_2_5'],
      ),
      WorldNode(
        id: 'zealot_2_5',
        title: 'Conclave Master',
        description: 'Complete Stage 2 of the Zealot path',
        type: NodeType.milestone,
        requiredLevel: 10,
        stage: 2,
        levelInStage: 5,
        archetype: archetypeKey,
        primaryAttributes: ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'],
        connectedNodeIds: ['zealot_3_1'],
      ),

      // STAGE 3: ASCENSION (Levels 11-15)
      WorldNode(
        id: 'zealot_3_1',
        title: 'Ascension Begin',
        description: 'Begin your journey to transcendence',
        type: NodeType.waypoint,
        requiredLevel: 11,
        stage: 3,
        levelInStage: 1,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_3_2'],
      ),
      WorldNode(
        id: 'zealot_3_2',
        title: 'Divine Connection',
        description: '7 consecutive days of perfect habit adherence',
        type: NodeType.resource,
        requiredLevel: 12,
        stage: 3,
        levelInStage: 2,
        archetype: archetypeKey,
        primaryAttributes: ['spirit', 'focus'],
        connectedNodeIds: ['zealot_3_3'],
      ),
      WorldNode(
        id: 'zealot_3_3',
        title: 'Trial of Transcendence',
        description: '21-day streak with all spirit-based habits',
        type: NodeType.challenge,
        requiredLevel: 13,
        stage: 3,
        levelInStage: 3,
        archetype: archetypeKey,
        primaryAttributes: ['spirit', 'strength', 'vitality'],
        connectedNodeIds: ['zealot_3_4'],
      ),
      WorldNode(
        id: 'zealot_3_4',
        title: 'Eternal Flame',
        description: 'Maintain a 30-day devotion practice',
        type: NodeType.resource,
        requiredLevel: 14,
        stage: 3,
        levelInStage: 4,
        archetype: archetypeKey,
        primaryAttributes: ['spirit'],
        connectedNodeIds: ['zealot_3_5'],
      ),
      WorldNode(
        id: 'zealot_3_5',
        title: 'Ascended',
        description: 'Complete Stage 3 - You have ascended!',
        type: NodeType.milestone,
        requiredLevel: 15,
        stage: 3,
        levelInStage: 5,
        archetype: archetypeKey,
        primaryAttributes: ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'],
        connectedNodeIds: [],
      ),
    ];
  }

  /// Get visual theme for Zealot
  static Map<String, dynamic> getTheme() {
    return {
      'primaryColor': 0xFFFFAB00,
      'accentColor': 0xFFFFD54F,
      'background': 'flame_gradient',
      'particle': 'ember',
      'architecture': 'cathedral',
    };
  }
}
```

**Step 2: Update catalog to include Zealot**

```dart
// In ArchetypeMapsCatalog, add:
static const Map<String, dynamic> allArchetypes = {
  // ... existing archetypes ...
  'zealot': {
    'nodes': ZealotArchetype.getNodes(),
    'theme': ZealotArchetype.getTheme(),
    'stageCount': 3,
    'levelsPerStage': 5,
  },
};
```

**Step 3: Fix Zealot journey link**

```dart
// Update the getArchetypeJourney method:
static List<WorldNode> getArchetypeJourney(String archetypeKey) {
  switch (archetypeKey.toLowerCase()) {
    case 'zealot':
      return ZealotArchetype.getNodes();
    // ... other cases ...
    default:
      return [];
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/world_map/domain/models/archetype_maps_catalog.dart
git commit -m "feat: add complete Zealot archetype with 15 levels"
```

---

### Task 5.2: Standardize All Archetypes to 5-Level Stages

**Files:**
- Modify: `lib/features/world_map/domain/models/archetype_maps_catalog.dart`

**Step 1: Update all archetypes with stage information**

For each archetype (Athlete, Scholar, Creator, Stoic, Explorer), update node definitions to include:
- `stage`: Sequential stage number (1, 2, 3...)
- `levelInStage`: Position within stage (1-5)
- `primaryAttributes`: List of affected attributes

Example pattern for Athlete:

```dart
// STAGE 1: VALLEY BASE (Levels 1-5)
WorldNode(
  id: 'athlete_1_1',
  title: 'First Steps',
  description: 'Begin your athletic journey',
  type: NodeType.waypoint,
  requiredLevel: 1,
  stage: 1,
  levelInStage: 1,
  archetype: 'athlete',
  primaryAttributes: ['strength'],
  connectedNodeIds: ['athlete_1_2'],
),
// ... continue pattern for all 5 nodes in stage
```

Repeat for all archetypes following the 5-node pattern:
1. Waypoint (level 1)
2. Resource (level 2)
3. Challenge (level 3)
4. Resource (level 4)
5. Milestone (level 5)

**Step 2: Commit**

```bash
git add lib/features/world_map/domain/models/archetype_maps_catalog.dart
git commit -m "feat: standardize all archetypes to 5 levels per stage"
```

---

## Phase 6: XP Flow Integration

### Task 6.1: Update XP Award Logic

**Files:**
- Modify: `lib/features/gamification/data/repositories/firestore_gamification_repository.dart`

**Step 1: Add node-based XP awarding**

```dart
/// Award XP to a specific node and its attributes
Future<void> awardNodeXp(
  String userId,
  String nodeId,
  int amount, {
  List<String>? attributes,
}) async {
  final profile = await getUserStats(userId);

  // Get the node to find its attributes
  final node = _getNodeById(nodeId);
  final targetAttributes = attributes ?? node?.primaryAttributes ?? [];

  // Add XP to each target attribute
  var updatedStats = profile.avatarStats;
  for (final attr in targetAttributes) {
    updatedStats = updatedStats.addAttributeXp(attr, amount);
  }

  // Also add to node XP
  // This would require tracking node XP separately
  // For now, we'll track it in worldState

  final updatedWorldState = Map<String, dynamic>.from(profile.worldState ?? {});
  final nodeProgress = Map<String, dynamic>.from(
    updatedWorldState['nodeProgress'] ?? {},
  );
  final currentNodeXp = (nodeProgress[nodeId]?['xp'] as int? ?? 0) + amount;
  nodeProgress[nodeId] = {
    'xp': currentNodeXp,
    'completed': currentNodeXp >= 100,
  };
  updatedWorldState['nodeProgress'] = nodeProgress;

  await _firestore.collection('user_stats').doc(userId).update({
    'avatarStats': updatedStats.toMap(),
    'worldState': updatedWorldState,
  });
}

WorldNode? _getNodeById(String nodeId) {
  // Search through all archetype nodes
  for (final archetype in ArchetypeMapsCatalog.allArchetypes.values) {
    final nodes = archetype['nodes'] as List<WorldNode>?;
    if (nodes != null) {
      try {
        return nodes.firstWhere((n) => n.id == nodeId);
      } catch (_) {
        continue;
      }
    }
  }
  return null;
}
```

**Step 2: Commit**

```bash
git add lib/features/gamification/data/repositories/firestore_gamification_repository.dart
git commit -m "feat: add node-based XP awarding"
```

---

## Phase 7: Testing & Verification

### Task 7.1: Create Integration Tests

**Files:**
- Create: `test/features/gamification/integration/level_progression_test.dart`

**Step 1: Write level-up trigger test**

```dart
test('Level-up screen triggers on every level increase', () async {
  // Arrange
  final container = ProviderContainer();
  final listener = container.read(levelUpListenerProvider.notifier);

  // Act - simulate level up from 1 to 2
  await listener.checkForLevelUp(UserProfile(
    uid: 'test',
    avatarStats: UserAvatarStats(level: 2, totalXp: 500),
  ));

  // Assert - level-up should be triggered
  expect(container.read(lastCelebratedLevelProvider), 2);
});
```

**Step 2: Run tests**

```bash
flutter test test/features/gamification/integration/level_progression_test.dart
```

**Step 3: Commit**

```bash
git add test/features/gamification/integration/
git commit -m "test: add level progression integration tests"
```

---

## Summary

### Files Modified/Created:

**Phase 1:**
- `lib/core/theme/archetype_theme.dart` (added ArchetypeColors)
- `lib/features/auth/domain/entities/user_extension.dart` (added attribute XP)
- `lib/features/world_map/domain/models/world_node.dart` (added stage/attributes)

**Phase 2:**
- `lib/features/world_map/domain/services/node_state_service.dart` (created)
- `lib/features/world_map/presentation/widgets/structure_node.dart` (updated)

**Phase 3:**
- `lib/features/gamification/presentation/widgets/level_up_listener.dart` (fixed)

**Phase 4:**
- `lib/features/profile/presentation/widgets/synergy_status_card.dart` (expanded)

**Phase 5:**
- `lib/features/world_map/domain/models/archetype_maps_catalog.dart` (Zealot + stages)

**Phase 6:**
- `lib/features/gamification/data/repositories/firestore_gamification_repository.dart` (XP logic)

**Phase 7:**
- `test/features/gamification/integration/level_progression_test.dart` (created)

### Commit Strategy:

1. Each task commits independently
2. Commit messages follow: `feat:`, `fix:`, `test:` prefix
3. Atomic changes - one logical unit per commit

### Rollback Plan:

If any phase fails, revert to last known good commit:
```bash
git log --oneline -10  # Find last good commit
git revert <commit-hash>  # Revert problematic commit
```
