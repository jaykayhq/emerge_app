# World Map Immersive Portal Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the World Map screen into an immersive 3D experience with GLSL shaders, gesture controls, and a cohesive animation flow from the Timeline to the Attribute Details. Incorporates ambient particles, glowing constellations, and a glassmorphic HUD.

**Architecture:** Use a `FragmentProgram` inside `CentralHealthOrb` for performant GPU rendering. We'll add query parameters to go_router for `/world-map?focusAttribute=strength` to trigger the zoom/anchor animation in `WorldRingLayout` before it proceeds to `/attribute/strength`. We will redesign `WorldTypeNode` into a 3D-styled node, add particle and line layers, and a glassmorphic HUD.

**Tech Stack:** Flutter, GLSL (Fragment Shaders), go_router, Riverpod.

---

### Task 1: Fragment Shader Integration for Central Orb

**Files:**
- Create: `shaders/cracked_orb.frag`
- Modify: `pubspec.yaml`
- Modify: `lib/features/world_map/presentation/widgets/central_health_orb.dart`
- Test: `test/features/world_map/presentation/widgets/central_health_orb_test.dart`

- [ ] **Step 1: Write the GLSL Fragment Shader**

```glsl
// shaders/cracked_orb.frag
#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_pan;
uniform float u_health_pct; // 0.0 to 1.0

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / u_resolution;
    // Simple placeholder logic for an orb with cracks and rotation
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    if (dist > 0.5) {
        fragColor = vec4(0.0);
        return;
    }
    
    // Simulate 3D rotation with pan
    vec2 rotatedUv = uv + u_pan * 0.1;
    
    // Simulated cracks based on health (lower health = more visible)
    float crack = sin(rotatedUv.x * 20.0 + u_time) * cos(rotatedUv.y * 20.0 + u_time);
    float crackIntensity = (1.0 - u_health_pct) * step(0.8, crack);
    
    // Base glow
    vec3 baseColor = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), u_health_pct);
    vec3 finalColor = mix(baseColor, vec3(0.0), crackIntensity);
    
    // 3D Sphere shading
    float lighting = 1.0 - (dist / 0.5);
    finalColor *= lighting;
    
    fragColor = vec4(finalColor, 1.0);
}
```

- [ ] **Step 2: Add shader to pubspec.yaml**

```yaml
flutter:
  shaders:
    - shaders/cracked_orb.frag
```

- [ ] **Step 3: Write failing test for CentralHealthOrb**

```dart
// test/features/world_map/presentation/widgets/central_health_orb_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/central_health_orb.dart';

void main() {
  testWidgets('CentralHealthOrb tracks 7 taps for easter egg', (tester) async {
    int easterEggCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CentralHealthOrb(
          currentHealth: 50,
          maxHealth: 100,
          onEasterEggTriggered: () => easterEggCount++,
        ),
      ),
    ));

    final orb = find.byType(GestureDetector).first;
    for (int i = 0; i < 7; i++) {
      await tester.tap(orb);
    }
    
    expect(easterEggCount, 1);
  });
}
```

- [ ] **Step 4: Implement CentralHealthOrb with Shader and Gestures**

```dart
// lib/features/world_map/presentation/widgets/central_health_orb.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class CentralHealthOrb extends StatefulWidget {
  final double currentHealth;
  final double maxHealth;
  final VoidCallback? onTap;
  final VoidCallback? onEasterEggTriggered;

  const CentralHealthOrb({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
    this.onTap,
    this.onEasterEggTriggered,
  });

  @override
  State<CentralHealthOrb> createState() => _CentralHealthOrbState();
}

class _CentralHealthOrbState extends State<CentralHealthOrb> with SingleTickerProviderStateMixin {
  FragmentProgram? _program;
  late Ticker _ticker;
  double _time = 0.0;
  Offset _pan = Offset.zero;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    })..start();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/cracked_orb.frag');
    if (mounted) setState(() => _program = program);
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 1)) {
      _tapCount = 1;
    } else {
      _tapCount++;
      if (_tapCount == 7) {
        widget.onEasterEggTriggered?.call();
        _tapCount = 0;
      }
    }
    _lastTapTime = now;
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) return const CircularProgressIndicator();

    final healthPct = (widget.currentHealth / widget.maxHealth).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: (details) {
        setState(() {
          _pan += details.delta;
        });
      },
      child: CustomPaint(
        size: const Size(200, 200),
        painter: _OrbPainter(
          program: _program!,
          time: _time,
          pan: _pan,
          healthPct: healthPct,
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final FragmentProgram program;
  final double time;
  final Offset pan;
  final double healthPct;

  _OrbPainter({required this.program, required this.time, required this.pan, required this.healthPct});

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, pan.dx);
    shader.setFloat(4, pan.dy);
    shader.setFloat(5, healthPct);
    
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}
```

- [ ] **Step 5: Run tests and commit**
Run: `flutter test test/features/world_map/presentation/widgets/central_health_orb_test.dart`
Expected: PASS
Commit: `git add pubspec.yaml shaders/cracked_orb.frag lib/... test/...`
`git commit -m "feat(world): integrate fragment shader for 3D cracked orb with gestures and easter egg"`

---

### Task 2: Redesign WorldTypeNode (Attribute Nodes)

**Files:**
- Modify: `lib/features/world_map/presentation/widgets/world_type_node.dart`
- Test: `test/features/world_map/presentation/widgets/world_type_node_test.dart`

- [ ] **Step 1: Write failing test**
Ensure the node displays its proper string name and primaryColor.

```dart
// test/features/world_map/presentation/widgets/world_type_node_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

void main() {
  testWidgets('WorldTypeNode displays correct label and styled container', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WorldTypeNode(attribute: HabitAttribute.strength, onTap: () {}),
      ),
    ));

    expect(find.text('Strength'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify failure**
Run: `flutter test test/features/world_map/presentation/widgets/world_type_node_test.dart`
Expected: FAIL (Text says `config.worldName` which might be different than `Strength`, and we need to enforce the color application).

- [ ] **Step 3: Implement 3D WorldTypeNode styling**

```dart
// lib/features/world_map/presentation/widgets/world_type_node.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:flutter/material.dart';

// Helper if attribute enum doesn't map cleanly to names directly
String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

class WorldTypeNode extends StatelessWidget {
  final HabitAttribute attribute;
  final VoidCallback onTap;

  const WorldTypeNode({
    super.key,
    required this.attribute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = WorldTypeConfig.forAttribute(attribute);
    final theme = Theme.of(context);
    final String labelName = _capitalize(attribute.name);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.primaryColor.withValues(alpha: 0.15),
              border: Border.all(color: config.primaryColor, width: 2),
              // 3D pop effect
              boxShadow: [
                BoxShadow(
                  color: config.primaryColor.withValues(alpha: 0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              config.fallbackIcon,
              color: config.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              labelName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: config.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test and commit**
Run: `flutter test test/features/world_map/presentation/widgets/world_type_node_test.dart`
Expected: PASS
Commit: `git add lib/features/world_map/presentation/widgets/world_type_node.dart test/...`
`git commit -m "design(world): redesign WorldTypeNode with 3D shadows and solid attribute names"`

---

### Task 3: Bridge Routing Logic (Timeline -> WorldMap -> Attribute)

**Files:**
- Modify: `lib/core/router/router.dart`
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`

- [ ] **Step 1: Write routing unit test**

```dart
// Add to test/core/router/router_test.dart (or equivalent)
// test redirection or path building
```

- [ ] **Step 2: Update router & timeline**

Modify `lib/features/timeline/presentation/screens/timeline_screen.dart` (or `habit_timeline_section.dart` call site) to push to world map with focus:
```dart
// Find where onHabitTap is defined and change the navigation action
context.go('/world-map?focus=${habit.attribute.name}');
```

- [ ] **Step 3: Update WorldMapScreen to handle Focus Animation**

```dart
// lib/features/world_map/presentation/screens/world_map_screen.dart
// Update WorldMapScreen to accept focus Attribute, run a quick animation 
// (e.g. scale up the tapped node using a Tween), and then delay and navigate:

class WorldMapScreen extends ConsumerStatefulWidget {
  final String? focusAttribute;
  const WorldMapScreen({super.key, this.focusAttribute});
  // ...
```
*(Implementation details will be coded during execution to hook `focusAttribute` into `initState` delay and then `context.go('/attribute/$focusAttribute')`)*

- [ ] **Step 4: Verify UI manually**
Run: `flutter run`
Expected: Tapping a habit smoothly navigates to the World Map, highlights the node, then goes to Attribute details.

- [ ] **Step 5: Commit changes**
Commit: `git commit -am "feat(routing): bridge timeline to world map to attribute flow"`

---

### Task 4: World Map Ambient Layer & Constellations

**Files:**
- Create: `lib/features/world_map/presentation/widgets/ambient_particles.dart`
- Create: `lib/features/world_map/presentation/widgets/constellation_lines.dart`
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`

- [ ] **Step 1: Implement Particle Background**
Create `AmbientParticles` widget using a `CustomPainter` and `Ticker` to render floating, slowly moving stardust points that represent pure potential.

- [ ] **Step 2: Implement Constellation Lines**
Create `ConstellationLines` widget that takes the center orb coordinates and the node coordinates, drawing glowing lines using `Paint()..maskFilter = MaskFilter.blur(...)` to signify connection.

- [ ] **Step 3: Integrate into WorldMapScreen**
Place `AmbientParticles` behind the `WorldRingLayout` and `ConstellationLines` between the background and the nodes.

- [ ] **Step 4: Commit changes**
Commit: `git commit -am "feat(world): add ambient particles and constellation connections"`

---

### Task 5: World State HUD (Entropy / Vitality)

**Files:**
- Create: `lib/features/world_map/presentation/widgets/world_state_hud.dart`
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`

- [ ] **Step 1: Create Glassmorphic HUD**
Implement `WorldStateHUD` using `BackdropFilter` with `ui.ImageFilter.blur`, wrapping a `Row` that shows "Entropy" percentage and "Vitality" level in a high-tech/RPG style.

- [ ] **Step 2: Connect HUD to Providers**
Use `ConsumerWidget` to read the global health/entropy state from `worldHealthStreamProvider`.

- [ ] **Step 3: Position HUD on Screen**
Place `WorldStateHUD` at the top (safe area) of `WorldMapScreen` using a `Positioned` widget inside the main `Stack`.

- [ ] **Step 4: Commit changes**
Commit: `git commit -am "feat(world): add glassmorphic world state HUD for entropy and vitality"`

---
