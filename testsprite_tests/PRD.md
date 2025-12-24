# Emerge: Habit Formation Blueprint (Product Requirements Document)

## 1. Executive Summary
Emerge is an identity-first habit formation application designed to SUSTAIN long-term behavioral change by addressing the "Identity" layer of action. It gamifies real life by treating the user's progress as an evolving RPG character and world.

## 2. Core Vision
- **Identity-First**: Focus on "Who do I want to become?" rather than just "What do I want to log?"
- **Compound Interest Visualization**: Makes marginal gains visible through evolving avatars and worlds (City or Forest).
- **Behavioral Science Integration**: Built on the "Four Laws of Behavior Change" (Atomic Habits).

## 3. Key Features

### 3.1 RPG Character Creation (Onboarding)
- **Archetype Selection**: Athlete, Creator, Scholar, Stoic.
- **Identity Mapping**: Users select attributes (Vitality, Focus, Creativity) that define their character's path.
- **Habit Stacking Builder**: Tools to link new habits to existing "anchor" behaviors.

### 3.2 Dynamic Visual Progression
- **Morphing Avatar**: Evolves physically based on completions (e.g., strength habits add muscle/armor).
- **Living World (City/Forest)**: 
  - City builds skyscrapers for productivity/structure.
  - Forest grows trees and wildlife for wellness/mindfulness.
- **Habit Decay**: Visualizing entropy (weeds, fog, graffiti) when habits are missed.
- **Recovery Mechanic**: "Never Miss Twice" rule gamified to clear entropy immediately.

### 3.3 The Four Laws UX
1. **Cue (Make it Obvious)**: Context-aware dashboards (Morning/Evening stacks) and home screen widgets.
2. **Craving (Make it Attractive)**: Dopamine spikes via anticipation, leveling up, and social tribes.
3. **Response (Make it Easy)**: "Two-Minute Rule" mode to lower the barrier to entry.
4. **Reward (Make it Satisfying)**: Instant visual/auditory feedback and real-world rewards (Sponsored Challenges).

### 3.4 AI Goldilocks Engine
- **Dynamic Difficulty**: Adjusts habit targets based on consistency (Flow State optimization).
- **Pattern Recognition**: Identifies anti-patterns and suggests stack re-ordering.
- **Identity Affirmation**: AI-generated reports that speak to the user's desired persona.

## 4. Technical Requirements
- **Flutter SDK**: ^3.10.0 (Impeller Engine enabled for fluid animations).
- **Core Frameworks**: Riverpod (^2.6.1), GoRouter (^14.6.0).
- **Firebase Gen 2 (Production Standard)**: 
  - `firebase_core`: ^3.15.2
  - `firebase_auth`: ^5.3.3
  - `cloud_firestore`: ^5.5.0
  - `firebase_ai`: ^2.3.0 (Vertex AI SDK) via Cloud Functions.
- **Data Persistence**: Hive (^2.2.3) for local storage.
- **Generative AI**: `google_generative_ai` (^0.4.0).
- **Local-First Privacy**: Sensitive reflections and identity attributes stored locally via Hive.

## 5. Success Metrics
- **Daily Retention**: Percentage of users who complete at least one "vote" per day.
- **Stickiness**: Conversion from outcome-based habits to identity-based stacks.
- **Recovery Rate**: Time taken to clear entropy after a missed habit.
