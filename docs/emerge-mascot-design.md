# Emerge Mascot Design: **Koa** the Cosmic Turtle

**Version:** 1.0
**Status:** Proposal
**Aligns with:** `docs/design.md` (Design System), `docs/Emerge App_ Habit Formation Blueprint.md`

---

## 1. Why a Turtle?

The turtle is the perfect mascot for an identity-first habit engine:

| Turtle Trait | Habit Formation Parallel |
|-------------|-------------------------|
| **Slow but steady** | "1% better every day" — compound growth |
| **Carries its home** | Identity travels with you — habits are portable |
| **Long-lived** | Long-term thinking, not quick fixes |
| **Resilient shell** | Mental fortitude, emotional regulation |
| **Wise (cultural association)** | Scholar archetype, reflection, mastery |
| **Grounded** | Stoic archetype, presence, mindfulness |

The turtle embodies **"never miss twice"** — they don't sprint, they persist.

---

## 2. Character Design

### 2.1 Name: **Koa**

- **Meaning:** Hawaiian for "warrior," "brave," "confident"
- **Pronunciation:** KO-ah
- **Why:** Connects to the Athlete archetype's strength while remaining approachable. Short, memorable, easy to say in notifications.

### 2.2 Visual Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Cosmic aesthetic** | Shell has nebula-like swirls (purple/teal gradients) |
| **Round shapes** | Friendly, non-threatening (matches glassmorphism softness) |
| **Minimal detail** | Recognizable at 32px (favicon) to billboard |
| **Archetype-responsive** | Shell color shifts based on user's primary archetype |
| **Expressive eyes** | Large, warm eyes that convey emotion clearly |

### 2.3 Base Design Specifications

```
Proportions:
- Head: 40% of body height (large = cute, approachable)
- Shell: 45% of body width (prominent but not overwhelming)
- Limbs: Short, rounded (emphasizes "slow and steady")
- Eyes: 25% of head width (expressive, warm)

Color Palette (Default - Explorer):
- Shell Base: #1A0A2A (cosmic void center)
- Shell Swirls: #2BEE79 (neon teal) + #A5E7FF (nebula blue)
- Body: #2A1A3A (cosmic mid-purple)
- Belly: #14FFFFFF (glass white, 8% opacity effect)
- Eyes: White with #2BEE79 iris glow
- Cheeks: #FF8E72 (soft coral blush)

Style:
- Flat design with bold outlines (2px, #0A0A1A)
- Subtle glow effect on shell (matches cosmic theme)
- No outlines on eyes (clean, modern)
- Rounded corners on all shapes (no sharp edges)
```

---

## 3. Archetype Shell Variants

Koa's shell changes color based on the user's primary archetype. This reinforces identity visually — the mascot literally embodies who the user is becoming.

| Archetype | Shell Primary | Shell Accent | Visual Effect |
|-----------|--------------|--------------|---------------|
| **Athlete** | #FF5252 (red) | #FF8E72 (coral) | Flame-like swirls, kinetic energy lines |
| **Scholar** | #7C3AED (purple) | #B794F6 (lavender) | Star chart patterns, constellation glow |
| **Creator** | #FFD700 (gold) | #FFD93D (yellow) | Paint splatter accents, creative sparkles |
| **Stoic** | #26A69A (teal) | #4DD4AC (mint) | Zen garden patterns, serene mist |
| **Zealot** | #991B1B (crimson) | #B45309 (ember) | Flame aura, intense glow |
| **Explorer** | #009688 (teal) | #64FFDA (cyan) | Compass rose, map-like contours |

**Implementation:** The shell uses a base gradient with an overlay pattern. The pattern is a `CustomPainter` that draws archetype-specific shapes (flames, stars, paint drops, etc.) using the accent color at 30% opacity.

---

## 4. Expression System

Koa has **7 core expressions** that map to user behavior and app states. Each expression is a distinct pose/emotion.

### 4.1 Expression Catalog

| Expression | When Shown | Visual | Audio |
|------------|-----------|--------|-------|
| **Happy** | Habit completed, streak milestone | Eyes sparkle, gentle smile, slight bounce | Soft chime (C major chord) |
| **Excited** | Level up, major achievement, world event | Wide eyes, open smile, arms raised, shell glows | Triumphant fanfare |
| **Neutral** | Default idle state | Relaxed pose, gentle half-smile | None |
| **Encouraging** | User opens app after inactivity | Warm smile, head tilt, one arm extended | Gentle whoosh |
| **Sad** | Streak broken, missed habits | Downturned mouth, droopy eyes, shell dims | Soft descending tone |
| **Sleepy** | Late night / early morning usage | Half-closed eyes, yawning, "zzz" particles | Soft snore |
| **Proud** | Weekly/monthly recap, transformation trailer | Chest puffed, arms crossed, shell radiant | Rising crescendo |

### 4.2 Expression State Machine

```
                    ┌─────────────┐
                    │   Neutral   │ ← default
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │  Happy   │    │Excited   │    │Encouraging│
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │               │               │
         └───────┬───────┴───────┬───────┘
                 │               │
                 ▼               ▼
          ┌──────────┐    ┌──────────┐
          │  Proud   │    │   Sad    │
          └──────────┘    └──────────┘

    Sleepy: Independent state (time-based, not behavior-based)
```

### 4.3 Expression Triggers (Technical)

```dart
enum MascotExpression {
  neutral,      // Default / idle
  happy,        // Habit completed (single)
  excited,      // Level up, streak milestone (7+ days)
  encouraging,  // User returns after 2+ day gap
  sad,          // Streak broken, missed 2+ days
  sleepy,       // Usage between 10pm-6am local time
  proud,        // Weekly recap, world milestone
}

// Trigger logic:
MascotExpression resolveExpression({
  required HabitCompletionEvent? lastEvent,
  required int currentStreak,
  required int daysSinceLastActive,
  required int hourOfDay,
  required bool isMilestone,
}) {
  // Time-based override
  if (hourOfDay >= 22 || hourOfDay < 6) return MascotExpression.sleepy;
  
  // Behavior-based
  if (isMilestone) return MascotExpression.proud;
  if (daysSinceLastActive >= 2) return MascotExpression.encouraging;
  if (lastEvent == EventType.streakBroken) return MascotExpression.sad;
  if (currentStreak >= 7) return MascotExpression.excited;
  if (lastEvent == EventType.habitCompleted) return MascotExpression.happy;
  
  return MascotExpression.neutral;
}
```

---

## 5. Integration Points

### 5.1 Narrator System Replacement

The current `NarratorAvatar` (44dp circle with "✦") becomes Koa:

**Current:**
```dart
// narrator_avatar.dart
child: Text('✦', style: TextStyle(fontSize: 14, color: Colors.white)),
```

**Proposed:**
```dart
// narrator_avatar.dart
child: MascotAvatar(
  expression: currentExpression,
  size: 44,
  archetype: userArchetype,
),
```

### 5.2 Timeline Integration

Koa appears on the Timeline screen as a **small companion** (32dp) in the top-right corner, next to the progress ring:

```
┌──────────────────────────────┐
│  Good morning, Explorer  🐢  │  ← Koa with "happy" expression
│  ┌────────────────────────┐  │
│  │    Today's Progress    │  │
│  │        ◯ 3/5           │  │
│  └────────────────────────┘  │
│  ...habits list...           │
└──────────────────────────────┘
```

### 5.3 World Map Integration

On the World Map, Koa sits at the user's **current position** — the cursor/avatar on the map is Koa walking through the user's digital world. As the world grows, Koa explores new areas.

### 5.4 Empty States

Koa appears in all empty states with appropriate expressions:

| Empty State | Koa's Expression | Copy |
|-------------|-----------------|------|
| No habits yet | Encouraging | "Ready to start your journey? I'll be right here." |
| All habits complete | Proud | "You did it! Time to rest." |
| World is empty | Encouraging | "Your world is waiting. Let's build it together." |
| No reflections | Sleepy | "Even I rest sometimes. Try tonight?" |

### 5.5 Notification Voice

Koa sends notifications in first person, matching the expression:

```dart
const Map<MascotExpression, List<String>> notificationLines = {
  MascotExpression.happy: [
    "That's one vote for your future self! 🐢",
    "You showed up. That matters.",
  ],
  MascotExpression.excited: [
    "7 days strong! You're building something real.",
    "Level up! Your world just got bigger.",
  ],
  MascotExpression.encouraging: [
    "Missed you. No judgment — let's start fresh.",
    "Even turtles rest. Ready to move again?",
  ],
  MascotExpression.sad: [
    "We broke the streak, but not the habit. Tomorrow?",
    "One miss doesn't erase your progress.",
  ],
  MascotExpression.sleepy: [
    "Still up? One small habit before bed?",
    "Late night reflection? I'm here.",
  ],
  MascotExpression.proud: [
    "Look how far you've come. 🐢",
    "Your world is thriving because of you.",
  ],
};
```

---

## 6. Animation Specifications

### 6.1 Idle Animation

Koa has a subtle **breathing animation** when idle:

```dart
// Subtle scale pulse: 0.98 → 1.02 → 0.98
// Duration: 3 seconds (loop)
// Easing: Curves.easeInOut
// Applies to: entire mascot body
```

### 6.2 Expression Transition

When expression changes, Koa transitions with a **morph**:

```dart
// Transition type: AnimatedSwitcher with fade + scale
// Duration: 200ms (animationMedium)
// Scale: 0.9 → 1.0 (slight bounce)
// Key: ValueKey(expression.name) for proper switching
```

### 6.3 Completion Celebration

When a habit is completed:

```dart
// 1. Koa bounces (scale 1.0 → 1.15 → 1.0, 300ms)
// 2. Shell glows (opacity 0 → 0.4 → 0, 500ms)
// 3. Particle burst from shell (30 particles, archetype colors)
// 4. Koa settles into "happy" expression
```

### 6.4 Streak Break Reaction

When a streak is broken:

```dart
// 1. Koa shrinks slightly (scale 1.0 → 0.95, 200ms)
// 2. Shell dims (brightness -20%, 300ms)
// 3. Koa looks down (expression morph to "sad")
// 4. After 2 seconds: gentle bounce (encouraging animation)
```

---

## 7. Asset Specifications

### 7.1 Required Assets

| Asset | Size | Format | Purpose |
|-------|------|--------|---------|
| `koa_base.png` | 512×512 | PNG (transparent) | Base mascot for rendering |
| `koa_expressions/` | 512×512 each | PNG (transparent) | 7 expression variants |
| `koa_shell_patterns/` | 256×256 | SVG/PNG | 6 archetype shell overlays |
| `koa_favicon.png` | 32×32, 64×64, 128×128 | PNG | App icon variants |
| `koa_notification.png` | 96×96 | PNG | Push notification icon |
| `koa_lottie/` | - | Lottie JSON | Animated expressions |

### 7.2 Naming Convention

```
assets/
  mascot/
    koa_happy.png
    koa_neutral.png
    koa_sad.png
    koa_excited.png
    koa_encouraging.png
    koa_sleepy.png
    koa_proud.png
    koa_shell_athlete.png
    koa_shell_scholar.png
    koa_shell_creator.png
    koa_shell_stoic.png
    koa_shell_zealot.png
    koa_shell_explorer.png
    koa_favicon_32.png
    koa_favicon_64.png
    koa_favicon_128.png
    koa_notification.png
    koa_idle.json (Lottie)
    koa_happy.json (Lottie)
    koa_sad.json (Lottie)
```

---

## 8. Personality & Voice

### 8.1 Personality Traits

| Trait | Description | Example Behavior |
|-------|-------------|------------------|
| **Warm** | Never cold or robotic | Uses "we" and "let's" instead of "you should" |
| **Patient** | Never rushes or shames | "No judgment" after missed days |
| **Witty** | Light humor, never sarcastic | "Even turtles beat the hare" |
| **Loyal** | Always present, never abandons | "I'm right here" in empty states |
| **Honest** | Direct but kind | "We broke the streak" not "Oops!" |

### 8.2 Voice Rules

| Rule | Do | Don't |
|------|-----|-------|
| First person | "I'm proud of you" | "The app is proud" |
| Identity-focused | "You're acting like a Writer" | "You wrote today" |
| Never shame | "Let's try again" | "You failed" |
| Brief | "3 of 5 done!" | "You have completed 3 out of 5 habits" |
| Specific | "Tuesday is your strongest day" | "You're doing well" |
| Warm but not cutesy | "Great streak!" | "You're a super-duper star! ⭐⭐⭐" |

### 8.3 Notification Copy by Context

**Morning:**
```
"Good morning! Ready to vote for your future self? 🐢"
"Your world is waiting. Let's make today count."
```

**Afternoon:**
```
"Quick check-in — 2 habits left today. You've got this."
"Halfway through the day. Halfway through your list too."
```

**Evening:**
```
"Wind-down time. One reflection before bed?"
"Today's done. Your world grew a little. 🐢"
```

**Streak Milestone:**
```
"7 days! You're not just building habits — you're building identity."
"30 days strong. Look how far you've come."
```

**Return After Break:**
```
"Missed you. No judgment — let's start fresh."
"Even I rest sometimes. Ready to move again?"
```

---

## 9. Accessibility

### 9.1 Screen Reader Support

```dart
Semantics(
  label: 'Koa, your habit companion',
  hint: 'Shows your mascot with current expression',
  child: MascotWidget(...),
)
```

### 9.2 Reduced Motion

When `MediaQuery.disableAnimations` is true:
- Koa displays static expression (no idle animation)
- Expression transitions are instant (no morph)
- No particle effects on completion
- Shell glow is disabled

### 9.3 Color Contrast

- Koa's eyes must meet WCAG AA (4.5:1) against shell
- Expression indicators must not rely on color alone (add icon/text)
- Shell patterns must be visible in grayscale mode

---

## 10. Implementation Roadmap

### Phase 1: Core Mascot (Week 1-2)
- [ ] Create base Koa design (neutral expression)
- [ ] Implement `MascotAvatar` widget
- [ ] Replace `NarratorAvatar` with Koa
- [ ] Add idle animation

### Phase 2: Expressions (Week 3-4)
- [ ] Create all 7 expression variants
- [ ] Implement expression state machine
- [ ] Add expression triggers to narrator engine
- [ ] Animate expression transitions

### Phase 3: Archetype Shells (Week 5)
- [ ] Create 6 shell pattern variants
- [ ] Integrate with archetype selection
- [ ] Add shell color transitions

### Phase 4: Integration (Week 6)
- [ ] Timeline companion positioning
- [ ] World Map cursor replacement
- [ ] Empty state illustrations
- [ ] Notification voice integration

### Phase 5: Polish (Week 7)
- [ ] Lottie animations for key moments
- [ ] Sound effects for expressions
- [ ] Accessibility audit
- [ ] Performance optimization

---

## 11. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Notification open rate** | +15% vs current | Firebase Analytics |
| **Daily active users** | +10% | Firebase Analytics |
| **Empty state CTA click rate** | +25% | Custom event tracking |
| **App store reviews mentioning mascot** | 5+ positive | Manual review |
| **Social shares of mascot moments** | 100+/month | Share button tracking |

---

## 12. Open Questions

1. **Shell animation:** Should the shell swirls animate (slow rotation) or remain static?
2. **Sound design:** Should Koa have a "voice" (pitched sounds) or just UI sounds?
3. **Seasonal variants:** Should Koa have holiday-themed accessories ( santa hat, etc.)?
4. **User customization:** Should users be able to name Koa or choose alternate mascots?
5. **Multi-language:** How does the name "Koa" translate across supported languages?

---

**Document Author:** ZCode Agent
**Last Updated:** 2026-07-28
**Status:** Ready for review
